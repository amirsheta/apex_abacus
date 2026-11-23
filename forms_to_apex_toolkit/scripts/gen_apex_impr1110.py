# -*- coding: utf-8 -*-
"""
gen_apex_impr1110.py - step 04 revision 2: APEX 21.2 component export of IMPR1110 (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c, docs/f345_reference_standard.md).

Reads
  work/step03/page_design.json        the page design of step 03 (items, validations, processes,
                                      computations, dynamic actions) - analysis/.../IMPR1110_apex_page_spec.md
  forms/IMPR/IMPR1110_fmb.xml         item data types (source data type of the Form region columns)
  apex/Reference/f345.sql             template ids, existing ids / items / LOVs (checks)
  plsql/IMPR1110/impr1110_spec.sql    members of package IMPR1110 (checks)
Writes
  apex/IMPR1110/f345_impr1110.sql     component export, REVIEW BEFORE IMPORT (4 placeholders)
  apex/IMPR1110/f<app>_impr1110_import.sql  with --workspace-id --app-id --id-offset --schema

Declarative: native Form region (ROWID), FOS plug-in actions, native Enable / Disable / Set Value /
Submit Page, validations and processes = one call into IMPR1110. No JavaScript file, no AJAX callback.
IDs are deterministic: re-running gives the same file.

Usage (from forms_to_apex_toolkit):  python3 -I scripts/gen_apex_impr1110.py [--workspace-id=.. --app-id=.. --id-offset=.. --schema=..]
"""
import os, re, sys, json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESIGN = os.path.join(ROOT, 'work', 'step03', 'page_design.json')
XML = os.path.join(ROOT, 'forms', 'IMPR', 'IMPR1110_fmb.xml')
REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')
PKG = os.path.join(ROOT, 'plsql', 'IMPR1110', 'impr1110_spec.sql')
OUT = os.path.join(ROOT, 'apex', 'IMPR1110', 'f345_impr1110.sql')
DATE, STAMP = '2026-11-19', '20261119000000'
FORM = 'IMPR1110'
PG, PG_SEARCH, PG_MOB = 1110, 111001, 111002

# ----------------------------------------------------------------------------- f345 ids (standard 3)
F345 = dict(
    UI='11622010846008869795', PAGE_MAIN='11622270914969205733', REGION_HERO='11621859120066869682',
    REGION_FORM='11621909206693869707', REGION_GRID='11621913486616869708', REGION_DIALOG='11621894586660869699',
    REGION_BUTTONS='11621861869875869684', LABEL_REQ='11621984380233869750', LABEL_OPT='11621983529556869749',
    BUTTON='11621986167597869752', LIST_FUNS_TPL='63163863023905992916', LIST_PAGE_FUNS='73054485650159247603',
    P0_ACTIONS='73488102084440079322')
ITEM_OPTS = '#DEFAULT#:t-Form-fieldContainer--stretchInputs'

# ----------------------------------------------------------------------------- helpers
def q(s):
    """SQL literal; non-ASCII text -> unistr() as in a real APEX export."""
    if s is None:
        return 'null'
    s = str(s)
    if all(ord(ch) < 128 for ch in s):
        return "'" + s.replace("'", "''") + "'"
    out = []
    for ch in s:
        o = ord(ch)
        out.append('\\005C' if ch == '\\' else "''" if ch == "'" else ch if o < 128 else '\\%04X' % o)
    return "unistr('" + ''.join(out) + "')"

def lit(s):
    """long literal: lines joined with wwv_flow_string.join, pieces < 3000 chars"""
    if s is None:
        return 'null'
    if len(s) <= 3000 and '\n' not in s:
        return q(s)
    lines = []
    for line in s.split('\n'):
        parts = [line[i:i + 3000] for i in range(0, len(line), 3000)] or ['']
        lines.append('\n||'.join(q(p) for p in parts))
    return 'wwv_flow_string.join(wwv_flow_t_varchar2(\n' + ',\n'.join(lines) + '))'

_ids = {}
def nid(key, kind):
    """deterministic id <page or 9000><kind 2><seq 6>"""
    if key in _ids:
        return _ids[key]
    page = key.split(':')[0]
    base = int(page) if page.isdigit() else 9000
    n = sum(1 for k in _ids if k.split(':')[0] == page and _ids[k][len(str(base)):len(str(base)) + 2] == '%02d' % kind) + 1
    _ids[key] = '%d%02d%06d' % (base, kind, n * 10)
    return _ids[key]
def ref(key):
    if key not in _ids:
        raise KeyError('undefined id ' + key)
    return 'wwv_flow_api.id(%s)' % _ids[key]
def fid(name):
    return 'wwv_flow_api.id(%s)' % F345[name]
def call(proc, params, comment=None):
    lines = ['-- ' + comment] if comment else []
    lines.append('wwv_flow_api.%s(' % proc)
    first = True
    for k, v in params:
        if v is None or v == 'null':
            continue
        lines.append('%s%s=>%s' % (' ' if first else ',', k, v))
        first = False
    lines.append(');')
    return '\n'.join(lines)
def block(title, body):
    return 'prompt --%s\nbegin\n%s\nend;\n/\n' % (title, body)
src = lambda s: q('Source: ' + s)
def plsql_cond(cond):
    """design condition text -> (when, type, when2)"""
    if not cond or cond == '-':
        return None
    return (cond, 'EXPRESSION', 'PLSQL')

D = json.load(open(DESIGN, encoding='utf-8'))
UNCERTAIN = set()      # parameters that f345 does not show: listed in import_notes.md

# ----------------------------------------------------------------------------- item data types (XML)
xml = open(XML, encoding='utf-8', errors='replace').read()
_b = xml.index('<Block Name="IMPORTERS"')
_blk = xml[_b:xml.index('</Block>', _b)]
XML_TYPE = {m.group(1): (re.search(r'DataType="([^"]+)"', m.group(2)) or [None, None])[1]
            for m in re.finditer(r'<Item Name="([^"]+)"([^>]*)>', _blk)}
def source_type(item, source):
    if item in ('BUS_ID_EXPRD_DT', 'BUS_ID_ISSUE_DT', 'LST_TRAN_DT'):
        return 'DATE'
    if XML_TYPE.get(item) == 'Number' or 'NUMBER' in (source or ''):
        return 'NUMBER'
    return 'VARCHAR2'

# ----------------------------------------------------------------------------- items
def item_kind(t):
    for pre, k in [('Popup LOV', 'NATIVE_POPUP_LOV'), ('Display Only', 'NATIVE_DISPLAY_ONLY'),
                   ('Number Field', 'NATIVE_NUMBER_FIELD'), ('Text Field', 'NATIVE_TEXT_FIELD'),
                   ('Select List', 'NATIVE_SELECT_LIST'), ('Textarea', 'NATIVE_TEXTAREA'), ('Hidden', 'NATIVE_HIDDEN')]:
        if t.startswith(pre):
            return k
    raise ValueError('unknown item type ' + t)

