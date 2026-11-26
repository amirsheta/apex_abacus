# -*- coding: utf-8 -*-
"""
gen_apex_impr2210.py - APEX 21.2 component export of IMPR2210 (report parameter form) (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c / 4d, docs/f345_reference_standard.md) and the approved report-screen
standard 13-b (Forms_to_APEX APPROVED_STANDARD.md: P<page>_REPORT, page 0 REPORT_PRINT custom event,
PRINT_CHECK_VAL returns the ardpdf link of the report package IMPR2210_ARD; standard 13-c).

Design : analysis/IMPR2210/IMPR2210_apex_page_spec.md; the design data is written in this script (sections marked
         "spec N"), so a spec change means a change here and a re-run.
Helpers: copied from scripts/gen_apex_impr2130.py (same screen: port, importer list LICE_NO, CTR_BLK; the count of
         PRINT_CHECK_VAL runs on AGNTS with the report joins), with its own importer LOV LOV_IMPR2210_REP_IMPR because the
         LOV call names the port item P2210_P_PORT_CD - precedent LOV_IMPR1130_CITIES). The screen calls the list
         "رقم الشركة الوسيطة" (brokerage company = AGNTS.IMPR_NBR_AGENT_ID), so the labels say so.
Checks : apex/Reference/f345.sql, every other component export apex/*/f345_*.sql, plsql/IMPR2210/impr2210_spec.sql,
         plsql_templates/lov_apx.sql, plsql_templates/forms_apx.sql.
Writes : apex/IMPR2210/f345_impr2210.sql   component export, REVIEW BEFORE IMPORT (4 placeholders)
         apex/IMPR2210/f<app>_impr2210_import.sql  with --workspace-id --app-id --id-offset --schema

Usage (from forms_to_apex_toolkit):
    python3 -I scripts/gen_apex_impr2210.py [--workspace-id=.. --app-id=.. --id-offset=.. --schema=..]
"""
import glob, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
import number_only      # Number Field items: CSS class number_only + one page-load handler on page 0
import functions_drawer # the FUNCS region is on page 0, never on a form page
import item_icons      # Post Text icon next to every entry item, from the item name (f202604 convention)
import items_to_submit # every page item a query / LOV / FOS call reads is in its Items to Submit (user rule 2026-11-25)
import client_condition  # an item in an item-type client-side condition has a default value (user rule 2026-11-26)
import lov_apx         # shared LOVs: function body returning SQL, code in LOV_APX (CLAUDE.md 4d)
REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')
IMPR1110_EXPORT = os.path.join(ROOT, 'apex', 'IMPR1110', 'f345_impr1110.sql')
PKG = os.path.join(ROOT, 'plsql', 'IMPR2210', 'impr2210_spec.sql')
OUT = os.path.join(ROOT, 'apex', 'IMPR2210', 'f345_impr2210.sql')
OTHER_EXPORTS = [p for p in glob.glob(os.path.join(ROOT, 'apex', '*', 'f345_*.sql'))
                 if os.path.basename(os.path.dirname(p)) not in ('IMPR2210', 'Reference')]
