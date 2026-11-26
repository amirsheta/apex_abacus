# -*- coding: utf-8 -*-
"""
gen_apex_impr1130.py - step 04: APEX 21.2 component export of IMPR1130 (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c, docs/f345_reference_standard.md).
Written by work/IMPR1130/step04/make_generator.py from scripts/gen_apex_impr1110.py (do not edit by hand:
change make_generator.py and re-run it).

Reads
  work/IMPR1130/step03/page_design.json   the page design of step 03 (items, validations, processes,
                                      computations, dynamic actions, LOVs) - analysis/IMPR1130/IMPR1130_apex_page_spec.md
  forms/IMPR/IMPR1130_fmb.xml         item data types (source data type of the Form region columns)
  apex/Reference/f345.sql             template ids, existing ids / items / LOVs (checks)
  apex/IMPR1110/f345_impr1110.sql, apex/SUPPORT_ENTRY/f345_support_entry.sql, apex/IMPR1120/f345_impr1120.sql
                                      shared components reused (page group IMPR, application items, LOVs), id clashes
  plsql/IMPR1130/impr1130_spec.sql    members of package IMPR1130 (checks)
Writes
  apex/IMPR1130/f345_impr1130.sql     component export, REVIEW BEFORE IMPORT (4 placeholders)
  apex/IMPR1130/f<app>_impr1130_import.sql  with --workspace-id --app-id --id-offset --schema

Declarative: native Form region (ROWID), FOS plug-in actions, native Enable / Disable / Set Value /
Submit Page, validations and processes = one call into IMPR1130. No JavaScript file, no AJAX callback.
IDs are deterministic: re-running gives the same file.

Usage (from forms_to_apex_toolkit):  python3 -I scripts/gen_apex_impr1130.py [--workspace-id=.. --app-id=.. --id-offset=.. --schema=..]
"""
import os, re, sys, json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
import number_only      # Number Field items: CSS class number_only + one page-load handler
import functions_drawer # the FUNCS region is on page 0, never on a form page
import item_icons      # Post Text icon next to every entry item, from the item name (f202604 convention)
import items_to_submit # every page item a query / LOV / FOS call reads is in its Items to Submit (user rule 2026-11-25)
import client_condition  # an item in an item-type client-side condition has a default value (user rule 2026-11-26)
import lov_apx         # shared LOVs: function body returning SQL, code in LOV_APX (CLAUDE.md 4d)
DESIGN = os.path.join(ROOT, 'work', 'IMPR1130', 'step03', 'page_design.json')
XML = os.path.join(ROOT, 'forms', 'IMPR', 'IMPR1130_fmb.xml')
REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')
PKG = os.path.join(ROOT, 'plsql', 'IMPR1130', 'impr1130_spec.sql')
OUT = os.path.join(ROOT, 'apex', 'IMPR1130', 'f345_impr1130.sql')
OTHER_EXPORTS = [os.path.join(ROOT, 'apex', f) for f in ('IMPR1110/f345_impr1110.sql', 'SUPPORT_ENTRY/f345_support_entry.sql',
                                                           'IMPR1120/f345_impr1120.sql')]