def page_item(page, plug_key, seq, it, form_region=False):
    name = it['name']
    k = it['kind']
    p = [('p_id', 'wwv_flow_api.id(%s)' % nid('%s:item:%s' % (page, name), 4)), ('p_name', q(name))]
    if form_region and it.get('column'):
        p.append(('p_source_data_type', q(it['data_type'])))
        if it.get('pk'):
            p.append(('p_is_primary_key', 'true'))
    if it.get('req'):
        p.append(('p_is_required', 'true'))
    p += [('p_item_sequence', str(seq)), ('p_item_plug_id', ref(plug_key))]
    if form_region and it.get('column'):
        p.append(('p_item_source_plug_id', ref(plug_key)))
    p += [('p_item_default', q(it.get('default'))), ('p_prompt', q(it.get('label'))),
          ('p_format_mask', q(it.get('mask')))]
    if form_region and it.get('column'):
        p += [('p_source', q(it['column'])), ('p_source_type', q('REGION_SOURCE_COLUMN'))]
    p.append(('p_display_as', q(k)))
    if it.get('lov'):
        p += [('p_named_lov', q(it['lov'])), ('p_lov_display_null', q('YES'))]
        if k != 'NATIVE_POPUP_LOV':
            p.append(('p_lov_null_text', q('-')))
        if it.get('cascade'):
            p.append(('p_lov_cascade_parent_items', q(it['cascade'])))
            p.append(('p_ajax_optimize_refresh', q('Y')))
            UNCERTAIN.add('p_lov_cascade_parent_items / p_ajax_optimize_refresh (cascading LOV parents)')
    if k in ('NATIVE_TEXT_FIELD', 'NATIVE_NUMBER_FIELD', 'NATIVE_POPUP_LOV', 'NATIVE_TEXTAREA'):
        p.append(('p_cSize', '30'))
    if it.get('maxlen') and k not in ('NATIVE_DISPLAY_ONLY', 'NATIVE_HIDDEN', 'NATIVE_SELECT_LIST'):
        p.append(('p_cMaxlength', str(it['maxlen'])))
    if k == 'NATIVE_TEXTAREA':
        p.append(('p_cHeight', '4'))
    if it.get('tag_css'):
        p.append(('p_tag_css_classes', q(it['tag_css'])))
    if k != 'NATIVE_HIDDEN':
        p.append(('p_begin_on_new_line', q('YES' if it.get('newline', True) else 'NO')))
        if it.get('span'):
            p.append(('p_colspan', str(it['span'])))
        if it.get('hidden'):
            p.append(('p_grid_column_css_classes', q('u-hidden')))
    if it.get('read_only'):
        ro = it['read_only']
        if ro == 'ALWAYS':
            p += [('p_read_only_when_type', q('ALWAYS'))]
        else:
            p += [('p_read_only_when', q(ro)), ('p_read_only_when2', q('PLSQL')), ('p_read_only_when_type', q('EXPRESSION'))]
            UNCERTAIN.add('p_read_only_when2 => PLSQL with p_read_only_when_type => EXPRESSION (f345 shows the pattern only for p_display_when)')
    if it.get('display_when'):
        p += [('p_display_when', q(it['display_when'])), ('p_display_when2', q('PLSQL')), ('p_display_when_type', q('EXPRESSION'))]
    if k != 'NATIVE_HIDDEN':
        p += [('p_field_template', fid('LABEL_REQ' if it.get('req') else 'LABEL_OPT')),
              ('p_item_template_options', q(ITEM_OPTS))]
    if it.get('tag'):
        p.append(('p_tag_attributes', q(it['tag'])))
    p.append(('p_is_persistent', q('N')))
    if it.get('protect'):
        p.append(('p_protection_level', q(it['protect'])))
    if k == 'NATIVE_TEXT_FIELD':
        p += [('p_attribute_01', q('N')), ('p_attribute_02', q('N')), ('p_attribute_04', q(it.get('subtype', 'TEXT'))),
              ('p_attribute_05', q('BOTH'))]
    elif k == 'NATIVE_NUMBER_FIELD':
        p += [('p_attribute_03', q('right'))]
    elif k == 'NATIVE_TEXTAREA':
        p += [('p_attribute_01', q('Y')), ('p_attribute_02', q('N')), ('p_attribute_03', q('N')), ('p_attribute_04', q('BOTH'))]
    elif k == 'NATIVE_SELECT_LIST':
        p += [('p_attribute_01', q('NONE')), ('p_attribute_02', q('N'))]
    elif k == 'NATIVE_POPUP_LOV':
        p += [('p_attribute_01', q('DIALOG')), ('p_attribute_02', q('FIRST_ROWSET')), ('p_attribute_03', q('N'))]
    elif k == 'NATIVE_DISPLAY_ONLY':
        # p_attribute_01 = Send On Page Submit: N (server value, spec section 4)
        p += [('p_attribute_01', q('N')), ('p_attribute_02', q('VALUE')), ('p_attribute_04', q('N')), ('p_attribute_05', q('PLAIN'))]
    elif k == 'NATIVE_HIDDEN':
        p += [('p_attribute_01', q(it.get('value_protected', 'Y')))]
    p.append(('p_item_comment', q(it.get('comment'))))
    return call('create_page_item', p)

def design_item(i, seq_hidden):
    t = i['type']
    it = dict(name=i['name'], kind=item_kind(t))
    if i['name'] == 'P1110_HERO_TITLE':
        it['kind'] = 'NATIVE_HIDDEN'                      # shown by the hero region (&P1110_HERO_TITLE.), as AGR1100
    it['value_protected'] = 'N' if 'Value Protected = No' in t else 'Y'
    it['label'] = None if i['label'] in ('-', '') else i['label']
    it['req'] = i['required'] == 'Yes'
    it['mask'] = None if i['mask'] in ('-', '') else i['mask']
    it['default'] = i['default'].split(':', 1)[1].strip() if i['default'].startswith('Static:') else None
    it['lov'] = None if i['lov'] in ('-', '') else i['lov']
    if i['parents'] not in ('-', ''):
        it['cascade'] = ','.join(x.strip() if x.strip().startswith('P1110_') else 'P1110_' + x.strip()
                                 for x in i['parents'].split(','))
    it['maxlen'] = None if i['maxlen'] in ('-', '') else i['maxlen']
    col = i['column']
    if col == 'ROWID (primary key)':
        it.update(column='ROWID', pk=True, data_type='ROWID')
        UNCERTAIN.add('ROWID primary key of the Form region: p_include_rowid_column, item p_source ROWID / p_source_data_type ROWID')
    elif col not in ('-', ''):
        it.update(column=col, data_type=source_type(i['name'][len('P1110_'):], i['source']))
    if 'hijri-date-default' in t:
        it['tag_css'] = 'hijri-date-default'                 # f345 app-wide Hijri picker (Hijri_init.js)
        it['tag'] = 'placeholder="%s"' % 'سنة-شهر-يوم'   # default HIJRI_DATE_FORMAT YYYY-MM-MI
    tags = []
    if 'E-Mail' in t: it['subtype'] = 'EMAIL'
    if 'Phone' in t: it['subtype'] = 'PHONE'
    if 'dir=ltr' in t: tags.append('dir="ltr"')
    if 'upper case' in t: tags.append('style="text-transform:uppercase"')
    if tags: it['tag'] = ' '.join(tags)
    ro = i['read_only']
    if ro.startswith('Always'):
        it['read_only'] = 'ALWAYS'
    elif ro.startswith('PL/SQL Expression'):
        it['read_only'] = re.search(r'`(.+)`', ro).group(1)
    cond = i['condition']
    if cond.startswith('Server-side condition: NOT'):
        it['display_when'] = 'NOT ' + re.search(r'`(.+)`', cond).group(1)
    elif cond.startswith('Server-side condition:'):
        it['display_when'] = re.search(r'`(.+)`', cond).group(1)
    lay = i['layout']
    if lay == 'hidden' or 'hidden' in lay:
        seq = int(lay.split('/')[0]) if '/' in lay else seq_hidden
        it['hidden'] = True
    else:
        seq = int(lay.split('/')[0])
        m = re.search(r'row (Yes|No) / col (\d+) span (\d+)', lay)
        it['newline'] = m.group(1) == 'Yes'
        span = int(m.group(3))
        it['span'] = max(span, 2) if it['label'] else span
    if i['name'] in ('P1110_MODULE_ID',):
        it['protect'] = 'S'                                # set by the f345 Page Functions URL (checksum)
    it['comment'] = ('Source: %s.%s' % (FORM, i['source'])) + (' - ' + i['notes'] if i['notes'] not in ('-', '') else '') \
        if i['source'] != '-' else 'Source: %s - %s' % (FORM, i['notes'])
    return seq, it

# ----------------------------------------------------------------------------- dynamic actions
EVENT = {'Change': 'change', 'Get Focus': 'focusin', 'Lose Focus': 'focusout', 'Dialog Closed': 'apexafterclosedialog',
         'Before Page Submit': 'apexbeforepagesubmit'}