DATE, STAMP = '2026-11-26', '20261126000000'
FORM = 'IMPR2210'
PG = 2210                          # report page: no search page <page>01
SHARED_BASE = 9221                 # IMPR1110 9000, ... IMPR1210 / IMPR2110 9210, IMPR2120 9212 ... IMPR2180 9218, IMPR2210 9221

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
    """deterministic id <page or 9210><kind 2><seq 6>"""
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
    if it.get('static'):
        # Forms list item: static values from the XML (ListItemElement labels / values), as IMPR1210 P_TYPE
        p += [('p_lov', q(it['static'])), ('p_lov_display_null', q('NO'))]
        UNCERTAIN.add('NATIVE_SELECT_LIST with an inline STATIC2 LOV (p_lov), no null entry (IMPR1210 uses STATIC2 on a radio group)')
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
    if it.get('cond'):          # server-side condition (PL/SQL expression), as IMPR1110 WASL_CITY
        p += [('p_display_when', q(it['cond'])), ('p_display_when2', q('PLSQL')), ('p_display_when_type', q('EXPRESSION'))]
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
    """trigger: ('ITEM', item) | ('COLUMN', region_key, column) | ('BUTTON', button_key) | ('CUSTOM', event) | ('READY',)
       actions: list of parameter lists (TRUE) or ('FALSE', parameter list); cond: None | 'NOT_NULL' | 'ENTER' | ('EQUALS', value)"""
    ek = '%s:da:%s' % (page, name)
    nid(ek, 8)
    p = [('p_id', ref(ek)), ('p_name', q(name)), ('p_event_sequence', str(seq))]
    if trigger[0] == 'ITEM':
        p += [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q(trigger[1]))]
    elif trigger[0] == 'COLUMN':
        p += [('p_triggering_element_type', q('COLUMN')), ('p_triggering_region_id', ref(trigger[1])),
              ('p_triggering_element', q(trigger[2]))]
    elif trigger[0] == 'CUSTOM':     # page 0 button event on document (f202604 page 2100 REPORT_SHOW)
        p += [('p_triggering_element_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_element', q('document'))]
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
                      '(not in f345)')
    p += [('p_bind_type', q('bind')), ('p_bind_event_type', q(event)),
          ('p_bind_event_type_custom', q(trigger[1]) if trigger[0] == 'CUSTOM' else None), ('p_da_event_comment', src(s))]
    out = [call('create_page_da_event', p)]
    for i, a in enumerate(actions, 1):
        result, prm = ('FALSE', a[1]) if isinstance(a, tuple) else ('TRUE', a)
        ak = '%s:daa:%s:%d' % (page, name, i * 10)
        nid(ak, 9)
        out.append(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q(result)),
                                                  ('p_action_sequence', str(i * 10)),
                                                  ('p_execute_on_page_init', q('Y' if trigger[0] == 'READY' or init else 'N'))] + prm))
    return '\n'.join(out)


# ----------------------------------------------------------------------------- design (spec 2-10)
R_HERO, R_PARAMS, R_CTR = '2210:plug:TITLE', '2210:plug:CALLING_PARAMETERS', '2210:plug:CTR_BLK'
PORT_VISIBLE = 'IMPR2210.P_PORT_CD_IS_VISIBLE(P_CURR_PORT_CD => :P_CURR_PORT_CD)'

