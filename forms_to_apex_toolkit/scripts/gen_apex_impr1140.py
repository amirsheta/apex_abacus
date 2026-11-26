# -*- coding: utf-8 -*-
"""
gen_apex_impr1140.py - step 04: APEX 21.2 component export of IMPR1140 (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c / 4d, docs/f345_reference_standard.md).

Design : analysis/IMPR1140/IMPR1140_apex_page_spec.md (step 03); the design data is written in this
         script (sections marked "spec N"), so a spec change means a change here and a re-run.
Checks : apex/Reference/f345.sql (template ids, existing ids / items / LOVs),
         every other component export apex/*/f345_*.sql (shared components reused from IMPR1110, id clashes),
         plsql/IMPR1140/impr1140_spec.sql (members and parameter names of every call),
         plsql_templates/lov_apx.sql (LOV functions), plsql_templates/forms_apx.sql (common helpers).
Writes : apex/IMPR1140/f345_impr1140.sql   component export, REVIEW BEFORE IMPORT (4 placeholders)
         apex/IMPR1140/f<app>_impr1140_import.sql  with --workspace-id --app-id --id-offset --schema

Parameter patterns: the helpers come from scripts/gen_apex_impr1120.py / gen_apex_impr1110.py; the Popup LOV
grid column is copied from the AGR1100 page 11100 of f345 (git abc7d61, column CTRY_CD). Parameters that appear
in none of them are collected in UNCERTAIN and listed in import_notes.md.

Usage (from forms_to_apex_toolkit):
    python3 -I scripts/gen_apex_impr1140.py [--workspace-id=.. --app-id=.. --id-offset=.. --schema=..]
"""
import glob, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
import number_only      # Number Field items: CSS class number_only + one page-load handler on page 0
import functions_drawer # the FUNCS region is on page 0, never on a form page
import item_icons      # Post Text icon next to every entry item, from the item name (f202604 convention)
import items_to_submit # every page item a query / LOV / FOS call reads is in its Items to Submit (user rule 2026-11-25)
import client_condition  # an item in an item-type client-side condition has a default value (user rule 2026-11-26)
import search_page      # a search page <page>01 reads no data when the dialog opens (user request 2026-11-26)
import lov_apx         # shared LOVs: function body returning SQL, code in LOV_APX (CLAUDE.md 4d)
REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')
IMPR1110_EXPORT = os.path.join(ROOT, 'apex', 'IMPR1110', 'f345_impr1110.sql')
PKG = os.path.join(ROOT, 'plsql', 'IMPR1140', 'impr1140_spec.sql')
OUT = os.path.join(ROOT, 'apex', 'IMPR1140', 'f345_impr1140.sql')
OTHER_EXPORTS = [p for p in glob.glob(os.path.join(ROOT, 'apex', '*', 'f345_*.sql'))
                 if os.path.basename(os.path.dirname(p)) not in ('IMPR1140', 'Reference')]
DATE, STAMP = '2026-11-24', '20261124000000'
FORM = 'IMPR1140'
PG, PG_SEARCH = 1140, 114001
SHARED_BASE = 9140                 # IMPR1110 9000, IMPR1116 9116, IMPR1120 9120, IMPR1125 9125

# ----------------------------------------------------------------------------- f345 ids (standard 3)
F345 = dict(
    UI='11622010846008869795', PAGE_MAIN='11622270914969205733', REGION_HERO='11621859120066869682',
    REGION_FORM='11621909206693869707', REGION_GRID='11621913486616869708', REGION_TABS='11621923018393869712',
    LABEL_REQ='11621984380233869750', LABEL_OPT='11621983529556869749',
    BUTTON='11621986167597869752', P0_ACTIONS='73488102084440079322')
IMPR1110_IDS = dict(PAGE_GROUP_IMPR='900001000010')
REUSED_LOVS = ['LOV_SD_PORTS']
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
    """deterministic id <page or 9140><kind 2><seq 6>"""
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
    """it: name, kind, label, column, data_type, pk, req, lov, lov_null, submit, default, maxlen, read_only,
       value_protected, protect, span, newline, comment"""
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
    p += [('p_item_default', q(it.get('default'))), ('p_prompt', q(it.get('label')))]
    if form_region and it.get('column'):
        p += [('p_source', q(it['column'])), ('p_source_type', q('REGION_SOURCE_COLUMN'))]
    p.append(('p_display_as', q(k)))
    if it.get('lov'):
        p += [('p_named_lov', q(it['lov'])), ('p_lov_display_null', q(it.get('lov_null', 'YES')))]
        if it.get('submit'):
            p.append(('p_ajax_items_to_submit', q(it['submit'])))
    if k in ('NATIVE_TEXT_FIELD', 'NATIVE_NUMBER_FIELD', 'NATIVE_POPUP_LOV'):
        p.append(('p_cSize', '30'))
    if it.get('maxlen') and k not in ('NATIVE_DISPLAY_ONLY', 'NATIVE_HIDDEN', 'NATIVE_SELECT_LIST'):
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
    if k != 'NATIVE_HIDDEN':
        p += [('p_field_template', fid('LABEL_REQ' if it.get('req') else 'LABEL_OPT')),
              ('p_item_template_options', q(ITEM_OPTS))]
    p.append(('p_is_persistent', q('N')))
    if it.get('protect'):
        p.append(('p_protection_level', q(it['protect'])))
    if k == 'NATIVE_TEXT_FIELD':
        p += [('p_attribute_01', q('N')), ('p_attribute_02', q('N')), ('p_attribute_04', q('TEXT')), ('p_attribute_05', q('BOTH'))]
    elif k == 'NATIVE_NUMBER_FIELD':
        p += [('p_attribute_03', q('right'))]
    elif k == 'NATIVE_SELECT_LIST':
        p += [('p_attribute_01', q('NONE')), ('p_attribute_02', q('N'))]
    elif k == 'NATIVE_POPUP_LOV':
        p += [('p_attribute_01', q('DIALOG')), ('p_attribute_02', q('FIRST_ROWSET')), ('p_attribute_03', q('N'))]
    elif k == 'NATIVE_DISPLAY_ONLY':
        # p_attribute_01 = Send On Page Submit (N: server value, FOS / processes set it - as IMPR1110)
        p += [('p_attribute_01', q('N')), ('p_attribute_02', q('VALUE')), ('p_attribute_04', q('N')), ('p_attribute_05', q('PLAIN'))]
    elif k == 'NATIVE_HIDDEN':
        p += [('p_attribute_01', q(it.get('value_protected', 'Y')))]
    p.append(('p_item_comment', q(it.get('comment'))))
    return call('create_page_item', p)

# ----------------------------------------------------------------------------- region columns (IG)
FILTER = [('p_enable_filter', 'true'), ('p_filter_operators', q('C:S:CASE_INSENSITIVE:REGEXP')), ('p_filter_is_required', 'false'),
          ('p_filter_text_case', q('MIXED')), ('p_filter_lov_type', q('NONE')), ('p_use_as_row_header', 'false'),
          ('p_enable_sort_group', 'true'), ('p_enable_control_break', 'true'), ('p_enable_hide', 'true')]