def da_event(page, n, d):
    ek = '%s:da:%s' % (page, d['name'])
    nid(ek, 8)
    prm = [('p_id', ref(ek)), ('p_name', q(d['name'])), ('p_event_sequence', str(n * 10))]
    sel = d['selection']
    if sel.startswith('Item '):
        prm += [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q(sel[5:]))]
    elif sel.startswith('JavaScript Expression'):
        prm += [('p_triggering_element_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_element', q('document'))]
    cond = d['condition']
    m = re.match(r'Item (\w+) = (\w+)$', cond)
    if m:
        prm += [('p_triggering_condition_type', q('EQUALS')), ('p_triggering_expression', q(m.group(2)))]
    elif re.match(r'Item (\w+) is not null$', cond):
        prm += [('p_triggering_condition_type', q('NOT_NULL'))]
    elif cond.startswith('JavaScript expression: '):
        prm += [('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_expression', q(cond[len('JavaScript expression: '):]))]
    elif cond == 'dialog page 111002':
        prm += [('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')),
                ('p_triggering_expression', q('this.data && this.data.dialogPageId == %d' % PG_MOB))]
    elif cond.startswith('TODO: dialog = SUPPORT_ENTRY'):
        prm += [('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')),
                ('p_triggering_expression', q("this.data && this.data.dialogPageId != %d && $v('P1110_FUNCTION_PENDING') !== ''" % PG_MOB))]
    if len(prm) > 5 and any(k == 'p_triggering_condition_type' for k, _ in prm):
        UNCERTAIN.add('DA client-side condition p_triggering_condition_type / p_triggering_expression (not in f345)')
    ev = d['event']
    if ev.startswith('Custom: '):
        prm += [('p_bind_type', q('bind')), ('p_bind_event_type', q('custom')), ('p_bind_event_type_custom', q(ev[8:]))]
    else:
        prm += [('p_bind_type', q('bind')), ('p_bind_event_type', q(EVENT[ev]))]
    prm.append(('p_da_event_comment', src(d['source'] + ' / spec 10')))
    out = [call('create_page_da_event', prm)]
    init = 'Y' if d['fire_init'] == 'Yes' else 'N'
    seq = 0
    for a in d['actions']:
        if a['action'] == '-':
            continue
        seq += 10
        ak = '%s:daa:%s:%d' % (page, d['name'], seq)
        nid(ak, 9)
        base = [('p_id', ref(ak)), ('p_event_id', ref(ek)),
                ('p_event_result', q('FALSE' if a['note'] == 'False action' else 'TRUE')),
                ('p_action_sequence', str(seq)), ('p_execute_on_page_init', q(init))]
        act = a['action']
        if act.startswith('FOS'):
            base += [('p_action', q('PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE')), ('p_attribute_01', lit(a['code'])),
                     ('p_attribute_02', q(','.join(a['submit']) or None)), ('p_attribute_03', q(','.join(a['ret']) or None)),
                     ('p_attribute_05', q('#SQLERRM#')),
                     ('p_attribute_15', q('escape-message' if 'change events ON' in act else 'suppressChangeEvent:escape-message')),
                     ('p_wait_for_result', q('Y'))]
        elif act == 'Execute JavaScript Code':
            base += [('p_action', q('NATIVE_JAVASCRIPT_CODE')), ('p_attribute_01', lit(a['code']))]
        elif act in ('Disable', 'Enable'):
            base += [('p_action', q('NATIVE_' + act.upper())), ('p_affected_elements_type', q('ITEM')),
                     ('p_affected_elements', q(a['code'].replace('items ', '').replace(' ', '')))]
            UNCERTAIN.add('NATIVE_ENABLE / NATIVE_DISABLE with p_affected_elements (not in f345)')
        elif act == 'Set Value':
            m = re.match(r"Static (NULL|'([^']*)') -> (\w+)(, Suppress Change Event = Yes)?$", a['code'])
            j = re.match(r"JavaScript Expression (.+) -> (\w+)$", a['code'])
            if m:
                base += [('p_action', q('NATIVE_SET_VALUE')), ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q(m.group(3))),
                         ('p_attribute_01', q('STATIC_ASSIGNMENT')), ('p_attribute_02', q(m.group(2))),
                         ('p_attribute_09', q('Y' if m.group(4) else 'N')), ('p_wait_for_result', q('Y'))]
            elif j:
                base += [('p_action', q('NATIVE_SET_VALUE')), ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q(j.group(2))),
                         ('p_attribute_01', q('JAVASCRIPT_EXPRESSION')), ('p_attribute_05', q(j.group(1))),
                         ('p_attribute_09', q('N')), ('p_wait_for_result', q('Y'))]
            else:
                raise ValueError('Set Value ' + a['code'])
            UNCERTAIN.add('NATIVE_SET_VALUE attributes 01 / 02 / 05 / 09 (not in f345)')
        elif act == 'Submit Page':
            base += [('p_action', q('NATIVE_SUBMIT_PAGE')), ('p_attribute_01', q(a['code'].split()[-1])), ('p_attribute_02', q('Y'))]
            UNCERTAIN.add('NATIVE_SUBMIT_PAGE attributes 01 / 02 (not in f345)')
        else:
            raise ValueError('action ' + act)
        out.append(call('create_page_da_action', base))
    return '\n'.join(out)

def hide_toolbar_da(page, n):
    ek, ak = '%s:da:Hide' % page, '%s:daa:Hide:10' % page
    nid(ek, 8); nid(ak, 9)
    return '\n'.join([
        call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('Hide')), ('p_event_sequence', str(n)),
                                      ('p_bind_type', q('bind')), ('p_bind_event_type', q('ready')),
                                      ('p_da_event_comment', src('f345 AGR1100_SEARCH "Hide" (page 0 toolbar not used in a dialog)'))]),
        call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                       ('p_action_sequence', '10'), ('p_execute_on_page_init', q('Y')), ('p_action', q('NATIVE_HIDE')),
                                       ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', fid('P0_ACTIONS'))])])

def process(page, key, seq, point, name, code, cond, s, ptype='NATIVE_PLSQL', extra=None, region=None):
    nid(key, 7)
    prm = [('p_id', ref(key)), ('p_process_sequence', str(seq)), ('p_process_point', q(point))]
    if region:
        prm.append(('p_region_id', ref(region)))
    prm += [('p_process_type', q(ptype)), ('p_process_name', q(name)),
            ('p_process_sql_clob', lit(code) if code else None), ('p_process_clob_language', q('PLSQL') if code else None)]
    prm += (extra or [])
    prm.append(('p_error_display_location', q('INLINE_IN_NOTIFICATION')))
    if cond:
        prm += [('p_process_when', q(cond[0])), ('p_process_when_type', q(cond[1])),
                ('p_process_when2', q(cond[2]) if len(cond) > 2 else None)]
    prm.append(('p_process_comment', src(s)))
    return call('create_page_process', prm)

# ----------------------------------------------------------------------------- shared components
GLOBALS = ['ALLOW_MCI', 'ALLOW_MOI', 'BRKR_ATHRZTN_NBR_B', 'CHEK', 'CHK_DUP_BUSID', 'CHK_IMP_TYP', 'EXEC_QUERY_NOW',
           'EXE_DETAIL_QUERY', 'FLAGUPDATE', 'FUNS_BUSID', 'FUNS_IMP', 'IMP0F4', 'IMPR_NAME_B', 'IMPR_NBR', 'IMPR_NBR_B',
           'INS', 'LETTER_DT', 'LETTER_NBR', 'MINS_COMM_CD', 'MOBILE_NO', 'OLD_IMPR_TYPE_CD', 'OLD_PORT_CD', 'PORT_CD',
           'SET', 'STAT_CLR', 'STAT_QUE', 'SUPP_TITLE_CD', 'VALID']
NEW_PARAMS = [('P_BRKR_PORT_CD', ':PARAMETER.P_BRKR_PORT_CD of the menu (CIC_MENU) - TODO: set by the f345 login'),
              ('P_LIC_TYPE', ':PARAMETER.P_LIC_TYPE of the menu (CIC_MENU) - TODO: set by the f345 login'),
              ('P_PRSNL_IMPR', ':PARAMETER.PRSNL_IMPR of IMPR1110 (set by the caller, read once by PARAMETERS ENTRY)'),
              ('P_LETTER_NBR', ':PARAMETER.LETTER_NBR of IMPR1110 (set by the caller, read once by PARAMETERS ENTRY)')]
LOVS = [  # spec section 6
    ('LOV_SD_PORTS', 'SELECT port_cd d, port_cd r, port_name FROM sd_ports WHERE port_status = 1 AND port_type = NVL(:P_PORT_TYPE, port_type) ORDER BY port_cd',
     [('PORT_NAME', 'اسم الجمرك', 'VARCHAR2')], 'LOV form LOV_SD_PORTS / CGFK$IMPORTERS_PORT_CD'),
    ('LOV_IMPR_TYPE', "SELECT DISTINCT itidt.impr_type_cd d, itidt.impr_type_cd r, it.impr_type_name FROM impr_type_id_types itidt, impr_types it WHERE it.impr_type_cd = itidt.impr_type_cd AND itidt.impr_type_cd > 0 AND (:G_CHK_IMP_TYP = '1' OR itidt.status = 1) ORDER BY 2",
     [('IMPR_TYPE_NAME', 'النشاط التجاري', 'VARCHAR2')], 'LOV form LOV_Impr_Type (type part) / CGFK$IMPORTERS_IMPR_TYPE_CD'),
    ('LOV_IMPR_TYPE_BUS_ID', "SELECT bit.bus_id_type_name d, itidt.bus_id_type_cd r FROM impr_type_id_types itidt, bus_id_types bit WHERE bit.bus_id_type_cd = itidt.bus_id_type_cd AND itidt.impr_type_cd = :P1110_IMPR_TYPE_CD AND itidt.impr_type_cd > 0 AND (:G_CHK_IMP_TYP = '1' OR itidt.status = 1) ORDER BY itidt.bus_id_type_cd",
     [], 'LOV form LOV_Impr_Type (bus-id-type part)'),
    ('LOV_CITIES_IMP_ID', 'SELECT city_cd d, city_cd r, city_arb_name, mins_comm_cd FROM cities WHERE city_status = 1 AND ctry_cd = NVL(CASE WHEN :P1110_IMPR_TYPE_CD = 3 AND :P1110_BUS_ID_TYPE_CD = 2 THEN 100 ELSE TO_NUMBER(:P1110_CTRY_CD) END, ctry_cd) ORDER BY ctry_cd, city_cd',
     [('CITY_ARB_NAME', 'المدينة', 'VARCHAR2'), ('MINS_COMM_CD', 'رمز الوزارة', 'NUMBER')], 'LOV form LOV_CITIES_IMP (CITY_CODE_OF_ID) / CGFK$IMPORTERS_CITY_CODE_OF_ID'),
    ('LOV_CITIES_IMP_BRNH', 'SELECT city_cd d, city_cd r, city_arb_name, mins_comm_cd FROM cities WHERE city_status = 1 AND ctry_cd = NVL(:P1110_CTRY_CD, ctry_cd) ORDER BY ctry_cd, city_cd',
     [('CITY_ARB_NAME', 'المدينة', 'VARCHAR2'), ('MINS_COMM_CD', 'رمز الوزارة', 'NUMBER')], 'LOV form LOV_CITIES_IMP (BRNH_CITY_CD)'),
    ('LOV_CITIES', 'SELECT city_cd d, city_cd r, city_arb_name FROM cities WHERE city_status = 1 AND ctry_cd = NVL(:P1110_ADD_CTRY_CD, ctry_cd) ORDER BY ctry_cd, city_cd',
     [('CITY_ARB_NAME', 'المدينة', 'VARCHAR2')], 'LOV form LOV_CITIES / CGFK$IMPORTERS_ADD_CTRY_CD (city part)'),
    ('LOV_COUNTRIES', 'SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries WHERE ctry_status = 1 AND ctry_cd NOT IN (-1) ORDER BY ctry_cd',
     [('CRTY_ARBC_NAME', 'الدولة', 'VARCHAR2')], 'LOV form LOV_COUNTRIES / CGFK$IMPORTERS_ADD_CTRY_CD'),
    ('LOV_COUNTRIES_GULF', 'SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries WHERE (:P1110_IMPR_TYPE_CD = 4 AND :P1110_BUS_ID_TYPE_CD = 16 AND ctry_cd IN (113,116,117,119,120,100)) OR (NOT (NVL(:P1110_IMPR_TYPE_CD,0) = 4 AND NVL(:P1110_BUS_ID_TYPE_CD,0) = 16) AND ctry_status = 1) ORDER BY ctry_cd',
     [('CRTY_ARBC_NAME', 'الدولة', 'VARCHAR2')], 'PU CALL_LOV_COUNTRIES / CALL_LOV_COUN_GULF - CTRY_CD'),
    ('LOV_IMPR', 'SELECT impr_nbr d, impr_nbr r, arbc_impr_name, bus_id, bus_id_brnch, impr_tel_nbr FROM importers WHERE port_cd = :P_CURR_PORT_CD',
     [('ARBC_IMPR_NAME', 'الاسم', 'VARCHAR2'), ('BUS_ID', 'الرقم الإستدلالي', 'VARCHAR2'), ('BUS_ID_BRNCH', 'الرقم الفرعي', 'VARCHAR2'), ('IMPR_TEL_NBR', 'تليفون', 'VARCHAR2')],
     'LOV form LOV_IMPR'),
    ('LOV_COMM_RGSTRTN_TYPE', "SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'COMM_RGSTRTN_TYPE' ORDER BY 2", [],
     'list item IMPORTERS.COMM_RGSTRTN_TYPE (CGDV$POPULATE_DYNAMIC_LISTS)'),
    ('LOV_ALLOWED_EXPORT', "SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'ALLOWED EXPORT' ORDER BY 2", [],
     'list item IMPORTERS.IMPR_EXPR_TYPE (CGDV$POPULATE_DYNAMIC_LISTS)')]
