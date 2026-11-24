# -*- coding: utf-8 -*-
"""
gen_apex_impr1116.py - step 04: APEX 21.2 component export of IMPR1116 (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c, docs/f345_reference_standard.md).

Design : analysis/IMPR1116/IMPR1116_apex_page_spec.md (step 03); the design data is written in this
         script (sections marked "spec N"), so a spec change means a change here and a re-run.
Checks : apex/Reference/f345.sql (template ids, existing ids / items / LOVs),
         apex/IMPR1110/f345_impr1110.sql (shared components reused from IMPR1110, id clashes),
         apex/IMPR1120/f345_impr1120.sql, apex/SUPPORT_ENTRY/f345_support_entry.sql (id / LOV clashes),
         plsql/IMPR1116/impr1116_spec.sql (members and parameter names of every call).
Writes : apex/IMPR1116/f345_impr1116.sql   component export, REVIEW BEFORE IMPORT (4 placeholders)
         apex/IMPR1116/f<app>_impr1116_import.sql  with --workspace-id --app-id --id-offset --schema

Helpers, process / validation / DA builders and the self-check are copied unchanged from
scripts/gen_apex_impr1120.py (export of 2026-11-23/24); only the design (spec 0-13) is new.
Parameters that appear neither in f345 nor in an earlier export are collected in UNCERTAIN (import_notes.md).

Usage (from forms_to_apex_toolkit):
    python3 -I scripts/gen_apex_impr1116.py [--workspace-id=.. --app-id=.. --id-offset=.. --schema=..]
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
import number_only      # Number Field items: CSS class number_only + one page-load handler
import functions_drawer # the FUNCS region is on page 0, never on a form page
import item_icons      # Post Text icon next to every entry item, from the item name (f202604 convention)
import lov_apx         # shared LOVs: function body returning SQL, code in LOV_APX (CLAUDE.md 4d)
REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')
IMPR1110_EXPORT = os.path.join(ROOT, 'apex', 'IMPR1110', 'f345_impr1110.sql')
PKG = os.path.join(ROOT, 'plsql', 'IMPR1116', 'impr1116_spec.sql')
OUT = os.path.join(ROOT, 'apex', 'IMPR1116', 'f345_impr1116.sql')
OTHER_EXPORTS = [os.path.join(ROOT, 'apex', 'IMPR1120', 'f345_impr1120.sql'),
                 os.path.join(ROOT, 'apex', 'SUPPORT_ENTRY', 'f345_support_entry.sql')]
DATE, STAMP = '2026-11-24', '20261124000000'
FORM = 'IMPR1116'
PG, PG_SEARCH = 1116, 111601
SHARED_BASE = 9116                 # IMPR1110 uses 9000, IMPR1120 9120 for their shared components

# ----------------------------------------------------------------------------- f345 ids (standard 3)
F345 = dict(
    UI='11622010846008869795', PAGE_MAIN='11622270914969205733', REGION_HERO='11621859120066869682',
    REGION_FORM='11621909206693869707', REGION_GRID='11621913486616869708', REGION_DIALOG='11621894586660869699',
    LABEL_REQ='11621984380233869750', LABEL_OPT='11621983529556869749',
    BUTTON='11621986167597869752', LIST_FUNS_TPL='63163863023905992916', LIST_PAGE_FUNS='73054485650159247603',
    P0_ACTIONS='73488102084440079322')
# shared components created by the IMPR1110 export (already in application 202530) - reused, not re-created
IMPR1110_IDS = dict(PAGE_GROUP_IMPR='900001000010')
REUSED_LOVS = []
ITEM_OPTS = '#DEFAULT#:t-Form-fieldContainer--stretchInputs'
UNCERTAIN = set()

# ----------------------------------------------------------------------------- helpers (as gen_apex_impr1110.py)
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
    """deterministic id <page or 9120><kind 2><seq 6>"""
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

# ----------------------------------------------------------------------------- page items
def page_item(page, plug_key, seq, it, form_region=False):
    """it: name, kind, label, column, data_type, pk, req, lov, maxlen, read_only (ALWAYS | (when, type[, when2])),
       send (Display Only: Send On Page Submit), value_protected, tag_css, tag, span, newline, comment"""
    name, k = it['name'], it['kind']
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
    p += [('p_prompt', q(it.get('label')))]
    if form_region and it.get('column'):
        p += [('p_source', q(it['column'])), ('p_source_type', q('REGION_SOURCE_COLUMN'))]
    p.append(('p_display_as', q(k)))
    if it.get('lov'):
        p += [('p_named_lov', q(it['lov'])), ('p_lov_display_null', q('YES'))]
        if k == 'NATIVE_SELECT_LIST':
            p.append(('p_lov_null_text', q('-')))
    if k in ('NATIVE_TEXT_FIELD', 'NATIVE_NUMBER_FIELD', 'NATIVE_POPUP_LOV'):
        p.append(('p_cSize', '30'))
    if it.get('maxlen') and k not in ('NATIVE_DISPLAY_ONLY', 'NATIVE_HIDDEN'):
        p.append(('p_cMaxlength', str(it['maxlen'])))
    css = number_only.add_class(it.get('tag_css')) if k == 'NATIVE_NUMBER_FIELD' else it.get('tag_css')
    if css:
        p.append(('p_tag_css_classes', q(css)))
    if item_icons.post_text(name, k):
        p.append(('p_post_element_text', q(item_icons.post_text(name, k))))
    if k != 'NATIVE_HIDDEN':
        p.append(('p_begin_on_new_line', q('YES' if it.get('newline', True) else 'NO')))
        if it.get('span'):
            p.append(('p_colspan', str(it['span'])))
    ro = it.get('read_only')
    if ro == 'ALWAYS':
        p.append(('p_read_only_when_type', q('ALWAYS')))
    elif ro:
        p += [('p_read_only_when', q(ro[0]))]
        if len(ro) > 2:
            p.append(('p_read_only_when2', q(ro[2])))
            UNCERTAIN.add('item p_read_only_when2 => PLSQL with p_read_only_when_type => EXPRESSION (f345 shows the pattern only for p_display_when; IMPR1110 uses it too)')
        p.append(('p_read_only_when_type', q(ro[1])))
    if k != 'NATIVE_HIDDEN':
        p += [('p_field_template', fid('LABEL_REQ' if it.get('req') else 'LABEL_OPT')),
              ('p_item_template_options', q(ITEM_OPTS))]
    if it.get('tag'):
        p.append(('p_tag_attributes', q(it['tag'])))
    p.append(('p_is_persistent', q('N')))
    if it.get('protect'):
        p.append(('p_protection_level', q(it['protect'])))
    if k == 'NATIVE_TEXT_FIELD':
        p += [('p_attribute_01', q('N')), ('p_attribute_02', q('N')), ('p_attribute_04', q('TEXT')), ('p_attribute_05', q('BOTH'))]
    elif k == 'NATIVE_NUMBER_FIELD':
        p += [('p_attribute_03', q('right'))]
    elif k == 'NATIVE_SELECT_LIST':      # as IMPR1110 (P1110_BUS_ID_TYPE_CD): null text '-', no extra values
        p += [('p_attribute_01', q('NONE')), ('p_attribute_02', q('N'))]
    elif k == 'NATIVE_POPUP_LOV':
        p += [('p_attribute_01', q('DIALOG')), ('p_attribute_02', q('FIRST_ROWSET')), ('p_attribute_03', q('N'))]
    elif k == 'NATIVE_DISPLAY_ONLY':
        # p_attribute_01 = Send On Page Submit; p_attribute_02 = Based On (VALUE / LOV)
        p += [('p_attribute_01', q('Y' if it.get('send') else 'N')), ('p_attribute_02', q('LOV' if it.get('lov') else 'VALUE')),
              ('p_attribute_04', q('N')), ('p_attribute_05', q('PLAIN'))]
        if it.get('lov'):
            UNCERTAIN.add('Display Only based on LOV: p_attribute_02 => LOV with p_named_lov (P1116_ID_TYPE_GZT; as IMPR1120 P1120_IMPR_EXPR_TYPE)')
    elif k == 'NATIVE_HIDDEN':
        p += [('p_attribute_01', q(it.get('value_protected', 'Y')))]
    p.append(('p_item_comment', q(it.get('comment'))))
    return call('create_page_item', p)

# ----------------------------------------------------------------------------- region columns (IG)
FILTER = [('p_enable_filter', 'true'), ('p_filter_operators', q('C:S:CASE_INSENSITIVE:REGEXP')), ('p_filter_is_required', 'false'),
          ('p_filter_text_case', q('MIXED')), ('p_filter_lov_type', q('NONE')), ('p_use_as_row_header', 'false'),
          ('p_enable_sort_group', 'true'), ('p_enable_control_break', 'true'), ('p_enable_hide', 'true')]

def ig_column(page, c, seq):
    """c: name, kind (HIDDEN / TEXT / NUMBER / SELECT / DISPLAY / LINK; TEXT / NUMBER on NUMBER data get number_only), data_type, heading, pk, req, maxlen, css, lov_key,
       default_plsql, read_only, link_target, link_text, comment"""
    key = '%s:col:%s' % (page, c['name'])
    nid(key, 2)
    p = [('p_id', ref(key)), ('p_name', q(c['name'])), ('p_source_type', q('DB_COLUMN')), ('p_source_expression', q(c['name'])),
         ('p_data_type', q(c['data_type'])), ('p_is_query_only', 'false')]
    k = c['kind']
    if k == 'HIDDEN':
        p += [('p_item_type', q('NATIVE_HIDDEN')), ('p_display_sequence', str(seq)), ('p_attribute_01', q('Y')),
              ('p_use_as_row_header', 'false'), ('p_enable_sort_group', 'false'),
              ('p_is_primary_key', 'true' if c.get('pk') else 'false'), ('p_duplicate_value', 'true'), ('p_include_in_export', 'false')]
    else:
        item_type = dict(TEXT='NATIVE_TEXT_FIELD', NUMBER='NATIVE_NUMBER_FIELD', SELECT='NATIVE_SELECT_LIST',
                         DISPLAY='NATIVE_DISPLAY_ONLY', LINK='NATIVE_LINK')[k]
        p += [('p_item_type', q(item_type)), ('p_heading', q(c['heading'])), ('p_heading_alignment', q('CENTER')),
              ('p_display_sequence', str(seq)), ('p_value_alignment', q('CENTER'))]
        css = c.get('css')
        if k in ('TEXT', 'NUMBER') and c['data_type'] == 'NUMBER':
            css = number_only.add_class(css)          # editable number column: digits only (scripts/number_only.py)
        if k == 'TEXT':
            p += [('p_attribute_01', q('N')), ('p_attribute_02', q('N')), ('p_attribute_04', q('TEXT')), ('p_attribute_05', q('BOTH'))]
        if k in ('TEXT', 'NUMBER') and css:
            p.append(('p_item_css_classes', q(css)))
        elif k == 'DISPLAY':
            p += [('p_attribute_02', q('VALUE')), ('p_attribute_05', q('PLAIN'))]
        elif k == 'LINK':
            p += [('p_link_target', q(c['link_target'])), ('p_link_text', q(c['link_text'])), ('p_link_attributes', q('target="_top"'))]
        if k in ('TEXT', 'NUMBER', 'SELECT'):
            p.append(('p_is_required', 'true' if c.get('req') else 'false'))
        if c.get('maxlen'):
            p.append(('p_max_length', str(c['maxlen'])))
        if k == 'SELECT':
            p += [('p_lov_type', q('SHARED')), ('p_lov_id', ref(c['lov_key'])), ('p_lov_display_extra', 'false'),
                  ('p_lov_display_null', 'false')]
            UNCERTAIN.add('IG select list column on a shared LOV: p_lov_type => SHARED + p_lov_id (f345 shows only SQL_QUERY / p_lov_source)')
        p += FILTER + [('p_is_primary_key', 'false')]
    if c.get('default_item'):    # master key from the master form item (Forms CopyValueFrom)
        p += [('p_default_type', q('ITEM')), ('p_default_expression', q(c['default_item']))]
        UNCERTAIN.add('IG column default from a page item: p_default_type => ITEM + p_default_expression (f345 shows only STATIC)')
    if c.get('default_plsql'):
        p += [('p_default_type', q('EXPRESSION')), ('p_default_language', q('PLSQL')), ('p_default_expression', lit(c['default_plsql']))]
        UNCERTAIN.add('IG column default PL/SQL expression: p_default_type => EXPRESSION + p_default_language => PLSQL (f345 shows only STATIC)')
    p += [('p_duplicate_value', 'true'), ('p_include_in_export', 'false' if k == 'HIDDEN' else 'true')] if k != 'HIDDEN' else []
    if c.get('read_only'):
        p += [('p_readonly_condition_type', q('EXPRESSION')), ('p_readonly_condition', lit(c['read_only'])),
              ('p_readonly_condition2', q('PLSQL')), ('p_readonly_for_each_row', 'true')]
    out = call('create_region_column', p, c.get('comment'))
    return out

def ig_row_columns(page):
    out = []
    for name, itype, seq, extra in [('APEX$ROW_ACTION', 'NATIVE_ROW_ACTION', 20, []),
                                    ('APEX$ROW_SELECTOR', 'NATIVE_ROW_SELECTOR', 10,
                                     [('p_attribute_01', q('Y')), ('p_attribute_02', q('Y')), ('p_attribute_03', q('N'))])]:
        key = '%s:col:%s' % (page, name)
        nid(key, 2)
        out.append(call('create_region_column', [('p_id', ref(key)), ('p_name', q(name)), ('p_item_type', q(itype)),
                                                 ('p_display_sequence', str(seq))] + extra))
    return out

# ----------------------------------------------------------------------------- processes / validations / DAs
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

def validation(page, seq, name, code, cond, assoc_item=None, ig_region=None, assoc_column=None, s=''):
    key = '%s:val:%s' % (page, name)
    nid(key, 6)
    p = [('p_id', ref(key))]
    if ig_region:
        p.append(('p_tabular_form_region_id', ref(ig_region)))
    p += [('p_validation_name', q(name)), ('p_validation_sequence', str(seq)), ('p_validation', lit(code)),
          ('p_validation2', q('PLSQL')), ('p_validation_type', q('FUNC_BODY_RETURNING_ERR_TEXT'))]
    if cond[1] == 'EXPRESSION':
        p += [('p_validation_condition', q(cond[0])), ('p_validation_condition2', q('PLSQL')), ('p_validation_condition_type', q('EXPRESSION'))]
    else:
        p += [('p_validation_condition', q(cond[0])), ('p_validation_condition_type', q(cond[1]))]
    if ig_region:
        p += [('p_exec_cond_for_each_row', q('Y')), ('p_associated_column', q(assoc_column))]
    else:
        p.append(('p_associated_item', ref('%s:item:%s' % (page, assoc_item))))
    p += [('p_error_display_location', q('INLINE_WITH_FIELD_AND_NOTIFICATION')), ('p_validation_comment', src(s))]
    return call('create_page_validation', p)

def fos(code, submit, ret=None):
    return [('p_action', q('PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE')), ('p_attribute_01', lit(code)),
            ('p_attribute_02', q(','.join(submit))), ('p_attribute_03', q(','.join(ret)) if ret else None),
            ('p_attribute_05', q('#SQLERRM#')), ('p_attribute_15', q('suppressChangeEvent:escape-message')),
            ('p_wait_for_result', q('Y'))]

def da(page, seq, name, trigger, event, actions, s, cond=None):
    """trigger: ('ITEM', item) | ('COLUMN', region_key, column) | ('BUTTON', button_key) | ('READY',)"""
    ek = '%s:da:%s' % (page, name)
    nid(ek, 8)
    p = [('p_id', ref(ek)), ('p_name', q(name)), ('p_event_sequence', str(seq))]
    if trigger[0] == 'ITEM':
        p += [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q(trigger[1]))]
    elif trigger[0] == 'COLUMN':
        p += [('p_triggering_element_type', q('COLUMN')), ('p_triggering_region_id', ref(trigger[1])),
              ('p_triggering_element', q(trigger[2]))]
    elif trigger[0] == 'BUTTON':
        p += [('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref(trigger[1]))]
    if cond == 'NOT_NULL':
        p.append(('p_triggering_condition_type', q('NOT_NULL')))
        UNCERTAIN.add('DA client-side condition p_triggering_condition_type => NOT_NULL (not in f345; IMPR1110 uses it)')
    elif cond == 'ENTER':      # the key that fired the event is Enter (one JavaScript expression, no JavaScript action)
        p += [('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_expression', q('this.browserEvent.which === 13'))]
        UNCERTAIN.add('DA client-side condition JAVASCRIPT_EXPRESSION this.browserEvent.which === 13 (Enter key; not in f345)')
    p += [('p_bind_type', q('bind')), ('p_bind_event_type', q(event)), ('p_da_event_comment', src(s))]
    out = [call('create_page_da_event', p)]
    for i, a in enumerate(actions, 1):
        ak = '%s:daa:%s:%d' % (page, name, i * 10)
        nid(ak, 9)
        out.append(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                                  ('p_action_sequence', str(i * 10)),
                                                  ('p_execute_on_page_init', q('Y' if trigger[0] == 'READY' else 'N'))] + a))   # Page Load: as f345 'Hide'
    return '\n'.join(out)


# ----------------------------------------------------------------------------- interactive grid (IMPR1116: read-only grids only)
def ig(page, plug_key, cols, hidden, empty_msg, rows_per_page=None, search=False):
    """read-only IG (spec 3): f345 standard 8 defaults; search=True -> the search-page variant of IMPR1120 112001"""
    gk, rk, vk = '%s:ig' % page, '%s:igr' % page, '%s:igv' % page
    nid(gk, 3); nid(rk, 3); nid(vk, 3)
    prm = [('p_id', ref(gk)), ('p_internal_uid', str(page) + '000201'), ('p_is_editable', 'false')]
    prm += [('p_lazy_loading', 'true' if search else 'false'), ('p_requires_filter', 'false'), ('p_select_first_row', 'true'),
            ('p_fixed_row_height', 'true'), ('p_pagination_type', q('SET')),
            ('p_show_total_row_count', 'true'), ('p_no_data_found_message', q(empty_msg)),
            ('p_show_toolbar', 'true'),
            ('p_toolbar_buttons', q('ACTIONS_MENU:RESET' if search else 'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET')),
            ('p_enable_save_public_report', 'false'), ('p_enable_subscriptions', 'true'), ('p_enable_flashback', 'true'),
            ('p_define_chart_view', 'true'), ('p_enable_download', 'true'), ('p_download_formats', q('CSV:HTML:XLSX:PDF')),
            ('p_enable_mail_download', 'true'), ('p_fixed_header', q('PAGE')), ('p_show_icon_view', 'false'), ('p_show_detail_view', 'false')]
    out = [call('create_interactive_grid', prm)]
    out.append(call('create_ig_report', [('p_id', ref(rk)), ('p_interactive_grid_id', ref(gk)), ('p_static_id', q(str(page) + '000202')),
                                         ('p_type', q('PRIMARY')), ('p_default_view', q('GRID')),
                                         ('p_rows_per_page', str(rows_per_page) if rows_per_page else None),
                                         ('p_show_row_number', 'false'), ('p_settings_area_expanded', 'true')]))
    if rows_per_page:
        UNCERTAIN.add('create_ig_report p_rows_per_page => %d (Forms Records Displayed; not in f345, IMPR1120 uses it)' % rows_per_page)
    out.append(call('create_ig_report_view', [('p_id', ref(vk)), ('p_report_id', ref(rk)), ('p_view_type', q('GRID')),
                                              ('p_stretch_columns', 'true'), ('p_srv_exclude_null_values', 'false'),
                                              ('p_srv_only_display_columns', 'true'), ('p_edit_mode', 'false')]))
    for i, name in enumerate(cols):
        key = '%s:igc:%s' % (page, name)
        nid(key, 3)
        out.append(call('create_ig_report_column', [('p_id', ref(key)), ('p_view_id', ref(vk)), ('p_display_seq', str(i)),
                                                    ('p_column_id', ref('%s:col:%s' % (page, name))),
                                                    ('p_is_visible', 'false' if name in hidden else 'true'), ('p_is_frozen', 'false')]))
    return out

# ----------------------------------------------------------------------------- design (spec 0-13)
# page 1116, Form region IMPR_PRTL_NAT (spec 4.1) - Forms navigation order
MASTER_ITEMS = [
    dict(name='P1116_ROW_ID', kind='NATIVE_HIDDEN', column='ROWID', data_type='ROWID', pk=True,
         comment='Source: IMPR1116.IMPR_PRTL_NAT key mode ROWID (Form region primary key, = P0_PAGE_PK)'),
    dict(name='P1116_PRTL_NAT_ISN', kind='NATIVE_DISPLAY_ONLY', label='مسلسل', column='PRTL_NAT_ISN', data_type='NUMBER',
         span=2, send=True, comment='Source: IMPR1116.IMPR_PRTL_NAT.PRTL_NAT_ISN (Update Allowed = No); sent: key of the PRE-UPDATE activity log'),
    dict(name='P1116_IMPR_TYPE_CD', kind='NATIVE_HIDDEN', column='IMPR_TYPE_CD', data_type='NUMBER',
         comment='Source: IMPR1116.IMPR_PRTL_NAT.IMPR_TYPE_CD (Visible = No) - bind of the IMPORTERS grid'),
    dict(name='P1116_CTRY_CD', kind='NATIVE_HIDDEN', column='CTRY_CD', data_type='NUMBER',
         comment='Source: IMPR1116.IMPR_PRTL_NAT.CTRY_CD (Visible = No) - bind of the IMPORTERS grid'),
    dict(name='P1116_BUS_ID_TYPE_CD', kind='NATIVE_HIDDEN', column='BUS_ID_TYPE_CD', data_type='NUMBER',
         comment='Source: IMPR1116.IMPR_PRTL_NAT.BUS_ID_TYPE_CD (Visible = No) - bind of the IMPORTERS grid'),
    dict(name='P1116_BUS_ID', kind='NATIVE_HIDDEN', column='BUS_ID', data_type='VARCHAR2',
         comment='Source: IMPR1116.IMPR_PRTL_NAT.BUS_ID (Visible = No) - bind of the IMPORTERS grid'),
    dict(name='P1116_BUS_ID_BRNCH', kind='NATIVE_HIDDEN', column='BUS_ID_BRNCH', data_type='VARCHAR2',
         comment='Source: IMPR1116.IMPR_PRTL_NAT.BUS_ID_BRNCH (Visible = No) - bind of the IMPORTERS grid (NVL ..., 0)'),
    dict(name='P1116_ID_TYPE_GZT', kind='NATIVE_DISPLAY_ONLY', label='نوع السجل', column='ID_TYPE_GZT', data_type='VARCHAR2',
         lov='LOV_ID_TYPE_GZT', newline=False, span=3,
         comment='Source: IMPR1116.IMPR_PRTL_NAT.ID_TYPE_GZT (list item, CG_REF_CODES ID_TYPE_GZT; Update Allowed = No)'),
    dict(name='P1116_BUS_ID_NEW', kind='NATIVE_DISPLAY_ONLY', label='رقم السجل', column='BUS_ID_NEW', data_type='VARCHAR2',
         newline=False, span=3, comment='Source: IMPR1116.IMPR_PRTL_NAT.BUS_ID_NEW (Update Allowed = No)'),
    dict(name='P1116_GAZT_NAME', kind='NATIVE_DISPLAY_ONLY', label='الاسم', column='GAZT_NAME', data_type='VARCHAR2',
         span=8, comment='Source: IMPR1116.IMPR_PRTL_NAT.GAZT_NAME (Update Allowed = No)'),
    dict(name='P1116_REVIEW_FLAG', kind='NATIVE_SELECT_LIST', label='حالة المراجعة', column='REVIEW_FLAG', data_type='NUMBER',
         lov='LOV_PRTL_NAT_FLAG', newline=False, span=4, read_only=('P0_PAGE_PK', 'ITEM_IS_NULL'),
         comment='Source: IMPR1116.IMPR_PRTL_NAT.REVIEW_FLAG (list item, CG_REF_CODES PRTL_NAT_FLAG; the only updatable item)'),
]
IMPORTERS_COLUMNS = [
    dict(name='ROW_ID', kind='HIDDEN', data_type='VARCHAR2', pk=True, comment='Source: IMPR1116.IMPORTERS ROWID (grid key)'),
    dict(name='PORT_CD', kind='DISPLAY', data_type='NUMBER', heading='الجمرك', comment='Source: IMPR1116.IMPORTERS.PORT_CD'),
    dict(name='IMPR_NBR', kind='DISPLAY', data_type='NUMBER', heading='الرقم', comment='Source: IMPR1116.IMPORTERS.IMPR_NBR'),
    dict(name='HQ_IMPR_NBR', kind='HIDDEN', data_type='NUMBER', comment='Source: IMPR1116.IMPORTERS.HQ_IMPR_NBR (Visible = No)'),
    dict(name='IMPR_TYPE_CD', kind='HIDDEN', data_type='NUMBER', comment='Source: IMPR1116.IMPORTERS.IMPR_TYPE_CD (Visible = No)'),
    dict(name='BUS_ID_TYPE_CD', kind='HIDDEN', data_type='NUMBER', comment='Source: IMPR1116.IMPORTERS.BUS_ID_TYPE_CD (Visible = No)'),
    dict(name='BUS_ID', kind='HIDDEN', data_type='VARCHAR2', comment='Source: IMPR1116.IMPORTERS.BUS_ID (Visible = No)'),
    dict(name='BUS_ID_BRNCH', kind='HIDDEN', data_type='VARCHAR2', comment='Source: IMPR1116.IMPORTERS.BUS_ID_BRNCH (Visible = No)'),
    dict(name='L_IT1_IMPR_TYPE_NAME', kind='DISPLAY', data_type='VARCHAR2', heading='نوع المستورد',
         comment='Source: IMPR1116.IMPORTERS.L_IT1_IMPR_TYPE_NAME (POST-QUERY CGFK$QRY_IMPORTERS_IMP_ITIDT_F -> outer join)'),
    dict(name='ARBC_IMPR_NAME', kind='DISPLAY', data_type='VARCHAR2', heading='اسم المستورد', comment='Source: IMPR1116.IMPORTERS.ARBC_IMPR_NAME'),
    dict(name='L_BIT_BUS_ID_TYPE_NAME', kind='DISPLAY', data_type='VARCHAR2', heading='مسمى الاستدلالى',
         comment='Source: IMPR1116.IMPORTERS.L_BIT_BUS_ID_TYPE_NAME (POST-QUERY CGFK$QRY_IMPORTERS_IMP_ITIDT_F -> outer join)'),
]
IMPORTERS_SQL = '\n'.join([
    '-- Forms block IMPORTERS: WHERE on the current IMPR_PRTL_NAT record + POST-QUERY lookup CGFK$QRY_IMPORTERS_IMP_ITIDT_F',
    'SELECT ROWIDTOCHAR(i.ROWID) AS row_id,',
    '       i.port_cd,',
    '       i.impr_nbr,',
    '       i.hq_impr_nbr,',
    '       i.impr_type_cd,',
    '       i.bus_id_type_cd,',
    '       i.bus_id,',
    '       i.bus_id_brnch,',
    '       l_it1.impr_type_name   AS l_it1_impr_type_name,',
    '       i.arbc_impr_name,',
    '       l_bit.bus_id_type_name AS l_bit_bus_id_type_name',
    '  FROM importers i,',
    '       impr_type_id_types l_itidt,',
    '       impr_types l_it1,',
    '       bus_id_types l_bit',
    ' WHERE i.impr_type_cd   = :P1116_IMPR_TYPE_CD',
    '   AND i.ctry_cd        = :P1116_CTRY_CD',
    '   AND i.bus_id_type_cd = :P1116_BUS_ID_TYPE_CD',
    '   AND i.bus_id         = :P1116_BUS_ID',
    '   AND NVL(i.bus_id_brnch, 0) = NVL(:P1116_BUS_ID_BRNCH, 0)',
    '   AND l_itidt.impr_type_cd (+)   = i.impr_type_cd',
    '   AND l_itidt.bus_id_type_cd (+) = i.bus_id_type_cd',
    '   AND l_it1.impr_type_cd (+)     = l_itidt.impr_type_cd',
    '   AND l_bit.bus_id_type_cd (+)   = l_itidt.bus_id_type_cd'])
SEARCH_SQL = '\n'.join([
    '-- Forms block IMPR_PRTL_NAT query: WHERE REVIEW_FLAG = 0 AND GAZT_NAME IS NOT NULL (IMPR1116.IMPR_PRTL_NAT_IS_PENDING);',
    "-- optional search text over every shown column. URL-safe ROWID: a '+' in f?p arrives as a space.",
    "SELECT TRANSLATE(ROWIDTOCHAR(n.ROWID), '+/', '-_') AS row_id,",
    '       n.prtl_nat_isn,',
    '       n.id_type_gzt,',
    '       (SELECT r.rv_meaning FROM cg_ref_codes r',
    "         WHERE r.rv_domain = 'ID_TYPE_GZT' AND r.rv_low_value = n.id_type_gzt AND ROWNUM = 1) AS id_type_gzt_name,",
    '       n.bus_id_new,',
    '       n.gazt_name',
    '  FROM impr_prtl_nat n',
    " WHERE (SELECT IMPR1116.IMPR_PRTL_NAT_IS_PENDING(REVIEW_FLAG => n.review_flag, GAZT_NAME => n.gazt_name) FROM dual) = 'Y'",
    '   AND (:P111601_SEARCH IS NULL',
    "        OR INSTR(UPPER(n.prtl_nat_isn || '|' || n.id_type_gzt || '|' || n.bus_id_new || '|' || n.gazt_name),",
    '                 UPPER(TRIM(:P111601_SEARCH))) > 0)'])
SEARCH_COLUMNS = [
    ('ROW_ID', None, 'VARCHAR2'), ('PRTL_NAT_ISN', 'مسلسل', 'NUMBER'), ('ID_TYPE_GZT', 'رمز نوع السجل', 'VARCHAR2'),
    ('ID_TYPE_GZT_NAME', 'نوع السجل', 'VARCHAR2'), ('BUS_ID_NEW', 'رقم السجل', 'VARCHAR2'), ('GAZT_NAME', 'الاسم', 'VARCHAR2')]
NEW_LOVS = [  # spec 6
    ('LOV_ID_TYPE_GZT', lov_apx.call('REFERENCE_CODES', P_DOMAIN='ID_TYPE_GZT'),
     'list item IMPR_PRTL_NAT.ID_TYPE_GZT (CGDV$POPULATE_DYNAMIC_LISTS)'),
    ('LOV_PRTL_NAT_FLAG', lov_apx.call('REFERENCE_CODES', P_DOMAIN='PRTL_NAT_FLAG'),
     'list item IMPR_PRTL_NAT.REVIEW_FLAG (CGDV$POPULATE_DYNAMIC_LISTS)')]
PRE_UPDATE = ('IMPR1116.PRE_UPDATE(P_PRTL_NAT_ISN => :P1116_PRTL_NAT_ISN, P_CURR_PORT_CD => :P_CURR_PORT_CD, '
              'SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);')

# ----------------------------------------------------------------------------- generation
def gen():
    out = []
    W = out.append
    W('''-- =============================================================================
-- REVIEW BEFORE IMPORT
-- File        : apex/IMPR1116/f345_impr1116.sql
-- Generated by: Claude Code (scripts/gen_apex_impr1116.py, step 04 revision 1) from
--               analysis/IMPR1116/IMPR1116_apex_page_spec.md, %s, form IMPR1116
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / 4c, docs/f345_reference_standard.md 3-9: Form region (ROWID, update only),
--               read-only Interactive Grid detail, one-line calls into package IMPR1116 (version 001).
--               No JavaScript action, no AJAX callback.
-- Contents    : component export INTO the application installed from f345 AND already holding the
--               IMPR1110 export (page group IMPR is reused):
--               pages 1116 (main) and 111601 (search) + 2 LOVs.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR1116/import_notes.md
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
    for name, sql, s in NEW_LOVS:
        nid('9116:lov:' + name, 5)
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), call('create_list_of_values', [
            ('p_id', ref('9116:lov:' + name)), ('p_lov_name', q(name))] + lov_apx.lov_attributes(sql, q),
            'Source: IMPR1116 ' + s + ' / spec 6')))

    # ---------------------------------------------------------------- page 1116 (spec 2-12)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG)
    A(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM)), ('p_alias', q(FORM)),
        ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('Y')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_step_template', fid('PAGE_MAIN')),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1116.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR1116.fmb - spec 2 / f345 standard 4'))
    hero = ('<div class="cg-hero-row"><div class="cg-hero-top"><span class="cg-hero-ic fa fa-check-square-o" aria-hidden="true"></span>'
            '<div><div class="cg-hero-k">المستوردون</div><div class="cg-hero-t">&P1116_HERO_TITLE.</div>'
            '<div class="cg-hero-d">مراجعة بيانات رقم المنشأة 700 المدخلة من البوابة</div></div></div></div>')
    nid('1116:plug:IMPR_PRTL_NAT_HERO', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1116:plug:IMPR_PRTL_NAT_HERO')), ('p_plug_name', q('الهيدر')), ('p_region_name', q('IMPR_PRTL_NAT_HERO')),
        ('p_region_css_classes', q('cg-hero')), ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '10'), ('p_plug_source', q(hero)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src('IMPR1116.TITLE (OLB) -> f345 hero / spec 3'))]))
    nid('1116:plug:IMPR_PRTL_NAT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1116:plug:IMPR_PRTL_NAT')), ('p_plug_name', q('بيانات رقم المنشأة 700 للمستورد')), ('p_region_name', q('IMPR_PRTL_NAT')),
        ('p_region_css_classes', q('zatca-forms cg-form cg-card')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_FORM')), ('p_plug_display_sequence', '20'), ('p_query_type', q('TABLE')),
        ('p_query_table', q('IMPR_PRTL_NAT')), ('p_include_rowid_column', 'true'), ('p_is_editable', 'true'),
        ('p_edit_operations', q('u')), ('p_lost_update_check_type', q('VALUES')),
        ('p_plug_source_type', q('NATIVE_FORM')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1116.IMPR_PRTL_NAT (Insert / Delete Allowed = No, only REVIEW_FLAG updatable; key mode ROWID; '
                               'one record from page 111601, spec decision 1) / spec 3'))]))
    UNCERTAIN.add("Form region p_edit_operations => 'u' (update only; IMPR1110 uses 'i:u')")
    UNCERTAIN.add('ROWID primary key of the Form region: p_include_rowid_column, item source ROWID / p_source_data_type ROWID (as IMPR1110)')
    nid('1116:plug:IMPORTERS', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1116:plug:IMPORTERS')), ('p_plug_name', q('المستوردين')), ('p_region_name', q('IMPORTERS')),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', '30'), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(IMPORTERS_SQL)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q('P1116_IMPR_TYPE_CD,P1116_CTRY_CD,P1116_BUS_ID_TYPE_CD,P1116_BUS_ID,P1116_BUS_ID_BRNCH')),
        ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_display_condition_type', q('ITEM_IS_NOT_NULL')), ('p_plug_display_when_condition', q('P0_PAGE_PK')),
        ('p_plug_comment', src('IMPR1116.IMPORTERS (query only; WHERE on :IMPR_PRTL_NAT.*, requeried by IMPR_PRTL_NAT.WHEN-NEW-RECORD-INSTANCE; '
                               'POST-QUERY lookup as outer joins) / spec 3'))]))
    for i, c in enumerate(IMPORTERS_COLUMNS):
        A(ig_column(PG, c, (i + 1) * 10))
    for c in ig(PG, '1116:plug:IMPORTERS', [c['name'] for c in IMPORTERS_COLUMNS],
                {c['name'] for c in IMPORTERS_COLUMNS if c['kind'] == 'HIDDEN'},
                'لا يوجد مستوردون بنفس بيانات التعريف', rows_per_page=10):
        A(c)
    # branch (spec 12)
    nid('1116:branch:STAY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1116:branch:STAY')), ('p_branch_name', q('IMPR1116 - stay in the form')),
        ('p_branch_action', q('f?p=&APP_ID.:1116:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '10'),
        ('p_branch_comment', src('Forms stays in the form after COMMIT / spec 12'))]))
    # items (spec 4.1, 4.2)
    for i, it in enumerate(MASTER_ITEMS, 1):
        A(page_item(PG, '1116:plug:IMPR_PRTL_NAT', i * 10, it, form_region=True))
    for seq, it in [(10, dict(name='P1116_HERO_TITLE', kind='NATIVE_HIDDEN', value_protected='Y',
                              comment='Source: IMPR1116.TITLE (OLB) - shown by the hero region (&P1116_HERO_TITLE.)')),
                    (20, dict(name='P1116_MODULE_ID', kind='NATIVE_HIDDEN', value_protected='Y', protect='S',
                              comment='Source: IMPR1116 :PARAMETER.P_MODULE_ID (f345, kept by SCREEN ENTRY RESET)'))]:
        A(page_item(PG, '1116:plug:IMPR_PRTL_NAT_HERO', seq, it))
    # processes (spec 8)
    NEW = 'NULL;  -- f345 session setup (SSO_APP_USER, P_CURR_PORT_CD, V_USR_TYPE ...) is done by the application; disabled as in AGR1100'
    BH, AS = 'BEFORE_HEADER', 'AFTER_SUBMIT'
    procs = [
        (BH, 10, 'New', NEW, ('', 'NEVER'), 'f345 session setup copied from AGR1100 (condition Never, as in AGR1100 / IMPR1120) / standard 6', {}),
        (BH, 20, 'P0_PAGE_PK CHECK', 'IMPR1116.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK);', None, 'f345 record key / spec 8', {}),
        (BH, 40, 'PARAMETERS', ":P1116_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1116_MODULE_ID, FORM_NAME => 'IMPR1116');",
         None, 'f345 / spec 8', {}),
        (BH, 70, 'P0_PAGE_PK', ':P1116_ROW_ID := :P0_PAGE_PK;', None, 'f345 (key = ROWID) / spec 8', {}),
        (BH, 80, 'Initialize form', None, None, 'IMPR1116 block IMPR_PRTL_NAT fetch / spec 8',
         dict(ptype='NATIVE_FORM_INIT', region='1116:plug:IMPR_PRTL_NAT')),
        (BH, 100, 'HEADER TITLE', "FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1116_MODULE_ID, P_HERO_TITLE => :P1116_HERO_TITLE, "
                                  "DEFAULT_TITLE => 'استعراض بيانات رقم المنشأة 700 المدخلة من البوابة');",
         None, 'f345 (OLB block TITLE) / spec 8', {}),
        (AS, 10, 'PRE-INSERT', 'IMPR1116.PRE_INSERT;', (":P0_PAGE_PK IS NULL AND :REQUEST = 'CREATE'", 'EXPRESSION', 'PLSQL'),
         'IMPR1116.IMPR_PRTL_NAT.PRE-INSERT (block Insert Allowed = No) / spec 8', {}),
        (AS, 20, 'PRE-UPDATE', PRE_UPDATE, (":P0_PAGE_PK IS NOT NULL AND :REQUEST = 'SAVE'", 'EXPRESSION', 'PLSQL'),
         'IMPR1116.IMPR_PRTL_NAT.PRE-UPDATE (activity log) / spec 8', {}),
        (AS, 30, 'PRE-DELETE', 'IMPR1116.PRE_DELETE;', ('DELETE', 'REQUEST_EQUALS_CONDITION'),
         'IMPR1116.IMPR_PRTL_NAT.PRE-DELETE (block Delete Allowed = No) / spec 8', {}),
        (AS, 40, 'Process form', None, ('SAVE', 'REQUEST_EQUALS_CONDITION'), 'IMPR1116 Forms default UPDATE of block IMPR_PRTL_NAT / spec 8',
         dict(ptype='NATIVE_FORM_DML', region='1116:plug:IMPR_PRTL_NAT',
              extra=[('p_attribute_01', q('REGION_SOURCE')), ('p_attribute_05', q('Y')), ('p_attribute_06', q('Y')),
                     ('p_attribute_08', q('Y')), ('p_process_success_message', q('تم الحفظ بنجاح'))])),
    ]
    for point, seq, name, code, cond, s, kw in procs:
        key = '1116:proc:%s:%s' % (point, name)
        A(process(PG, key, seq, point, name, code, cond, s, ptype=kw.get('ptype', 'NATIVE_PLSQL'),
                  extra=kw.get('extra'), region=kw.get('region')))
    W(block('application/pages/page_01116', '\n'.join(P)))

    # ---------------------------------------------------------------- page 111601 (search, spec 3.2 / 4.4)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_SEARCH)
    A(call('create_page', [
        ('p_id', str(PG_SEARCH)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM + '_SEARCH')), ('p_alias', q(FORM + '-SEARCH')),
        ('p_page_mode', q('MODAL')), ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_height', q('800')),
        ('p_dialog_width', q('1800')), ('p_protection_level', q('C')), ('p_first_item', q('AUTO_FIRST_ITEM')),
        ('p_page_comment', src('IMPR1116 Enter-Query / Execute-Query of block IMPR_PRTL_NAT / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: f345 search page <page>01 (page 0 SEARCH)'))
    nid('111601:plug:CRIT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('111601:plug:CRIT')), ('p_plug_name', q('بحث')), ('p_region_name', q('IMPR_PRTL_NAT_SEARCH_CRITERIA')),
        ('p_region_css_classes', q('zatca-forms cg-form')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_HERO')), ('p_plug_display_sequence', '10'), ('p_attribute_01', q('N')),
        ('p_attribute_02', q('TEXT')), ('p_attribute_03', q('Y')),
        ('p_plug_comment', src('IMPR1116.IMPR_PRTL_NAT Enter-Query criteria, as one search text over all columns / spec 3'))]))
    nid('111601:plug:IG', 1)
    A(call('create_page_plug', [
        ('p_id', ref('111601:plug:IG')), ('p_plug_name', q('بيانات البوابة غير المراجعة')), ('p_region_name', q('IMPR_PRTL_NAT_SEARCH')),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', '20'), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(SEARCH_SQL)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q('P111601_SEARCH')),
        ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1116.IMPR_PRTL_NAT block query (WHERE REVIEW_FLAG = 0 AND GAZT_NAME IS NOT NULL); pending rows shown at once, '
                               'optional search text (spec decision 2) / spec 3'))]))
    for i, (c, h, dt) in enumerate(SEARCH_COLUMNS):
        if c == 'ROW_ID':
            col = dict(name=c, kind='HIDDEN', data_type=dt, pk=True)
        elif c == 'PRTL_NAT_ISN':
            col = dict(name=c, kind='LINK', data_type=dt, heading=h,
                       link_target='f?p=&APP_ID.:1116:&SESSION.::&DEBUG.:1116:P0_PAGE_PK:&ROW_ID.', link_text='&PRTL_NAT_ISN.',
                       comment='Source: IMPR1116.IMPR_PRTL_NAT.PRTL_NAT_ISN - opens the record on page 1116 (P0_PAGE_PK = URL-safe ROWID)')
        else:
            col = dict(name=c, kind='DISPLAY', data_type=dt, heading=h)
        A(ig_column(PG_SEARCH, col, (i + 1) * 10))
    for c in ig(PG_SEARCH, '111601:plug:IG', [c for c, _, _ in SEARCH_COLUMNS], {'ROW_ID'},
                'لا توجد بيانات بوابة بانتظار المراجعة', search=True):
        A(c)
    UNCERTAIN.add('search IG: p_lazy_loading true, toolbar ACTIONS_MENU:RESET (own search text, as IMPR1120 112001)')
    A(page_item(PG_SEARCH, '111601:plug:CRIT', 10, dict(
        name='P111601_SEARCH', kind='NATIVE_TEXT_FIELD', label='بحث في كل الأعمدة', maxlen=200, span=6,
        comment='Source: IMPR1116.IMPR_PRTL_NAT query criteria (PRTL_NAT_ISN, ID_TYPE_GZT, BUS_ID_NEW, GAZT_NAME) as one text over all columns')))
    nid('111601:btn:SEARCH', 2)
    A(call('create_page_button', [
        ('p_id', ref('111601:btn:SEARCH')), ('p_button_sequence', '40'), ('p_button_plug_id', ref('111601:plug:CRIT')),
        ('p_button_name', q('SEARCH')), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
        ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q('بحث')), ('p_button_position', q('BODY')),
        ('p_icon_css_classes', q('fa-search')), ('p_button_css_classes', q('cg-b-search')),
        ('p_button_comment', src('IMPR1116 TOOLBAR.EXECUTE (Execute Query of block IMPR_PRTL_NAT) / spec 5'))]))
    nid('111601:btn:CLEAR', 2)
    A(call('create_page_button', [
        ('p_id', ref('111601:btn:CLEAR')), ('p_button_sequence', '50'), ('p_button_plug_id', ref('111601:plug:CRIT')),
        ('p_button_name', q('CLEAR')), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
        ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q('مسح البحث')), ('p_button_position', q('BODY')),
        ('p_icon_css_classes', q('fa-eraser')), ('p_button_css_classes', q('cg-b-clear')),
        ('p_button_comment', src('IMPR1116 TOOLBAR.CLEAR_ALL for the search / spec 5'))]))
    refresh = [('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('111601:plug:IG'))]
    A(da(PG_SEARCH, 10, 'SEARCH WHEN-BUTTON-PRESSED', ('BUTTON', '111601:btn:SEARCH'), 'click', [refresh],
         'IMPR1116 TOOLBAR.EXECUTE / spec 10'))
    A(da(PG_SEARCH, 12, 'SEARCH KEY-ENTER', ('ITEM', 'P111601_SEARCH'), 'keyup', [refresh],
         'IMPR1116 KEY-EXEQRY (Enter in the search text; f345 AGR1100_SEARCH keyup pattern) / spec 10', cond='ENTER'))
    A(da(PG_SEARCH, 15, 'CLEAR WHEN-BUTTON-PRESSED', ('BUTTON', '111601:btn:CLEAR'), 'click',
         [[('p_action', q('NATIVE_CLEAR')), ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q('P111601_SEARCH'))], refresh],
         'IMPR1116 TOOLBAR.CLEAR_ALL (search criteria) / spec 10'))
    UNCERTAIN.add('NATIVE_CLEAR action with p_affected_elements (search CLEAR; as IMPR1120 112001)')
    UNCERTAIN.add('button DA: p_triggering_button_id (search SEARCH / CLEAR; IMPR1110 uses it)')
    ek, ak = '111601:da:Hide', '111601:daa:Hide:10'
    nid(ek, 8); nid(ak, 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('Hide')), ('p_event_sequence', '20'),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('ready')),
                                    ('p_da_event_comment', src('f345 AGR1100_SEARCH "Hide" (page 0 toolbar not used in a dialog)'))]))
    A(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('Y')), ('p_action', q('NATIVE_HIDE')),
                                     ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', fid('P0_ACTIONS'))]))
    W(block('application/pages/page_111601', '\n'.join(P)))

    W('''prompt --application/end_environment
begin
wwv_flow_api.component_end;
end;
/
set verify on feedback on define on
prompt  ...done
''')
    text = '\n'.join(out)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    return text


# ----------------------------------------------------------------------------- checks
def names_of(text, api):
    out = []
    for chunk in text.split('wwv_flow_api.%s(' % api)[1:]:
        m = re.search(r"\n[ ,]p_name=>'([^']+)'", chunk[:chunk.find('\n);')])
        if m: out.append(m.group(1))
    return out

def unq(s):
    """decode a q() literal back to text (for the checks)"""
    m = re.fullmatch(r"unistr\('(.*)'\)", s, re.S)
    if m:
        return re.sub(r'\\([0-9A-F]{4})', lambda x: chr(int(x.group(1), 16)), m.group(1)).replace("''", "'")
    return s[1:-1].replace("''", "'") if s.startswith("'") else s

def selfcheck(text):
    problems = item_icons.check(text) + lov_apx.check(text) + functions_drawer.check_form_page(text)
    ref_txt = open(REF, encoding='utf-8', errors='replace').read()
    i1110 = open(IMPR1110_EXPORT, encoding='utf-8', errors='replace').read()
    pkg_txt = re.sub(r'--[^\n]*', '', open(PKG, encoding='utf-8').read())
    if 'wwv_flow_imp' in text: problems.append('wwv_flow_imp found')
    if '{{' in text: problems.append('{{ found')
    allowed = {'__WORKSPACE_ID__', '__APP_ID__', '__SCHEMA_NAME__', '__ID_OFFSET__'}
    ph = set(re.findall(r'__[A-Z_]+__', text))
    if ph - allowed: problems.append('unexpected placeholders %s' % sorted(ph - allowed))
    if re.search(r'password|pwd', text, re.I): problems.append('password text found')
    code = '\n'.join(l for l in text.splitlines() if not l.startswith('--') and not re.match(r'^[ ,]p_\w*comment=>', l))
    if re.search(r'\bAI_[A-Z]', code): problems.append('AI_ item name found')
    if re.search(r'pkg_', code, re.I): problems.append('page calls pkg_')
    for bad in ('ON_DEMAND', 'p_javascript_file_urls', 'AJAX_FUNCTION', 'create_security_scheme'):
        if bad in code: problems.append('not allowed: ' + bad)
    defined = re.findall(r'[ ,]p_id=>wwv_flow_api\.id\((\d+)\)', text)
    if len(defined) != len(set(defined)): problems.append('duplicate p_id')
    ref_ids = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', ref_txt))
    ids_1110 = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', i1110))
    if set(defined) & ref_ids: problems.append('ids clash with f345')
    if set(defined) & ids_1110: problems.append('ids clash with the IMPR1110 export')
    other_txt = ''.join(open(p, encoding='utf-8', errors='replace').read() for p in OTHER_EXPORTS if os.path.exists(p))
    ids_other = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', other_txt))
    if set(defined) & ids_other: problems.append('ids clash with the IMPR1120 / SUPPORT_ENTRY exports')
    for n in re.findall(r"p_lov_name=>'([^']+)'", text):
        if n in set(re.findall(r"p_lov_name=>'([^']+)'", other_txt)): problems.append('LOV %s already in IMPR1120 / SUPPORT_ENTRY' % n)
    missing = set(re.findall(r'wwv_flow_api\.id\((\d+)\)', text)) - set(defined) - ref_ids - ids_1110
    if missing: problems.append('ids used but defined nowhere: %s' % sorted(missing))
    for k, v in F345.items():
        if v not in ref_ids: problems.append('f345 id %s (%s) not in f345.sql' % (k, v))
    for k, v in IMPR1110_IDS.items():
        if v not in ids_1110: problems.append('IMPR1110 id %s (%s) not in the IMPR1110 export' % (k, v))
    lov_1110 = set(re.findall(r"p_lov_name=>'([^']+)'", i1110))
    for n in REUSED_LOVS:
        if n not in lov_1110: problems.append('reused LOV %s not in the IMPR1110 export' % n)
    ref_lovs = set(re.findall(r"p_lov_name=>'([^']+)'", ref_txt))
    for n in re.findall(r"p_lov_name=>'([^']+)'", text):
        if n in ref_lovs or n in lov_1110: problems.append('LOV %s already exists (f345 / IMPR1110)' % n)
    for n in re.findall(r"p_named_lov=>'([^']+)'", text):
        if n not in lov_1110 | set(re.findall(r"p_lov_name=>'([^']+)'", text)): problems.append('named LOV %s not defined' % n)
    if names_of(text, 'create_flow_item'): problems.append('application item created (none expected)')
    # package members and parameter names
    sigs = {}
    for m in re.finditer(r'(?:PROCEDURE|FUNCTION)\s+([A-Z0-9_$]+)\s*(\((.*?)\))?\s*(?:RETURN\s+\w+\s*)?;', pkg_txt, re.S):
        sigs[m.group(1).upper()] = set(re.findall(r'\b([A-Z][A-Z0-9_$]*)\s+(?:IN|OUT)\b', m.group(3) or ''))
    plain = '\n'.join(unq(v) for v in re.findall(r"(?:unistr\('(?:[^']|'')*'\)|'(?:[^']|'')*')", code))
    for m in set(re.findall(r'IMPR1116\.([A-Z_0-9$]+)', plain)):
        if m not in sigs: problems.append('IMPR1116.%s not in impr1116_spec.sql' % m)
    for m in re.finditer(r'IMPR1116\.([A-Z0-9_$]+)\(([^()]*)\)', plain):
        name, args = m.groups()
        given = re.findall(r'([A-Z0-9_$]+)\s*=>', args)
        if name in sigs and given and set(given) != sigs[name]:
            problems.append('call %s: parameters %s vs spec %s' % (name, sorted(set(given) ^ sigs[name]), ''))
    # common helpers: FORMS_APX 004 (plsql_templates/forms_apx.sql); members and named parameters must exist
    sys.path.insert(0, os.path.join(ROOT, 'scripts'))
    import forms_apx_helpers
    fx = forms_apx_helpers.forms_apx_members(ROOT)
    for name in set(re.findall(r'FORMS_APX\.([A-Z0-9_$]+)', plain)):
        if name not in fx: problems.append('FORMS_APX.%s not in forms_apx.sql' % name)
    for m in re.finditer(r'FORMS_APX\.([A-Z0-9_$]+)\(([^()]*(?:\([^()]*\)[^()]*)*)\)', plain):
        name, args = m.groups()
        given = set(re.findall(r'(?<![.\w])([A-Z0-9_$]+)\s*=>', re.sub(r'\([^()]*\)', '()', args)))
        if name in fx and given and not given <= fx[name]:
            problems.append('call FORMS_APX.%s: unknown parameters %s' % (name, sorted(given - fx[name])))
    for name in re.findall(r"p_(?:name|process_name|validation_name)=>'([^']*)'", text):
        if '.' in name and ' ' not in name and not name.startswith('P'): problems.append('dot in component name ' + name)
    # binds: page items, IG columns, application items
    page_items = set(names_of(text, 'create_page_item'))
    columns = set(names_of(text, 'create_region_column'))
    ref_items = set(names_of(ref_txt, 'create_flow_item'))
    for b in set(re.findall(r"(?<![\w$&])[:](P\d+_\w+|P_\w+|G_\w+|SSO_APP_USER|V_USR_TYPE)\b", plain)):
        if b not in page_items | ref_items and not b.startswith('P0_'): problems.append('bind :%s has no item' % b)
    for b in set(re.findall(r"(?<![\w$&:])[:]([A-Z][A-Z_$]+)\b", plain)):
        if b not in columns | page_items | ref_items | {'APEX$ROW_STATUS', 'REQUEST', 'APP_USER'} and not re.match(r'P\d', b) \
                and not b.startswith(('P_', 'G_', 'SSO_', 'V_', 'P0_')):
            problems.append('bind :%s is no column / item' % b)
    fos_actions = [c for c in code.split('wwv_flow_api.create_page_da_action(')[1:] if 'PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE' in c[:c.find('\n);')]]
    for b in set(x for c in fos_actions for x in re.findall(r"p_attribute_0[23]=>'([^']+)'", c[:c.find('\n);')])):
        for i in b.split(','):
            if i not in page_items | columns and not i.startswith('P0_'): problems.append('FOS item %s missing' % i)
    if text.count('\nbegin\n') != text.count('\nend;\n/'): problems.append('begin/end not balanced')
    # Execute JavaScript Code: at most 3 lines (CLAUDE.md §4c); the only one is the number_only handler
    for j in re.findall(r"p_action=>'NATIVE_JAVASCRIPT_CODE'\n,p_attribute_01=>(.*?)\n(?=[,)])", text, re.S):
        if j.count("',\n") + 1 > 3: problems.append('JavaScript action > 3 lines')
        problems.append('unexpected JavaScript action: ' + j[:60])
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
    # a region column (and create_interactive_grid) belongs to the region created last before it
    current = None
    for m in re.finditer(r"wwv_flow_api\.(create_page_plug|create_page|create_region_column|create_interactive_grid)\(\n p_id=>wwv_flow_api\.id\((\d+)\)(.*?)\n\);", text, re.S):
        api, pid, rest = m.groups()
        if api == 'create_page': current = None
        elif api == 'create_page_plug': current = (pid, 'NATIVE_IG' in rest)
        elif not current or not current[1]:
            problems.append('%s %s follows a region that is not an interactive grid' % (api, pid))
    for m in re.finditer(r"p_triggering_element_type=>'COLUMN'\n,p_triggering_region_id=>wwv_flow_api\.id\((\d+)\)\n,p_triggering_element=>'([^']+)'", text):
        rid, col = m.groups()
        seg = text.split('p_id=>wwv_flow_api.id(%s)' % rid, 1)[1].split('wwv_flow_api.create_page_plug(', 1)[0]
        if "p_name=>'%s'" % col not in seg: problems.append('DA column %s not a column of region %s' % (col, rid))
    # package body: private functions inside SQL, parameters not qualified inside SQL (scripts/parameter_names.py)
    sys.path.insert(0, os.path.join(ROOT, 'scripts'))
    import parameter_names
    spec_raw = open(PKG, encoding='utf-8').read()
    body_raw = open(PKG.replace('_spec.sql', '_body.sql'), encoding='utf-8').read()
    for hit in parameter_names.private_functions_in_sql(spec_raw, body_raw):
        problems.append('package: private function %s called inside SQL in %s (ORA-00904)' % (hit[1], hit[0]))
    for hit in parameter_names.unqualified_in_sql(spec_raw, body_raw):
        problems.append('package: parameter %s not qualified inside SQL in %s' % (hit[1], hit[0]))
    for name in forms_apx_helpers.leftovers(spec_raw + body_raw):
        problems.append('package: common helper %s defined in IMPR1116 (belongs to FORMS_APX)' % name)
    for name in forms_apx_helpers.unknown_calls(spec_raw + body_raw, ROOT):
        problems.append('package: FORMS_APX.%s not in forms_apx.sql' % name)
    counts = {k: len(re.findall(r'wwv_flow_api\.%s\(' % k, text)) for k in [
        'create_page', 'create_page_plug', 'create_page_item', 'create_page_button', 'create_page_validation',
        'create_page_process', 'create_page_da_event', 'create_page_da_action', 'create_page_computation', 'create_page_branch',
        'create_region_column', 'create_interactive_grid', 'create_ig_report_column', 'create_list_of_values',
        'create_flow_item', 'create_message', 'create_security_scheme', 'create_page_group']}
    counts['NATIVE_JAVASCRIPT_CODE actions'] = text.count("p_action=>'NATIVE_JAVASCRIPT_CODE'")
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
    path = os.path.join(ROOT, 'apex', 'IMPR1116', 'f%s_impr1116_import.sql' % vals['app_id'])
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
    print('problems:', probs or 'none')
    if probs:
        sys.exit(1)
    if len(sys.argv) > 1:
        ready_copy(t, sys.argv[1:])