DATE, STAMP = '2026-11-24', '20261124000000'
FORM = 'IMPR1130'
PG, PG_SEARCH = 1130, 113001
PI = 'P1130_'
SHARED_BASE = 9130                 # IMPR1110 uses 9000, IMPR1120 9120 for their shared components
# created by the IMPR1110 export (already in application 202530): reused, not re-created
IMPR1110_IDS = dict(PAGE_GROUP_IMPR='900001000010')

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
    base = int(page) if page.isdigit() else SHARED_BASE
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
    if item in ('BUS_ID_EXPRD_DT', 'BUS_ID_ISSUE_DT', 'LST_TRAN_DT', 'BIRTH_DT'):
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
        if it.get('cascade') and k == 'NATIVE_POPUP_LOV':
            # Popup LOV: the parents only feed the LOV query (Items to Submit, as the real 21.2 export f202604).
            # A cascading parent would clear the item whenever a parent changes - after the WHEN-VALIDATE-ITEM DA
            # of the parent had set it and its name item (Forms never clears it), so the name items went stale.
            p.append(('p_ajax_items_to_submit', q(it['cascade'])))
        elif it.get('cascade'):
            p.append(('p_lov_cascade_parent_items', q(it['cascade'])))
            p.append(('p_ajax_optimize_refresh', q('Y')))
            UNCERTAIN.add('p_lov_cascade_parent_items / p_ajax_optimize_refresh (cascading LOV parents)')
    if k in ('NATIVE_TEXT_FIELD', 'NATIVE_NUMBER_FIELD', 'NATIVE_POPUP_LOV', 'NATIVE_TEXTAREA'):
        p.append(('p_cSize', '30'))
    if it.get('maxlen') and k not in ('NATIVE_DISPLAY_ONLY', 'NATIVE_HIDDEN', 'NATIVE_SELECT_LIST'):
        p.append(('p_cMaxlength', str(it['maxlen'])))
    if k == 'NATIVE_TEXTAREA':
        p.append(('p_cHeight', '4'))
    css = number_only.add_class(it.get('tag_css')) if k == 'NATIVE_NUMBER_FIELD' else it.get('tag_css')
    if css:
        p.append(('p_tag_css_classes', q(css)))
    if item_icons.post_text(name, k):
        p.append(('p_post_element_text', q(item_icons.post_text(name, k))))
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
    if i['name'] == PI + 'HERO_TITLE':
        it['kind'] = 'NATIVE_HIDDEN'                      # shown by the hero region (&P1130_HERO_TITLE.), as AGR1100
    it['value_protected'] = 'N' if 'Value Protected = No' in t else 'Y'
    it['label'] = None if i['label'] in ('-', '') else i['label']
    it['req'] = i['required'] == 'Yes'
    it['mask'] = None if i['mask'] in ('-', '') else i['mask']
    it['default'] = i['default'].split(':', 1)[1].strip() if i['default'].startswith('Static:') else None
    it['lov'] = None if i['lov'] in ('-', '') else i['lov']
    if i['parents'] not in ('-', ''):
        it['cascade'] = ','.join(x.strip() if x.strip().startswith(PI) else PI + x.strip()
                                 for x in i['parents'].split(','))
    it['maxlen'] = None if i['maxlen'] in ('-', '') else i['maxlen']
    col = i['column']
    if col == 'ROWID (primary key)':
        it.update(column='ROWID', pk=True, data_type='ROWID')
        UNCERTAIN.add('ROWID primary key of the Form region: p_include_rowid_column, item p_source ROWID / p_source_data_type ROWID')
    elif col not in ('-', ''):
        it.update(column=col, data_type=source_type(i['name'][len(PI):], i['source']))
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
    if i['name'] in (PI + 'MODULE_ID',):
        it['protect'] = 'S'                                # set by the f345 Page Functions URL (checksum)
    it['comment'] = ('Source: %s.%s' % (FORM, i['source'])) + (' - ' + i['notes'] if i['notes'] not in ('-', '') else '') \
        if i['source'] != '-' else 'Source: %s - %s' % (FORM, i['notes'])
    return seq, it

# ----------------------------------------------------------------------------- dynamic actions
EVENT = {'Change': 'change', 'Get Focus': 'focusin', 'Lose Focus': 'focusout', 'Dialog Closed': 'apexafterclosedialog',
         'Before Page Submit': 'apexbeforepagesubmit', 'Page Load': 'ready', 'Click': 'click'}