STATIC_LOVS = [('LOV_EXPRESS_POST', [('لا', '0'), ('نعم', '1'), ('تم انشاءه بواسطة البريد السريع', '2')], 'list item IMPORTERS.EXPRESS_POST'),
               ('LOV_CAR_AGENT_FLAG', [('ليس وكيل سيارات', '0'), ('وكيل سيارات', '1')], 'pop list IMPORTERS.CAR_AGENT_FLAG')]
PRE_INSERT_TEXT = 'يجب مراجعة البيانات والتأكد من صحتها قبل التخزين، لايمكن التعديل إلا من قبل شئون المستوردين! هل ترغب بالاستمرار؟'

def gen():
    out = []
    W = out.append
    W('''-- =============================================================================
-- REVIEW BEFORE IMPORT
-- File        : apex/IMPR1110/f345_impr1110.sql
-- Generated by: Claude Code (scripts/gen_apex_impr1110.py, step 04 revision 2) from
--               analysis/IMPR1110/IMPR1110_apex_page_spec.md (work/step03/page_design.json), %s, form IMPR1110
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / 4c, docs/f345_reference_standard.md 3-9: native Form region (ROWID),
--               FOS + native dynamic actions, one-line calls into package IMPR1110 (version 010).
--               No JavaScript file, no AJAX callback process.
-- Contents    : component export INTO the application installed from f345: pages 1110 (main),
--               111001 (search), 111002 (mobile) + the shared components they need.
--               The SUPPORT_ENTRY page (functions F1, F2, F3, F5) belongs to its own form - not here.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR1110/import_notes.md
-- WARNING     : generated wwv_flow_api code is not an officially supported way to build APEX
--               applications. Import into a DEV workspace first, back up the application,
--               review every page in Page Designer.
-- Status      : NOT IMPORTED.
-- =============================================================================
prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
begin
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2021.10.15'
,p_release=>'21.2.0'
,p_default_workspace_id=>__WORKSPACE_ID__
,p_default_application_id=>__APP_ID__
,p_default_id_offset=>__ID_OFFSET__
,p_default_owner=>'__SCHEMA_NAME__'
);
end;
/
''' % DATE)
    # ---------------------------------------------------------------- shared components
    nid('9000:pg:IMPR', 1)
    W(block('application/shared_components/user_interface/page_groups/impr',
            call('create_page_group', [('p_id', ref('9000:pg:IMPR')), ('p_group_name', q('IMPR')),
                                       ('p_group_desc', q('Forms application IMPR (subsystem IMPORTERS)'))],
                 'Source: IMPR1110.fmb module group IMPR / spec 2')))
    body = []
    for g in GLOBALS:
        n = 'G_' + g
        nid('9000:ai:' + n, 2)
        body.append(call('create_flow_item', [('p_id', ref('9000:ai:' + n)), ('p_name', q(n)), ('p_protection_level', q('I')),
                                              ('p_item_comment', src(':GLOBAL.%s (FORMS_APX.GET_GLOBAL / SET_GLOBAL) / spec 13.2' % g))]))
    for n, s in NEW_PARAMS:
        nid('9000:ai:' + n, 2)
        body.append(call('create_flow_item', [('p_id', ref('9000:ai:' + n)), ('p_name', q(n)), ('p_protection_level', q('I')),
                                              ('p_item_comment', src(s + ' / spec 13.2'))]))
    W(block('application/shared_components/logic/application_items', '\n'.join(body)))
    # one place for the Hijri date format of the forms (user request 2026-11-23): read by IMPR1110.HIJRI_DATE_FORMAT
    # and IMPR1120.HIJRI_DATE_FORMAT (default YYYY-MM-MI = the f345 Hijri picker output); change it here or with
    # APEX_APP_SETTING.SET_VALUE, no recompile
    nid('9000:set:HIJRI_DATE_FORMAT', 7)
    W(block('application/shared_components/app_settings/hijri_date_format',
            call('create_app_setting', [('p_id', ref('9000:set:HIJRI_DATE_FORMAT')), ('p_name', q('HIJRI_DATE_FORMAT')),
                                        ('p_value', q('YYYY-MM-MI')), ('p_is_required', q('N')),
                                        ('p_comments', q('Hijri date format of the IMPR forms (Oracle format mask; the day is kept '
                                                         'in the minutes MI). Must match the f345 Hijri picker (page 0, iYYYY-iMM-iDD).'))],
                 'Source: Forms mask CGSO$HDATE_ARB (MI-MM-YYYY / MI-MM-RRRR), now one Application Setting')))
    UNCERTAIN.add('create_app_setting (Application Setting HIJRI_DATE_FORMAT; not in f345): p_name, p_value, p_is_required, p_comments')
    for name, sql, cols, s in LOVS:
        nid('9000:lov:' + name, 5)
        b = [call('create_list_of_values', [
            ('p_id', ref('9000:lov:' + name)), ('p_lov_name', q(name)), ('p_source_type', q('SQL')), ('p_location', q('LOCAL')),
            ('p_lov_query', lit(sql)), ('p_return_column_name', q('R')), ('p_display_column_name', q('D'))], 'Source: ' + s + ' / spec 6')]
        for i, (c, h, dt) in enumerate(cols):
            key = '9000:lovc:%s:%s' % (name, c)
            nid(key, 6)
            b.append(call('create_list_of_values_cols', [
                ('p_id', ref(key)), ('p_lov_id', ref('9000:lov:' + name)), ('p_query_column_name', q(c)),
                ('p_heading', q(h)), ('p_display_sequence', str((i + 1) * 10)), ('p_data_type', q(dt))]))
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), '\n'.join(b)))
    for name, vals, s in STATIC_LOVS:
        nid('9000:lov:' + name, 5)
        b = [call('create_list_of_values', [('p_id', ref('9000:lov:' + name)), ('p_lov_name', q(name)),
                                            ('p_lov_query', "'.'||%s||'.'" % ref('9000:lov:' + name)), ('p_location', q('STATIC'))],
                  'Source: ' + s + ' (values from the XML) / spec 6')]
        for i, (d, r) in enumerate(vals):
            key = '9000:lovd:%s:%s' % (name, r)
            nid(key, 6)
            b.append(call('create_static_lov_data', [('p_id', ref(key)), ('p_lov_disp_sequence', str(i + 1)),
                                                     ('p_lov_disp_value', q(d)), ('p_lov_return_value', q(r))]))
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), '\n'.join(b)))
    nid('9000:msg:PRE_INSERT', 3)
    W(block('application/shared_components/globalization/messages/impr1110_pre_insert_confirm',
            call('create_message', [('p_id', ref('9000:msg:PRE_INSERT')), ('p_name', q('IMPR1110_PRE_INSERT_CONFIRM')),
                                    ('p_message_language', q('ar-sa')), ('p_message_text', q(PRE_INSERT_TEXT))],
                 'Source: IMPR1110.IMPORTERS.PRE-INSERT CONFIRM (brokers) / spec 11')))
    UNCERTAIN.add('wwv_flow_api.create_message (Text Message; f345 has none) - p_message_language ar-sa')

    # ---------------------------------------------------------------- page 1110
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG)
    A(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM)), ('p_alias', q(FORM)),
        ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('Y')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', ref('9000:pg:IMPR')), ('p_step_template', fid('PAGE_MAIN')), ('p_page_css_classes', q('zf')),
        ('p_page_template_options', q('#DEFAULT#')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1110.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR1110.fmb - spec 2 / f345 standard 4'))
    hero = ('<div class="cg-hero-row"><div class="cg-hero-top"><span class="cg-hero-ic fa fa-id-card-o" aria-hidden="true"></span>'
            '<div><div class="cg-hero-k">المستوردون</div><div class="cg-hero-t">&P1110_HERO_TITLE.</div>'
            '<div class="cg-hero-d">إضافة وتعديل بيانات المستورد وبيانات النشاط والعنوان</div></div></div></div>')
    nid('1110:plug:IMPORTERS_HERO', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1110:plug:IMPORTERS_HERO')), ('p_plug_name', q('الهيدر')), ('p_region_name', q('IMPORTERS_HERO')),
        ('p_region_css_classes', q('cg-hero')), ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '5'), ('p_plug_source', q(hero)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src('IMPR1110.TITLE (OLB) -> f345 hero / spec 3'))]))
    nid('1110:plug:IMPORTERS', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1110:plug:IMPORTERS')), ('p_plug_name', q('إضافة وتعديل بيانات مستورد')), ('p_region_name', q('IMPORTERS')),
        ('p_region_css_classes', q('zatca-forms cg-form cg-card')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_FORM')), ('p_plug_display_sequence', '10'), ('p_query_type', q('TABLE')),
        ('p_query_table', q('IMPORTERS')), ('p_query_where', q('PORT_CD = :P_CURR_PORT_CD')),
        ('p_include_rowid_column', 'true'), ('p_is_editable', 'true'), ('p_edit_operations', q('i:u')),
        ('p_lost_update_check_type', q('VALUES')), ('p_plug_source_type', q('NATIVE_FORM')),
        ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1110.IMPORTERS (single record, WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD, key mode ROWID) / spec 3'))]))
    UNCERTAIN.add('p_query_where on the NATIVE_FORM region (AGR1100 has no WHERE clause)')
    nid('1110:plug:FUNCS', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1110:plug:FUNCS')), ('p_plug_name', q('الوظائف')), ('p_region_name', q('FUNCS')),
        ('p_region_css_classes', q('cg-funcs')), ('p_region_template_options', q('#DEFAULT#:js-dialog-size480x320')),
        ('p_plug_template', fid('REGION_DIALOG')), ('p_plug_display_sequence', '990'), ('p_plug_source_type', q('NATIVE_LIST')),
        ('p_list_id', fid('LIST_PAGE_FUNS')), ('p_list_template_id', fid('LIST_FUNS_TPL')), ('p_plug_query_num_rows', '15'),
        ('p_plug_comment', src('IMPR1110.LSIDE / TMPLT function menu (FORM.KEY-F9), opened by page 0 FUNCS; f345 list Page Functions filtered by P1110_ADJ_FUNS / spec 3'))]))
    nid('1110:branch:STAY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1110:branch:STAY')), ('p_branch_name', q('IMPR1110 - stay in the form')),
        ('p_branch_action', q('f?p=&APP_ID.:1110:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '20'),
        ('p_branch_comment', src('Forms stays in the form after COMMIT / spec 12'))]))
    nid('1110:branch:QUERY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1110:branch:QUERY')), ('p_branch_name', q('EXECUTE-QUERY')),
        ('p_branch_action', q('f?p=&APP_ID.:1110:&SESSION.::&DEBUG.:1110::')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '10'),
        ('p_branch_condition_type', q('REQUEST_EQUALS_CONDITION')), ('p_branch_condition', q('EXECUTE_QUERY')),
        ('p_branch_comment', src('IMPR1110.IMPORTERS.WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY: clear cache 1110, P0_PAGE_PK kept / spec 12'))]))
    items = []
    hidden_seq = 2000
    for i in D['items']:
        hidden_seq += 10
        items.append(design_item(i, hidden_seq))
    for seq, it in sorted(items, key=lambda x: x[0]):
        A(page_item(PG, '1110:plug:IMPORTERS', seq, it, form_region=True))
    names = set(it['name'] for _, it in items)
    # computations (spec 9)
    for n, c in enumerate([c for c in D['computations'] if c['item'].startswith('P1110_')], 1):
        key = '1110:comp:' + c['item']
        nid(key, 5)
        # the condition is part of the expression: create_page_computation has no PL/SQL-expression
        # condition language parameter in 21.2 (p_compute_when2 -> PLS-00306 on import, 2026-11-19)
        expr = c['expression'] if c['condition'] == '-' else 'CASE WHEN %s THEN %s END' % (c['condition'], c['expression'])
        A(call('create_page_computation', [
            ('p_id', ref(key)), ('p_computation_sequence', str(n * 10)), ('p_computation_item', q(c['item'])),
            ('p_computation_point', q('AFTER_HEADER' if c['point'].startswith('After') else 'BEFORE_HEADER')),
            ('p_computation_type', q('EXPRESSION')), ('p_computation_language', q('PLSQL')), ('p_computation', lit(expr)),
            ('p_computation_comment', src(c['source'] + ' / spec 9'))]))
    # validations (spec 7)
    for n, v in enumerate(D['validations'], 1):
        key = '1110:val:' + v['name']
        nid(key, 6)
        if v.get('condition'):
            cond = [('p_validation_condition', q(":REQUEST IN ('CREATE', 'SAVE') AND " + v['condition'])),
                    ('p_validation_condition2', q('PLSQL')), ('p_validation_condition_type', q('EXPRESSION'))]
        else:
            cond = [('p_validation_condition', q('CREATE,SAVE')), ('p_validation_condition_type', q('REQUEST_IN_CONDITION'))]
        A(call('create_page_validation', [
            ('p_id', ref(key)), ('p_validation_name', q(v['name'])), ('p_validation_sequence', str(n * 10)),
            ('p_validation', lit(v['code'])), ('p_validation2', q('PLSQL')), ('p_validation_type', q('FUNC_BODY_RETURNING_ERR_TEXT'))]
            + cond + [('p_associated_item', 'wwv_flow_api.id(%s)' % _ids['1110:item:' + v['item']]),
                      ('p_error_display_location', q('INLINE_WITH_FIELD_AND_NOTIFICATION')),
                      ('p_validation_comment', src('IMPR1110.' + v['source'] + ' / spec 7'))]))
    # processes (spec 8, f345 standard 6)
    # AGR1100 keeps its session setup as a disabled process (condition Never); its code holds a host name,
    # which an export must not carry (prompt 04 rule 8) - the f345 application sets the session items
    AGR_NEW = 'NULL;  -- f345 session setup (SSO_APP_USER, P_CURR_PORT_CD, V_USR_TYPE ...) is done by the application; disabled as in AGR1100'
    for p in D['processes']:
        point = 'BEFORE_HEADER' if p['point'] == 'Before Header' else 'AFTER_SUBMIT'
        key = '1110:proc:%s:%s' % (point, p['name'])
        s = 'IMPR1110 %s / spec 8' % p['source']
        if p['name'] == 'New':
            A(process(PG, key, p['seq'], point, 'New', AGR_NEW, ('', 'NEVER'), 'f345 session setup copied from AGR1100 '
                      '(condition Never, as in AGR1100) / standard 6'))
        elif p['name'] == 'Initialize form IMPORTERS':
            A(process(PG, key, p['seq'], point, 'Initialize form', None, None, s, ptype='NATIVE_FORM_INIT', region='1110:plug:IMPORTERS'))
        elif p['name'] == 'Process form IMPORTERS':
            A(process(PG, key, p['seq'], point, 'Process form', None, ('CREATE,SAVE', 'REQUEST_IN_CONDITION'), s,
                      ptype='NATIVE_FORM_DML', region='1110:plug:IMPORTERS',
                      extra=[('p_attribute_01', q('REGION_SOURCE')), ('p_attribute_05', q('Y')), ('p_attribute_06', q('Y')),
                             ('p_attribute_08', q('Y')), ('p_process_success_message', q('تم الحفظ بنجاح'))]))
        else:
            A(process(PG, key, p['seq'], point, p['name'], p['code'], plsql_cond(p['condition']), s))
    # dynamic actions (spec 10)
    for n, d in enumerate(D['das'], 1):
        A(da_event(PG, n, d))
    W(block('application/pages/page_01110', '\n'.join(P)))

    # ---------------------------------------------------------------- page 111001 (search)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_SEARCH)
    A(call('create_page', [
        ('p_id', str(PG_SEARCH)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM + '_SEARCH')), ('p_alias', q(FORM + '-SEARCH')),
        ('p_page_mode', q('MODAL')), ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', ref('9000:pg:IMPR')), ('p_page_css_classes', q('zf')),
        ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_height', q('800')), ('p_dialog_width', q('1800')),
        ('p_protection_level', q('C')), ('p_first_item', q('AUTO_FIRST_ITEM')),
        ('p_page_comment', src('IMPR1110 Enter-Query / Execute-Query of block IMPORTERS (TOOLBAR.RE_ENTER_QUERY) / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: f345 search page <page>01 (page 0 SEARCH)'))
    nid('111001:plug:CRIT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('111001:plug:CRIT')), ('p_plug_name', q('بحث')), ('p_region_name', q('IMPORTERS_SEARCH_CRITERIA')),
        ('p_region_css_classes', q('zatca-forms cg-form')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_HERO')), ('p_plug_display_sequence', '10'), ('p_attribute_01', q('N')),
        ('p_attribute_02', q('TEXT')), ('p_attribute_03', q('Y')),
        ('p_plug_comment', src('IMPR1110.IMPORTERS.PRE-QUERY criteria as one search text over all columns / spec 3'))]))
    # one search text over every shown column; no rows until a search (Forms Enter-Query), no sort clause (user request 2026-11-23)
    ig_sql = '\n'.join([
        '-- one search text over every shown column; no rows until a search is made, as Forms opens the block in',
        '-- Enter-Query mode: the dialog opens without reading IMPORTERS. No sort clause: the whole result is not sorted',
        "SELECT TRANSLATE(ROWIDTOCHAR(i.ROWID), '+/', '-_') AS row_id,   -- URL-safe: a '+' in f?p arrives as a space",
        '       i.impr_nbr, i.arbc_impr_name, i.eng_impr_name, i.bus_id, i.bus_id_brnch,',
        "       i.impr_type_cd || ' - ' || it.impr_type_name AS impr_type, i.hq_impr_nbr",
        '  FROM importers i, impr_types it',
        ' WHERE :P111001_SEARCH IS NOT NULL',
        '   AND i.port_cd = :P_CURR_PORT_CD',
        '   AND it.impr_type_cd (+) = i.impr_type_cd',
        '   AND (NVL(:P1110_P_PRSNL_IMPR, 0) <> 1 OR i.impr_type_cd = 4)',
        "   AND (INSTR(UPPER(i.impr_nbr || '|' || i.arbc_impr_name || '|' || i.eng_impr_name || '|' || i.bus_id || '|' ||",
        "                    i.bus_id_brnch || '|' || i.impr_type_cd || ' - ' || it.impr_type_name || '|' || i.hq_impr_nbr),",
        '              UPPER(TRIM(:P111001_SEARCH))) > 0',
        "        OR i.impr_name_std LIKE '%' || (SELECT str_db.strformat(TRIM(:P111001_SEARCH), 1) FROM dual) || '%')"])
    nid('111001:plug:IG', 1)
    A(call('create_page_plug', [
        ('p_id', ref('111001:plug:IG')), ('p_plug_name', q('المستوردون')), ('p_region_name', q('IMPORTERS_SEARCH')),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', '20'), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(ig_sql)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q('P111001_SEARCH')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1110.IMPORTERS block query + PRE-QUERY (PRSNL_IMPR; block ORDER BY dropped); one search text '
                               'over all columns, no query until a search, no total row count, lazy loading / spec 3'))]))
    cols = [('ROW_ID', None, 'VARCHAR2'), ('IMPR_NBR', 'الرقم الجمركي', 'NUMBER'), ('ARBC_IMPR_NAME', 'الاسم العربي', 'VARCHAR2'),
            ('ENG_IMPR_NAME', 'الاسم الأجنبي', 'VARCHAR2'), ('BUS_ID', 'الرقم الإستدلالي', 'VARCHAR2'),
            ('BUS_ID_BRNCH', 'الرقم الفرعي', 'VARCHAR2'), ('IMPR_TYPE', 'النشاط التجاري', 'VARCHAR2'), ('HQ_IMPR_NBR', 'الرقم الموحد', 'NUMBER')]
    filt = [('p_enable_filter', 'true'), ('p_filter_operators', q('C:S:CASE_INSENSITIVE:REGEXP')), ('p_filter_is_required', 'false'),
            ('p_filter_text_case', q('MIXED')), ('p_filter_lov_type', q('NONE')), ('p_use_as_row_header', 'false'),
            ('p_enable_sort_group', 'true'), ('p_enable_control_break', 'true'), ('p_enable_hide', 'true'),
            ('p_is_primary_key', 'false'), ('p_duplicate_value', 'true'), ('p_include_in_export', 'true')]
    for i, (c, h, dt) in enumerate(cols):
        key = '111001:col:' + c
        nid(key, 2)
        prm = [('p_id', ref(key)), ('p_name', q(c)), ('p_source_type', q('DB_COLUMN')), ('p_source_expression', q(c)),
               ('p_data_type', q(dt)), ('p_is_query_only', 'false')]
        if c == 'ROW_ID':
            prm += [('p_item_type', q('NATIVE_HIDDEN')), ('p_display_sequence', '10'), ('p_attribute_01', q('N')),
                    ('p_use_as_row_header', 'false'), ('p_enable_sort_group', 'false'), ('p_is_primary_key', 'true'),
                    ('p_duplicate_value', 'true'), ('p_include_in_export', 'false')]
        elif c == 'IMPR_NBR':
            # ROW_ID is URL-safe ('+' / '/' -> '-' / '_'); IMPR1110.P0_PAGE_PK_CHECK translates it back (spec 3)
            prm += [('p_item_type', q('NATIVE_LINK')), ('p_heading', q(h)), ('p_heading_alignment', q('CENTER')),
                    ('p_display_sequence', str((i + 1) * 10)), ('p_value_alignment', q('CENTER')),
                    ('p_link_target', q('f?p=&APP_ID.:1110:&SESSION.::&DEBUG.:1110:P0_PAGE_PK:&ROW_ID.')),
                    ('p_link_text', q('&IMPR_NBR.')), ('p_link_attributes', q('target="_top"'))] + filt
        else:
            prm += [('p_item_type', q('NATIVE_DISPLAY_ONLY')), ('p_heading', q(h)), ('p_heading_alignment', q('CENTER')),
                    ('p_display_sequence', str((i + 1) * 10)), ('p_value_alignment', q('CENTER')),
                    ('p_attribute_02', q('VALUE')), ('p_attribute_05', q('PLAIN'))] + filt
        A(call('create_region_column', prm))
    nid('111001:ig', 3)
    A(call('create_interactive_grid', [
        ('p_id', ref('111001:ig')), ('p_internal_uid', '111001000201'), ('p_is_editable', 'false'), ('p_lazy_loading', 'true'),
        ('p_requires_filter', 'false'), ('p_select_first_row', 'true'), ('p_fixed_row_height', 'true'), ('p_pagination_type', q('SET')),
        ('p_show_total_row_count', 'false'), ('p_no_data_found_message', q('لا توجد نتائج - أدخل نص البحث ثم اضغط بحث')),
        ('p_show_toolbar', 'true'), ('p_toolbar_buttons', q('ACTIONS_MENU:RESET')), ('p_enable_save_public_report', 'false'),
        ('p_enable_subscriptions', 'true'), ('p_enable_flashback', 'true'), ('p_define_chart_view', 'true'),
        ('p_enable_download', 'true'), ('p_download_formats', q('CSV:HTML:XLSX:PDF')), ('p_enable_mail_download', 'true'),
        ('p_fixed_header', q('PAGE')), ('p_show_icon_view', 'false'), ('p_show_detail_view', 'false')]))
    nid('111001:igr', 3)
    A(call('create_ig_report', [('p_id', ref('111001:igr')), ('p_interactive_grid_id', ref('111001:ig')),
                                ('p_static_id', q('111001000202')), ('p_type', q('PRIMARY')), ('p_default_view', q('GRID')),
                                ('p_show_row_number', 'false'), ('p_settings_area_expanded', 'true')]))
    nid('111001:igv', 3)
    A(call('create_ig_report_view', [('p_id', ref('111001:igv')), ('p_report_id', ref('111001:igr')), ('p_view_type', q('GRID')),
                                     ('p_stretch_columns', 'true'), ('p_srv_exclude_null_values', 'false'),
                                     ('p_srv_only_display_columns', 'true'), ('p_edit_mode', 'false')]))
    for i, (c, h, dt) in enumerate(cols):
        key = '111001:igc:' + c
        nid(key, 3)
        A(call('create_ig_report_column', [('p_id', ref(key)), ('p_view_id', ref('111001:igv')), ('p_display_seq', str((i + 1) * 10)),
                                           ('p_column_id', ref('111001:col:' + c)), ('p_is_visible', 'false' if c == 'ROW_ID' else 'true'),
                                           ('p_is_frozen', 'false')]))
    A(page_item(PG_SEARCH, '111001:plug:CRIT', 10, dict(
        name='P111001_SEARCH', kind='NATIVE_TEXT_FIELD', label='بحث في كل الأعمدة', maxlen=200, span=6,
        comment='Source: IMPR1110.IMPORTERS query criteria (ARBC_IMPR_NAME: PRE-QUERY IMPR_NAME_STD = STR.StrFormat(name, TRUE), '
                'and the QBE of the other items) as one text over all columns (user request 2026-11-23)')))
    nid('111001:btn:SEARCH', 2)
    A(call('create_page_button', [
        ('p_id', ref('111001:btn:SEARCH')), ('p_button_sequence', '20'), ('p_button_plug_id', ref('111001:plug:CRIT')),
        ('p_button_name', q('SEARCH')), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
        ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q('بحث')), ('p_button_position', q('BODY')),
        ('p_icon_css_classes', q('fa-search')), ('p_button_css_classes', q('cg-b-search')),
        ('p_button_comment', src('IMPR1110 EXECUTE_QUERY of block IMPORTERS / spec 3'))]))
    nid('111001:btn:CLEAR', 2)
    A(call('create_page_button', [
        ('p_id', ref('111001:btn:CLEAR')), ('p_button_sequence', '30'), ('p_button_plug_id', ref('111001:plug:CRIT')),
        ('p_button_name', q('CLEAR')), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
        ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q('مسح البحث')), ('p_button_position', q('BODY')),
        ('p_icon_css_classes', q('fa-eraser')), ('p_button_css_classes', q('cg-b-clear')),
        ('p_button_comment', src('IMPR1110 TOOLBAR.CLEAR_ALL for the search (user request 2026-11-23) / spec 3'))]))
    ek, ak = '111001:da:SEARCH', '111001:daa:SEARCH:10'
    nid(ek, 8); nid(ak, 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('SEARCH')), ('p_event_sequence', '10'),
                                    ('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('111001:btn:SEARCH')),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('click')),
                                    ('p_da_event_comment', src('IMPR1110 EXECUTE_QUERY / spec 3'))]))
    A(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('N')), ('p_action', q('NATIVE_REFRESH')),
                                     ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('111001:plug:IG'))]))
    UNCERTAIN.add('button DA: p_triggering_button_id (page 111001 SEARCH)')
    refresh = [('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('111001:plug:IG'))]
    ek = '111001:da:SEARCH KEY-ENTER'
    nid(ek, 8); nid(ek + ':10', 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('SEARCH KEY-ENTER')), ('p_event_sequence', '12'),
                                    ('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q('P111001_SEARCH')),
                                    ('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')),
                                    ('p_triggering_expression', q('this.browserEvent.which === 13')),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('keyup')),
                                    ('p_da_event_comment', src('IMPR1110 KEY-EXEQRY (Enter in the search text; f345 AGR1100_SEARCH '
                                                               '"SEARCH REFRESH" keyup pattern) / spec 3'))]))
    A(call('create_page_da_action', [('p_id', ref(ek + ':10')), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('N'))] + refresh))
    UNCERTAIN.add('DA client-side condition JAVASCRIPT_EXPRESSION this.browserEvent.which === 13 (Enter key; not in f345)')
    ek = '111001:da:CLEAR'
    nid(ek, 8); nid(ek + ':10', 9); nid(ek + ':20', 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('CLEAR WHEN-BUTTON-PRESSED')), ('p_event_sequence', '15'),
                                    ('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('111001:btn:CLEAR')),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('click')),
                                    ('p_da_event_comment', src('IMPR1110 TOOLBAR.CLEAR_ALL (search criteria) / spec 3'))]))
    A(call('create_page_da_action', [('p_id', ref(ek + ':10')), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('N')), ('p_action', q('NATIVE_CLEAR')),
                                     ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q('P111001_SEARCH'))]))
    A(call('create_page_da_action', [('p_id', ref(ek + ':20')), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '20'), ('p_execute_on_page_init', q('N'))] + refresh))
    UNCERTAIN.add('NATIVE_CLEAR action with p_affected_elements (page 111001 CLEAR; not in f345)')
    UNCERTAIN.add('search IG 111001: p_lazy_loading true, p_show_total_row_count false, toolbar ACTIONS_MENU:RESET (search field removed)')
    A(hide_toolbar_da(PG_SEARCH, 20))
    W(block('application/pages/page_111001', '\n'.join(P)))

    # ---------------------------------------------------------------- page 111002 (mobile)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_MOB)
    A(call('create_page', [
        ('p_id', str(PG_MOB)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM + '_MOBILE')), ('p_alias', q(FORM + '-MOBILE')),
        ('p_page_mode', q('MODAL')), ('p_step_title', q('تعديل رقم الجوال')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', ref('9000:pg:IMPR')), ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')),
        ('p_dialog_height', q('320')), ('p_dialog_width', q('480')), ('p_protection_level', q('C')),
        ('p_page_comment', src('LOV_UPDATE_IMPR_MOBILE.fmb (function IMPR1110_MOB) / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))]))
    for sid, title, seq, t, cls, s in [('BLK', 'تعديل رقم الجوال', 10, 'REGION_HERO', 'zatca-forms cg-form', 'LOV_UPDATE_IMPR_MOBILE.BLK'),
                                       ('CTRL_BLK', 'CTRL_BLK', 20, 'REGION_BUTTONS', None, 'LOV_UPDATE_IMPR_MOBILE.CTRL_BLK')]:
        nid('111002:plug:' + sid, 1)
        A(call('create_page_plug', [
            ('p_id', ref('111002:plug:' + sid)), ('p_plug_name', q(title)), ('p_region_name', q(sid)), ('p_region_css_classes', q(cls)),
            ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid(t)), ('p_plug_display_sequence', str(seq)),
            ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')), ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')),
            ('p_plug_comment', src(s + ' / spec 3'))]))
    for i, (nm, lbl, act, icon, cls, s) in enumerate([('PB_OK', 'موافق', 'SUBMIT', 'fa-check', 'cg-b-save', 'CTRL_BLK.PB_OK'),
                                                      ('PB_CANCEL', 'إلغاء', 'DEFINED_BY_DA', 'fa-times', 'cg-b-funcs', 'CTRL_BLK.PB_CANCEL')]):
        nid('111002:btn:' + nm, 2)
        A(call('create_page_button', [
            ('p_id', ref('111002:btn:' + nm)), ('p_button_sequence', str((i + 1) * 10)), ('p_button_plug_id', ref('111002:plug:CTRL_BLK')),
            ('p_button_name', q(nm)), ('p_button_action', q(act)), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
            ('p_button_template_id', fid('BUTTON')), ('p_button_is_hot', q('Y') if nm == 'PB_OK' else None), ('p_button_image_alt', q(lbl)),
            ('p_button_position', q('NEXT')), ('p_icon_css_classes', q(icon)), ('p_button_css_classes', q(cls)),
            ('p_button_comment', src('LOV_UPDATE_IMPR_MOBILE.%s.WHEN-BUTTON-PRESSED / spec 3' % s))]))
    A(page_item(PG_MOB, '111002:plug:BLK', 10, dict(name='P111002_MOBILE_NO', kind='NATIVE_TEXT_FIELD', label='رقم الجوال',
                                                    subtype='PHONE', maxlen=31, span=6, comment='Source: LOV_UPDATE_IMPR_MOBILE.BLK.MOBILE_NO')))
    A(page_item(PG_MOB, '111002:plug:BLK', 20, dict(name='P111002_IMPR_NBR', kind='NATIVE_HIDDEN', value_protected='Y', protect='S',
                                                    comment='Source: IMPR1110 :IMPORTERS.IMPR_NBR passed to LOV_UPDATE_IMPR_MOBILE (URL with checksum)')))
    A(page_item(PG_MOB, '111002:plug:BLK', 30, dict(name='P111002_CENTRAL_MOBILE', kind='NATIVE_HIDDEN', value_protected='Y',
                                                    comment='Source: LOV_UPDATE_IMPR_MOBILE :PARAMETER.P_CENTRAL_MOBILE (PU LOV_UPDATE_MOBLIE)')))
    for n, c in enumerate([c for c in D['computations'] if c['item'].startswith('P111002_')], 1):
        key = '111002:comp:' + c['item']
        nid(key, 5)
        cond = [] if c['condition'] == '-' else [('p_compute_when', q(c['condition'].split()[0][1:])), ('p_compute_when_type', q('ITEM_IS_NULL'))]
        A(call('create_page_computation', [
            ('p_id', ref(key)), ('p_computation_sequence', str(n * 10)), ('p_computation_item', q(c['item'])),
            ('p_computation_point', q('BEFORE_HEADER')), ('p_computation_type', q('EXPRESSION')), ('p_computation_language', q('PLSQL')),
            ('p_computation', q(c['expression']))] + cond + [('p_computation_comment', src(c['source'] + ' / spec 9'))]))
    A(process(PG_MOB, '111002:proc:KEEP', 10, 'AFTER_HEADER', 'G_LAST_PAGE KEEP', ':G_LAST_PAGE := 1110;', None,
              'f345 SCREEN ENTRY RESET keeps the open record only for <page> and <page>01; without this the record of 1110 is cleared / standard 4'))
    A(process(PG_MOB, '111002:proc:OK', 10, 'AFTER_SUBMIT', 'PB_OK WHEN-BUTTON-PRESSED',
              'IMPR1110.MOBILE_OK(P_MOBILE_NO => :P111002_MOBILE_NO);', ('PB_OK', 'REQUEST_EQUALS_CONDITION'),
              'LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_OK.WHEN-BUTTON-PRESSED / spec 8'))
    A(process(PG_MOB, '111002:proc:CLOSE', 20, 'AFTER_SUBMIT', 'Close Dialog', None, ('PB_OK', 'REQUEST_EQUALS_CONDITION'),
              'LOV_UPDATE_IMPR_MOBILE COPY_SELECTED_VALUES + EXIT_FORM / spec 8', ptype='NATIVE_CLOSE_WINDOW'))
    ek = '111002:da:PB_CANCEL'
    nid(ek, 8)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('PB_CANCEL WHEN-BUTTON-PRESSED')), ('p_event_sequence', '10'),
                                    ('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('111002:btn:PB_CANCEL')),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('click')),
                                    ('p_da_event_comment', src('LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_CANCEL.WHEN-BUTTON-PRESSED (CANCEL_LOV_FORM) / spec 3'))]))
    for seq, a in [(10, [('p_action', q('PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE')), ('p_attribute_01', q('IMPR1110.MOBILE_CANCEL;')),
                         ('p_attribute_05', q('#SQLERRM#')), ('p_attribute_15', q('suppressChangeEvent:escape-message')),
                         ('p_wait_for_result', q('Y'))]),
                   (20, [('p_action', q('NATIVE_DIALOG_CANCEL'))])]:
        ak = '111002:daa:PB_CANCEL:%d' % seq
        nid(ak, 9)
        A(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                         ('p_action_sequence', str(seq)), ('p_execute_on_page_init', q('N'))] + a))
    UNCERTAIN.add('NATIVE_DIALOG_CANCEL action (page 111002 PB_CANCEL)')
    A(hide_toolbar_da(PG_MOB, 20))
    W(block('application/pages/page_111002', '\n'.join(P)))

    W('''prompt --application/end_environment
begin
wwv_flow_api.component_end;
end;
/
set verify on feedback on define on
prompt  ...done
''')
    text = '\n'.join(out)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    return text

