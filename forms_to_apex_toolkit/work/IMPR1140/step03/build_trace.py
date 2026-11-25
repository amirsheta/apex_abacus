"""build_trace.py - IMPR1140 step 03: traceability matrix (page spec section 14) and the registry script.

Every Forms object of forms/IMPR/IMPR1140_fmb.xml gets exactly one row: blocks, items, triggers, relations,
LOVs, record groups, canvases, tab pages, windows, alerts, parameters, libraries, program units, visual
attributes, globals and called forms. The mapping follows analysis/IMPR1140/IMPR1140_logic_extraction.md and
the page design in work/IMPR1140/step03/spec_manual.md (sections 0-13).

Usage (from forms_to_apex_toolkit/):
    python3 -I work/IMPR1140/step03/build_trace.py
Writes : registry/IMPR1140_registry.sql,
         analysis/IMPR1140/IMPR1140_apex_page_spec.md (= spec_manual.md with the matrix inserted)
"""
import collections
import html
import re
import xml.etree.ElementTree as ET

NS = '{http://xmlns.oracle.com/Forms}'
FORM, PAGE, SEARCH = 'IMPR1140', 1140, 114001
fm = ET.parse('forms/IMPR/IMPR1140_fmb.xml').getroot().find(NS + 'FormModule')
rows = []          # (type, name, apex_type, apex_name, page, member, status, notes)


def U(s):
    return html.unescape(html.unescape(s or ''))


def add(t, name, apex_type=None, apex_name=None, page=None, member=None, status='MAPPED', notes=''):
    rows.append((t, name, apex_type, apex_name, page, (FORM + '.' + member) if member else None, status, notes))