def da_event(page, n, d):
    ek = '%s:da:%s' % (page, d['name'])
    nid(ek, 8)
    prm = [('p_id', ref(ek)), ('p_name', q(d['name'])), ('p_event_sequence', str(n * 10))]
    sel = d['selection']
    if sel.startswith('Item '):
        prm += [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q(sel[5:]))]
    elif sel.startswith('JavaScript Expression'):
        prm += [('p_triggering_element_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_element', q('document'))]
    elif sel.startswith('Button '):
        prm += [('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('%s:btn:%s' % (page, sel[7:])))]
        UNCERTAIN.add('button DA: p_triggering_button_id (as page 113001 SEARCH; IMPR1110 uses it)')
    cond = d['condition']
    m = re.match(r'Item (\w+) = (\w+)$', cond)
    if m:
        prm += [('p_triggering_condition_type', q('EQUALS')), ('p_triggering_expression', q(m.group(2)))]
    elif re.match(r'Item (\w+) is not null$', cond):
        prm += [('p_triggering_condition_type', q('NOT_NULL'))]
    elif cond.startswith('JavaScript expression: '):
        prm += [('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_expression', q(cond[len('JavaScript expression: '):]))]
    elif re.match(r'dialog page \d+$', cond):
        prm += [('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')),
                ('p_triggering_expression', q('this.data && this.data.dialogPageId == %s' % cond.split()[-1]))]
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
# page group IMPR, application items (G_ALLOW_MCI, G_ALLOW_MOI, G_LETTER_*, G_PORT_CD, G_SUPP_TITLE_CD,
# G_CHK_IMP_TYP, P_PRSNL_IMPR, P_LETTER_NBR), Application Setting HIJRI_DATE_FORMAT and 8 LOVs come from the
# IMPR1110 export; G_SUPPORT_ENTRY_CALLER from the SUPPORT_ENTRY export (spec 13)
LOVS = [(l['name'], l['call'], [tuple(c) for c in l['columns']], l['source']) for l in D['lovs']['new']]
REUSED_LOVS = [l['name'] for l in D['lovs']['reused']]

def gen():
    out = []
    W = out.append
    W('''-- =============================================================================
-- REVIEW BEFORE IMPORT
-- File        : apex/IMPR1130/f345_impr1130.sql
-- Generated by: Claude Code (scripts/gen_apex_impr1130.py, step 04) from
--               analysis/IMPR1130/IMPR1130_apex_page_spec.md (work/IMPR1130/step03/page_design.json), %s, form IMPR1130
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / 4c, docs/f345_reference_standard.md 3-9: native Form region (ROWID),
--               FOS + native dynamic actions, one-line calls into package IMPR1130 (version 001) and FORMS_APX (004, common helpers).
--               No JavaScript file, no AJAX callback process.
-- Contents    : component export INTO the application installed from f345: pages 1130 (main) and
--               113001 (search) + 4 shared LOVs. Needs the IMPR1110 export (page group IMPR, application
--               items, LOVs, Application Setting HIJRI_DATE_FORMAT) and the SUPPORT_ENTRY export (page 9001,
--               G_SUPPORT_ENTRY_CALLER) imported first.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR1130/import_notes.md
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
    # ---------------------------------------------------------------- shared components (spec 13)
    UNCERTAIN.add(lov_apx.UNCERTAIN)
    for name, sql, cols, s in LOVS:
        nid('9130:lov:' + name, 5)
        b = [call('create_list_of_values', [
            ('p_id', ref('9130:lov:' + name)), ('p_lov_name', q(name))] + lov_apx.lov_attributes(sql, q), 'Source: IMPR1130 ' + s + ' / spec 6')]
        for i, (c, h, dt, visible) in enumerate(lov_apx.column_definitions(cols)):
            key = '9130:lovc:%s:%s' % (name, c)
            nid(key, 6)
            b.append(call('create_list_of_values_cols', [
                ('p_id', ref(key)), ('p_lov_id', ref('9130:lov:' + name)), ('p_query_column_name', q(c)),
                ('p_heading', q(h)), ('p_display_sequence', str((i + 1) * 10)), ('p_data_type', q(dt))]
                + lov_apx.column_attributes(visible)))
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), '\n'.join(b)))
    # ---------------------------------------------------------------- page 1130
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG)
    A(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM)), ('p_alias', q(FORM)),
        ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('Y')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_step_template', fid('PAGE_MAIN')), ('p_page_css_classes', q('zf')),
        ('p_page_template_options', q('#DEFAULT#')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1130.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR1130.fmb - spec 2 / f345 standard 4'))
    hero = ('<div class="cg-hero-row"><div class="cg-hero-top"><span class="cg-hero-ic fa fa-id-card-o" aria-hidden="true"></span>'
            '<div><div class="cg-hero-k">المستوردون</div><div class="cg-hero-t">&P1130_HERO_TITLE.</div>'
            '<div class="cg-hero-d">إضافة وتعديل بيانات المستورد ورقم المنشأة وبيانات النشاط والعنوان</div></div></div></div>')
    nid('1130:plug:IMPORTERS_HERO', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1130:plug:IMPORTERS_HERO')), ('p_plug_name', q('الهيدر')), ('p_region_name', q('IMPORTERS_HERO')),
        ('p_region_css_classes', q('cg-hero')), ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '5'), ('p_plug_source', q(hero)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src('IMPR1130.TITLE (OLB) -> f345 hero / spec 3'))]))
    nid('1130:btn:SUPPORT_ENTRY', 2)
    A(call('create_page_button', [
        ('p_id', ref('1130:btn:SUPPORT_ENTRY')), ('p_button_sequence', '10'), ('p_button_plug_id', ref('1130:plug:IMPORTERS_HERO')),
        ('p_button_name', q('SUPPORT_ENTRY')), ('p_button_action', q('DEFINED_BY_DA')),
        ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')), ('p_button_template_id', fid('BUTTON')),
        ('p_button_image_alt', q('بيانات المساندة الفنية')), ('p_button_position', q('BODY')),
        ('p_icon_css_classes', q('fa-file-text-o')), ('p_button_css_classes', q('cg-b-funcs')),
        ('p_button_comment', src('IMPR1130.WHEN-NEW-FORM-INSTANCE OPEN_FORM(SUPPORT_ENTRY) - letter dialog on demand (D1) / spec 5'))]))
    nid('1130:plug:IMPORTERS', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1130:plug:IMPORTERS')), ('p_plug_name', q('إضافة وتعديل بيانات مستورد')), ('p_region_name', q('IMPORTERS')),
        ('p_region_css_classes', q('zatca-forms cg-form cg-card')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_FORM')), ('p_plug_display_sequence', '10'), ('p_query_type', q('TABLE')),
        ('p_query_table', q('IMPORTERS')), ('p_query_where', q('PORT_CD = :P_CURR_PORT_CD')),
        ('p_include_rowid_column', 'true'), ('p_is_editable', 'true'), ('p_edit_operations', q('i:u')),
        ('p_lost_update_check_type', q('VALUES')), ('p_plug_source_type', q('NATIVE_FORM')),
        ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1130.IMPORTERS (single record, WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD, key mode ROWID; delete by process KEY-DELREC) / spec 3'))]))
    UNCERTAIN.add('p_query_where on the NATIVE_FORM region (AGR1100 has no WHERE clause)')
    # functions menu: region FUNCS on page 0 (side drawer of every page, scripts/functions_drawer.py)
    nid('1130:branch:STAY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1130:branch:STAY')), ('p_branch_name', q('IMPR1130 - stay in the form')),
        ('p_branch_action', q('f?p=&APP_ID.:1130:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '20'),
        ('p_branch_comment', src('Forms stays in the form after COMMIT / spec 12'))]))
    nid('1130:branch:QUERY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1130:branch:QUERY')), ('p_branch_name', q('EXECUTE-QUERY')),
        ('p_branch_action', q('f?p=&APP_ID.:1130:&SESSION.::&DEBUG.:1130::')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '10'),
        ('p_branch_condition_type', q('REQUEST_EQUALS_CONDITION')), ('p_branch_condition', q('EXECUTE_QUERY')),
        ('p_branch_comment', src('IMPR1130.IMPORTERS.WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY: clear cache 1130, P0_PAGE_PK kept / spec 12'))]))
    items = []
    hidden_seq = 2000
    for i in D['items']:
        hidden_seq += 10
        items.append(design_item(i, hidden_seq))
    for seq, it in sorted(items, key=lambda x: x[0]):
        A(page_item(PG, '1130:plug:IMPORTERS', seq, it, form_region=True))
    names = set(it['name'] for _, it in items)
    # computations (spec 9)
    for n, c in enumerate([c for c in D['computations'] if c['item'].startswith(PI)], 1):
        key = '1130:comp:' + c['item']
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
        key = '1130:val:' + v['name']
        nid(key, 6)
        if v.get('condition'):
            cond = [('p_validation_condition', q(":REQUEST IN ('CREATE', 'SAVE') AND " + v['condition'])),
                    ('p_validation_condition2', q('PLSQL')), ('p_validation_condition_type', q('EXPRESSION'))]
        else:
            cond = [('p_validation_condition', q('CREATE,SAVE')), ('p_validation_condition_type', q('REQUEST_IN_CONDITION'))]
        A(call('create_page_validation', [
            ('p_id', ref(key)), ('p_validation_name', q(v['name'])), ('p_validation_sequence', str(n * 10)),
            ('p_validation', lit(v['code'])), ('p_validation2', q('PLSQL')), ('p_validation_type', q('FUNC_BODY_RETURNING_ERR_TEXT'))]
            + cond + [('p_associated_item', 'wwv_flow_api.id(%s)' % _ids['1130:item:' + v['item']]),
                      ('p_error_display_location', q('INLINE_WITH_FIELD_AND_NOTIFICATION')),
                      ('p_validation_comment', src('IMPR1130.' + v['source'] + ' / spec 7'))]))
    # processes (spec 8, f345 standard 6)
    # AGR1100 keeps its session setup as a disabled process (condition Never); its code holds a host name,
    # which an export must not carry (prompt 04 rule 8) - the f345 application sets the session items
    AGR_NEW = 'NULL;  -- f345 session setup (SSO_APP_USER, P_CURR_PORT_CD, V_USR_TYPE ...) is done by the application; disabled as in AGR1100'
    for p in D['processes']:
        point = 'BEFORE_HEADER' if p['point'] == 'Before Header' else 'AFTER_SUBMIT'
        key = '1130:proc:%s:%s' % (point, p['name'])
        s = 'IMPR1130 %s / spec 8' % p['source']
        if p['name'] == 'New':
            A(process(PG, key, p['seq'], point, 'New', AGR_NEW, ('', 'NEVER'), 'f345 session setup copied from AGR1100 '
                      '(condition Never, as in AGR1100) / standard 6'))
        elif p['name'] == 'Initialize form IMPORTERS':
            A(process(PG, key, p['seq'], point, 'Initialize form', None, None, s, ptype='NATIVE_FORM_INIT', region='1130:plug:IMPORTERS'))
        elif p['name'] == 'Process form IMPORTERS':
            A(process(PG, key, p['seq'], point, 'Process form', None, ('CREATE,SAVE', 'REQUEST_IN_CONDITION'), s,
                      ptype='NATIVE_FORM_DML', region='1130:plug:IMPORTERS',
                      extra=[('p_attribute_01', q('REGION_SOURCE')), ('p_attribute_05', q('Y')), ('p_attribute_06', q('Y')),
                             ('p_attribute_08', q('Y')), ('p_process_success_message', q('تم الحفظ بنجاح'))]))
        else:
            A(process(PG, key, p['seq'], point, p['name'], p['code'], plsql_cond(p['condition']), s))
    # dynamic actions (spec 10)
    for n, d in enumerate(D['das'], 1):
        A(da_event(PG, n, d))
    # the number_only handler is the page 0 DA NUMBER ONLY (scripts/number_only.py, added by build_full_app.py)
    W(block('application/pages/page_01130', '\n'.join(P)))

    # ---------------------------------------------------------------- page 113001 (search)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_SEARCH)
    A(call('create_page', [
        ('p_id', str(PG_SEARCH)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM + '_SEARCH')), ('p_alias', q(FORM + '-SEARCH')),
        ('p_page_mode', q('MODAL')), ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_page_css_classes', q('zf')),
        ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_height', q('800')), ('p_dialog_width', q('1800')),
        ('p_protection_level', q('C')), ('p_first_item', q('AUTO_FIRST_ITEM')),
        ('p_page_comment', src('IMPR1130 Enter-Query / Execute-Query of block IMPORTERS (TOOLBAR.RE_ENTER_QUERY) / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: f345 search page <page>01 (page 0 SEARCH)'))
    nid('113001:plug:CRIT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('113001:plug:CRIT')), ('p_plug_name', q('بحث')), ('p_region_name', q('IMPORTERS_SEARCH_CRITERIA')),
        ('p_region_css_classes', q('zatca-forms cg-form')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_HERO')), ('p_plug_display_sequence', '10'), ('p_attribute_01', q('N')),
        ('p_attribute_02', q('TEXT')), ('p_attribute_03', q('Y')),
        ('p_plug_comment', src('IMPR1130.IMPORTERS.PRE-QUERY criteria as one search text over all columns / spec 3'))]))
    # one search text over every shown column; no rows until a search (Forms Enter-Query), no sort clause (user request 2026-11-23)
    ig_sql = '\n'.join([
        '-- one search text over every shown column; no rows until a search is made, as Forms opens the block in',
        '-- Enter-Query mode: the dialog opens without reading IMPORTERS. No sort clause: the whole result is not sorted',
        "SELECT TRANSLATE(ROWIDTOCHAR(i.ROWID), '+/', '-_') AS row_id,   -- URL-safe: a '+' in f?p arrives as a space",
        '       i.impr_nbr, i.arbc_impr_name, i.eng_impr_name, i.bus_id, i.bus_id_brnch,',
        "       i.impr_type_cd || ' - ' || it.impr_type_name AS impr_type, i.hq_impr_nbr",
        '  FROM importers i, impr_types it',
        ' WHERE :P113001_SEARCH IS NOT NULL',
        '   AND i.port_cd = :P_CURR_PORT_CD',
        '   AND it.impr_type_cd (+) = i.impr_type_cd',
        '   AND (NVL(:P1130_P_PRSNL_IMPR, 0) <> 1 OR i.impr_type_cd = 4)',
        "   AND (INSTR(UPPER(i.impr_nbr || '|' || i.arbc_impr_name || '|' || i.eng_impr_name || '|' || i.bus_id || '|' ||",
        "                    i.bus_id_brnch || '|' || i.impr_type_cd || ' - ' || it.impr_type_name || '|' || i.hq_impr_nbr),",
        '              UPPER(TRIM(:P113001_SEARCH))) > 0',
        "        OR i.impr_name_std LIKE '%' || (SELECT str_db.strformat(TRIM(:P113001_SEARCH), 1) FROM dual) || '%')"])
    nid('113001:plug:IG', 1)
    A(call('create_page_plug', [
        ('p_id', ref('113001:plug:IG')), ('p_plug_name', q('المستوردون')), ('p_region_name', q('IMPORTERS_SEARCH')),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', '20'), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(ig_sql)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q('P113001_SEARCH')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1130.IMPORTERS block query + PRE-QUERY (PRSNL_IMPR; block ORDER BY dropped); one search text '
                               'over all columns, no query until a search, no total row count, lazy loading / spec 3'))]))
    cols = [('ROW_ID', None, 'VARCHAR2'), ('IMPR_NBR', 'الرقم الجمركي', 'NUMBER'), ('ARBC_IMPR_NAME', 'الاسم العربي', 'VARCHAR2'),
            ('ENG_IMPR_NAME', 'الاسم الأجنبي', 'VARCHAR2'), ('BUS_ID', 'الرقم الإستدلالي', 'VARCHAR2'),
            ('BUS_ID_BRNCH', 'الرقم الفرعي', 'VARCHAR2'), ('IMPR_TYPE', 'النشاط التجاري', 'VARCHAR2'), ('HQ_IMPR_NBR', 'الرقم الموحد', 'NUMBER')]
    filt = [('p_enable_filter', 'true'), ('p_filter_operators', q('C:S:CASE_INSENSITIVE:REGEXP')), ('p_filter_is_required', 'false'),
            ('p_filter_text_case', q('MIXED')), ('p_filter_lov_type', q('NONE')), ('p_use_as_row_header', 'false'),
            ('p_enable_sort_group', 'true'), ('p_enable_control_break', 'true'), ('p_enable_hide', 'true'),
            ('p_is_primary_key', 'false'), ('p_duplicate_value', 'true'), ('p_include_in_export', 'true')]
    for i, (c, h, dt) in enumerate(cols):
        key = '113001:col:' + c
        nid(key, 2)
        prm = [('p_id', ref(key)), ('p_name', q(c)), ('p_source_type', q('DB_COLUMN')), ('p_source_expression', q(c)),
               ('p_data_type', q(dt)), ('p_is_query_only', 'false')]
        if c == 'ROW_ID':
            prm += [('p_item_type', q('NATIVE_HIDDEN')), ('p_display_sequence', '10'), ('p_attribute_01', q('N')),
                    ('p_use_as_row_header', 'false'), ('p_enable_sort_group', 'false'), ('p_is_primary_key', 'true'),
                    ('p_duplicate_value', 'true'), ('p_include_in_export', 'false')]
        elif c == 'IMPR_NBR':
            # ROW_ID is URL-safe ('+' / '/' -> '-' / '_'); IMPR1130.P0_PAGE_PK_CHECK translates it back (spec 3)
            prm += [('p_item_type', q('NATIVE_LINK')), ('p_heading', q(h)), ('p_heading_alignment', q('CENTER')),
                    ('p_display_sequence', str((i + 1) * 10)), ('p_value_alignment', q('CENTER')),
                    ('p_link_target', q('f?p=&APP_ID.:1130:&SESSION.::&DEBUG.:1130:P0_PAGE_PK:&ROW_ID.')),
                    ('p_link_text', q('&IMPR_NBR.')), ('p_link_attributes', q('target="_top"'))] + filt
        else:
            prm += [('p_item_type', q('NATIVE_DISPLAY_ONLY')), ('p_heading', q(h)), ('p_heading_alignment', q('CENTER')),
                    ('p_display_sequence', str((i + 1) * 10)), ('p_value_alignment', q('CENTER')),
                    ('p_attribute_02', q('VALUE')), ('p_attribute_05', q('PLAIN'))] + filt
        A(call('create_region_column', prm))
    nid('113001:ig', 3)
    A(call('create_interactive_grid', [
        ('p_id', ref('113001:ig')), ('p_internal_uid', '113001000201'), ('p_is_editable', 'false'), ('p_lazy_loading', 'true'),
        ('p_requires_filter', 'false'), ('p_select_first_row', 'true'), ('p_fixed_row_height', 'true'), ('p_pagination_type', q('SET')),
        ('p_show_total_row_count', 'false'), ('p_no_data_found_message', q('لا توجد نتائج - أدخل نص البحث ثم اضغط بحث')),
        ('p_show_toolbar', 'true'), ('p_toolbar_buttons', q('ACTIONS_MENU:RESET')), ('p_enable_save_public_report', 'false'),
        ('p_enable_subscriptions', 'true'), ('p_enable_flashback', 'true'), ('p_define_chart_view', 'true'),
        ('p_enable_download', 'true'), ('p_download_formats', q('CSV:HTML:XLSX:PDF')), ('p_enable_mail_download', 'true'),
        ('p_fixed_header', q('PAGE')), ('p_show_icon_view', 'false'), ('p_show_detail_view', 'false')]))
    nid('113001:igr', 3)
    A(call('create_ig_report', [('p_id', ref('113001:igr')), ('p_interactive_grid_id', ref('113001:ig')),
                                ('p_static_id', q('113001000202')), ('p_type', q('PRIMARY')), ('p_default_view', q('GRID')),
                                ('p_show_row_number', 'false'), ('p_settings_area_expanded', 'true')]))
    nid('113001:igv', 3)
    A(call('create_ig_report_view', [('p_id', ref('113001:igv')), ('p_report_id', ref('113001:igr')), ('p_view_type', q('GRID')),
                                     ('p_stretch_columns', 'true'), ('p_srv_exclude_null_values', 'false'),
                                     ('p_srv_only_display_columns', 'true'), ('p_edit_mode', 'false')]))
    for i, (c, h, dt) in enumerate(cols):
        key = '113001:igc:' + c
        nid(key, 3)
        A(call('create_ig_report_column', [('p_id', ref(key)), ('p_view_id', ref('113001:igv')), ('p_display_seq', str((i + 1) * 10)),
                                           ('p_column_id', ref('113001:col:' + c)), ('p_is_visible', 'false' if c == 'ROW_ID' else 'true'),
                                           ('p_is_frozen', 'false')]))
    A(page_item(PG_SEARCH, '113001:plug:CRIT', 10, dict(
        name='P113001_SEARCH', kind='NATIVE_TEXT_FIELD', label='بحث في كل الأعمدة', maxlen=200, span=6,
        comment='Source: IMPR1130.IMPORTERS query criteria (ARBC_IMPR_NAME: PRE-QUERY IMPR_NAME_STD = STR.StrFormat(name, TRUE), '
                'and the QBE of the other items) as one text over all columns (user request 2026-11-23)')))
    nid('113001:btn:SEARCH', 2)
    A(call('create_page_button', [
        ('p_id', ref('113001:btn:SEARCH')), ('p_button_sequence', '20'), ('p_button_plug_id', ref('113001:plug:CRIT')),
        ('p_button_name', q('SEARCH')), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
        ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q('بحث')), ('p_button_position', q('BODY')),
        ('p_icon_css_classes', q('fa-search')), ('p_button_css_classes', q('cg-b-search')),
        ('p_button_comment', src('IMPR1130 EXECUTE_QUERY of block IMPORTERS / spec 3'))]))
    nid('113001:btn:CLEAR', 2)
    A(call('create_page_button', [
        ('p_id', ref('113001:btn:CLEAR')), ('p_button_sequence', '30'), ('p_button_plug_id', ref('113001:plug:CRIT')),
        ('p_button_name', q('CLEAR')), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
        ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q('مسح البحث')), ('p_button_position', q('BODY')),
        ('p_icon_css_classes', q('fa-eraser')), ('p_button_css_classes', q('cg-b-clear')),
        ('p_button_comment', src('IMPR1130 TOOLBAR.CLEAR_ALL for the search (user request 2026-11-23) / spec 3'))]))
    ek, ak = '113001:da:SEARCH', '113001:daa:SEARCH:10'
    nid(ek, 8); nid(ak, 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('SEARCH')), ('p_event_sequence', '10'),
                                    ('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('113001:btn:SEARCH')),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('click')),
                                    ('p_da_event_comment', src('IMPR1130 EXECUTE_QUERY / spec 3'))]))
    A(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('N')), ('p_action', q('NATIVE_REFRESH')),
                                     ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('113001:plug:IG'))]))
    UNCERTAIN.add('button DA: p_triggering_button_id (as page 113001 SEARCH; IMPR1110 uses it)')
    refresh = [('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('113001:plug:IG'))]
    ek = '113001:da:SEARCH KEY-ENTER'
    nid(ek, 8); nid(ek + ':10', 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('SEARCH KEY-ENTER')), ('p_event_sequence', '12'),
                                    ('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q('P113001_SEARCH')),
                                    ('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')),
                                    ('p_triggering_expression', q('this.browserEvent.which === 13')),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('keyup')),
                                    ('p_da_event_comment', src('IMPR1130 KEY-EXEQRY (Enter in the search text; f345 AGR1100_SEARCH '
                                                               '"SEARCH REFRESH" keyup pattern) / spec 3'))]))
    A(call('create_page_da_action', [('p_id', ref(ek + ':10')), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('N'))] + refresh))
    UNCERTAIN.add('DA client-side condition JAVASCRIPT_EXPRESSION this.browserEvent.which === 13 (Enter key; not in f345)')
    ek = '113001:da:CLEAR'
    nid(ek, 8); nid(ek + ':10', 9); nid(ek + ':20', 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('CLEAR WHEN-BUTTON-PRESSED')), ('p_event_sequence', '15'),
                                    ('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('113001:btn:CLEAR')),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('click')),
                                    ('p_da_event_comment', src('IMPR1130 TOOLBAR.CLEAR_ALL (search criteria) / spec 3'))]))
    A(call('create_page_da_action', [('p_id', ref(ek + ':10')), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('N')), ('p_action', q('NATIVE_CLEAR')),
                                     ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q('P113001_SEARCH'))]))
    A(call('create_page_da_action', [('p_id', ref(ek + ':20')), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '20'), ('p_execute_on_page_init', q('N'))] + refresh))
    UNCERTAIN.add('NATIVE_CLEAR action with p_affected_elements (page 113001 CLEAR; not in f345)')
    UNCERTAIN.add('search IG 113001: p_lazy_loading true, p_show_total_row_count false, toolbar ACTIONS_MENU:RESET (search field removed)')
    A(hide_toolbar_da(PG_SEARCH, 20))
    W(block('application/pages/page_113001', '\n'.join(P)))

    W('''prompt --application/end_environment
begin
wwv_flow_api.component_end;
end;
/
set verify on feedback on define on
prompt  ...done
''')
    text = client_condition.fix(items_to_submit.fix('\n'.join(out)))   # Items to Submit = every page item read (user rule 2026-11-25)
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
    problems = items_to_submit.check(text) + client_condition.check(text) + item_icons.check(text) + lov_apx.check(text) + functions_drawer.check_form_page(text)
    ref_txt = open(REF, encoding='utf-8', errors='replace').read()
    others = '\n'.join(open(f, encoding='utf-8', errors='replace').read() for f in OTHER_EXPORTS)
    pkg_txt = re.sub(r'--[^\n]*', '', open(PKG, encoding='utf-8').read())
    if 'wwv_flow_imp' in text: problems.append('wwv_flow_imp found')
    if '{{' in text: problems.append('{{ found')
    allowed = {'__WORKSPACE_ID__', '__APP_ID__', '__SCHEMA_NAME__', '__ID_OFFSET__'}
    ph = set(re.findall(r'__[A-Z_]+__', text))
    if ph - allowed: problems.append('unexpected placeholders %s' % sorted(ph - allowed))
    if re.search(r'password|pwd', text, re.I): problems.append('password text found')
    code = '\n'.join(l for l in text.splitlines() if not l.startswith('--') and not re.match(r'^[ ,]p_\w*comment=>', l))
    if re.search(r'\bAI_[A-Z]', code): problems.append('AI_ item name found')
    if re.search(r'pkg_|IMPR1110|_APX\.(?!.)', code, re.I): problems.append('page calls pkg_ / IMPR1110')
    # common helpers: FORMS_APX 004 (plsql_templates/forms_apx.sql); members and named parameters must exist
    sys.path.insert(0, os.path.join(ROOT, 'scripts'))
    import forms_apx_helpers
    fx = forms_apx_helpers.forms_apx_members(ROOT)
    for name in set(re.findall(r'FORMS_APX\.([A-Z0-9_$]+)', code)):
        if name not in fx: problems.append('FORMS_APX.%s not in forms_apx.sql' % name)
    for m in re.finditer(r'FORMS_APX\.([A-Z0-9_$]+)\(([^()]*(?:\([^()]*\)[^()]*)*)\)', code):
        name, args = m.groups()
        given = set(re.findall(r'(?<![.\w])([A-Z0-9_$]+)\s*=>', re.sub(r'\([^()]*\)', '()', args)))
        if name in fx and given and not given <= fx[name]:
            problems.append('call FORMS_APX.%s: unknown parameters %s' % (name, sorted(given - fx[name])))
    for bad in ('ON_DEMAND', 'p_javascript_file_urls', 'AJAX_FUNCTION', 'impr1130.js'):
        if bad in code: problems.append('not allowed: ' + bad)
    defined = re.findall(r'[ ,]p_id=>wwv_flow_api\.id\((\d+)\)', text)
    if len(defined) != len(set(defined)): problems.append('duplicate p_id')
    ref_ids = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', ref_txt))
    if set(defined) & ref_ids: problems.append('ids clash with f345')
    other_ids = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', others))
    if set(defined) & other_ids: problems.append('ids clash with the IMPR1110 / SUPPORT_ENTRY / IMPR1120 exports')
    for k, v in IMPR1110_IDS.items():
        if v not in other_ids: problems.append('IMPR1110 id %s (%s) not in the IMPR1110 export' % (k, v))
    missing = set(re.findall(r'wwv_flow_api\.id\((\d+)\)', text)) - set(defined) - ref_ids - other_ids
    if missing: problems.append('ids used but defined nowhere: %s' % sorted(missing))
    for k, v in F345.items():
        if v not in ref_ids: problems.append('f345 id %s (%s) not in f345.sql' % (k, v))
    ref_items = set(names_of(ref_txt, 'create_flow_item')) | set(names_of(others, 'create_flow_item'))
    if len(ref_items) < 10: problems.append('could not read the application items of f345')
    for n in names_of(text, 'create_flow_item'):
        if n in ref_items: problems.append('application item %s already in f345' % n)
    ref_lovs = set(re.findall(r"p_lov_name=>'([^']+)'", ref_txt))
    other_lovs = set(re.findall(r"p_lov_name=>'([^']+)'", others))
    for n in re.findall(r"p_lov_name=>'([^']+)'", text):
        if n in ref_lovs or n in other_lovs: problems.append('LOV %s already exists (f345 / other export)' % n)
    for n in REUSED_LOVS:
        if n not in other_lovs: problems.append('reused LOV %s not in the IMPR1110 export' % n)
    for n in set(re.findall(r"p_named_lov=>'([^']+)'", text)):
        if n not in other_lovs | set(re.findall(r"p_lov_name=>'([^']+)'", text)): problems.append('named LOV %s not defined' % n)
    if 'G_SUPPORT_ENTRY_CALLER' not in others: problems.append('SUPPORT_ENTRY export without G_SUPPORT_ENTRY_CALLER')
    members = set(m.upper() for m in re.findall(r'(?m)^\s*(?:PROCEDURE|FUNCTION)\s+(\w+)', pkg_txt))
    for m in set(re.findall(r'IMPR1130\.([A-Z_0-9]+)', code)):
        if m not in members: problems.append('IMPR1130.%s not in impr1130_spec.sql' % m)
    for m in set(re.findall(r'SUPPORT_ENTRY\.([A-Z_0-9]+)', code)):
        if m not in ('OPEN_DIALOG',): problems.append('SUPPORT_ENTRY.%s not part of the caller contract' % m)
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
    # editable grid number columns (Text / Number Field on NUMBER data) carry number_only too (user request 2026-11-24)
    for c in text.split('wwv_flow_api.create_region_column(')[1:]:
        c = c[:c.find('\n);')]
        if re.search(r"p_item_type=>'NATIVE_(NUMBER|TEXT)_FIELD'", c) and "p_data_type=>'NUMBER'" in c and number_only.CLASS not in c:
            problems.append('grid number column without class %s: %s' % (number_only.CLASS, re.search(r"p_name=>'([^']+)'", c).group(1)))
    # the class works through the page 0 DA NUMBER ONLY (added by scripts/build_full_app.py): no copy on form pages
    if "p_name=>'NUMBER ONLY'" in text: problems.append('NUMBER ONLY DA on a form page (it belongs to page 0)')
    for c in text.split('wwv_flow_api.create_page_item(')[1:]:
        c = c[:c.find('\n);')]
        if "p_display_as=>'NATIVE_NUMBER_FIELD'" in c and number_only.CLASS not in c:
            problems.append('number field without class %s: %s' % (number_only.CLASS, re.search(r"p_name=>'([^']+)'", c).group(1)))
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
    path = os.path.join(ROOT, 'apex', 'IMPR1130', 'f%s_impr1130_import.sql' % vals['app_id'])
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
    json.dump(sorted(UNCERTAIN), open(os.path.join(ROOT, 'work', 'IMPR1130', 'step04', 'uncertain.json'), 'w'), indent=1)
    print('problems:', probs or 'none')
    if probs:
        sys.exit(1)
    if len(sys.argv) > 1:
        ready_copy(t, sys.argv[1:])