# ----------------------------------------------------------------------------- checks
def names_of(text, api):
    """p_name of every wwv_flow_api.<api>( call"""
    out = []
    for chunk in text.split('wwv_flow_api.%s(' % api)[1:]:
        m = re.search(r"\n[ ,]p_name=>'([^']+)'", chunk[:chunk.find('\n);')])
        if m: out.append(m.group(1))
    return out

def selfcheck(text):
    problems = []
    ref_txt = open(REF, encoding='utf-8', errors='replace').read()
    pkg_txt = re.sub(r'--[^\n]*', '', open(PKG, encoding='utf-8').read())
    if 'wwv_flow_imp' in text: problems.append('wwv_flow_imp found')
    if '{{' in text: problems.append('{{ found')
    allowed = {'__WORKSPACE_ID__', '__APP_ID__', '__SCHEMA_NAME__', '__ID_OFFSET__'}
    ph = set(re.findall(r'__[A-Z_]+__', text))
    if ph - allowed: problems.append('unexpected placeholders %s' % sorted(ph - allowed))
    if re.search(r'password|pwd', text, re.I): problems.append('password text found')
    code = '\n'.join(l for l in text.splitlines() if not l.startswith('--') and not re.match(r'^[ ,]p_\w*comment=>', l))
    if re.search(r'\bAI_[A-Z]', code): problems.append('AI_ item name found')
    if re.search(r'pkg_|IMPR1110_APX\.|FORMS_APX\.', code, re.I): problems.append('page calls pkg_ / IMPR1110_APX / FORMS_APX')
    for bad in ('ON_DEMAND', 'p_javascript_file_urls', 'AJAX_FUNCTION', 'impr1110.js'):
        if bad in code: problems.append('not allowed: ' + bad)
    defined = re.findall(r'[ ,]p_id=>wwv_flow_api\.id\((\d+)\)', text)
    if len(defined) != len(set(defined)): problems.append('duplicate p_id')
    ref_ids = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', ref_txt))
    if set(defined) & ref_ids: problems.append('ids clash with f345')
    missing = set(re.findall(r'wwv_flow_api\.id\((\d+)\)', text)) - set(defined) - ref_ids
    if missing: problems.append('ids used but defined nowhere: %s' % sorted(missing))
    for k, v in F345.items():
        if v not in ref_ids: problems.append('f345 id %s (%s) not in f345.sql' % (k, v))
    ref_items = set(names_of(ref_txt, 'create_flow_item'))
    if len(ref_items) < 10: problems.append('could not read the application items of f345')
    for n in names_of(text, 'create_flow_item'):
        if n in ref_items: problems.append('application item %s already in f345' % n)
    ref_lovs = set(re.findall(r"p_lov_name=>'([^']+)'", ref_txt))
    for n in re.findall(r"p_lov_name=>'([^']+)'", text):
        if n in ref_lovs: problems.append('LOV %s already in f345' % n)
    members = set(m.upper() for m in re.findall(r'(?m)^\s*(?:PROCEDURE|FUNCTION)\s+(\w+)', pkg_txt))
    for m in set(re.findall(r'IMPR1110\.([A-Z_0-9]+)', code)):
        if m not in members: problems.append('IMPR1110.%s not in impr1110_spec.sql' % m)
    for name in re.findall(r"p_(?:name|process_name|validation_name)=>'([^']*)'", text):
        if '.' in name and ' ' not in name and not name.startswith('P'): problems.append('dot in component name ' + name)
    # every page item referenced in a bind exists on the page or is an application item
    page_items = set(names_of(text, 'create_page_item'))
    app_items = ref_items | set(names_of(text, 'create_flow_item')) | {'APP_USER', 'REQUEST', 'APP_ID'}
    for b in set(re.findall(r"(?<![\w$&])[:](P\d+_\w+|P_\w+|G_\w+|SSO_APP_USER|V_USR_TYPE|P0_PAGE_PK)\b", code)):
        if b not in page_items | app_items and not b.startswith('P0_'): problems.append('bind :%s has no item' % b)
    for b in set(re.findall(r"p_attribute_0[23]=>'([^']+)'", code)):
        for i in b.split(','):
            if re.match(r'P\d+_', i) and i not in page_items: problems.append('FOS item %s missing' % i)
    js = re.findall(r"p_action=>'NATIVE_JAVASCRIPT_CODE'\n,p_attribute_01=>(.*?)\n(?=[,)])", text, re.S)
    for j in js:
        if j.count("',\n") + 1 > 3: problems.append('JavaScript action > 3 lines')
    if text.count('\nbegin\n') != text.count('\nend;\n/'): problems.append('begin/end not balanced')
    counts = {k: len(re.findall(r'wwv_flow_api\.%s\(' % k, text)) for k in [
        'create_page', 'create_page_plug', 'create_page_item', 'create_page_button', 'create_page_validation',
        'create_page_process', 'create_page_da_event', 'create_page_da_action', 'create_page_computation', 'create_page_branch',
        'create_region_column', 'create_interactive_grid', 'create_ig_report_column', 'create_list_of_values',
        'create_list_of_values_cols', 'create_static_lov_data', 'create_flow_item', 'create_message',
        'create_security_scheme', 'create_page_group']}
    counts['NATIVE_JAVASCRIPT_CODE actions'] = len(js)
    counts['FOS actions'] = text.count("p_action=>'PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE'")
    return problems, counts, sorted(ph)

