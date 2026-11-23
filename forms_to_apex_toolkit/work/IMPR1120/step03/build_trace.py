"""build_trace.py - IMPR1120 step 03: traceability matrix (page spec section 14) and the registry script.

Every Forms object of forms/IMPR/IMPR1120_fmb.xml gets exactly one row: blocks, items, triggers,
relations, LOVs, record groups, canvases, windows, alerts, parameters, libraries, globals, called forms
and program units. The mapping follows analysis/IMPR1120/IMPR1120_logic_extraction.md and the page
design in analysis/IMPR1120/IMPR1120_apex_page_spec.md (sections 0-13).

Usage (from forms_to_apex_toolkit/):
    python3 -I work/IMPR1120/step03/build_trace.py
Writes : work/IMPR1120/step03/trace.md, registry/IMPR1120_registry.sql,
         analysis/IMPR1120/IMPR1120_apex_page_spec.md (= spec_manual.md with the matrix inserted)
"""
import collections
import html
import re
import xml.etree.ElementTree as ET

NS = '{http://xmlns.oracle.com/Forms}'
FORM, PAGE, SEARCH = 'IMPR1120', 1120, 112001
fm = ET.parse('forms/IMPR/IMPR1120_fmb.xml').getroot().find(NS + 'FormModule')


def U(s):
    return html.unescape(html.unescape(s or ''))


rows = []          # (type, name, apex_type, apex_name, page, member, status, notes)


def add(t, name, apex_type=None, apex_name=None, page=None, member=None, status='MAPPED', notes=''):
    rows.append((t, name, apex_type, apex_name, page, member, status, notes))


def pk(m):
    return FORM + '.' + m if m else None