PARAM_ITEMS = [
    dict(name='P2210_P_PORT_CD', kind='NATIVE_POPUP_LOV', label='رمز الجمرك', lov='LOV_SD_PORTS', span=3, cond=PORT_VISIBLE,
         comment='Source: IMPR2210.CALLING_PARAMETERS.P_PORT_CD (KEY-LISTVAL / P_LOV_PORT -> REP_LOV_SD_PORTS; '
                 'hidden when P_CURR_PORT_CD != 99, WHEN-NEW-FORM-INSTANCE)'),
    dict(name='P2210_P_PORT_NAME', kind='NATIVE_DISPLAY_ONLY', newline=False, span=9, cond=PORT_VISIBLE,
         comment='Source: IMPR2210.CALLING_PARAMETERS.P_PORT_NAME (set by P_PORT_CD WHEN-VALIDATE-ITEM)'),
    # one Popup LOV for the importers (user request 2026-11-25): each pick is added to the table CTR_BLK;
    # LICE_NO only holds the picked numbers (comma list, empty = every importer of the port), not typed any more
    dict(name='P2210_SECT_LOV', kind='NATIVE_POPUP_LOV', label='رقم الشركة الوسيطة', lov='LOV_IMPR2210_REP_IMPR', submit='P2210_P_PORT_CD',
         span=6,
         comment='Source: IMPR2210.CALLING_PARAMETERS.LICE_NO (KEY-LISTVAL) / SECT_LOV (button) -> LOV form REP_LOV_IMPR; '
                 'the picked importer is added to the table CTR_BLK (LICE_NO)'),
    dict(name='P2210_LICE_NO', kind='NATIVE_HIDDEN', value_protected='N',
         comment='Source: IMPR2210.CALLING_PARAMETERS.LICE_NO (importer numbers separated by commas, filled by the '
                 'Popup LOV P2210_SECT_LOV; empty = every importer of the port); submitted by CTR_BLK, SECT_LOV and REPORT_PRINT'),
]
HERO_ITEMS = [
    dict(name='P2210_HERO_TITLE', kind='NATIVE_HIDDEN', value_protected='Y',
         comment='Source: IMPR2210.TITLE.SCREEN_NAME (:PARAMETER.P_MODULE_NAME) - hero, sent to the report as P_MODULE_NAME'),
    dict(name='P2210_MODULE_ID', kind='NATIVE_HIDDEN', value_protected='Y', protect='S',
         comment='Source: IMPR2210 :PARAMETER.P_MODULE_ID (f345, kept by SCREEN ENTRY RESET)'),
    dict(name='P2210_REPORT_NO', kind='NATIVE_HIDDEN', value_protected='Y',
         comment='Source: IMPR2210.TITLE.REPORT_NO (P_SYS_ID - P_REP_NO, WHEN-NEW-FORM-INSTANCE) - hero, report parameter P_REPORT_NO'),
    dict(name='P2210_P_CURR_PORT_NAME', kind='NATIVE_HIDDEN', value_protected='Y',
         comment='Source: IMPR2210.TITLE.P_CURR_PORT_NAME (port name of the user, WHEN-NEW-FORM-INSTANCE) - hero'),
    dict(name='P2210_REPORT', kind='NATIVE_HIDDEN', value_protected='Y',
         comment='Source: f345 report flag - page 0 shows only REPORT_PRINT, CLEAR, BACK when this item exists (no value; '
                 'scripts/report_toolbar.py, DEC-018)'),
    dict(name='P2210_REPORT_URL', kind='NATIVE_HIDDEN', value_protected='N',
         comment='Source: IMPR2210 REP.Run_Product (PRINT_CHECK_VAL) - ardpdf link of IMPR2210_ARD returned by FOS, '
                 'opened in a new tab'),
]
CTR_SQL = '\n'.join([
    '-- CTR_BLK.WHEN-NEW-BLOCK-INSTANCE: one row per importer number of LICE_NO, with the name of the importer of the port',
    '-- (CALLING_PARAMETERS.LICE_NO.WHEN-VALIDATE-ITEM: port NVL(P_PORT_CD, PARAMETER.P_CURR_PORT_CD), message if not found)',
    'SELECT l.seq, l.p_agr_nbr,',
    "       NVL(i.arbc_impr_name, 'هذا المستورد غير موجود') AS p_agr_desc",
    '  FROM (SELECT LEVEL AS seq,',
    "               TO_NUMBER(REGEXP_SUBSTR(REGEXP_REPLACE(:P2210_LICE_NO, '\\s', ''), '[^,]+', 1, LEVEL)) AS p_agr_nbr",
    '          FROM dual',
    "         WHERE REGEXP_LIKE(RTRIM(REGEXP_REPLACE(:P2210_LICE_NO, '\\s', ''), ','), '^[0-9]+(,[0-9]+)*$')",
    "       CONNECT BY REGEXP_SUBSTR(REGEXP_REPLACE(:P2210_LICE_NO, '\\s', ''), '[^,]+', 1, LEVEL) IS NOT NULL) l,",
    '       importers i',
    ' WHERE i.impr_nbr (+) = l.p_agr_nbr',
    '   AND i.port_cd (+) = NVL(:P2210_P_PORT_CD, :P_CURR_PORT_CD)',
    ' ORDER BY l.seq'])
CTR_COLUMNS = [
    dict(name='SEQ', kind='HIDDEN', data_type='NUMBER', pk=True, comment='Source: IMPR2210.CTR_BLK record number (grid key)'),
    dict(name='P_AGR_NBR', kind='DISPLAY', data_type='NUMBER', heading='رقم الشركة الوسيطة',
         comment='Source: IMPR2210.CTR_BLK.P_AGR_NBR (Visible = false in Forms, shown here so the name has its number)'),
    dict(name='P_AGR_DESC', kind='DISPLAY', data_type='VARCHAR2', heading='اسم الشركة الوسيطة',
         comment='Source: IMPR2210.CTR_BLK.P_AGR_DESC (:GLOBAL.CHPT_ARB split by commas)'),
]
NEW_LOVS = [
    ('LOV_IMPR2210_REP_IMPR', lov_apx.call('IMPORTERS', P_PORT_ITEM='P2210_P_PORT_CD', P_DEFAULT_PORT_ITEM='P_CURR_PORT_CD'),
     [('D', 'رقم المستورد', 'NUMBER'), ('ARBC_IMPR_NAME', 'اسم المستورد', 'VARCHAR2'), ('BUS_ID', 'الرقم الاستدلالى', 'VARCHAR2')],
     'LOV form REP_LOV_IMPR (CALL_FORM in SECT_LOV / LICE_NO.KEY-LISTVAL; IMPR2210 passes no port, so the LOV form '
     'used its default P_CURR_PORT_CD 30 - SUGGESTION: here the port NVL(P_PORT_CD, P_CURR_PORT_CD) as LICE_NO and the report)')]