def ig_column(rk, c, seq):
    """rk: region key (page:region); c: name, kind (HIDDEN / TEXT / NUMBER / SELECT / POPUP / DISPLAY / LINK), data_type,
       heading, pk, req, maxlen, lov_key, default_item, default_static, query_only, read_only, link_target, link_text, comment"""
    key = '%s:col:%s' % (rk, c['name'])
    nid(key, 2)
    p = [('p_id', ref(key)), ('p_name', q(c['name'])), ('p_source_type', q('DB_COLUMN')), ('p_source_expression', q(c['name'])),
         ('p_data_type', q(c['data_type'])), ('p_is_query_only', 'true' if c.get('query_only') else 'false')]
    k = c['kind']
    if k == 'HIDDEN':
        p += [('p_item_type', q('NATIVE_HIDDEN')), ('p_display_sequence', str(seq)), ('p_attribute_01', q('Y')),
              ('p_use_as_row_header', 'false'), ('p_enable_sort_group', 'false'),
              ('p_is_primary_key', 'true' if c.get('pk') else 'false'), ('p_duplicate_value', 'true'), ('p_include_in_export', 'false')]
    else:
        item_type = dict(TEXT='NATIVE_TEXT_FIELD', NUMBER='NATIVE_NUMBER_FIELD', SELECT='NATIVE_SELECT_LIST', POPUP='NATIVE_POPUP_LOV',
                         DISPLAY='NATIVE_DISPLAY_ONLY', LINK='NATIVE_LINK')[k]
        p += [('p_item_type', q(item_type)), ('p_heading', q(c['heading'])), ('p_heading_alignment', q('CENTER')),
              ('p_display_sequence', str(seq)), ('p_value_alignment', q('CENTER'))]
        css = None
        if k in ('TEXT', 'NUMBER') and c['data_type'] == 'NUMBER':
            css = number_only.add_class(None)          # editable number column: digits only (scripts/number_only.py)
        if k == 'TEXT':
            p += [('p_attribute_01', q('N')), ('p_attribute_02', q('N')), ('p_attribute_04', q('TEXT')), ('p_attribute_05', q('BOTH'))]
        elif k == 'NUMBER':
            p += [('p_attribute_03', q('right'))]
        elif k == 'POPUP':        # as AGR1100 page 11100 column CTRY_CD
            p += [('p_attribute_01', q('POPUP')), ('p_attribute_02', q('FIRST_ROWSET')), ('p_attribute_03', q('N')),
                  ('p_attribute_04', q('N')), ('p_attribute_05', q('N'))]
        elif k == 'DISPLAY':
            p += [('p_attribute_02', q('VALUE')), ('p_attribute_05', q('PLAIN'))]
        elif k == 'LINK':
            p += [('p_link_target', q(c['link_target'])), ('p_link_text', q(c['link_text'])), ('p_link_attributes', q('target="_top"'))]
        if css:
            p.append(('p_item_css_classes', q(css)))
        if k in ('TEXT', 'NUMBER', 'SELECT', 'POPUP'):
            p.append(('p_is_required', 'true' if c.get('req') else 'false'))
        if c.get('maxlen'):
            p.append(('p_max_length', str(c['maxlen'])))
        if k in ('SELECT', 'POPUP'):
            p += [('p_lov_type', q('SHARED')), ('p_lov_id', ref(c['lov_key'])), ('p_lov_display_extra', 'false'),
                  ('p_lov_display_null', 'true' if k == 'POPUP' else 'false')]
            UNCERTAIN.add('IG select list / popup LOV column on a shared LOV: p_lov_type => SHARED + p_lov_id '
                          '(f345 shows only SQL_QUERY / p_lov_source; IMPR1120 uses it)')
        p += FILTER + [('p_is_primary_key', 'false')]
    if c.get('default_item'):    # master key from the master form item (Forms CopyValueFrom)
        p += [('p_default_type', q('ITEM')), ('p_default_expression', q(c['default_item']))]
        UNCERTAIN.add('IG column default from a page item: p_default_type => ITEM + p_default_expression (f345 shows only STATIC)')
    if c.get('default_static'):
        p += [('p_default_type', q('STATIC')), ('p_default_expression', q(c['default_static']))]
    if k != 'HIDDEN':
        p += [('p_duplicate_value', 'true'), ('p_include_in_export', 'true')]
    if c.get('read_only'):
        p += [('p_readonly_condition_type', q('EXPRESSION')), ('p_readonly_condition', lit(c['read_only'])),
              ('p_readonly_condition2', q('PLSQL')), ('p_readonly_for_each_row', 'true')]
    return call('create_region_column', p, c.get('comment'))

def ig_row_columns(rk):
    out = []
    for name, itype, seq, extra in [('APEX$ROW_ACTION', 'NATIVE_ROW_ACTION', 20, []),
                                    ('APEX$ROW_SELECTOR', 'NATIVE_ROW_SELECTOR', 10,
                                     [('p_attribute_01', q('Y')), ('p_attribute_02', q('Y')), ('p_attribute_03', q('N'))])]:
        key = '%s:col:%s' % (rk, name)
        nid(key, 2)
        out.append(call('create_region_column', [('p_id', ref(key)), ('p_name', q(name)), ('p_item_type', q(itype)),
                                                 ('p_display_sequence', str(seq))] + extra))
    return out

def ig(rk, uid, edit_ops, cols, hidden, empty_msg, rows=None, search=False):
    page = rk.split(':')[0]
    gk, rpk, vk = rk + ':ig', rk + ':igr', rk + ':igv'
    nid(gk, 3); nid(rpk, 3); nid(vk, 3)
    prm = [('p_id', ref(gk)), ('p_internal_uid', uid), ('p_is_editable', 'true' if edit_ops else 'false')]
    if edit_ops:
        prm += [('p_edit_operations', q(edit_ops)), ('p_lost_update_check_type', q('VALUES')), ('p_add_row_if_empty', 'false'),
                ('p_submit_checked_rows', 'false')]
    prm += [('p_lazy_loading', 'true' if search else 'false'), ('p_requires_filter', 'false'), ('p_select_first_row', 'true'),
            ('p_fixed_row_height', 'true'), ('p_pagination_type', q('SET')),
            ('p_show_total_row_count', 'false' if search else 'true'), ('p_no_data_found_message', q(empty_msg)),
            ('p_show_toolbar', 'true'),
            ('p_toolbar_buttons', q('ACTIONS_MENU:RESET' if search else 'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET')),
            ('p_enable_save_public_report', 'false'), ('p_enable_subscriptions', 'true'), ('p_enable_flashback', 'true'),
            ('p_define_chart_view', 'true'), ('p_enable_download', 'true'), ('p_download_formats', q('CSV:HTML:XLSX:PDF')),
            ('p_enable_mail_download', 'true'), ('p_fixed_header', q('PAGE')), ('p_show_icon_view', 'false'), ('p_show_detail_view', 'false')]
    out = [call('create_interactive_grid', prm)]
    out.append(call('create_ig_report', [('p_id', ref(rpk)), ('p_interactive_grid_id', ref(gk)), ('p_static_id', q(uid[:-1] + '2')),
                                         ('p_type', q('PRIMARY')), ('p_default_view', q('GRID')),
                                         ('p_rows_per_page', str(rows) if rows else None),
                                         ('p_show_row_number', 'false'), ('p_settings_area_expanded', 'true')]))
    if rows:
        UNCERTAIN.add('create_ig_report p_rows_per_page (Forms Records Displayed; not in f345; IMPR1120 uses it)')
    out.append(call('create_ig_report_view', [('p_id', ref(vk)), ('p_report_id', ref(rpk)), ('p_view_type', q('GRID')),
                                              ('p_stretch_columns', 'true'), ('p_srv_exclude_null_values', 'false'),
                                              ('p_srv_only_display_columns', 'true'), ('p_edit_mode', 'false')]))
    for i, name in enumerate(cols):
        key = '%s:igc:%s' % (rk, name)
        nid(key, 3)
        out.append(call('create_ig_report_column', [('p_id', ref(key)), ('p_view_id', ref(vk)), ('p_display_seq', str(i)),
                                                    ('p_column_id', ref('%s:col:%s' % (rk, name))),
                                                    ('p_is_visible', 'false' if name in hidden else 'true'), ('p_is_frozen', 'false')]))
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

def item_action(action, items):
    return [('p_action', q(action)), ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q(items))]

def da(page, seq, name, trigger, event, actions, s, cond=None, init=False):
    """trigger: ('ITEM', item) | ('COLUMN', region_key, column) | ('BUTTON', button_key) | ('READY',)
       actions: list of parameter lists (TRUE) or ('FALSE', parameter list); cond: None | 'NOT_NULL' | 'ENTER' | ('EQUALS', value)"""
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
    elif cond == 'ENTER':
        p += [('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_expression', q('this.browserEvent.which === 13'))]
        UNCERTAIN.add('DA client-side condition JAVASCRIPT_EXPRESSION this.browserEvent.which === 13 (Enter key; not in f345)')
    elif cond:
        p += [('p_triggering_condition_type', q(cond[0])), ('p_triggering_expression', q(cond[1]))]
        UNCERTAIN.add('DA client-side condition p_triggering_condition_type => EQUALS + p_triggering_expression, with FALSE actions '
                      '(page 1140 ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM; not in f345)')
    p += [('p_bind_type', q('bind')), ('p_bind_event_type', q(event)), ('p_da_event_comment', src(s))]
    out = [call('create_page_da_event', p)]
    for i, a in enumerate(actions, 1):
        result, prm = ('FALSE', a[1]) if isinstance(a, tuple) else ('TRUE', a)
        ak = '%s:daa:%s:%d' % (page, name, i * 10)
        nid(ak, 9)
        out.append(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q(result)),
                                                  ('p_action_sequence', str(i * 10)),
                                                  ('p_execute_on_page_init', q('Y' if trigger[0] == 'READY' or init else 'N'))] + prm))
    return '\n'.join(out)

# ----------------------------------------------------------------------------- design (spec 0-13)
APP = 'P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID'
R_RULES, R_PORTS, R_TARIFF, R_TABS = '1140:plug:IMPR_RULES', '1140:plug:IMPR_RULE_PORTS', '1140:plug:IMPR_RULE_TARIFF', '1140:plug:CG$M_TAB_1'
STORED = ':ROW_ID IS NOT NULL'     # Update Allowed = false: the column is entered on a new row only