FRAME = ('TITLE', 'EDI_MSG', 'LSIDE', 'TOOLBAR', 'CG$CTRL')
# ------------------------------------------------------------------ blocks
BLOCKS = {
    'TITLE': ('REGION', 'IMPR_RULES_HERO', PAGE, None, 'MAPPED', 'OLB title bar -> hero region (HEADER TITLE)'),
    'EDI_MSG': (None, None, None, None, 'DROPPED', 'OLB EDI ticker - dropped (timers, IMPR1110 decision 2026-11-19)'),
    'LSIDE': ('REGION', 'FUNCS (page 0 side drawer)', 0, None, 'MAPPED', 'OLB side function menu -> page 0 FUNCS, list Page Functions'),
    'TOOLBAR': ('REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, None, 'MAPPED', 'OLB toolbar -> f345 page 0 toolbar'),
    'IMPR_RULES': ('REGION', 'IMPR_RULES (Form region on IMPR_RULES, key ROWID)', PAGE, None, 'MAPPED', 'master; search page 114001 = Enter / Execute Query'),
    'IMPR_RULE_PORTS': ('REGION', 'IMPR_RULE_PORTS (editable IG in tab CG$M_TAB_1)', PAGE, 'IMPR_RULE_PORTS_SAVE_ROW', 'MAPPED',
                        'detail; WHERE PORT_CD = :P_CURR_PORT_CD; PL/SQL row DML'),
    'IMPR_RULE_TARIFF': ('REGION', 'IMPR_RULE_TARIFF (editable IG i:u in tab CG$M_TAB_1)', PAGE, 'IMPR_RULE_TARIFF_SAVE_ROW', 'MAPPED',
                         'detail; Delete Allowed = false; PL/SQL row DML'),
    'CG$CTRL': (None, None, None, None, 'DROPPED', 'Designer control block (tab bookkeeping)'),
}
blocks = fm.findall(NS + 'Block')
for b in blocks:
    a = BLOCKS[b.get('Name')]
    add('BLOCK', b.get('Name'), a[0], a[1], a[2], a[3], a[4], a[5])

# ------------------------------------------------------------------ items
TOOLBAR = {'SAVE': 'SAVE / CREATE', 'EXIT': 'BACK', 'EXIT1': 'BACK', 'CLEAR_ALL': 'CLEAR', 'REMOVE': 'DELETE (+ IG row delete)',
           'ENTER_QUERY': 'SEARCH', 'EXECUTE': 'SEARCH (page 114001)', 'RE_ENTER_QUERY': 'SEARCH', 'FUN_BUT': 'FUNCS',
           'INSERT': 'CREATE / IG add row', 'PRINT': 'FUNCS (Page Functions)'}
MASTER = {'RULE_ISN': 'P1140_RULE_ISN', 'RULE_TYPE': 'P1140_RULE_TYPE', 'ALL_BRNCH_FLAG': 'P1140_ALL_BRNCH_FLAG',
          'HQ_IMPR_NBR': 'P1140_HQ_IMPR_NBR', 'L_SI_ARBC_IMPR_NAME': 'P1140_L_SI_ARBC_IMPR_NAME', 'REC_STATUS': 'P1140_REC_STATUS',
          'BUS_ID_TYPE_CD': 'P1140_BUS_ID_TYPE_CD', 'BUS_ID_TYPE_NAME': 'P1140_BUS_ID_TYPE_NAME', 'BUS_ID': 'P1140_BUS_ID',
          'BUS_ID_BRNCH': 'P1140_BUS_ID_BRNCH'}
LOV_BUTTONS = {'B_IMP': 'P1140_HQ_IMPR_NBR', 'PORT_CD2': 'IMPR_RULE_PORTS.PORT_CD', 'HRMNZD_CODE2': 'IMPR_RULE_TARIFF.HRMNZD_CODE'}
for b in blocks:
    bn = b.get('Name')
    for it in b.findall(NS + 'Item'):
        n = it.get('Name')
        full = bn + '.' + n
        if bn == 'TOOLBAR':
            if n in TOOLBAR:
                add('ITEM', full, 'BUTTON', TOOLBAR[n] + ' (page 0 toolbar)', 0, None, 'MAPPED', 'OLB toolbar button')
            else:
                add('ITEM', full, None, None, None, None, 'DROPPED', 'OLB toolbar navigation button (record / page scrolling: IG)')
        elif bn in FRAME:
            add('ITEM', full, None, None, None, None, 'DROPPED', 'frame item (%s)' % bn)
        elif bn == 'IMPR_RULES':
            if n in MASTER:
                add('ITEM', full, 'PAGE ITEM', MASTER[n], PAGE, None, 'MAPPED', 'spec 4.1')
            elif n in LOV_BUTTONS:
                add('ITEM', full, 'PAGE ITEM', LOV_BUTTONS[n] + ' (Popup LOV icon)', PAGE, None, 'MAPPED', 'LOV button')
            else:
                add('ITEM', full, None, None, None, None, 'DROPPED', 'non-database item made invisible in PRE-FORM')
        else:
            if n in LOV_BUTTONS:
                add('ITEM', full, 'IG COLUMN', LOV_BUTTONS[n] + ' (Popup LOV icon)', PAGE, None, 'MAPPED', 'LOV button')
            else:
                add('ITEM', full, 'IG COLUMN', bn + '.' + n, PAGE, None, 'MAPPED', 'spec 4.3' + (' (column EXCEPTED_QTY)' if n == 'EXEPTION_QTY' else ''))

# ------------------------------------------------------------------ relations
for b in blocks:
    for r in b.findall(NS + 'Relation'):
        add('RELATION', r.get('Name'), 'IG SQL', '%s WHERE rule_isn = :P1140_RULE_ISN' % r.get('DetailBlock'), PAGE, None, 'MAPPED',
            'master-detail on RULE_ISN; details shown when P0_PAGE_PK is not null')

# ------------------------------------------------------------------ triggers
T = {   # (owner, trigger) -> (apex type, apex name, member, status, note)
    ('IMPR_RULES', 'POST-QUERY'): ('PROCESS', 'POST-QUERY', 'POST_QUERY', 'MAPPED', 'Before Header 82'),
    ('IMPR_RULES', 'PRE-QUERY'): ('REGION SQL', 'IMPR_RULES_SEARCH (page 114001)', None, 'MAPPED', 'BUS_ID_TYPE_NAME criterion in the search text'),
    ('IMPR_RULES', 'KEY-DELREC'): ('PROCESS', 'KEY-DELREC', 'KEY_DELREC', 'MAPPED', 'confirm = page 0 DELETE; delete = Process form - DELETE'),
    ('IMPR_RULES', 'PRE-INSERT'): ('PROCESS', 'PRE-INSERT', 'PRE_INSERT', 'MAPPED', ''),
    ('IMPR_RULES', 'POST-INSERT'): ('PROCESS', 'POST-INSERT', 'POST_INSERT', 'MAPPED', 'SMS (LIB_USR.SMS_MESSAGE missing source)'),
    ('IMPR_RULES', 'PRE-UPDATE'): ('PROCESS', 'PRE-UPDATE', 'PRE_UPDATE', 'MAPPED', ''),
    ('IMPR_RULES', 'POST-UPDATE'): ('PROCESS', 'POST-UPDATE', 'POST_UPDATE', 'MAPPED', 'activity log + SMS'),
    ('IMPR_RULES', 'PRE-DELETE'): ('PROCESS', 'PRE-DELETE', 'PRE_DELETE', 'MAPPED', ''),
    ('IMPR_RULES', 'WHEN-NEW-RECORD-INSTANCE'): ('DA', 'ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM (fire on initialization)', 'ADJ_BRANCH', 'MAPPED', ''),
    ('IMPR_RULES.RULE_TYPE', 'WHEN-LIST-CHANGED'): ('DA', 'RULE_TYPE WHEN-LIST-CHANGED', 'RULE_TYPE_VALIDATION', 'MAPPED', ''),
    ('IMPR_RULES.RULE_TYPE', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'RULE_TYPE VALIDATION', 'RULE_TYPE_VALIDATION', 'MAPPED', ''),
    ('IMPR_RULES.ALL_BRNCH_FLAG', 'WHEN-VALIDATE-ITEM'): ('DA', 'ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM + process of the same name', 'ADJ_BRANCH', 'MAPPED', ''),
    ('IMPR_RULES.HQ_IMPR_NBR', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'HQ_IMPR_NBR VALIDATION + DA HQ_IMPR_NBR WHEN-VALIDATE-ITEM', 'HQ_IMPR_NBR_VALIDATE_ITEM', 'MAPPED', 'also HQ_IMPR_NBR_VALIDATION'),
    ('IMPR_RULES.HQ_IMPR_NBR', 'KEY-LISTVAL'): ('LOV', 'LOV_SINGLE_IMPORTERS (Popup LOV)', None, 'MAPPED', 'SINGLE_IMP_LOV'),
    ('IMPR_RULES.B_IMP', 'WHEN-BUTTON-PRESSED'): ('LOV', 'Popup LOV icon of P1140_HQ_IMPR_NBR', None, 'MAPPED', ''),
    ('IMPR_RULE_PORTS', 'POST-QUERY'): ('IG SQL', 'IMPR_RULE_PORTS (join SD_PORTS)', 'IMPR_RULE_PORTS_INSERT_ALLOWED', 'MAPPED', 'insert-allowed part -> server check'),
    ('IMPR_RULE_PORTS', 'PRE-RECORD'): ('PROCESS', 'IMPR_RULE_PORTS - Save Interactive Grid Data', 'IMPR_RULE_PORTS_INSERT_ALLOWED', 'MAPPED', 'server check in PRE-INSERT'),
    ('IMPR_RULE_PORTS', 'WHEN-NEW-RECORD-INSTANCE'): ('PROCESS', 'IMPR_RULE_PORTS - Save Interactive Grid Data', 'IMPR_RULE_PORTS_INSERT_ALLOWED', 'MAPPED', 'server check in PRE-INSERT'),
    ('IMPR_RULE_PORTS', 'PRE-INSERT'): ('PROCESS', 'IMPR_RULE_PORTS - Save Interactive Grid Data', 'IMPR_RULE_PORTS_PRE_INSERT', 'MAPPED', 'row status C'),
    ('IMPR_RULE_PORTS', 'PRE-UPDATE'): ('PROCESS', 'IMPR_RULE_PORTS - Save Interactive Grid Data', 'IMPR_RULE_PORTS_PRE_UPDATE', 'MAPPED', 'row status U'),
    ('IMPR_RULE_PORTS', 'PRE-DELETE'): ('PROCESS', 'IMPR_RULE_PORTS - Save Interactive Grid Data', 'IMPR_RULE_PORTS_PRE_DELETE', 'MAPPED', 'row status D'),
    ('IMPR_RULE_PORTS.PORT_CD', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'IMPR_RULE_PORTS PORT_CD VALIDATION + DA IMPR_RULE_PORTS PORT_CD WHEN-VALIDATE-ITEM', 'PORT_CD_WHEN_VALIDATE_ITEM', 'MAPPED', 'also PORT_CD_VALIDATION'),
    ('IMPR_RULE_PORTS.PORT_CD', 'KEY-LISTVAL'): ('LOV', 'LOV_SD_PORTS (Popup LOV column)', None, 'MAPPED', 'CALL_SD_PORTS'),
    ('IMPR_RULE_PORTS.PORT_CD2', 'WHEN-BUTTON-PRESSED'): ('LOV', 'Popup LOV icon of PORT_CD', None, 'MAPPED', ''),
    ('IMPR_RULE_TARIFF', 'POST-QUERY'): ('IG SQL', 'IMPR_RULE_TARIFF column INTL_UNIT', 'IMPR_RULE_TARIFF_POST_QUERY', 'MAPPED', ''),
    ('IMPR_RULE_TARIFF', 'PRE-INSERT'): ('PROCESS', 'IMPR_RULE_TARIFF - Save Interactive Grid Data', 'IMPR_RULE_TARIFF_PRE_INSERT', 'MAPPED', 'row status C'),
    ('IMPR_RULE_TARIFF', 'PRE-UPDATE'): ('PROCESS', 'IMPR_RULE_TARIFF - Save Interactive Grid Data', 'IMPR_RULE_TARIFF_PRE_UPDATE', 'MAPPED', 'row status U'),
    ('IMPR_RULE_TARIFF', 'PRE-DELETE'): (None, None, None, 'DROPPED', 'Delete Allowed = false: cannot fire; delete refused in IMPR_RULE_TARIFF_SAVE_ROW'),
    ('IMPR_RULE_TARIFF.HRMNZD_CODE', 'WHEN-VALIDATE-ITEM'): ('VALIDATION', 'IMPR_RULE_TARIFF HRMNZD_CODE VALIDATION + DA IMPR_RULE_TARIFF HRMNZD_CODE WHEN-VALIDATE-ITEM', 'HRMNZD_CODE_VALIDATE_ITEM', 'MAPPED', 'also HRMNZD_CODE_VALIDATION'),
    ('IMPR_RULE_TARIFF.HRMNZD_CODE', 'POST-CHANGE'): ('DA', 'IMPR_RULE_TARIFF HRMNZD_CODE WHEN-VALIDATE-ITEM', 'HRMNZD_CODE_VALIDATE_ITEM', 'MAPPED', 'merged (same description lookup)'),
    ('IMPR_RULE_TARIFF.HRMNZD_CODE', 'KEY-LISTVAL'): ('LOV', 'LOV_HARMONIZED_TARIFF (Popup LOV column)', None, 'MAPPED', 'DSP_TRF_ITEMS_LOV'),
    ('IMPR_RULE_TARIFF.HRMNZD_CODE2', 'WHEN-BUTTON-PRESSED'): ('LOV', 'Popup LOV icon of HRMNZD_CODE', None, 'MAPPED', ''),
    ('IMPR_RULE_TARIFF.EXEPTION_QTY', 'WHEN-VALIDATE-ITEM'): ('DA', 'IMPR_RULE_TARIFF EXEPTION_QTY WHEN-VALIDATE-ITEM', 'EXEPTION_QTY_VALIDATE_ITEM', 'MAPPED', 'FOS + native Alert'),
    ('FORM', 'PRE-FORM'): (None, None, None, 'DROPPED', 'NIB.PRE_FORM / version stamps / hide D / date format -> f345 shell'),
    ('FORM', 'WHEN-NEW-FORM-INSTANCE'): (None, None, None, 'DROPPED', 'NIB + Designer start-up -> f345 shell, shared LOVs, native master-detail'),
    ('FORM', 'WHEN-TAB-PAGE-CHANGED'): ('REGION', 'CG$M_TAB_1 (Tabs Container)', None, 'MAPPED', 'native tabs'),
}
KEY_TOOLBAR = {'KEY-EXIT': 'BACK', 'KEY-ENTQRY': 'SEARCH', 'KEY-EXEQRY': 'SEARCH', 'KEY-CLRBLK': 'CLEAR', 'KEY-CLRFRM': 'CLEAR',
               'KEY-CLRREC': 'CLEAR', 'KEY-DELREC': 'DELETE', 'KEY-F9': 'FUNCS', 'KEY-PRINT': 'FUNCS', 'KEY-COMMIT': 'SAVE'}


def trigger_rows(owner, trg):
    n = trg.get('Name')
    code = U(trg.get('TriggerText'))
    key = (owner, n)
    if key in T:
        a = T[key]
        add('TRIGGER', owner + '.' + n, a[0], a[1], PAGE if a[0] else None, a[2], a[3], a[4])
        return
    lvl0 = owner.split('.')[0]
    if lvl0 in FRAME or (lvl0 == 'FORM' and not code.strip()):
        add('TRIGGER', owner + '.' + n, None, None, None, None, 'DROPPED', 'frame / OLB trigger')
    elif n in KEY_TOOLBAR and owner == 'FORM':
        add('TRIGGER', owner + '.' + n, 'BUTTON', KEY_TOOLBAR[n] + ' (page 0 toolbar)', 0, None, 'MAPPED', 'NIB key delegation')
    elif n == 'KEY-LISTVAL':
        add('TRIGGER', owner + '.' + n, None, None, None, None, 'DROPPED', 'Designer "may the LOV be shown" check -> item read-only state')
    elif n == 'KEY-HELP':
        add('TRIGGER', owner + '.' + n, None, None, None, None, 'DROPPED', 'MS-Help (obsolete)')
    elif n in ('ON-ERROR', 'ON-MESSAGE'):
        add('TRIGGER', owner + '.' + n, 'APPLICATION', 'APP_ERROR_HANDLER + Text Messages', 0, None, 'MAPPED', 'f345 error handling')
    elif n.startswith('WHEN-TIMER') or n.startswith('WHEN-WINDOW') or n.startswith('WHEN-MOUSE'):
        add('TRIGGER', owner + '.' + n, None, None, None, None, 'DROPPED', 'timers / window / mouse (IMPR1110 decision)')
    else:
        add('TRIGGER', owner + '.' + n, None, None, None, None, 'DROPPED', 'Designer coordination / keyboard -> native APEX')


for trg in fm.findall(NS + 'Trigger'):
    trigger_rows('FORM', trg)
for b in blocks:
    for trg in b.findall(NS + 'Trigger'):
        trigger_rows(b.get('Name'), trg)
    for it in b.findall(NS + 'Item'):
        for trg in it.findall(NS + 'Trigger'):
            trigger_rows(b.get('Name') + '.' + it.get('Name'), trg)

# ------------------------------------------------------------------ LOVs and record groups
LOVS = {'CGFK$IMPR_RULE_PORTS_PORT_CD': ('LOV', 'LOV_SD_PORTS (reused, IMPR1110)'),
        'CGFK$IMPR_RULE_TARIFF_HRMNZD_C': ('LOV', 'LOV_HARMONIZED_TARIFF (LOV_APX.LOV_HARMONIZED_TARIFF)')}
for l in fm.findall(NS + 'LOV'):
    a = LOVS.get(l.get('Name'))
    if a:
        add('LOV', l.get('Name'), a[0], a[1], PAGE, None, 'MAPPED', '')
    else:
        add('LOV', l.get('Name'), None, None, None, None, 'DROPPED', 'OLB LOV')
for g in fm.findall(NS + 'RecordGroup'):
    n = g.get('Name')
    if n in LOVS:
        add('RECORD_GROUP', n, 'LOV', LOVS[n][1], PAGE, None, 'MAPPED', 'query of the LOV')
    else:
        add('RECORD_GROUP', n, None, None, None, None, 'DROPPED', 'Designer tab metadata')
add('RECORD_GROUP', 'CGDV$DLRG (runtime)', 'LOV', 'LOV_RULE_TYPE, LOV_REC_STATUS', PAGE, None, 'MAPPED', 'CG_REF_CODES lists')
add('LIST', 'IMPR_RULES.ALL_BRNCH_FLAG (static pop list)', 'LOV', 'LOV_ALL_BRNCH_FLAG (static)', PAGE, None, 'MAPPED', '')

# ------------------------------------------------------------------ canvases, tab pages, windows
CANV = {'CG$PAGE_1': ('REGION', 'IMPR_RULES'), 'CG$M_TAB_1': ('REGION', 'CG$M_TAB_1 (Tabs Container)'), 'TITLE': ('REGION', 'IMPR_RULES_HERO')}
for c in fm.findall(NS + 'Canvas'):
    n = c.get('Name')
    if n in CANV:
        add('CANVAS', n, CANV[n][0], CANV[n][1], PAGE, None, 'MAPPED', '')
    else:
        add('CANVAS', n, None, None, None, None, 'DROPPED', 'OLB frame canvas')
    for tp in c.findall(NS + 'TabPage'):
        tgt = 'IMPR_RULE_PORTS' if tp.get('Name').endswith('_1') else 'IMPR_RULE_TARIFF'
        add('TAB_PAGE', tp.get('Name'), 'REGION', tgt + ' (tab "%s")' % U(tp.get('Label')), PAGE, None, 'MAPPED', '')
for w in fm.findall(NS + 'Window'):
    add('WINDOW', w.get('Name'), 'PAGE', '1140 IMPR1140', PAGE, None, 'MAPPED', 'title -> HEADER TITLE')

# ------------------------------------------------------------------ alerts, parameters, libraries, PUs, VAs
for a in fm.findall(NS + 'Alert'):
    n = a.get('Name')
    if n in ('CFG_ERROR', 'CFG_INFORMATION'):
        add('ALERT', n, 'APEX', 'error text / FORMS_APX / native Alert', PAGE, None, 'MAPPED', 'spec 11')
    elif n == 'USR_WARNING_C':
        add('ALERT', n, 'BUTTON', 'DELETE confirm (page 0)', 0, None, 'MAPPED', 'TMPLT.KEY_DELETE_RECORD')
    else:
        add('ALERT', n, None, None, None, None, 'DROPPED', 'not used by business code')
PARAM = {'P_CURR_PORT_CD': 'P_CURR_PORT_CD', 'P_USER_ID': 'SSO_APP_USER', 'P_WS_ID': 'P_GLOBAL_V_WS_ID', 'P_PORT_TYPE': 'P_PORT_TYPE',
         'P_MODULE_ID': 'P1140_MODULE_ID', 'P_USER_NAME': 'V_USR_NAME', 'P_USER_TYPE': 'V_USR_TYPE', 'P_CLASS_CD': 'P_CLASS_CD'}
for p in fm.findall(NS + 'ModuleParameter'):
    n = p.get('Name')
    if n in PARAM:
        add('PARAMETER', n, 'ITEM', PARAM[n], PAGE if n == 'P_MODULE_ID' else 0, None, 'MAPPED', 'f345 item')
    else:
        add('PARAMETER', n, None, None, None, None, 'DROPPED', 'not used by business code')
for l in fm.findall(NS + 'AttachedLibrary'):
    add('LIBRARY', l.get('Name'), None, None, None, None, 'DROPPED' if l.get('Name') != 'CIC_LIB' else 'MAPPED',
        'calls replaced (inventory 10.3, 10.8)' if l.get('Name') != 'CIC_LIB' else 'ACTIVITY -> ACTIVITY_DB; STR -> FORMS_APX')
PU = {'CGFK$QRY_IMPR_RULES_IR_BIT_FK': 'CGFK$QRY_IMPR_RULES_IR_BIT_FK', 'CGFK$CHK_IMPR_RULE_PORTS_IRP_S': 'CGFK$CHK_IMPR_RULE_PORTS_IRP_S',
      'CGRI$CHK_IMPR_RULES': 'CGRI$CHK_IMPR_RULES', 'CHECK_FASH_ROLE_ID': 'CHECK_FASH_ROLE_ID', 'ADJ_BRANCH': 'ADJ_BRANCH'}
PU_LOV = {'SINGLE_IMP_LOV': 'LOV_SINGLE_IMPORTERS', 'DSP_TRF_ITEMS_LOV': 'LOV_HARMONIZED_TARIFF', 'CALL_SD_PORTS': 'LOV_SD_PORTS'}
for u in fm.findall(NS + 'ProgramUnit'):
    n = u.get('Name')
    if n in PU:
        add('PROGRAM_UNIT', n, 'PACKAGE', 'IMPR1140.' + PU[n], None, PU[n], 'MAPPED', 'same name')
    elif n in PU_LOV:
        add('PROGRAM_UNIT', n, 'LOV', PU_LOV[n], PAGE, None, 'MAPPED', 'LOV form -> Popup LOV')
    elif n in ('EXECUTE_FUNCTION', 'MOUSE_CLICK'):
        add('PROGRAM_UNIT', n, 'REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'Page Functions list')
    else:
        add('PROGRAM_UNIT', n, None, None, None, None, 'DROPPED', 'extraction report 1.6')
for v in fm.findall(NS + 'VisualAttribute'):
    add('VISUAL_ATTRIBUTE', v.get('Name'), 'THEME', 'Theme 42 / ZATCA Forms', None, None, 'MAPPED', 'OLB visual attribute -> theme style')
GLOBALS = ['ARBC_IMPR_NAME', 'BUS_ID', 'BUS_ID_TYPE_CD', 'BUS_ID_TYPE_NAME', 'HQ_IMPR_NBR', 'HRMNZD_CODE', 'IMPR_TYPE_CD', 'PORT_CD', 'PORT_NAME']
for g in GLOBALS:
    add('GLOBAL', g, 'DA', 'Popup LOV + FOS Items to Return', PAGE, None, 'MAPPED', 'LOV-form return channel')
for g in ['CG$HP_HFILE', 'CG$HP_HPATH', 'CG$QUERY_MODE', 'CURRENT_DT', 'CURRENT_VER', 'CURRENT_VERSION', 'EXIT', 'SYSTEM_OBJ']:
    add('GLOBAL', g, None, None, None, None, 'DROPPED', 'Designer / frame / version stamp')
for f, t in [('LOV_IMPORT_HQ_NBR', 'LOV_SINGLE_IMPORTERS'), ('LOV_IMPORT_HQ_N12', 'LOV_SINGLE_IMPORTERS (rule type 12)'),
             ('LOV_TRF_ITEMS', 'LOV_HARMONIZED_TARIFF'), ('LOV_SD_PORTS', 'LOV_SD_PORTS')]:
    add('CALLED_FORM', f, 'LOV', t, PAGE, None, 'MAPPED', 'CALL_FORM LOV form')
add('CALLED_FORM', 'LOV_Impr_Type', None, None, None, None, 'DROPPED', 'PU CALL_IMPR_TYPE is not called')
add('CALLED_FORM', 'V_CALLED_FORM (EXECUTE_FUNCTION)', 'REGION', 'FUNCS (page 0)', 0, None, 'MAPPED', 'Page Functions list')
add('EXTERNAL', 'LIB_USR.SMS_MESSAGE.SEND_SMS_MESSAGE', 'PACKAGE', 'IMPR1140 send_rule_sms', None, 'POST_INSERT', 'TODO', 'MISSING SOURCE')
add('EXTERNAL', 'STR_DB message 1-270', 'PACKAGE', 'FORMS_APX.ARABIC_MESSAGE(1, 270)', None, 'KEY_DELREC', 'TODO', 'text from the message table')

# ------------------------------------------------------------------ write
cnt = collections.Counter(r[6] for r in rows)


def md(v):
    return '–' if v is None or v == '' else str(v).replace('|', '\\|')


lines = ['## 14. Traceability matrix (every object of the XML)', '',
         'Generated by `work/IMPR1140/step03/build_trace.py`: **%d objects** — %s.' % (
             len(rows), ', '.join('%s %d' % (k, v) for k, v in sorted(cnt.items()))), '',
         '| # | Forms object type | Forms object | APEX component type | APEX component (f345 name) | Page | Package member | Status | Notes |',
         '|---|---|---|---|---|---|---|---|---|']
for i, r in enumerate(rows, 1):
    lines.append('| %d | %s |' % (i, ' | '.join(md(x) for x in r)))
spec = open('work/IMPR1140/step03/spec_manual.md', encoding='utf-8').read()
assert '<!-- TRACE -->' in spec
open('analysis/IMPR1140/IMPR1140_apex_page_spec.md', 'w', encoding='utf-8', newline='\n').write(
    spec.replace('<!-- TRACE -->', '\n'.join(lines) + '\n'))


def sq(v):
    return 'NULL' if v is None or v == '' else "'" + str(v).replace("'", "''") + "'"


sql = ['''-- =============================================================================
-- IMPR1140 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (traceability matrix, analysis/IMPR1140/IMPR1140_apex_page_spec.md section 14)
-- Form    : IMPR1140.fmb
-- Author  : Claude Code
-- Date    : 2026-11-24
-- Version : 1.0 (step 03, package IMPR1140 version 001)
-- Generated by work/IMPR1140/step03/build_trace.py - %d objects: %s.
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR1140';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR1140';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR1140', 'IMPR', 'IMPR', 202530, 1140, 1140, 'IMPR1140',
     'IMPR1140', 'COMPLEX', 'DESIGN', NULL, NULL,
     'قواعد التعامل مع المستوردين - step 03 page design (pages 1140, 114001); package IMPR1140 001 not compiled');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR1140', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN''' % (len(rows), ', '.join('%s %d' % (k, v) for k, v in sorted(cnt.items())))]
for r in rows:
    sql.append('    m(%s);' % ', '.join(sq(x) for x in r))
sql += ['END;', '/', '', 'COMMIT;', '']
open('registry/IMPR1140_registry.sql', 'w', encoding='utf-8', newline='\n').write('\n'.join(sql))
print(len(rows), dict(cnt))