# ------------------------------------------------------------------ blocks
BLOCKS = {
    'TITLE': ('REGION', 'IMPORTERS_HERO', PAGE, 'HEADER_TITLE', 'MAPPED', 'OLB title bar -> hero region (HEADER TITLE)'),
    'EDI_MSG': (None, None, None, None, 'DROPPED', 'OLB EDI message ticker - dropped (timers, IMPR1110 decision 2026-11-19)'),
    'LSIDE': ('REGION', 'FUNCS', PAGE, None, 'MAPPED', 'OLB side function menu -> inline dialog FUNCS, f345 list Page Functions'),
    'TOOLBAR': ('REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, None, 'MAPPED', 'OLB toolbar -> f345 page 0 toolbar'),
    'IMPORTERS': ('REGION', 'IMPORTERS (Form region, table IMPORTERS, primary key ROWID, read only)', PAGE, None, 'MAPPED',
                  'master, query only; search page 112001 = Enter / Execute Query'),
    'IMPR_SUSPN': ('REGION', 'IMPR_SUSPN (editable Interactive Grid on IMPR_SUSPNS)', PAGE, 'IMPR_SUSPN_SAVE_ROW', 'MAPPED',
                   'detail; WHERE SUSPN_RLSE_DT IS NULL; DML through IMPR_SUSPN_SAVE_ROW (soft delete)'),
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
    'ENTER': ('BUTTON', 'SEARCH (page 0 toolbar)', 0, 'MAPPED', 'Enter Query -> search page 112001'),
    'EXECUTE': ('BUTTON', 'SEARCH (page 0 toolbar)', 0, 'MAPPED', 'Execute Query -> search page 112001'),
    'RE_ENTER_QUERY': ('BUTTON', 'SEARCH (page 0 toolbar)', 0, 'MAPPED', ''),
    'FUN_BUT': ('BUTTON', 'FUNCS (page 0 toolbar)', 0, 'MAPPED', ''),
    'LIST_VALUE': (None, None, None, 'DROPPED', 'popup LOV icon of the item'),
    'HELP': (None, None, None, 'DROPPED', 'MS-Help obsolete'),
}
IMPORTERS_ITEMS = {
    'PORT_CD': 'Popup LOV LOV_SD_PORTS, read only unless port 99 and no record (PORT_CD_IS_READ_ONLY)',
    'PORT_NAME': 'Display Only (POST-QUERY / WHEN-CREATE-RECORD / LOV additional output)',
    'HQ_IMPR_NBR': 'Display Only', 'IMPR_NBR': 'Number Field, editable only while P0_PAGE_PK is null (entry of the importer)',
    'IMPR_TYPE_CD': 'Display Only', 'IMPR_TYPE_NAME': 'Display Only (POST-QUERY)', 'CTRY_CD': 'Display Only',
    'CRTY_ARBC_NAME': 'Display Only (POST-QUERY)', 'CITY_CODE_OF_ID': 'Display Only', 'ID_CITY_NAME': 'Display Only (POST-QUERY)',
    'IMPR_EXPR_TYPE': 'Display Only, LOV_ALLOWED_EXPORT', 'BUS_ID': 'Display Only', 'BUS_ID_TYPE_CD': 'Display Only',
    'BUS_ID_TYPE_NAME': 'Display Only (POST-QUERY)', 'BUS_ID_BRNCH': 'Display Only', 'ARBC_IMPR_NAME': 'Display Only',
    'ENG_IMPR_NAME': 'Display Only', 'IMPR_CNTCT_NAME': 'Display Only',
    'CTRY_CD_OF_ID': 'Hidden (Value Protected) - input of the POST-QUERY city lookup',
}
IMPORTERS_DROPPED = {
    'PORT_CD2': 'LOV button -> popup LOV icon', 'IMPR_TYPE_CD2': 'LOV button (item is display only)',
    'CTRY_CD2': 'LOV button (item is display only)', 'CITY_CODE_OF_ID2': 'LOV button (item is display only)',
    'BUTT': 'LOV button of BUS_ID_TYPE_CD (item is display only)',
    'SDP_PORT_STATUS': 'hidden lookup status, read nowhere', 'STATUS': 'hidden lookup status, read nowhere',
    'CTRY_CTRY_STATUS': 'hidden lookup status, read nowhere',
}
SUSPN_COLUMNS = {
    'SUSPN_STRT_DT': 'Text Field (HIJRI_DATE_FORMAT, default YYYY-MM-MI, hijri-date-default), required, default SUSPN_STRT_DT_DEFAULT',
    'SUSPN_END_DT': 'Text Field (HIJRI_DATE_FORMAT, default YYYY-MM-MI, hijri-date-default), required',
    'SUSPN_SEQ': 'Hidden, primary key (set by IMPR_SUSPN_PRE_INSERT)',
    'SUSPN_RSN_CD': 'Select List LOV_IMPR_SUSPN_RSN_CD, default SUSPN_RSN_CD_DEFAULT',
    'SUSPN_RSN_TEXT': 'Text Field, required, default SUSPN_RSN_TEXT_DEFAULT',
    'SUSPN_SIDE_CD': 'Select List LOV_SUSPN_SIDE_CD, default SUSPN_SIDE_CD_DEFAULT, read only once stored',
    'IMPR_NBR': 'Hidden, primary key (default = master item P1120_IMPR_NBR; save call NVL(:IMPR_NBR, :P1120_IMPR_NBR))',
    'PORT_CD': 'Hidden, primary key (default = master item P1120_PORT_CD; save call NVL(:PORT_CD, :P1120_PORT_CD))',
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
        elif bn == 'IMPORTERS':
            if n in IMPORTERS_ITEMS:
                add('ITEM', full, 'ITEM', 'P%d_%s' % (PAGE, n), PAGE, None, 'MAPPED', IMPORTERS_ITEMS[n])
            elif n == 'IMPR_NAME_STD':
                add('ITEM', full, 'IG_COLUMN', 'search filter on IMPR_NAME_STD (page 112001 SQL)', SEARCH,
                    pk('IMPORTERS_PRE_QUERY_NAME_STD'), 'MAPPED', 'standardised Arabic name, query only')
            else:
                add('ITEM', full, None, None, None, None, 'DROPPED', IMPORTERS_DROPPED[n])
        elif bn == 'IMPR_SUSPN':
            if n == 'SUSPN_RLSE_DT':
                add('ITEM', full, None, None, None, pk('IMPR_SUSPN_SAVE_ROW'), 'MAPPED',
                    'not a grid column: set by IMPR_SUSPN_PRE_UPDATE / IMPR_SUSPN_ON_DELETE; region WHERE SUSPN_RLSE_DT IS NULL')
            else:
                add('ITEM', full, 'IG_COLUMN', 'IMPR_SUSPN.' + n, PAGE, None, 'MAPPED', SUSPN_COLUMNS[n])

# ------------------------------------------------------------------ triggers
T = {}   # key OWNER.TRIGGER -> (apex_type, apex_name, page, member, status, notes)


def t(key, at, an, pg, mb, st, nt):
    T[key] = (at, an, pg, mb, st, nt)


t('FORM.WHEN-NEW-FORM-INSTANCE', 'PROCESS', 'WHEN-NEW-FORM-INSTANCE', PAGE, 'INIT_FORM', 'MAPPED',
  'site check; PORT_CD rule -> PORT_CD_IS_READ_ONLY; port value -> IMPORTERS WHEN-CREATE-RECORD; NIB / CG$ startup -> f345, LOVs')
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
t('IMPORTERS.PRE-QUERY', 'IG_COLUMN', 'IMPORTERS_SEARCH region SQL (page 112001)', SEARCH,
  'IMPORTERS_PRE_QUERY_PORT_CD', 'MAPPED', 'port rule + one search text P112001_SEARCH over all columns (+ IMPORTERS_PRE_QUERY_NAME_STD); Exec_Query_Now -> P0_PAGE_PK')
t('IMPORTERS.POST-QUERY', 'PROCESS', 'POST-QUERY', PAGE, 'IMPORTERS_POST_QUERY', 'MAPPED', 'Before Header after Initialize form')
t('IMPORTERS.WHEN-CREATE-RECORD', 'PROCESS', 'IMPORTERS WHEN-CREATE-RECORD', PAGE, 'IMPORTERS_WHEN_CREATE_RECORD', 'MAPPED',
  'Before Header when P0_PAGE_PK is null')
t('IMPORTERS.ON-ERROR', 'TEXT_MESSAGE', 'APP_ERROR_HANDLER (f345)', None, None, 'MAPPED', 'Designer constraint messages')
t('IMPORTERS.KEY-HELP', None, None, None, None, 'DROPPED', 'MS-Help obsolete')
t('IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM', 'VALIDATION', 'IMPR_NBR VALIDATION + DA IMPR_NBR WHEN-VALIDATE-ITEM + process EXECUTE-QUERY',
  PAGE, 'IMPR_NBR_VALIDATION', 'MAPPED', 'also IMPR1120.IMPR_NBR_WHEN_VALIDATE_ITEM (process EXECUTE-QUERY)')
t('IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM', None, None, None, None, 'DROPPED',
  'item display only; names come from IMPORTERS_POST_QUERY')
t('IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE', 'DYNAMIC_ACTION', 'IMPR_NBR WHEN-VALIDATE-ITEM (Submit EXECUTE_QUERY)', PAGE,
  None, 'MAPPED', 'CLEAR_BLOCK + EXECUTE_QUERY -> page submit')
for it in ('PORT_CD',):
    t('IMPORTERS.%s.KEY-LISTVAL' % it, 'LOV', 'LOV_SD_PORTS (Popup LOV of P1120_PORT_CD; on 112001 the port is part of the search text)', PAGE, None, 'MAPPED',
      'CALL_FORM LOV_SD_PORTS')
for it, lov in (('IMPR_TYPE_CD', 'LOV_Impr_Type'), ('CTRY_CD', 'LOV_COUNTRIES'), ('CITY_CODE_OF_ID', 'LOV_CITIES')):
    t('IMPORTERS.%s.KEY-LISTVAL' % it, 'IG_COLUMN', 'IMPORTERS_SEARCH column filter (page 112001)', SEARCH, None, 'MAPPED',
      'CALL_FORM %s used as query criterion -> IG column filter' % lov)
t('IMPR_SUSPN.WHEN-NEW-RECORD-INSTANCE', 'IG_COLUMN', 'Read Only of every IMPR_SUSPN column (For Each Row)', PAGE,
  'IMPR_SUSPN_IS_READ_ONLY', 'MAPPED', 'NEXT_RECORD -> row read only + server check; stored side -> SUSPN_SIDE_CD_IS_READ_ONLY; GO_ITEM dropped')
t('IMPR_SUSPN.POST-QUERY', 'IG_COLUMN', 'IMPR_SUSPN.SUSPN_SIDE_CD Read Only', PAGE, 'SUSPN_SIDE_CD_IS_READ_ONLY', 'MAPPED', '')
t('IMPR_SUSPN.PRE-INSERT', 'PROCESS', 'IMPR_SUSPN - Save Interactive Grid Data', PAGE, 'IMPR_SUSPN_PRE_INSERT', 'MAPPED',
  'called by IMPR_SUSPN_SAVE_ROW (row status C)')
t('IMPR_SUSPN.POST-INSERT', 'PROCESS', 'IMPR_SUSPN - Save Interactive Grid Data', PAGE, 'IMPR_SUSPN_POST_INSERT', 'MAPPED',
  'called by IMPR_SUSPN_SAVE_ROW; COMMIT removed (HIGH); enabling part -> SUSPN_SIDE_CD_IS_READ_ONLY')
t('IMPR_SUSPN.PRE-UPDATE', 'PROCESS', 'IMPR_SUSPN - Save Interactive Grid Data', PAGE, 'IMPR_SUSPN_PRE_UPDATE', 'MAPPED',
  'called by IMPR_SUSPN_SAVE_ROW (row status U)')
t('IMPR_SUSPN.ON-DELETE', 'PROCESS', 'IMPR_SUSPN - Save Interactive Grid Data', PAGE, 'IMPR_SUSPN_ON_DELETE', 'MAPPED',
  'soft delete, called by IMPR_SUSPN_SAVE_ROW (row status D)')
t('IMPR_SUSPN.KEY-DELREC', 'IG_COLUMN', 'IMPR_SUSPN row delete (native confirm)', PAGE, None, 'MAPPED',
  'TMPLT.KEY_DELETE_RECORD: confirm + delete + COMMIT -> IG delete, APEX commit')
t('IMPR_SUSPN.ON-ERROR', 'TEXT_MESSAGE', 'IS_1_IMP_FK (Text Message) + APP_ERROR_HANDLER', None, None, 'MAPPED', '')
t('IMPR_SUSPN.KEY-HELP', None, None, None, None, 'DROPPED', 'MS-Help obsolete')
t('IMPR_SUSPN.SUSPN_STRT_DT.WHEN-NEW-ITEM-INSTANCE', 'IG_COLUMN', 'IMPR_SUSPN.SUSPN_STRT_DT default', PAGE, 'SUSPN_STRT_DT_DEFAULT', 'MAPPED', '')
t('IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM', 'VALIDATION',
  'IMPR_SUSPN SUSPN_STRT_DT VALIDATION + DA IMPR_SUSPN SUSPN_STRT_DT WHEN-VALIDATE-ITEM', PAGE, 'SUSPN_STRT_DT_VALIDATION', 'MAPPED', '')
t('IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM', 'VALIDATION',
  'IMPR_SUSPN SUSPN_END_DT VALIDATION + DA IMPR_SUSPN SUSPN_END_DT WHEN-VALIDATE-ITEM', PAGE, 'SUSPN_END_DT_VALIDATION', 'MAPPED', '')
t('IMPR_SUSPN.SUSPN_RLSE_DT.WHEN-VALIDATE-ITEM', None, None, None, None, 'DROPPED', 'hidden, non-navigable item: never fires')
t('IMPR_SUSPN.SUSPN_RSN_CD.WHEN-NEW-ITEM-INSTANCE', 'IG_COLUMN', 'IMPR_SUSPN.SUSPN_RSN_CD / SUSPN_RSN_TEXT defaults', PAGE,
  'SUSPN_RSN_CD_DEFAULT', 'MAPPED', 'with SUSPN_RSN_TEXT_DEFAULT')
t('IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM', 'VALIDATION',
  'IMPR_SUSPN SUSPN_RSN_CD VALIDATION + DA IMPR_SUSPN SUSPN_RSN_CD WHEN-VALIDATE-ITEM', PAGE, 'SUSPN_RSN_CD_VALIDATION', 'MAPPED',
  'derived SUSPN_RSN_TEXT -> SUSPN_RSN_CD_VALIDATE_ITEM')
t('IMPR_SUSPN.SUSPN_RSN_TEXT.WHEN-NEW-ITEM-INSTANCE', None, None, None, None, 'DROPPED', 'body is NULL')
t('IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-NEW-ITEM-INSTANCE', 'IG_COLUMN', 'IMPR_SUSPN.SUSPN_SIDE_CD default', PAGE, 'SUSPN_SIDE_CD_DEFAULT', 'MAPPED', '')
t('IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-LIST-CHANGED', 'DYNAMIC_ACTION', 'IMPR_SUSPN SUSPN_SIDE_CD WHEN-LIST-CHANGED', PAGE,
  'SUSPN_SIDE_CD_VALIDATION', 'MAPPED', '')
t('IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-VALIDATE-ITEM', 'VALIDATION', 'IMPR_SUSPN SUSPN_SIDE_CD VALIDATION', PAGE,
  'SUSPN_SIDE_CD_VALIDATION', 'MAPPED', '')


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
    if name == 'KEY-LISTVAL' and blk in ('IMPORTERS', 'IMPR_SUSPN'):
        return (None, None, None, None, 'DROPPED', 'Designer "may the LOV be shown" check -> item read-only state')
    if name == 'KEY-F4' and blk == 'IMPR_SUSPN':
        return (None, None, None, None, 'DROPPED', 'INTRFACE.DISP_DATE_CON -> date column (Hijri picker)')
    if name == 'WHEN-BUTTON-PRESSED' and blk == 'IMPORTERS':
        return (None, None, None, None, 'DROPPED', 'LOV button -> popup LOV icon / item display only')
    return None


def owner_of(trg, parents):
    return '.'.join(parents)


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

# ------------------------------------------------------------------ relations (nested in the master block)
for b in blocks:
    for r in b.findall(NS + 'Relation'):
        add('RELATION', r.get('Name'), 'REGION', 'IMPR_SUSPN (IG WHERE port_cd = :P1120_PORT_CD AND impr_nbr = :P1120_IMPR_NBR)',
            PAGE, None, 'MAPPED', '%s -> %s; master keys from the master form (column default + NVL in the save call)' % (b.get('Name'), r.get('DetailBlock')))

# ------------------------------------------------------------------ LOVs and record groups
LOVS = {
    'CGFK$IMPORTERS_PORT_CD': ('LOV', 'LOV_SD_PORTS (from IMPR1110)', PAGE, 'MAPPED', 'P1120_PORT_CD (port 99 only)'),
    'CGFK$IMPORTERS_CITY_CODE_OF_ID': (None, None, None, 'DROPPED', 'item display only; search by IG column filter'),
    'CGFK$IMPORTERS_CTRY_CD': (None, None, None, 'DROPPED', 'item display only; search by IG column filter'),
    'CGFK$IMPORTERS_HQ_IMPR_NBR': (None, None, None, 'DROPPED', 'item display only'),
    'CGFK$IMPORTERS_IMPR_TYPE_CD': (None, None, None, 'DROPPED', 'item display only; search by IG column filter'),
}
for lv in fm.findall(NS + 'LOV'):
    a = LOVS[lv.get('Name')]
    add('LOV', lv.get('Name'), a[0], a[1], a[2], None, a[3], a[4])
for rg in fm.findall(NS + 'RecordGroup'):
    a = LOVS[rg.get('Name')]
    add('RECORD_GROUP', rg.get('Name'), a[0], a[1], a[2], None, a[3], 'query of LOV ' + rg.get('Name'))
add('RECORD_GROUP', 'CGDV$DLRG (runtime)', 'LOV', 'LOV_ALLOWED_EXPORT, LOV_IMPR_SUSPN_RSN_CD, LOV_SUSPN_SIDE_CD', PAGE, None, 'MAPPED',
    'CREATE_GROUP_FROM_QUERY on CG_REF_CODES in CGDV$POPULATE_DYNAMIC_LISTS')

# ------------------------------------------------------------------ canvases, windows
for c in fm.findall(NS + 'Canvas'):
    if c.get('Name') == 'CG$PAGE_1':
        add('CANVAS', 'CG$PAGE_1', 'PAGE', '1120 IMPR1120', PAGE, None, 'MAPPED', 'main content canvas')
    else:
        add('CANVAS', c.get('Name'), None, None, None, None, 'DROPPED', 'OLB canvas ' + c.get('Name'))
for w in fm.findall(NS + 'Window'):
    add('WINDOW', w.get('Name'), 'PAGE', '1120 IMPR1120', PAGE, None, 'MAPPED', 'console window')

# ------------------------------------------------------------------ alerts
ALERTS = {
    'CFG_ERROR': ('TEXT_MESSAGE', 'CHECK_ERROR / FORMS_APX.FORM_TRIGGER_FAILURE (inline error)', 'MAPPED',
                  'STR.DispArbMsg ERROR 9-100, 9-110; DispAlert SYSTEM_ERROR'),
    'CFG_SYSTEM_ERROR': ('TEXT_MESSAGE', 'FORMS_APX.FORM_TRIGGER_FAILURE (activity log / Hijri date errors)', 'MAPPED', ''),
    'CFG_INFORMATION': ('TEXT_MESSAGE', 'validation error text (message 9-150 stops the query in Forms too)', 'MAPPED', ''),
    'USR_WARNING_B': ('DYNAMIC_ACTION', 'IG row delete confirm "هل أنت متأكد من عملية الحذف"', 'MAPPED', 'TMPLT.KEY_DELETE_RECORD'),
}
for al in fm.findall(NS + 'Alert'):
    a = ALERTS.get(al.get('Name'))
    if a:
        add('ALERT', al.get('Name'), a[0], a[1], PAGE, None, a[2], a[3])
    else:
        add('ALERT', al.get('Name'), None, None, None, None, 'DROPPED', 'not used by IMPR1120 code')

# ------------------------------------------------------------------ parameters
PARAMS = {
    'CURRENT_SIDE': ('ITEM', 'P1120_P_CURRENT_SIDE', PAGE, 'GET_CURRENT_SIDE', 'MAPPED', 'source to confirm (inventory §15 #1)'),
    'P_CURR_PORT_CD': ('APP_ITEM', 'P_CURR_PORT_CD (f345)', None, None, 'MAPPED', ''),
    'P_USER_ID': ('APP_ITEM', 'SSO_APP_USER (f345)', None, None, 'MAPPED', 'ACTIVITY_DB user'),
    'P_WS_ID': ('APP_ITEM', 'P_GLOBAL_V_WS_ID (f345)', None, None, 'MAPPED', 'ACTIVITY_DB workstation'),
    'P_MODULE_ID': ('ITEM', 'P1120_MODULE_ID', PAGE, 'GET_MODULE_ID', 'MAPPED', ''),
    'P_PORT_TYPE': ('APP_ITEM', 'P_PORT_TYPE (f345)', None, None, 'MAPPED', 'bind of LOV_SD_PORTS'),
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
    'CIC_LIB': ('MAPPED', 'NIB / TMPLT -> f345; STR -> STR_DB; HIJDATE -> HIJDATE_DB; ACTIVITY -> ACTIVITY_DB; INTRFACE -> date column'),
    'OFGBSL': ('MAPPED', 'CGBS$ master-detail -> native Form + IG'),
    'CIC_AMSG': ('MAPPED', 'Des$Form_errors messages -> FORMS_APX / APP_ERROR_HANDLER'),
    'OFGTEL': ('TODO', 'MISSING SOURCE - constraint messages (CGTE$); block texts known, Text Messages per constraint'),
}
for lb in fm.findall(NS + 'AttachedLibrary'):
    a = LIBS.get(lb.get('Name'), ('DROPPED', 'not needed in the browser (help, DLL, window, tab, pick list)'))
    add('LIBRARY', lb.get('Name'), None, None, None, None, a[0], a[1])

# ------------------------------------------------------------------ globals (from the decoded code)
GLOBALS = {
    'EXEC_QUERY_NOW': 'P0_PAGE_PK (process EXECUTE-QUERY)', 'PORT_CD': 'P0_PAGE_PK / LOV return', 'IMPR_NBR': 'P0_PAGE_PK',
    'PORT_NAME': 'LOV additional output of P1120_PORT_CD',
}
code = ' '.join(U(x.get('TriggerText')) for x in fm.iter(NS + 'Trigger')) + ' ' + \
       ' '.join(U(x.get('ProgramUnitText')) for x in fm.iter(NS + 'ProgramUnit'))
code_nc = re.sub(r'--[^\n]*|/\*.*?\*/', ' ', code, flags=re.S)
for g in sorted(set(x.upper() for x in re.findall(r':GLOBAL\.(\w+[$\w]*)', code_nc, re.I))):
    if g in GLOBALS:
        add('GLOBAL', g, 'ITEM', GLOBALS[g], PAGE, None, 'MAPPED', 'no G_ application item needed')
    else:
        add('GLOBAL', g, None, None, None, None, 'DROPPED',
            'LOV-form return value / Designer internal / version stamp / function menu - not needed')

# ------------------------------------------------------------------ called forms
for f, (at, an, pg, nt) in {
    'LOV_SD_PORTS': ('LOV', 'LOV_SD_PORTS', PAGE, 'PORT_CD KEY-LISTVAL'),
    'LOV_IMPR_TYPE': ('IG_COLUMN', 'IMPORTERS_SEARCH column filter IMPR_TYPE_CD', SEARCH, 'IMPR_TYPE_CD KEY-LISTVAL'),
    'LOV_COUNTRIES': ('IG_COLUMN', 'IMPORTERS_SEARCH column filter CTRY_CD', SEARCH, 'CTRY_CD KEY-LISTVAL'),
    'LOV_CITIES': ('IG_COLUMN', 'IMPORTERS_SEARCH column filter CITY_CODE_OF_ID', SEARCH, 'CITY_CODE_OF_ID KEY-LISTVAL'),
}.items():
    add('CALLED_FORM', f, at, an, pg, None, 'MAPPED', nt)
add('CALLED_FORM', 'V_CALLED_FORM (dynamic, PU EXECUTE_FUNCTION)', 'REGION', 'FUNCS (Page Functions list)', PAGE, None, 'TODO',
    'functions of the module in SC_SYSTEM_OBJECTS unknown (inventory §15 #9)')
add('CALLED_FORM', 'calendar forms (INTRFACE.DISP_CALENDAR / DISP_DATE_CON)', 'IG_COLUMN', 'hijri-date-default date columns', PAGE, None,
    'MAPPED', 'date KEY-LISTVAL / KEY-F4')

# ------------------------------------------------------------------ program units
PU = {
    'CGFK$QRY_IMPORTERS_IMP_SDP_FK': 'MAPPED', 'CGFK$QRY_IMPORTERS_IMP_ITIDT_F': 'MAPPED',
    'CGFK$QRY_IMPORTERS_IMP_CTRY_FK': 'MAPPED', 'CGFK$QRY_IMPORTERS_IMP_BUS_ID_': 'MAPPED',
}
PU_NOTE = {
    'CG$WHEN_NEW_FORM_INSTANCE': 'lists + block-sync startup -> shared LOVs / native master-detail',
    'CGDV$POPULATE_DYNAMIC_LISTS': 'shared LOVs on CG_REF_CODES',
    'EXECUTE_FUNCTION': 'f345 Page Functions (FUNCS)', 'MOUSE_CLICK': 'f345 Page Functions (FUNCS)',
    'ADJ_FUNS': 'empty in Forms', 'EXEC_FUNS': 'empty in Forms', 'CGTE$CHECK_CONSTRAINT_VIO': 'APP_ERROR_HANDLER',
    'CG$IMPR1120_GLOBALS': 'Designer dynamic WHERE holder',
    'CGFK$CHK_IMPORTERS_IMP_ITIDT_F': 'with IMPR_TYPE_CD WHEN-VALIDATE-ITEM (item display only)',
}
for p in fm.findall(NS + 'ProgramUnit'):
    n = p.get('Name')
    if n in PU:
        add('PROGRAM_UNIT', n, None, None, PAGE, pk(n), 'MAPPED', 'same name; called by IMPORTERS_POST_QUERY')
    else:
        add('PROGRAM_UNIT', n, None, None, None, None, 'DROPPED',
            PU_NOTE.get(n, 'not called by active code (NIB wrapper / Designer check / query-mode toggle)'))

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
open('work/IMPR1120/step03/trace.md', 'w', encoding='utf-8').write(trace)


def q(v):
    if v is None or v == '':
        return 'NULL'
    if isinstance(v, int):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"


reg = ["""-- =============================================================================
-- IMPR1120 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (traceability matrix, analysis/IMPR1120/IMPR1120_apex_page_spec.md section 14)
-- Form    : IMPR1120.fmb
-- Author  : Claude Code
-- Date    : 2026-11-23
-- Version : 1.0 (step 03 revision 1, package IMPR1120 version 008)
-- Generated by work/IMPR1120/step03/build_trace.py - %s
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR1120';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR1120';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR1120', 'IMPR', 'IMPR', 202530, 1120, 1120, 'IMPR1120',
     'IMPR1120', 'COMPLEX', 'DESIGN', NULL, NULL,
     'صيانة توقيفات المستوردين - step 03 rev 1 page design (pages 1120, 112001); package IMPR1120 008 not compiled');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR1120', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN""" % summary]
for r in rows:
    reg.append('    m(%s);' % ', '.join(q(x) for x in r))
reg.append('END;\n/\n\nCOMMIT;\n')
open('registry/IMPR1120_registry.sql', 'w', encoding='utf-8').write('\n'.join(reg))

spec = open('work/IMPR1120/step03/spec_manual.md', encoding='utf-8').read()
assert '<!-- TRACE -->' in spec
open('analysis/IMPR1120/IMPR1120_apex_page_spec.md', 'w', encoding='utf-8').write(spec.replace('<!-- TRACE -->', trace))
print(summary)
print('by type:', by_type)