# page 1140, region IMPR_RULES (spec 4.1) - Forms tab order
MASTER_ITEMS = [
    dict(name='P1140_ROW_ID', kind='NATIVE_HIDDEN', column='ROWID', data_type='ROWID', pk=True,
         comment='Source: IMPR1140.IMPR_RULES key mode ROWID (Form region primary key, = P0_PAGE_PK)'),
    dict(name='P1140_RULE_ISN', kind='NATIVE_DISPLAY_ONLY', label='مسلسل الاستثناء', column='RULE_ISN', data_type='NUMBER', span=2,
         comment='Source: IMPR1140.IMPR_RULES.RULE_ISN (display only; PRE-INSERT MAX + 1)'),
    dict(name='P1140_RULE_TYPE', kind='NATIVE_SELECT_LIST', label='نوع الاستثناء', column='RULE_TYPE', data_type='NUMBER',
         lov='LOV_RULE_TYPE', lov_null='NO', default='1', newline=False, span=10,
         comment='Source: IMPR1140.IMPR_RULES.RULE_TYPE (pop list, CG_REF_CODES RULE_TYPE, default 1)'),
    dict(name='P1140_ALL_BRNCH_FLAG', kind='NATIVE_SELECT_LIST', label='استخدام الاستثناء', column='ALL_BRNCH_FLAG', data_type='NUMBER',
         lov='LOV_ALL_BRNCH_FLAG', lov_null='NO', default='0', span=4,
         comment='Source: IMPR1140.IMPR_RULES.ALL_BRNCH_FLAG (static pop list, default 0)'),
    dict(name='P1140_REC_STATUS', kind='NATIVE_SELECT_LIST', label='حـالة السجل', column='REC_STATUS', data_type='NUMBER',
         lov='LOV_REC_STATUS', lov_null='NO', default='1', newline=False, span=4,
         comment='Source: IMPR1140.IMPR_RULES.REC_STATUS (pop list, CG_REF_CODES REC_STATUS, default 1)'),
    dict(name='P1140_HQ_IMPR_NBR', kind='NATIVE_POPUP_LOV', label='رقم المستورد الموحد', column='HQ_IMPR_NBR', data_type='NUMBER',
         lov='LOV_SINGLE_IMPORTERS', submit='P1140_RULE_TYPE', maxlen=11, span=3,
         comment='Source: IMPR1140.IMPR_RULES.HQ_IMPR_NBR (KEY-LISTVAL / B_IMP -> SINGLE_IMP_LOV: LOV_IMPORT_HQ_NBR or LOV_IMPORT_HQ_N12)'),
    dict(name='P1140_L_SI_ARBC_IMPR_NAME', kind='NATIVE_DISPLAY_ONLY', newline=False, span=9,
         comment='Source: IMPR1140.IMPR_RULES.L_SI_ARBC_IMPR_NAME (non-database; POST-QUERY / HQ_IMPR_NBR WHEN-VALIDATE-ITEM)'),
    dict(name='P1140_BUS_ID_TYPE_CD', kind='NATIVE_DISPLAY_ONLY', label='نوع الرقم الاستدلالى', column='BUS_ID_TYPE_CD', data_type='NUMBER',
         req=True, span=2, comment='Source: IMPR1140.IMPR_RULES.BUS_ID_TYPE_CD (Required; set by HQ_IMPR_NBR WHEN-VALIDATE-ITEM, saved)'),
    dict(name='P1140_BUS_ID_TYPE_NAME', kind='NATIVE_DISPLAY_ONLY', newline=False, span=4,
         comment='Source: IMPR1140.IMPR_RULES.BUS_ID_TYPE_NAME (non-database; POST-QUERY CGFK$QRY_IMPR_RULES_IR_BIT_FK)'),
    dict(name='P1140_BUS_ID', kind='NATIVE_DISPLAY_ONLY', label='الرقم الاستدلالى', column='BUS_ID', data_type='VARCHAR2', newline=False,
         span=3, comment='Source: IMPR1140.IMPR_RULES.BUS_ID (set by HQ_IMPR_NBR WHEN-VALIDATE-ITEM, saved)'),
    dict(name='P1140_BUS_ID_BRNCH', kind='NATIVE_TEXT_FIELD', label='الفرع', column='BUS_ID_BRNCH', data_type='VARCHAR2', maxlen=10,
         newline=False, span=3,
         comment='Source: IMPR1140.IMPR_RULES.BUS_ID_BRNCH (enterable while ALL_BRNCH_FLAG <> 1: PU ADJ_BRANCH)'),
]

PORTS_COLUMNS = [
    dict(name='ROW_ID', kind='HIDDEN', data_type='VARCHAR2', pk=True, comment='Source: IMPR1140.IMPR_RULE_PORTS ROWID (grid key)'),
    dict(name='RULE_ISN', kind='HIDDEN', data_type='NUMBER', default_item='P1140_RULE_ISN',
         comment='Source: IMPR1140.IMPR_RULE_PORTS.RULE_ISN (CopyValueFrom IMPR_RULES.RULE_ISN)'),
    dict(name='PORT_CD', kind='POPUP', data_type='NUMBER', heading='رمز الجمرك', req=True, lov_key='9140:lov:LOV_SD_PORTS_REUSED',
         read_only=STORED, comment='Source: IMPR1140.IMPR_RULE_PORTS.PORT_CD (Required, Update Allowed = false; LOV form LOV_SD_PORTS)'),
    dict(name='PORT_NAME', kind='DISPLAY', data_type='VARCHAR2', heading='اسم الجمرك', query_only=True,
         comment='Source: IMPR1140.IMPR_RULE_PORTS.PORT_NAME (POST-QUERY / PORT_CD WHEN-VALIDATE-ITEM)'),
    dict(name='REC_STATUS', kind='SELECT', data_type='NUMBER', heading='حالة السجل', req=True, lov_key='9140:lov:LOV_REC_STATUS',
         default_static='1', comment='Source: IMPR1140.IMPR_RULE_PORTS.REC_STATUS (pop list REC_STATUS, default 1)'),
]
TARIFF_COLUMNS = [
    dict(name='ROW_ID', kind='HIDDEN', data_type='VARCHAR2', pk=True, comment='Source: IMPR1140.IMPR_RULE_TARIFF ROWID (grid key)'),
    dict(name='RULE_ISN', kind='HIDDEN', data_type='NUMBER', default_item='P1140_RULE_ISN',
         comment='Source: IMPR1140.IMPR_RULE_TARIFF.RULE_ISN (CopyValueFrom IMPR_RULES.RULE_ISN)'),
    dict(name='HRMNZD_CODE', kind='POPUP', data_type='VARCHAR2', heading='رمز بند التعريفة', req=True, maxlen=16,
         lov_key='9140:lov:LOV_HARMONIZED_TARIFF', read_only=STORED,
         comment='Source: IMPR1140.IMPR_RULE_TARIFF.HRMNZD_CODE (Required, Update Allowed = false; LOV form LOV_TRF_ITEMS)'),
    dict(name='HT_ITEM_ARBC_DESC', kind='DISPLAY', data_type='VARCHAR2', heading='الوصــــــــــف', query_only=True,
         comment='Source: IMPR1140.IMPR_RULE_TARIFF.HT_ITEM_ARBC_DESC (HRMNZD_CODE POST-CHANGE / WHEN-VALIDATE-ITEM)'),
    dict(name='EXEPTION_QTY', kind='NUMBER', data_type='NUMBER', heading='الكمية المستثناة', req=True, maxlen=14,
         comment='Source: IMPR1140.IMPR_RULE_TARIFF.EXEPTION_QTY (column EXCEPTED_QTY, Required)'),
    dict(name='REMAINED_QTY', kind='DISPLAY', data_type='NUMBER', heading='الكمية المتبقية',
         comment='Source: IMPR1140.IMPR_RULE_TARIFF.REMAINED_QTY (display only; EXEPTION_QTY WHEN-VALIDATE-ITEM, saved)'),
    dict(name='INTL_UNIT', kind='DISPLAY', data_type='VARCHAR2', heading='الوحدةالدوليه', query_only=True,
         comment='Source: IMPR1140.IMPR_RULE_TARIFF.INTL_UNIT (POST-QUERY)'),
    dict(name='REC_STATUS', kind='SELECT', data_type='NUMBER', heading='حالة السجل', req=True, lov_key='9140:lov:LOV_REC_STATUS',
         default_static='1', comment='Source: IMPR1140.IMPR_RULE_TARIFF.REC_STATUS (pop list REC_STATUS, default 1)'),
    dict(name='ITEM_SEQUENCE', kind='HIDDEN', data_type='NUMBER', comment='Source: IMPR1140.IMPR_RULE_TARIFF.ITEM_SEQUENCE (PRE-INSERT MAX + 1)'),
]
PORTS_SQL = '\n'.join([
    'SELECT ROWIDTOCHAR(p.ROWID) AS row_id, p.rule_isn, p.port_cd, s.port_name, p.rec_status',
    '  FROM impr_rule_ports p, sd_ports s',
    ' WHERE p.rule_isn = :P1140_RULE_ISN',
    '   AND p.port_cd  = :P_CURR_PORT_CD          -- block WHERE (NALSALEH CENTRALIZED PROJECT)',
    '   AND s.port_cd (+) = p.port_cd'])