REPORT_ARGS = ('P_LICE_NO => :P2210_LICE_NO, P_PORT_CD => :P2210_P_PORT_CD, P_REPORT_NO => :P2210_REPORT_NO, '
               'P_HERO_TITLE => :P2210_HERO_TITLE, P_MODULE_ID => :P2210_MODULE_ID, P_CURR_PORT_CD => :P_CURR_PORT_CD, '
               'P_REPORT_URL => :P2210_REPORT_URL')
REPORT_SUBMIT = ['P2210_LICE_NO', 'P2210_P_PORT_CD', 'P2210_REPORT_NO', 'P2210_HERO_TITLE', 'P2210_MODULE_ID', 'P2210_REPORT_URL']
OPEN_URL = "var u = $v('P2210_REPORT_URL'); if (u) { window.open(u, '_blank'); }"

# ----------------------------------------------------------------------------- generation
def gen():
    out = []
    W = out.append
    W('''-- =============================================================================
-- REVIEW BEFORE IMPORT
-- File        : apex/IMPR2210/f345_impr2210.sql
-- Generated by: Claude Code (scripts/gen_apex_impr2210.py) from
--               analysis/IMPR2210/IMPR2210_apex_page_spec.md, %s, form IMPR2210
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / 4c / 4d, docs/f345_reference_standard.md; report screen as the approved standard
--               13-b / 13-c (P2210_REPORT, page 0 REPORT_PRINT custom event, PRINT_CHECK_VAL returns the ardpdf link of
--               the report package IMPR2210_ARD). One-line calls into package IMPR2210 (version 001).
-- Contents    : component export INTO the application installed from f345 AND already holding the
--               IMPR1110 export (page group IMPR and LOV_SD_PORTS are reused):
--               page 2210 (report parameters) + 1 LOV. No search page, no DML.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR2210/import_notes.md
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
    # ---------------------------------------------------------------- shared components (spec 6)
    UNCERTAIN.add(lov_apx.UNCERTAIN)
    for name, sql, cols, s in NEW_LOVS:
        nid('9221:lov:' + name, 5)
        b = [call('create_list_of_values', [('p_id', ref('9221:lov:' + name)), ('p_lov_name', q(name))] + lov_apx.lov_attributes(sql, q),
                  'Source: IMPR2210 ' + s + ' / spec 6')]
        for i, (c, h, dt, visible) in enumerate(lov_apx.column_definitions(cols)):
            key = '9221:lovc:%s:%s' % (name, c)
            nid(key, 6)
            b.append(call('create_list_of_values_cols', [
                ('p_id', ref(key)), ('p_lov_id', ref('9221:lov:' + name)), ('p_query_column_name', q(c)),
                ('p_heading', q(h)), ('p_display_sequence', str((i + 1) * 10)), ('p_data_type', q(dt))]
                + lov_apx.column_attributes(visible)))
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), '\n'.join(b)))

    # ---------------------------------------------------------------- page 2210 (spec 2-10)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG)
    A(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM)), ('p_alias', q(FORM)),
        ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_step_template', fid('PAGE_MAIN')),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR2210.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) - report parameter form of IMPR2210.rdf / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR2210.fmb - spec 2 / f345 standard 4, standard 13-b'))
    hero = ('<div class="cg-hero-row"><div class="cg-hero-top"><span class="cg-hero-ic fa fa-print" aria-hidden="true"></span>'
            '<div><div class="cg-hero-k">تقارير المستوردين</div><div class="cg-hero-t">&P2210_HERO_TITLE.</div>'
            '<div class="cg-hero-d">&P2210_P_CURR_PORT_NAME.</div></div></div>'
            '<div class="cg-kpis"><div class="cg-kpi"><b>&P2210_REPORT_NO.</b><span>رقم التقرير</span></div></div></div>')
    nid(R_HERO, 1)
    A(call('create_page_plug', [
        ('p_id', ref(R_HERO)), ('p_plug_name', q('الهيدر')), ('p_region_name', q('TITLE')),
        ('p_region_css_classes', q('cg-hero')), ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '10'), ('p_plug_source', q(hero)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')),
        ('p_plug_comment', src('IMPR2210.TITLE (SCREEN_NAME, REPORT_NO, P_CURR_PORT_NAME; OLB) -> f345 hero / spec 3'))]))
    nid(R_PARAMS, 1)
    A(call('create_page_plug', [
        ('p_id', ref(R_PARAMS)), ('p_plug_name', q('معاملات التقرير')), ('p_region_name', q('CALLING_PARAMETERS')),
        ('p_region_css_classes', q('zatca-forms cg-form cg-card')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_FORM')), ('p_plug_display_sequence', '20'), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')),
        ('p_plug_comment', src('IMPR2210.CALLING_PARAMETERS (control block, report parameters) / spec 3'))]))
    UNCERTAIN.add('static content region (control block) with the Form-region template Interactive Report and classes '
                  'zatca-forms cg-form cg-card (f345 uses the template for NATIVE_FORM regions)')
    nid(R_CTR, 1)
    A(call('create_page_plug', [
        ('p_id', ref(R_CTR)), ('p_plug_name', q('الشركات الوسيطة المختارة')), ('p_region_name', q('CTR_BLK')),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', '30'), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(CTR_SQL)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q('P2210_LICE_NO,P2210_P_PORT_CD')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR2210.CTR_BLK (control block, 5 records, read only: the numbers of LICE_NO and their names) / spec 3'))]))
    for i, c in enumerate(CTR_COLUMNS):
        A(ig_column(R_CTR, c, (i + 1) * 10))
    for c in ig(R_CTR, '221003000201', None, [c['name'] for c in CTR_COLUMNS], ['SEQ'],
                'لم يتم اختيار شركات وسيطة - التقرير لكل الشركات الوسيطة بالجمرك', rows=5, search=True):
        A(c)
    UNCERTAIN.add('read-only IG for a non-database multi-record block (CTR_BLK), toolbar ACTIONS_MENU:RESET (as the search grids)')
    # items (spec 4)
    for i, it in enumerate(PARAM_ITEMS, 1):
        A(page_item(PG, R_PARAMS, i * 10, it))
    for i, it in enumerate(HERO_ITEMS, 1):
        A(page_item(PG, R_HERO, i * 10, it))
    UNCERTAIN.add('page item display condition p_display_when / p_display_when2 PLSQL / p_display_when_type EXPRESSION '
                  '(P2210_P_PORT_CD, P2210_P_PORT_NAME; IMPR1110 uses it)')
    # processes (spec 8) - Before Header only: the page never submits (VIEW / PRINT are DAs, CLEAR / BACK are page 0)
    NEW = 'NULL;  -- f345 session setup (SSO_APP_USER, P_CURR_PORT_CD, V_USR_TYPE ...) is done by the application; disabled as in AGR1100'
    BH = 'BEFORE_HEADER'
    procs = [
        (10, 'New', NEW, ('', 'NEVER'), 'f345 session setup copied from AGR1100 (condition Never) / standard 6'),
        (20, 'P0_PAGE_PK CHECK', ':P0_PAGE_PK := NULL;  -- a report page holds no record (page 0 hides SAVE / DELETE)',
         None, 'f345 P0_PAGE_PK CHECK - report page / spec 8'),
        (40, 'PARAMETERS', ":P2210_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P2210_MODULE_ID, FORM_NAME => 'IMPR2210');",
         None, 'f345 / spec 8'),
        (60, 'WHEN-NEW-FORM-INSTANCE', 'IMPR2210.WHEN_NEW_FORM_INSTANCE(P_REPORT_NO => :P2210_REPORT_NO, '
         'P_CURR_PORT_NAME => :P2210_P_CURR_PORT_NAME, P_MODULE_ID => :P2210_MODULE_ID, P_CURR_PORT_CD => :P_CURR_PORT_CD);',
         None, 'IMPR2210.WHEN-NEW-FORM-INSTANCE / spec 8'),
        (100, 'HEADER TITLE', "FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P2210_MODULE_ID, P_HERO_TITLE => :P2210_HERO_TITLE, "
         "DEFAULT_TITLE => 'تفويضات الشركات الوسيطة');", None, 'f345 (OLB block TITLE, SCREEN_NAME = P_MODULE_NAME) / spec 8'),
    ]
    for seq, name, code, cond, s in procs:
        A(process(PG, '2210:proc:%s:%s' % (BH, name), seq, BH, name, code, cond, s))
    # dynamic actions (spec 10)
    refresh = [('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref(R_CTR))]
    A(da(PG, 10, 'P_PORT_CD WHEN-VALIDATE-ITEM', ('ITEM', 'P2210_P_PORT_CD'), 'change', [
        fos('IMPR2210.P_PORT_CD_WHEN_VALIDATE_ITEM(P_PORT_CD => :P2210_P_PORT_CD, P_PORT_NAME => :P2210_P_PORT_NAME);',
            ['P2210_P_PORT_CD', 'P2210_P_PORT_NAME'], ['P2210_P_PORT_NAME']), refresh],
        'IMPR2210.CALLING_PARAMETERS.P_PORT_CD.WHEN-VALIDATE-ITEM / spec 10'))
    # LICE_NO is not typed any more (hidden, filled by SECT_LOV): its list check runs in PRINT_CHECK_VAL
    A(da(PG, 30, 'SECT_LOV WHEN-BUTTON-PRESSED', ('ITEM', 'P2210_SECT_LOV'), 'change', [
        fos('IMPR2210.SECT_LOV_WHEN_BUTTON_PRESSED(P_SECT_LOV => :P2210_SECT_LOV, P_LICE_NO => :P2210_LICE_NO);',
            ['P2210_SECT_LOV', 'P2210_LICE_NO'], ['P2210_SECT_LOV', 'P2210_LICE_NO']), refresh],
        'IMPR2210.CALLING_PARAMETERS.SECT_LOV.WHEN-BUTTON-PRESSED, LICE_NO.KEY-LISTVAL (REP_LOV_IMPR) / spec 10'))   # no client-side condition (user 2026-11-25): an empty pick is ignored in SECT_LOV_WHEN_BUTTON_PRESSED
    # report page buttons: PRINT, CLEAR, BACK only (DEC-017 / DEC-018): page 0 REPORT_SHOW is Never, so no REPORT_SHOW DA;
    # Forms VIEW / KEY-F5 (PU CHECK_VAL, same code) open the same ARD PDF as PRINT
    for seq, event, member, s in [
            (60, 'REPORT_PRINT', 'PRINT_CHECK_VAL', 'IMPR2210.TOOLBAR.PRINT / VIEW.WHEN-BUTTON-PRESSED, KEY-PRINT, KEY-F4, KEY-F5 '
                                                    '-> PU PRINT_CHECK_VAL / CHECK_VAL, report IMPR2210_ARD')]:
        A(da(PG, seq, event, ('CUSTOM', event), 'custom', [
            item_action('NATIVE_CLEAR', 'P2210_REPORT_URL'),
            fos('IMPR2210.%s(%s);' % (member, REPORT_ARGS), REPORT_SUBMIT, ['P2210_REPORT_URL']),
            [('p_action', q('NATIVE_JAVASCRIPT_CODE')), ('p_attribute_01', q(OPEN_URL))]],
            s + ' (page 0 button %s triggers the custom event; standard 13-b) / spec 10' % event))
    UNCERTAIN.add('DA on a custom event of document: p_triggering_element_type JAVASCRIPT_EXPRESSION, p_triggering_element document, '
                  'p_bind_event_type custom + p_bind_event_type_custom (as the real 21.2 export f202604, page 2100 REPORT_SHOW)')
    UNCERTAIN.add('NATIVE_CLEAR with p_affected_elements_type ITEM (IMPR1120 uses it)')
    W(block('application/pages/page_02210', '\n'.join(P)))

    W('''prompt --application/end_environment
begin
wwv_flow_api.component_end;
end;
/
set verify on feedback on define on
prompt  ...done
''')
    text = client_condition.fix(items_to_submit.fix('\n'.join(out)))   # Items to Submit = every page item read (user rule 2026-11-25)
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
    problems = items_to_submit.check(text) + client_condition.check(text) + item_icons.check(text) + lov_apx.check(text) + functions_drawer.check_form_page(text)
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
    for m in set(re.findall(r'IMPR2210\.([A-Z_0-9$]+)', plain)):
        if m not in sigs: problems.append('IMPR2210.%s not in impr2210_spec.sql' % m)
    for m in re.finditer(r'IMPR2210\.([A-Z0-9_$]+)\(([^()]*)\)', plain):
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
    # Execute JavaScript Code: at most 3 lines (CLAUDE.md §4c); the only ones open the report URL (standard 13-b)
    for j in re.findall(r"p_action=>'NATIVE_JAVASCRIPT_CODE'\n,p_attribute_01=>(.*?)\n(?=[,)])", text, re.S):
        if j.count("',\n") + 1 > 3: problems.append('JavaScript action > 3 lines')
        if j != q(OPEN_URL): problems.append('unexpected JavaScript action: ' + j[:60])
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
        problems.append('package: common helper %s defined in IMPR2210 (belongs to FORMS_APX)' % name)
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
    path = os.path.join(ROOT, 'apex', 'IMPR2210', 'f%s_impr2210_import.sql' % vals['app_id'])
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