def ready_copy(text, args):
    """import-ready copy with the 4 placeholders replaced (App Builder cannot read the tokens)"""
    vals = {}
    for a in args:
        k, _, v = a.lstrip('-').partition('=')
        vals[k.replace('-', '_').lower()] = v.strip()
    need = ['workspace_id', 'app_id', 'id_offset', 'schema']
    missing = [k for k in need if not vals.get(k)]
    if missing: sys.exit('missing: ' + ', '.join('--%s=' % m.replace('_', '-') for m in missing))
    for k in ('workspace_id', 'app_id', 'id_offset'):
        if not re.fullmatch(r'-?\d+', vals[k]): sys.exit('--%s must be a number' % k.replace('_', '-'))
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_$#]{0,29}', vals['schema']): sys.exit('--schema is not a valid schema name')
    out = (text.replace('__WORKSPACE_ID__', vals['workspace_id']).replace('__APP_ID__', vals['app_id'])
               .replace('__ID_OFFSET__', vals['id_offset']).replace('__SCHEMA_NAME__', vals['schema'].upper()))
    path = os.path.join(ROOT, 'apex', 'IMPR1110', 'f%s_impr1110_import.sql' % vals['app_id'])
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(out)
    print('import-ready copy:', path)

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    t = gen()
    probs, counts, ph = selfcheck(t)
    print('written', OUT, len(t.splitlines()), 'lines')
    for k, v in counts.items():
        print('  %-32s %d' % (k, v))
    print('placeholders:', ', '.join(ph))
    print('uncertain parameters (import_notes.md):')
    for u in sorted(UNCERTAIN):
        print('  -', u)
    json.dump(sorted(UNCERTAIN), open(os.path.join(ROOT, 'work', 'step04_uncertain.json'), 'w'), indent=1)
    print('problems:', probs or 'none')
    if probs:
        sys.exit(1)
    if len(sys.argv) > 1:
        ready_copy(t, sys.argv[1:])