TARIFF_SQL = '\n'.join([
    'SELECT ROWIDTOCHAR(t.ROWID) AS row_id, t.rule_isn, t.hrmnzd_code, ht.item_arbc_desc AS ht_item_arbc_desc,',
    '       t.excepted_qty AS exeption_qty, t.remained_qty,',
    '       (SELECT IMPR1140.IMPR_RULE_TARIFF_POST_QUERY(HRMNZD_CODE => t.hrmnzd_code) FROM dual) AS intl_unit,',
    '       t.rec_status, t.item_sequence',
    '  FROM impr_rule_tariff t, harmonized_tariff ht',
    ' WHERE t.rule_isn = :P1140_RULE_ISN',
    '   AND ht.hrmnzd_code (+) = t.hrmnzd_code',
    ' ORDER BY t.item_sequence'])
SEARCH_SQL = '\n'.join([
    '-- one search text over every shown column; every row while the search text is empty (user request 2026-11-26).',
    '-- The PRE-QUERY BUS_ID_TYPE_NAME criterion is part of the text search. No ORDER BY (as IMPR1120).',
    "SELECT TRANSLATE(ROWIDTOCHAR(r.ROWID), '+/', '-_') AS row_id,   -- URL-safe: a '+' in f?p arrives as a space",
    '       r.rule_isn, r.rule_type, rt.rv_meaning AS rule_type_name,',
    "       DECODE(r.all_brnch_flag, 1, 'جميع الجمارك', 0, 'جمرك محدد') AS all_brnch_flag_name,",
    '       r.hq_impr_nbr,',
    '       CASE WHEN r.rule_type = 12',
    '            THEN (SELECT MAX(i.arbc_impr_name) FROM importers i',
    '                   WHERE i.port_cd = :P_CURR_PORT_CD AND i.hq_impr_nbr = r.hq_impr_nbr)',
    '            ELSE (SELECT MAX(s.arbc_impr_name) FROM single_importers s WHERE s.hq_impr_nbr = r.hq_impr_nbr)',
    '       END AS l_si_arbc_impr_name,',
    '       r.bus_id_type_cd, b.bus_id_type_name, r.bus_id, r.bus_id_brnch, rs.rv_meaning AS rec_status_name',
    '  FROM impr_rules r, bus_id_types b, cg_ref_codes rt, cg_ref_codes rs',
    ' WHERE b.bus_id_type_cd (+) = r.bus_id_type_cd',
    "   AND rt.rv_domain (+) = 'RULE_TYPE'  AND rt.rv_low_value (+) = TO_CHAR(r.rule_type)",
    "   AND rs.rv_domain (+) = 'REC_STATUS' AND rs.rv_low_value (+) = TO_CHAR(r.rec_status)",
    "   AND (:P114001_SEARCH IS NULL OR INSTR(UPPER(r.rule_isn || '|' || r.rule_type || '|' || rt.rv_meaning || '|' || r.hq_impr_nbr || '|' ||",
    "                   b.bus_id_type_name || '|' || r.bus_id || '|' || r.bus_id_brnch || '|' || rs.rv_meaning),",
    '             UPPER(TRIM(:P114001_SEARCH))) > 0)'])
SEARCH_COLUMNS = [
    ('ROW_ID', None, 'VARCHAR2'), ('RULE_ISN', 'مسلسل الاستثناء', 'NUMBER'), ('RULE_TYPE', 'نوع الاستثناء', 'NUMBER'),
    ('RULE_TYPE_NAME', 'وصف نوع الاستثناء', 'VARCHAR2'), ('ALL_BRNCH_FLAG_NAME', 'استخدام الاستثناء', 'VARCHAR2'),
    ('HQ_IMPR_NBR', 'رقم المستورد الموحد', 'NUMBER'), ('L_SI_ARBC_IMPR_NAME', 'اسم المستورد', 'VARCHAR2'),
    ('BUS_ID_TYPE_CD', 'نوع الرقم الاستدلالى', 'NUMBER'), ('BUS_ID_TYPE_NAME', 'مسمى نوع الرقم الاستدلالى', 'VARCHAR2'),
    ('BUS_ID', 'الرقم الاستدلالى', 'VARCHAR2'), ('BUS_ID_BRNCH', 'الفرع', 'VARCHAR2'), ('REC_STATUS_NAME', 'حـالة السجل', 'VARCHAR2')]
NEW_LOVS = [  # spec 6: (name, LOV_APX call, columns for a Popup LOV, source)
    ('LOV_RULE_TYPE', lov_apx.call('REFERENCE_CODES', P_DOMAIN='RULE_TYPE'), None,
     'pop list IMPR_RULES.RULE_TYPE (CGDV$POPULATE_DYNAMIC_LISTS, domain RULE_TYPE)'),
    ('LOV_REC_STATUS', lov_apx.call('REFERENCE_CODES', P_DOMAIN='REC_STATUS'), None,
     'pop lists REC_STATUS of IMPR_RULES, IMPR_RULE_PORTS, IMPR_RULE_TARIFF (CGDV$POPULATE_DYNAMIC_LISTS)'),
    ('LOV_SINGLE_IMPORTERS', lov_apx.call('SINGLE_IMPORTERS', P_RULE_TYPE_ITEM='P1140_RULE_TYPE'),
     [('D', 'رقم المستورد الموحد', 'NUMBER'), ('ARBC_IMPR_NAME', 'اسم المستورد', 'VARCHAR2'), ('BUS_ID', 'الرقم الاستدلالى', 'VARCHAR2')],
     'PU SINGLE_IMP_LOV (LOV forms LOV_IMPORT_HQ_NBR / LOV_IMPORT_HQ_N12)'),
    ('LOV_HARMONIZED_TARIFF', lov_apx.call('LOV_HARMONIZED_TARIFF'),
     [('D', 'رمز بند التعريفة', 'VARCHAR2'), ('ITEM_ARBC_DESC', 'الوصف', 'VARCHAR2')],
     'record group CGFK$IMPR_RULE_TARIFF_HRMNZD_C (LOV form LOV_TRF_ITEMS)')]
STATIC_LOVS = [('LOV_ALL_BRNCH_FLAG', [('جميع الجمارك', '1'), ('جمرك محدد', '0')], 'pop list IMPR_RULES.ALL_BRNCH_FLAG')]
MESSAGES = [  # spec 11: constraint texts of the ON-ERROR triggers
    ('IR_BIT_FK', 'This Bus Id Type Name does not exist', 'IMPR_RULES.ON-ERROR'),
    ('IRP_IR2_FK', 'Cannot delete استثناءات المستوردين while dependent جمارك الاستثناء exists', 'IMPR_RULES.ON-ERROR (40510)'),
    ('IRP_SDP_FK', 'This رمز الجمرك does not exist', 'IMPR_RULE_PORTS.ON-ERROR'),
    ('IRT_IR_FK', 'This رقم مسلسل الإستثناء does not exist', 'IMPR_RULE_TARIFF.ON-ERROR'),
    ('IRT_HT_FK', 'This رمز بند التعريفة does not exist', 'IMPR_RULE_TARIFF.ON-ERROR')]

PORTS_SAVE = ('IMPR1140.IMPR_RULE_PORTS_SAVE_ROW(APEX$ROW_STATUS => :APEX$ROW_STATUS, ROW_ID => :ROW_ID, '
              'RULE_ISN => NVL(:RULE_ISN, :P1140_RULE_ISN), PORT_CD => :PORT_CD, REC_STATUS => :REC_STATUS, '
              'P_ALL_BRNCH_FLAG => :P1140_ALL_BRNCH_FLAG, %s);' % APP)
TARIFF_SAVE = ('IMPR1140.IMPR_RULE_TARIFF_SAVE_ROW(APEX$ROW_STATUS => :APEX$ROW_STATUS, ROW_ID => :ROW_ID, '
               'RULE_ISN => NVL(:RULE_ISN, :P1140_RULE_ISN), HRMNZD_CODE => :HRMNZD_CODE, EXEPTION_QTY => :EXEPTION_QTY, '
               'REMAINED_QTY => :REMAINED_QTY, REC_STATUS => :REC_STATUS, ITEM_SEQUENCE => :ITEM_SEQUENCE, %s);' % APP)
MSG_INFO_QTY = ' تأكد من تطابق الوحده الدولية مع وحدة الكمية المستثناه '

# ----------------------------------------------------------------------------- generation
def gen():
    out = []
    W = out.append
    W('''-- =============================================================================
-- REVIEW BEFORE IMPORT
-- File        : apex/IMPR1140/f345_impr1140.sql
-- Generated by: Claude Code (scripts/gen_apex_impr1140.py, step 04) from
--               analysis/IMPR1140/IMPR1140_apex_page_spec.md, %s, form IMPR1140
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / 4c / 4d, docs/f345_reference_standard.md 3-9: editable Form region (ROWID),
--               two editable Interactive Grids in a Tabs Container with PL/SQL row DML, FOS + native dynamic
--               actions, one-line calls into package IMPR1140 (version 001). No JavaScript, no AJAX callback.
-- Contents    : component export INTO the application installed from f345 AND already holding the
--               IMPR1110 export (page group IMPR and LOV_SD_PORTS are reused):
--               pages 1140 (main) and 114001 (search) + 5 LOVs + 5 Text Messages.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR1140/import_notes.md
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
    # ---------------------------------------------------------------- shared components (spec 13.3)
    UNCERTAIN.add(lov_apx.UNCERTAIN)
    lov_1110 = open(IMPR1110_EXPORT, encoding='utf-8', errors='replace').read()
    m = re.search(r"create_list_of_values\(\n p_id=>wwv_flow_api\.id\((\d+)\)\n,p_lov_name=>'LOV_SD_PORTS'", lov_1110)
    _ids['9140:lov:LOV_SD_PORTS_REUSED'] = m.group(1)        # the grid column refers to the IMPR1110 LOV by id
    for name, sql, cols, s in NEW_LOVS:
        nid('9140:lov:' + name, 5)
        b = [call('create_list_of_values', [('p_id', ref('9140:lov:' + name)), ('p_lov_name', q(name))] + lov_apx.lov_attributes(sql, q),
                  'Source: IMPR1140 ' + s + ' / spec 6')]
        for i, (c, h, dt, visible) in enumerate(lov_apx.column_definitions(cols)):
            key = '9140:lovc:%s:%s' % (name, c)
            nid(key, 6)
            b.append(call('create_list_of_values_cols', [
                ('p_id', ref(key)), ('p_lov_id', ref('9140:lov:' + name)), ('p_query_column_name', q(c)),
                ('p_heading', q(h)), ('p_display_sequence', str((i + 1) * 10)), ('p_data_type', q(dt))]
                + lov_apx.column_attributes(visible)))
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), '\n'.join(b)))
    for name, vals, s in STATIC_LOVS:
        nid('9140:lov:' + name, 5)
        b = [call('create_list_of_values', [('p_id', ref('9140:lov:' + name)), ('p_lov_name', q(name)),
                                            ('p_lov_query', "'.'||%s||'.'" % ref('9140:lov:' + name)), ('p_location', q('STATIC'))],
                  'Source: IMPR1140 ' + s + ' (values from the XML) / spec 6')]
        for i, (d, r) in enumerate(vals):
            key = '9140:lovd:%s:%s' % (name, r)
            nid(key, 6)
            b.append(call('create_static_lov_data', [('p_id', ref(key)), ('p_lov_disp_sequence', str(i + 1)),
                                                     ('p_lov_disp_value', q(d)), ('p_lov_return_value', q(r))]))
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), '\n'.join(b)))
    for name, text, s in MESSAGES:
        nid('9140:msg:' + name, 3)
        W(block('application/shared_components/globalization/messages/' + name.lower(),
                call('create_message', [('p_id', ref('9140:msg:' + name)), ('p_name', q(name)),
                                        ('p_message_language', q('ar-sa')), ('p_message_text', q(text))],
                     'Source: IMPR1140.%s (constraint %s) / spec 11' % (s, name))))
    UNCERTAIN.add('wwv_flow_api.create_message (Text Message; f345 has none; IMPR1110 / IMPR1120 use it) - p_message_language ar-sa')

    # ---------------------------------------------------------------- page 1140 (spec 2-12)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG)
    A(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM)), ('p_alias', q(FORM)),
        ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('Y')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_step_template', fid('PAGE_MAIN')),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1140.fmb (window CGSO$WINDOW_1, canvases CG$PAGE_1 and CG$M_TAB_1) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR1140.fmb - spec 2 / f345 standard 4'))
    hero = ('<div class="cg-hero-row"><div class="cg-hero-top"><span class="cg-hero-ic fa fa-sliders" aria-hidden="true"></span>'
            '<div><div class="cg-hero-k">المستوردون</div><div class="cg-hero-t">&P1140_HERO_TITLE.</div>'
            '<div class="cg-hero-d">استثناءات التعامل مع المستوردين: الجمارك وبنود التعريفة</div></div></div></div>')
    nid('1140:plug:IMPR_RULES_HERO', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1140:plug:IMPR_RULES_HERO')), ('p_plug_name', q('الهيدر')), ('p_region_name', q('IMPR_RULES_HERO')),
        ('p_region_css_classes', q('cg-hero')), ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '10'), ('p_plug_source', q(hero)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src('IMPR1140.TITLE (OLB) -> f345 hero / spec 3'))]))
    nid(R_RULES, 1)
    A(call('create_page_plug', [
        ('p_id', ref(R_RULES)), ('p_plug_name', q('قواعد التعامل مع المستوردين')), ('p_region_name', q('IMPR_RULES')),
        ('p_region_css_classes', q('zatca-forms cg-form cg-card')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_FORM')), ('p_plug_display_sequence', '20'), ('p_query_type', q('TABLE')),
        ('p_query_table', q('IMPR_RULES')), ('p_include_rowid_column', 'true'), ('p_is_editable', 'true'),
        ('p_edit_operations', q('i:u:d')), ('p_plug_source_type', q('NATIVE_FORM')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1140.IMPR_RULES (single record, insert / update / delete; key mode ROWID) / spec 3'))]))
    UNCERTAIN.add('ROWID primary key of the Form region: p_include_rowid_column, item source ROWID / p_source_data_type ROWID (as IMPR1110)')
    UNCERTAIN.add('NATIVE_FORM region p_edit_operations => i:u:d (IMPR1110 uses i:u)')
    nid(R_TABS, 1)
    A(call('create_page_plug', [
        ('p_id', ref(R_TABS)), ('p_plug_name', q('تفاصيل الاستثناء')), ('p_region_name', q('CG$M_TAB_1')),
        ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_TABS')), ('p_plug_display_sequence', '30'),
        ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')), ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')),
        ('p_plug_display_condition_type', q('ITEM_IS_NOT_NULL')), ('p_plug_display_when_condition', q('P0_PAGE_PK')),
        ('p_plug_comment', src('IMPR1140 tab canvas CG$M_TAB_1 (WHEN-TAB-PAGE-CHANGED, CGLT$TAB_BLOCKS) / spec 3'))]))
    UNCERTAIN.add('Tabs Container region (template 11621923018393869712) with the two IGs as sub-regions (p_parent_plug_id); not in f345 pages')
    for seq, rk, title, sid, sql, s in [
            (40, R_PORTS, 'جمارك الإستثناء', 'IMPR_RULE_PORTS', PORTS_SQL,
             'IMPR1140.IMPR_RULE_PORTS (tab page CG$M_TAB_1_PAGE_1, relation CGFK$IRP_IR2_FK, WHERE PORT_CD = :P_CURR_PORT_CD)'),
            (50, R_TARIFF, 'بنود التعريفة المستثاه', 'IMPR_RULE_TARIFF', TARIFF_SQL,
             'IMPR1140.IMPR_RULE_TARIFF (tab page CG$M_TAB_1_PAGE_2, relation CGFK$IRT_IR_FK, Delete Allowed = false)')]:
        nid(rk, 1)
        A(call('create_page_plug', [
            ('p_id', ref(rk)), ('p_plug_name', q(title)), ('p_region_name', q(sid)), ('p_parent_plug_id', ref(R_TABS)),
            ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
            ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', str(seq)), ('p_query_type', q('SQL')),
            ('p_plug_source', lit(sql)), ('p_plug_source_type', q('NATIVE_IG')), ('p_ajax_items_to_submit', q('P1140_RULE_ISN')),
            ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')), ('p_plug_comment', src(s + ' / spec 3'))]))
        # IG columns right after their own region (APEX attaches a region column to the region created last; f345 AGR1100)
        for c in ig_row_columns(rk):
            A(c)
        cols = PORTS_COLUMNS if rk == R_PORTS else TARIFF_COLUMNS
        for i, c in enumerate(cols):
            A(ig_column(rk, c, (i + 3) * 10))
        hidden = ['ROW_ID', 'RULE_ISN', 'ITEM_SEQUENCE']
        for c in ig(rk, '1140%s0201' % ('4' if rk == R_PORTS else '5'), 'i:u:d' if rk == R_PORTS else 'i:u',
                    ['APEX$ROW_ACTION', 'APEX$ROW_SELECTOR'] + [c['name'] for c in cols], hidden,
                    'لا توجد جمارك للاستثناء' if rk == R_PORTS else 'لا توجد بنود تعريفة مستثناة', rows=8):
            A(c)
    # branches (spec 12)
    nid('1140:branch:STAY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1140:branch:STAY')), ('p_branch_name', q('IMPR1140 - stay in the form')),
        ('p_branch_action', q('f?p=&APP_ID.:1140:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '20'),
        ('p_branch_comment', src('Forms stays in the form after COMMIT / spec 12'))]))
    # items (spec 4.1, 4.2)
    for i, it in enumerate(MASTER_ITEMS, 1):
        A(page_item(PG, R_RULES, i * 10, it, form_region=True))
    for seq, it in [(10, dict(name='P1140_HERO_TITLE', kind='NATIVE_HIDDEN', value_protected='Y',
                              comment='Source: IMPR1140.TITLE (OLB) - shown by the hero region (&P1140_HERO_TITLE.)')),
                    (20, dict(name='P1140_MODULE_ID', kind='NATIVE_HIDDEN', value_protected='Y', protect='S',
                              comment='Source: IMPR1140 :PARAMETER.P_MODULE_ID (f345, kept by SCREEN ENTRY RESET)'))]:
        A(page_item(PG, '1140:plug:IMPR_RULES_HERO', seq, it))
    UNCERTAIN.add('p_item_default with a static value on Select List items (RULE_TYPE 1, ALL_BRNCH_FLAG 0, REC_STATUS 1; IMPR1110 uses p_item_default)')
    # validations (spec 7)
    save = ('CREATE,SAVE', 'REQUEST_IN_CONDITION')
    A(validation(PG, 10, 'RULE_TYPE VALIDATION', 'return IMPR1140.RULE_TYPE_VALIDATION(P_RULE_TYPE => :P1140_RULE_TYPE);', save,
                 assoc_item='P1140_RULE_TYPE', s='IMPR1140.IMPR_RULES.RULE_TYPE.WHEN-VALIDATE-ITEM / spec 7'))
    A(validation(PG, 20, 'HQ_IMPR_NBR VALIDATION',
                 'return IMPR1140.HQ_IMPR_NBR_VALIDATION(P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, P_RULE_TYPE => :P1140_RULE_TYPE, '
                 'P_CURR_PORT_CD => :P_CURR_PORT_CD);', save,
                 assoc_item='P1140_HQ_IMPR_NBR', s='IMPR1140.IMPR_RULES.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM / spec 7'))
    A(validation(PG, 30, 'BUS_ID_TYPE_CD REQUIRED',
                 "return FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :P1140_BUS_ID_TYPE_CD, ITEM_LABEL => 'نوع الرقم الاستدلالى');", save,
                 assoc_item='P1140_BUS_ID_TYPE_CD', s='IMPR1140.IMPR_RULES.BUS_ID_TYPE_CD (Required = true) / spec 7'))
    new_row = (":APEX$ROW_STATUS = 'C'", 'EXPRESSION')
    A(validation(PG, 110, 'IMPR_RULE_PORTS PORT_CD VALIDATION', 'return IMPR1140.PORT_CD_VALIDATION(PORT_CD => :PORT_CD);', new_row,
                 ig_region=R_PORTS, assoc_column='PORT_CD', s='IMPR1140.IMPR_RULE_PORTS.PORT_CD.WHEN-VALIDATE-ITEM / spec 7'))
    A(validation(PG, 210, 'IMPR_RULE_TARIFF HRMNZD_CODE VALIDATION',
                 'return IMPR1140.HRMNZD_CODE_VALIDATION(HRMNZD_CODE => :HRMNZD_CODE, P_RULE_ISN => :P1140_RULE_ISN, '
                 'P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, P_BUS_ID_TYPE_CD => :P1140_BUS_ID_TYPE_CD, P_BUS_ID => :P1140_BUS_ID);', new_row,
                 ig_region=R_TARIFF, assoc_column='HRMNZD_CODE', s='IMPR1140.IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM / spec 7'))
    # processes (spec 8)
    NEW = 'NULL;  -- f345 session setup (SSO_APP_USER, P_CURR_PORT_CD, V_USR_TYPE ...) is done by the application; disabled as in AGR1100'
    BH, AS = 'BEFORE_HEADER', 'AFTER_SUBMIT'
    form_dml = [('p_attribute_01', q('REGION_SOURCE')), ('p_attribute_05', q('Y')), ('p_attribute_06', q('Y')),
                ('p_attribute_08', q('Y')), ('p_process_success_message', q('تم الحفظ بنجاح'))]
    ig_dml = lambda code: [('p_attribute_01', q('PLSQL_CODE')), ('p_attribute_04', lit(code)), ('p_attribute_05', q('Y')),
                           ('p_attribute_06', q('N')), ('p_attribute_08', q('Y')), ('p_process_success_message', q('تم الحفظ بنجاح'))]
    ins = (':P0_PAGE_PK IS NULL AND :REQUEST = \'CREATE\'', 'EXPRESSION', 'PLSQL')
    upd = (':P0_PAGE_PK IS NOT NULL AND :REQUEST = \'SAVE\'', 'EXPRESSION', 'PLSQL')
    dele = ('DELETE', 'REQUEST_EQUALS_CONDITION')
    procs = [
        (BH, 10, 'New', NEW, ('', 'NEVER'), 'f345 session setup copied from AGR1100 (condition Never) / standard 6', {}),
        (BH, 20, 'P0_PAGE_PK CHECK', 'IMPR1140.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK);', None, 'f345 / spec 8', {}),
        (BH, 40, 'PARAMETERS', ":P1140_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1140_MODULE_ID, FORM_NAME => 'IMPR1140');",
         None, 'f345 / spec 8', {}),
        (BH, 70, 'P0_PAGE_PK', ':P1140_ROW_ID := :P0_PAGE_PK;', None, 'f345 (key = ROWID) / spec 8', {}),
        (BH, 80, 'Initialize form', None, None, 'IMPR1140 block IMPR_RULES fetch / spec 8', dict(ptype='NATIVE_FORM_INIT', region=R_RULES)),
        (BH, 82, 'POST-QUERY',
         'IMPR1140.POST_QUERY(P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, P_RULE_TYPE => :P1140_RULE_TYPE, '
         'P_BUS_ID_TYPE_CD => :P1140_BUS_ID_TYPE_CD, P_CURR_PORT_CD => :P_CURR_PORT_CD, '
         'P_L_SI_ARBC_IMPR_NAME => :P1140_L_SI_ARBC_IMPR_NAME, P_BUS_ID_TYPE_NAME => :P1140_BUS_ID_TYPE_NAME);',
         ('P1140_ROW_ID', 'ITEM_IS_NOT_NULL'), 'IMPR1140.IMPR_RULES.POST-QUERY / spec 8', {}),
        (BH, 100, 'HEADER TITLE', "FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1140_MODULE_ID, P_HERO_TITLE => :P1140_HERO_TITLE, "
         "DEFAULT_TITLE => 'قواعد التعامل مع المستوردين');", None, 'f345 (OLB block TITLE) / spec 8', {}),
        (AS, 5, 'ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM',
         'IMPR1140.ADJ_BRANCH(P_ALL_BRNCH_FLAG => :P1140_ALL_BRNCH_FLAG, P_BUS_ID_BRNCH => :P1140_BUS_ID_BRNCH);',
         save, 'IMPR1140.IMPR_RULES.ALL_BRNCH_FLAG.WHEN-VALIDATE-ITEM -> PU ADJ_BRANCH / spec 8', {}),
        (AS, 10, 'PRE-INSERT', 'IMPR1140.PRE_INSERT(P_RULE_ISN => :P1140_RULE_ISN, P_RULE_TYPE => :P1140_RULE_TYPE, %s);' % APP,
         ins, 'IMPR1140.IMPR_RULES.PRE-INSERT / spec 8', {}),
        (AS, 20, 'PRE-UPDATE', 'IMPR1140.PRE_UPDATE(P_RULE_TYPE => :P1140_RULE_TYPE, P_CURR_PORT_CD => :P_CURR_PORT_CD, '
         'SSO_APP_USER => :SSO_APP_USER);', upd, 'IMPR1140.IMPR_RULES.PRE-UPDATE / spec 8', {}),
        (AS, 25, 'KEY-DELREC', 'IMPR1140.KEY_DELREC(P_RULE_ISN => :P1140_RULE_ISN, P_CURR_PORT_CD => :P_CURR_PORT_CD);', dele,
         'IMPR1140.IMPR_RULES.KEY-DELREC (port-row check 1-270, CGRI, tariff rows) / spec 8', {}),
        (AS, 30, 'PRE-DELETE', 'IMPR1140.PRE_DELETE(P_RULE_ISN => :P1140_RULE_ISN, %s);' % APP, dele,
         'IMPR1140.IMPR_RULES.PRE-DELETE / spec 8', {}),
        (AS, 40, 'Process form', None, save, 'IMPR1140 block IMPR_RULES DML / spec 8',
         dict(ptype='NATIVE_FORM_DML', region=R_RULES, extra=form_dml)),
        (AS, 41, 'Process form - DELETE', None, dele, 'IMPR1140 block IMPR_RULES DML (delete) / spec 8',
         dict(ptype='NATIVE_FORM_DML', region=R_RULES, extra=form_dml)),
        (AS, 50, 'POST-INSERT', 'IMPR1140.POST_INSERT(P_RULE_ISN => :P1140_RULE_ISN, P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, '
         'P_RULE_TYPE => :P1140_RULE_TYPE, P_REC_STATUS => :P1140_REC_STATUS, P_CURR_PORT_CD => :P_CURR_PORT_CD);',
         ('CREATE', 'REQUEST_EQUALS_CONDITION'), 'IMPR1140.IMPR_RULES.POST-INSERT (SMS) / spec 8', {}),
        (AS, 60, 'POST-UPDATE', 'IMPR1140.POST_UPDATE(P_RULE_ISN => :P1140_RULE_ISN, P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, '
         'P_RULE_TYPE => :P1140_RULE_TYPE, P_REC_STATUS => :P1140_REC_STATUS, %s);' % APP,
         upd, 'IMPR1140.IMPR_RULES.POST-UPDATE (activity log, SMS) / spec 8', {}),
        (AS, 80, 'P0_PAGE_PK AFTER INSERT', ':P0_PAGE_PK := :P1140_ROW_ID;', ('CREATE', 'REQUEST_EQUALS_CONDITION'), 'f345 / spec 8', {}),
        (AS, 85, 'P0_PAGE_PK AFTER DELETE', ':P0_PAGE_PK := NULL;', dele, 'f345 / spec 8', {}),
        (AS, 110, 'IMPR_RULE_PORTS - Save Interactive Grid Data', None, ('SAVE', 'REQUEST_EQUALS_CONDITION'),
         'IMPR1140.IMPR_RULE_PORTS PRE-INSERT, PRE-UPDATE, PRE-DELETE + row DML (IMPR_RULE_PORTS_SAVE_ROW) / spec 8',
         dict(ptype='NATIVE_IG_DML', region=R_PORTS, extra=ig_dml(PORTS_SAVE))),
        (AS, 210, 'IMPR_RULE_TARIFF - Save Interactive Grid Data', None, ('SAVE', 'REQUEST_EQUALS_CONDITION'),
         'IMPR1140.IMPR_RULE_TARIFF PRE-INSERT, PRE-UPDATE + row DML (IMPR_RULE_TARIFF_SAVE_ROW) / spec 8',
         dict(ptype='NATIVE_IG_DML', region=R_TARIFF, extra=ig_dml(TARIFF_SAVE))),
    ]
    UNCERTAIN.add('NATIVE_IG_DML Target Type PL/SQL Code: p_attribute_01 => PLSQL_CODE, code in p_attribute_04 '
                  '(f345 shows only TABLE / p_attribute_03; IMPR1120 uses it); the code returns ROW_ID / ITEM_SEQUENCE of a new row')
    UNCERTAIN.add('Process form - DELETE: a second NATIVE_FORM_DML process on request DELETE (f345 standard 6)')
    for point, seq, name, code, cond, s, kw in procs:
        key = '1140:proc:%s:%s' % (point, name)
        A(process(PG, key, seq, point, name, code, cond, s, ptype=kw.get('ptype', 'NATIVE_PLSQL'),
                  extra=kw.get('extra'), region=kw.get('region')))
    # dynamic actions (spec 10) - the number_only handler is the page 0 DA NUMBER ONLY
    A(da(PG, 10, 'RULE_TYPE WHEN-LIST-CHANGED', ('ITEM', 'P1140_RULE_TYPE'), 'change', [
        fos('FORMS_APX.CHECK_ERROR(IMPR1140.RULE_TYPE_VALIDATION(P_RULE_TYPE => :P1140_RULE_TYPE));', ['P1140_RULE_TYPE'])],
        'IMPR1140.IMPR_RULES.RULE_TYPE.WHEN-LIST-CHANGED / spec 10'))
    A(da(PG, 20, 'ALL_BRNCH_FLAG WHEN-VALIDATE-ITEM', ('ITEM', 'P1140_ALL_BRNCH_FLAG'), 'change', [
        item_action('NATIVE_CLEAR', 'P1140_BUS_ID_BRNCH'), item_action('NATIVE_DISABLE', 'P1140_BUS_ID_BRNCH'),
        ('FALSE', item_action('NATIVE_ENABLE', 'P1140_BUS_ID_BRNCH'))],
        'IMPR1140.IMPR_RULES.ALL_BRNCH_FLAG.WHEN-VALIDATE-ITEM + WHEN-NEW-RECORD-INSTANCE (PU ADJ_BRANCH) / spec 10',
        cond=('EQUALS', '1'), init=True))
    UNCERTAIN.add('NATIVE_CLEAR / NATIVE_ENABLE / NATIVE_DISABLE with p_affected_elements_type ITEM (IMPR1120 uses NATIVE_CLEAR)')
    hq = ['P1140_BUS_ID', 'P1140_BUS_ID_BRNCH', 'P1140_BUS_ID_TYPE_CD', 'P1140_L_SI_ARBC_IMPR_NAME', 'P1140_BUS_ID_TYPE_NAME']
    A(da(PG, 30, 'HQ_IMPR_NBR WHEN-VALIDATE-ITEM', ('ITEM', 'P1140_HQ_IMPR_NBR'), 'change', [
        fos('IMPR1140.HQ_IMPR_NBR_VALIDATE_ITEM(P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, P_RULE_TYPE => :P1140_RULE_TYPE, '
            'P_CURR_PORT_CD => :P_CURR_PORT_CD, P_BUS_ID => :P1140_BUS_ID, P_BUS_ID_BRNCH => :P1140_BUS_ID_BRNCH, '
            'P_BUS_ID_TYPE_CD => :P1140_BUS_ID_TYPE_CD, P_L_SI_ARBC_IMPR_NAME => :P1140_L_SI_ARBC_IMPR_NAME, '
            'P_BUS_ID_TYPE_NAME => :P1140_BUS_ID_TYPE_NAME);', ['P1140_HQ_IMPR_NBR', 'P1140_RULE_TYPE'], hq)],
        'IMPR1140.IMPR_RULES.HQ_IMPR_NBR.WHEN-VALIDATE-ITEM / spec 10', cond='NOT_NULL'))
    A(da(PG, 110, 'IMPR_RULE_PORTS PORT_CD WHEN-VALIDATE-ITEM', ('COLUMN', R_PORTS, 'PORT_CD'), 'change', [
        fos('IMPR1140.PORT_CD_WHEN_VALIDATE_ITEM(PORT_CD => :PORT_CD, PORT_NAME => :PORT_NAME);', ['PORT_CD'], ['PORT_NAME'])],
        'IMPR1140.IMPR_RULE_PORTS.PORT_CD.WHEN-VALIDATE-ITEM / spec 10'))
    A(da(PG, 210, 'IMPR_RULE_TARIFF HRMNZD_CODE WHEN-VALIDATE-ITEM', ('COLUMN', R_TARIFF, 'HRMNZD_CODE'), 'change', [
        fos('IMPR1140.HRMNZD_CODE_VALIDATE_ITEM(HRMNZD_CODE => :HRMNZD_CODE, P_RULE_ISN => :P1140_RULE_ISN, '
            'P_HQ_IMPR_NBR => :P1140_HQ_IMPR_NBR, P_BUS_ID_TYPE_CD => :P1140_BUS_ID_TYPE_CD, P_BUS_ID => :P1140_BUS_ID, '
            'HT_ITEM_ARBC_DESC => :HT_ITEM_ARBC_DESC, INTL_UNIT => :INTL_UNIT);',
            ['HRMNZD_CODE', 'P1140_RULE_ISN', 'P1140_HQ_IMPR_NBR', 'P1140_BUS_ID_TYPE_CD', 'P1140_BUS_ID'],
            ['HT_ITEM_ARBC_DESC', 'INTL_UNIT'])],
        'IMPR1140.IMPR_RULE_TARIFF.HRMNZD_CODE.WHEN-VALIDATE-ITEM + POST-CHANGE / spec 10'))
    A(da(PG, 220, 'IMPR_RULE_TARIFF EXEPTION_QTY WHEN-VALIDATE-ITEM', ('COLUMN', R_TARIFF, 'EXEPTION_QTY'), 'change', [
        fos('IMPR1140.EXEPTION_QTY_VALIDATE_ITEM(EXEPTION_QTY => :EXEPTION_QTY, REMAINED_QTY => :REMAINED_QTY);',
            ['EXEPTION_QTY'], ['REMAINED_QTY']),
        [('p_action', q('NATIVE_ALERT')), ('p_attribute_01', q(MSG_INFO_QTY))]],
        'IMPR1140.IMPR_RULE_TARIFF.EXEPTION_QTY.WHEN-VALIDATE-ITEM (INFORMATION alert) / spec 10'))
    UNCERTAIN.add('NATIVE_ALERT with the text in p_attribute_01 (page 1140 EXEPTION_QTY; not in f345)')
    UNCERTAIN.add('FOS Items to Return = IG columns (PORT_NAME, HT_ITEM_ARBC_DESC, INTL_UNIT, REMAINED_QTY; IMPR1120 returns SUSPN_RSN_TEXT)')
    W(block('application/pages/page_01140', '\n'.join(P)))

    # ---------------------------------------------------------------- page 114001 (search, spec 3 / 4.4)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_SEARCH)
    A(call('create_page', [
        ('p_id', str(PG_SEARCH)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM + '_SEARCH')), ('p_alias', q(FORM + '-SEARCH')),
        ('p_page_mode', q('MODAL')), ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_height', q('800')),
        ('p_dialog_width', q('1800')), ('p_protection_level', q('C')), ('p_first_item', q('AUTO_FIRST_ITEM')),
        ('p_page_comment', src('IMPR1140 Enter-Query / Execute-Query of block IMPR_RULES / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: f345 search page <page>01 (page 0 SEARCH)'))
    nid('114001:plug:CRIT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('114001:plug:CRIT')), ('p_plug_name', q('بحث')), ('p_region_name', q('IMPR_RULES_SEARCH_CRITERIA')),
        ('p_region_css_classes', q('zatca-forms cg-form')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_HERO')), ('p_plug_display_sequence', '10'), ('p_attribute_01', q('N')),
        ('p_attribute_02', q('TEXT')), ('p_attribute_03', q('Y')),
        ('p_plug_comment', src('IMPR1140.IMPR_RULES query criteria as one search text over all columns / spec 3'))]))
    nid('114001:plug:IG', 1)
    A(call('create_page_plug', [
        ('p_id', ref('114001:plug:IG')), ('p_plug_name', q('قواعد التعامل مع المستوردين')), ('p_region_name', q('IMPR_RULES_SEARCH')),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', '20'), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(SEARCH_SQL)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q('P114001_SEARCH')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1140.IMPR_RULES block query + PRE-QUERY (ORDER BY dropped); every row until a search narrows it (user request 2026-11-26) / spec 3'))]))
    for i, (c, h, dt) in enumerate(SEARCH_COLUMNS):
        if c == 'ROW_ID':
            col = dict(name=c, kind='HIDDEN', data_type=dt, pk=True)
        elif c == 'RULE_ISN':
            col = dict(name=c, kind='LINK', data_type=dt, heading=h,
                       link_target='f?p=&APP_ID.:1140:&SESSION.::&DEBUG.:1140:P0_PAGE_PK:&ROW_ID.', link_text='&RULE_ISN.')
        else:
            col = dict(name=c, kind='DISPLAY', data_type=dt, heading=h)
        A(ig_column('114001:plug:IG', col, (i + 1) * 10))
    for c in ig('114001:plug:IG', '114001000201', None, [c for c, _, _ in SEARCH_COLUMNS], ['ROW_ID'],
                'لا توجد نتائج', search=True):
        A(c)
    UNCERTAIN.add('search IG: p_lazy_loading true, p_show_total_row_count false, toolbar ACTIONS_MENU:RESET (as IMPR1120)')
    A(page_item(PG_SEARCH, '114001:plug:CRIT', 10, dict(
        name='P114001_SEARCH', kind='NATIVE_TEXT_FIELD', label='بحث في كل الأعمدة', maxlen=200, span=6,
        comment='Source: IMPR1140.IMPR_RULES query criteria (RULE_ISN, RULE_TYPE, HQ_IMPR_NBR, BUS_ID_TYPE_NAME ...) as one text')))
    for key, seq, name, label, icon, css, s in [
            ('114001:btn:SEARCH', 40, 'SEARCH', 'بحث', 'fa-search', 'cg-b-search', 'TOOLBAR.EXECUTE (Execute Query of block IMPR_RULES)'),
            ('114001:btn:CLEAR', 50, 'CLEAR', 'مسح البحث', 'fa-eraser', 'cg-b-clear', 'TOOLBAR.CLEAR_ALL for the search')]:
        nid(key, 2)
        A(call('create_page_button', [
            ('p_id', ref(key)), ('p_button_sequence', str(seq)), ('p_button_plug_id', ref('114001:plug:CRIT')),
            ('p_button_name', q(name)), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
            ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q(label)), ('p_button_position', q('BODY')),
            ('p_icon_css_classes', q(icon)), ('p_button_css_classes', q(css)), ('p_button_comment', src('IMPR1140 ' + s + ' / spec 5'))]))
    refresh = [('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('114001:plug:IG'))]
    A(da(PG_SEARCH, 10, 'SEARCH WHEN-BUTTON-PRESSED', ('BUTTON', '114001:btn:SEARCH'), 'click', [refresh],
         'IMPR1140 TOOLBAR.EXECUTE / spec 10'))
    A(da(PG_SEARCH, 12, 'SEARCH KEY-ENTER', ('ITEM', 'P114001_SEARCH'), 'keyup', [refresh],
         'IMPR1140 KEY-EXEQRY (Enter in the search text) / spec 10', cond='ENTER'))
    A(da(PG_SEARCH, 15, 'CLEAR WHEN-BUTTON-PRESSED', ('BUTTON', '114001:btn:CLEAR'), 'click',
         [item_action('NATIVE_CLEAR', 'P114001_SEARCH'), refresh], 'IMPR1140 TOOLBAR.CLEAR_ALL (search criteria) / spec 10'))
    UNCERTAIN.add('button DA: p_triggering_button_id (page 114001 SEARCH; IMPR1110 uses it)')
    ek, ak = '114001:da:Hide', '114001:daa:Hide:10'
    nid(ek, 8); nid(ak, 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('Hide')), ('p_event_sequence', '20'),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('ready')),
                                    ('p_da_event_comment', src('f345 AGR1100_SEARCH "Hide" (page 0 toolbar not used in a dialog)'))]))
    A(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('Y')), ('p_action', q('NATIVE_HIDE')),
                                     ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', fid('P0_ACTIONS'))]))
    W(block('application/pages/page_114001', '\n'.join(P)))

    W('''prompt --application/end_environment
begin
wwv_flow_api.component_end;
end;
/
set verify on feedback on define on
prompt  ...done
''')
    text = search_page.fix(client_condition.fix(items_to_submit.fix('\n'.join(out))))   # Items to Submit = every page item read (user rule 2026-11-25)
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
    problems = items_to_submit.check(text) + client_condition.check(text) + search_page.check(text) + item_icons.check(text) + lov_apx.check(text) + functions_drawer.check_form_page(text)
    ref_txt = open(REF, encoding='utf-8', errors='replace').read()
    i1110 = open(IMPR1110_EXPORT, encoding='utf-8', errors='replace').read()
    others = '\n'.join(open(p, encoding='utf-8', errors='replace').read() for p in OTHER_EXPORTS)
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
    ids_other = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', others))
    if set(defined) & ref_ids: problems.append('ids clash with f345')
    if set(defined) & ids_other: problems.append('ids clash with another export: %s' % sorted(set(defined) & ids_other)[:5])
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
    for n in re.findall(r"create_message\(\n p_id=>[^\n]*\n,p_name=>'([^']+)'", text):
        if re.search(r"create_message\(\n p_id=>[^\n]*\n,p_name=>'%s'" % re.escape(n), others): problems.append('message %s exists in another export' % n)
    other_lovs = set(re.findall(r"p_lov_name=>'([^']+)'", others)) - lov_1110
    for n in re.findall(r"p_lov_name=>'([^']+)'", text):
        if n in other_lovs: problems.append('LOV %s already created by another export' % n)
    if names_of(text, 'create_flow_item'): problems.append('application item created (none expected)')
    # package members and parameter names
    sigs = {}
    for m in re.finditer(r'(?:PROCEDURE|FUNCTION)\s+([A-Z0-9_$]+)\s*(\((.*?)\))?\s*(?:RETURN\s+\w+\s*)?;', pkg_txt, re.S):
        sigs[m.group(1).upper()] = set(re.findall(r'\b([A-Z][A-Z0-9_$]*)\s+(?:IN|OUT)\b', m.group(3) or ''))
    plain = '\n'.join(unq(v) for v in re.findall(r"(?:unistr\('(?:[^']|'')*'\)|'(?:[^']|'')*')", code))
    for m in set(re.findall(r'IMPR1140\.([A-Z_0-9$]+)', plain)):
        if m not in sigs: problems.append('IMPR1140.%s not in impr1140_spec.sql' % m)
    for m in re.finditer(r'IMPR1140\.([A-Z0-9_$]+)\(([^()]*)\)', plain):
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
        problems.append('package: common helper %s defined in IMPR1140 (belongs to FORMS_APX)' % name)
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
    path = os.path.join(ROOT, 'apex', 'IMPR1140', 'f%s_impr1140_import.sql' % vals['app_id'])
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
