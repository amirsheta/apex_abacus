# -*- coding: utf-8 -*-
"""
gen_apex_impr1120.py - step 04: APEX 21.2 component export of IMPR1120 (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c, docs/f345_reference_standard.md).

Design : analysis/IMPR1120/IMPR1120_apex_page_spec.md (step 03); the design data is written in this
         script (sections marked "spec N"), so a spec change means a change here and a re-run.
Checks : apex/Reference/f345.sql (template ids, existing ids / items / LOVs),
         apex/IMPR1110/f345_impr1110.sql (shared components reused from IMPR1110, id clashes),
         plsql/IMPR1120/impr1120_spec.sql (members and parameter names of every call).
Writes : apex/IMPR1120/f345_impr1120.sql   component export, REVIEW BEFORE IMPORT (4 placeholders)
         apex/IMPR1120/f<app>_impr1120_import.sql  with --workspace-id --app-id --id-offset --schema

Parameter patterns: the helpers come from scripts/gen_apex_impr1110.py (export imported into 202530 on
2026-11-18); the editable Interactive Grid parameters (row action / selector columns, read-only per row,
column DAs, IG validations, IG DML) are copied from the AGR1100 page 11100 of f345 (git abc7d61).
Parameters that appear in neither are collected in UNCERTAIN and listed in import_notes.md.

Usage (from forms_to_apex_toolkit):
    python3 -I scripts/gen_apex_impr1120.py [--workspace-id=.. --app-id=.. --id-offset=.. --schema=..]
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')
IMPR1110_EXPORT = os.path.join(ROOT, 'apex', 'IMPR1110', 'f345_impr1110.sql')
PKG = os.path.join(ROOT, 'plsql', 'IMPR1120', 'impr1120_spec.sql')
OUT = os.path.join(ROOT, 'apex', 'IMPR1120', 'f345_impr1120.sql')
DATE, STAMP = '2026-11-23', '20261123000000'
FORM = 'IMPR1120'
PG, PG_SEARCH = 1120, 112001
SHARED_BASE = 9120                 # IMPR1110 uses 9000 for its shared components

# ----------------------------------------------------------------------------- f345 ids (standard 3)
F345 = dict(
    UI='11622010846008869795', PAGE_MAIN='11622270914969205733', REGION_HERO='11621859120066869682',
    REGION_FORM='11621909206693869707', REGION_GRID='11621913486616869708', REGION_DIALOG='11621894586660869699',
    LABEL_REQ='11621984380233869750', LABEL_OPT='11621983529556869749',
    BUTTON='11621986167597869752', LIST_FUNS_TPL='63163863023905992916', LIST_PAGE_FUNS='73054485650159247603',
    P0_ACTIONS='73488102084440079322')
# shared components created by the IMPR1110 export (already in application 202530) - reused, not re-created
IMPR1110_IDS = dict(PAGE_GROUP_IMPR='900001000010')
REUSED_LOVS = ['LOV_SD_PORTS', 'LOV_ALLOWED_EXPORT']
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
    if k in ('NATIVE_TEXT_FIELD', 'NATIVE_NUMBER_FIELD', 'NATIVE_POPUP_LOV'):
        p.append(('p_cSize', '30'))
    if it.get('maxlen') and k not in ('NATIVE_DISPLAY_ONLY', 'NATIVE_HIDDEN'):
        p.append(('p_cMaxlength', str(it['maxlen'])))
    if it.get('tag_css'):
        p.append(('p_tag_css_classes', q(it['tag_css'])))
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
    elif k == 'NATIVE_POPUP_LOV':
        p += [('p_attribute_01', q('DIALOG')), ('p_attribute_02', q('FIRST_ROWSET')), ('p_attribute_03', q('N'))]
    elif k == 'NATIVE_DISPLAY_ONLY':
        # p_attribute_01 = Send On Page Submit; p_attribute_02 = Based On (VALUE / LOV)
        p += [('p_attribute_01', q('Y' if it.get('send') else 'N')), ('p_attribute_02', q('LOV' if it.get('lov') else 'VALUE')),
              ('p_attribute_04', q('N')), ('p_attribute_05', q('PLAIN'))]
        if it.get('lov'):
            UNCERTAIN.add('Display Only based on LOV: p_attribute_02 => LOV with p_named_lov (P1120_IMPR_EXPR_TYPE)')
    elif k == 'NATIVE_HIDDEN':
        p += [('p_attribute_01', q(it.get('value_protected', 'Y')))]
    p.append(('p_item_comment', q(it.get('comment'))))
    return call('create_page_item', p)

# ----------------------------------------------------------------------------- region columns (IG)
FILTER = [('p_enable_filter', 'true'), ('p_filter_operators', q('C:S:CASE_INSENSITIVE:REGEXP')), ('p_filter_is_required', 'false'),
          ('p_filter_text_case', q('MIXED')), ('p_filter_lov_type', q('NONE')), ('p_use_as_row_header', 'false'),
          ('p_enable_sort_group', 'true'), ('p_enable_control_break', 'true'), ('p_enable_hide', 'true')]

def ig_column(page, c, seq):
    """c: name, kind (HIDDEN / TEXT / SELECT / DISPLAY / LINK), data_type, heading, pk, req, maxlen, css, lov_key,
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
        item_type = dict(TEXT='NATIVE_TEXT_FIELD', SELECT='NATIVE_SELECT_LIST', DISPLAY='NATIVE_DISPLAY_ONLY', LINK='NATIVE_LINK')[k]
        p += [('p_item_type', q(item_type)), ('p_heading', q(c['heading'])), ('p_heading_alignment', q('CENTER')),
              ('p_display_sequence', str(seq)), ('p_value_alignment', q('CENTER'))]
        if k == 'TEXT':
            p += [('p_attribute_01', q('N')), ('p_attribute_02', q('N')), ('p_attribute_04', q('TEXT')), ('p_attribute_05', q('BOTH'))]
            if c.get('css'):
                p.append(('p_item_css_classes', q(c['css'])))
        elif k == 'DISPLAY':
            p += [('p_attribute_02', q('VALUE')), ('p_attribute_05', q('PLAIN'))]
        elif k == 'LINK':
            p += [('p_link_target', q(c['link_target'])), ('p_link_text', q(c['link_text'])), ('p_link_attributes', q('target="_top"'))]
        if k in ('TEXT', 'SELECT'):
            p.append(('p_is_required', 'true' if c.get('req') else 'false'))
        if c.get('maxlen'):
            p.append(('p_max_length', str(c['maxlen'])))
        if k == 'SELECT':
            p += [('p_lov_type', q('SHARED')), ('p_lov_id', ref(c['lov_key'])), ('p_lov_display_extra', 'false'),
                  ('p_lov_display_null', 'false')]
            UNCERTAIN.add('IG select list column on a shared LOV: p_lov_type => SHARED + p_lov_id (f345 shows only SQL_QUERY / p_lov_source)')
        p += FILTER + [('p_is_primary_key', 'false')]
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

def ig(page, plug_key, editable, cols, empty_msg):
    gk, rk, vk = '%s:ig' % page, '%s:igr' % page, '%s:igv' % page
    nid(gk, 3); nid(rk, 3); nid(vk, 3)
    prm = [('p_id', ref(gk)), ('p_internal_uid', str(page) + '000201'), ('p_is_editable', 'true' if editable else 'false')]
    if editable:
        prm += [('p_edit_operations', q('i:u:d')), ('p_lost_update_check_type', q('VALUES')), ('p_add_row_if_empty', 'false'),
                ('p_submit_checked_rows', 'false')]
    search = page == PG_SEARCH   # search page: one search text of its own, opened fast (user request 2026-11-23)
    prm += [('p_lazy_loading', 'true' if search else 'false'), ('p_requires_filter', 'false'), ('p_select_first_row', 'true'),
            ('p_fixed_row_height', 'true'), ('p_pagination_type', q('SET')),
            ('p_show_total_row_count', 'false' if search else 'true'), ('p_no_data_found_message', q(empty_msg)),
            ('p_show_toolbar', 'true'),
            ('p_toolbar_buttons', q('ACTIONS_MENU:RESET' if search else 'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET')),
            ('p_enable_save_public_report', 'false'), ('p_enable_subscriptions', 'true'), ('p_enable_flashback', 'true'),
            ('p_define_chart_view', 'true'), ('p_enable_download', 'true'), ('p_download_formats', q('CSV:HTML:XLSX:PDF')),
            ('p_enable_mail_download', 'true'), ('p_fixed_header', q('PAGE')), ('p_show_icon_view', 'false'), ('p_show_detail_view', 'false')]
    out = [call('create_interactive_grid', prm)]
    out.append(call('create_ig_report', [('p_id', ref(rk)), ('p_interactive_grid_id', ref(gk)), ('p_static_id', q(str(page) + '000202')),
                                         ('p_type', q('PRIMARY')), ('p_default_view', q('GRID')), ('p_rows_per_page', '5') if page == PG else ('p_rows_per_page', None),
                                         ('p_show_row_number', 'false'), ('p_settings_area_expanded', 'true')]))
    if page == PG:
        UNCERTAIN.add('create_ig_report p_rows_per_page => 5 (Forms Records Displayed = 5; not in f345)')
    out.append(call('create_ig_report_view', [('p_id', ref(vk)), ('p_report_id', ref(rk)), ('p_view_type', q('GRID')),
                                              ('p_stretch_columns', 'true'), ('p_srv_exclude_null_values', 'false'),
                                              ('p_srv_only_display_columns', 'true'), ('p_edit_mode', 'false')]))
    for i, name in enumerate(cols):
        key = '%s:igc:%s' % (page, name)
        nid(key, 3)
        hidden = name in ('ROW_ID', 'PORT_CD', 'IMPR_NBR', 'SUSPN_SEQ') and page == PG or name == 'ROW_ID'
        out.append(call('create_ig_report_column', [('p_id', ref(key)), ('p_view_id', ref(vk)), ('p_display_seq', str(i)),
                                                    ('p_column_id', ref('%s:col:%s' % (page, name))),
                                                    ('p_is_visible', 'false' if hidden else 'true'), ('p_is_frozen', 'false')]))
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
                                                  ('p_action_sequence', str(i * 10)), ('p_execute_on_page_init', q('N'))] + a))
    return '\n'.join(out)

# ----------------------------------------------------------------------------- design (spec 0-13)
R_ROW = ('IMPR1120.IMPR_SUSPN_IS_READ_ONLY(SUSPN_SIDE_CD => :SUSPN_SIDE_CD, '
         'P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, P_CURR_PORT_CD => :P_CURR_PORT_CD)')
SITE = 'P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, P_CURR_PORT_CD => :P_CURR_PORT_CD'
KEYS = 'PORT_CD => :PORT_CD, IMPR_NBR => :IMPR_NBR, SUSPN_SEQ => :SUSPN_SEQ'

# page 1120, region IMPORTERS (spec 4.1) - Forms tab order
MASTER_ITEMS = [
    dict(name='P1120_ROW_ID', kind='NATIVE_HIDDEN', column='ROWID', data_type='ROWID', pk=True,
         comment='Source: IMPR1120.IMPORTERS key mode ROWID (Form region primary key, = P0_PAGE_PK)'),
    dict(name='P1120_PORT_CD', kind='NATIVE_POPUP_LOV', label='رمز الجمرك', column='PORT_CD', data_type='NUMBER', lov='LOV_SD_PORTS',
         maxlen=4, span=2, read_only=('IMPR1120.PORT_CD_IS_READ_ONLY(P_CURR_PORT_CD => :P_CURR_PORT_CD) OR :P0_PAGE_PK IS NOT NULL',
                                      'EXPRESSION', 'PLSQL'),
         comment='Source: IMPR1120.IMPORTERS.PORT_CD (WHEN-NEW-FORM-INSTANCE: editable for port 99; KEY-LISTVAL LOV_SD_PORTS)'),
    dict(name='P1120_PORT_NAME', kind='NATIVE_DISPLAY_ONLY', newline=False, span=4, send=True,
         comment='Source: IMPR1120.IMPORTERS.PORT_NAME (POST-QUERY / WHEN-CREATE-RECORD); sent: POST-INSERT notification'),
    dict(name='P1120_HQ_IMPR_NBR', kind='NATIVE_DISPLAY_ONLY', label='الرقم الموحد بالمصلحة', column='HQ_IMPR_NBR', data_type='NUMBER',
         newline=False, span=3, send=True, comment='Source: IMPR1120.IMPORTERS.HQ_IMPR_NBR; sent: POST-INSERT mobile lookup'),
    dict(name='P1120_IMPR_NBR', kind='NATIVE_NUMBER_FIELD', label='الرقم الجمركى', column='IMPR_NBR', data_type='NUMBER', maxlen=11,
         span=3, read_only=('P0_PAGE_PK', 'ITEM_IS_NOT_NULL'),
         comment='Source: IMPR1120.IMPORTERS.IMPR_NBR (WHEN-VALIDATE-ITEM -> query); editable while no importer is open'),
    dict(name='P1120_IMPR_TYPE_CD', kind='NATIVE_DISPLAY_ONLY', label='رمز النشاط التجارى', column='IMPR_TYPE_CD', data_type='NUMBER', span=2,
         comment='Source: IMPR1120.IMPORTERS.IMPR_TYPE_CD'),
    dict(name='P1120_IMPR_TYPE_NAME', kind='NATIVE_DISPLAY_ONLY', newline=False, span=4, comment='Source: IMPR1120.IMPORTERS.IMPR_TYPE_NAME (POST-QUERY)'),
    dict(name='P1120_CTRY_CD', kind='NATIVE_DISPLAY_ONLY', label='الجنسيه', column='CTRY_CD', data_type='NUMBER', newline=False, span=2,
         comment='Source: IMPR1120.IMPORTERS.CTRY_CD'),
    dict(name='P1120_CRTY_ARBC_NAME', kind='NATIVE_DISPLAY_ONLY', newline=False, span=4, comment='Source: IMPR1120.IMPORTERS.CRTY_ARBC_NAME (POST-QUERY)'),
    dict(name='P1120_CITY_CODE_OF_ID', kind='NATIVE_DISPLAY_ONLY', label='مصدر الرقم الإستدلالي', column='CITY_CODE_OF_ID', data_type='NUMBER',
         span=2, comment='Source: IMPR1120.IMPORTERS.CITY_CODE_OF_ID'),
    dict(name='P1120_ID_CITY_NAME', kind='NATIVE_DISPLAY_ONLY', newline=False, span=4, comment='Source: IMPR1120.IMPORTERS.ID_CITY_NAME (POST-QUERY)'),
    dict(name='P1120_IMPR_EXPR_TYPE', kind='NATIVE_DISPLAY_ONLY', label='النشاط الجمركي', column='IMPR_EXPR_TYPE', data_type='NUMBER',
         lov='LOV_ALLOWED_EXPORT', newline=False, span=6, comment='Source: IMPR1120.IMPORTERS.IMPR_EXPR_TYPE (list from CG_REF_CODES ALLOWED EXPORT)'),
    dict(name='P1120_BUS_ID', kind='NATIVE_DISPLAY_ONLY', label='الرقم الاستدلالى', column='BUS_ID', data_type='VARCHAR2', span=3, send=True,
         comment='Source: IMPR1120.IMPORTERS.BUS_ID; sent: POST-INSERT notification'),
    dict(name='P1120_BUS_ID_TYPE_CD', kind='NATIVE_DISPLAY_ONLY', label='نوعه', column='BUS_ID_TYPE_CD', data_type='NUMBER', newline=False, span=1,
         comment='Source: IMPR1120.IMPORTERS.BUS_ID_TYPE_CD'),
    dict(name='P1120_BUS_ID_TYPE_NAME', kind='NATIVE_DISPLAY_ONLY', newline=False, span=4, comment='Source: IMPR1120.IMPORTERS.BUS_ID_TYPE_NAME (POST-QUERY)'),
    dict(name='P1120_BUS_ID_BRNCH', kind='NATIVE_DISPLAY_ONLY', label='الفرع', column='BUS_ID_BRNCH', data_type='VARCHAR2', newline=False, span=2,
         comment='Source: IMPR1120.IMPORTERS.BUS_ID_BRNCH'),
    dict(name='P1120_ARBC_IMPR_NAME', kind='NATIVE_DISPLAY_ONLY', label='الاسم العربى', column='ARBC_IMPR_NAME', data_type='VARCHAR2', span=6,
         comment='Source: IMPR1120.IMPORTERS.ARBC_IMPR_NAME'),
    dict(name='P1120_ENG_IMPR_NAME', kind='NATIVE_DISPLAY_ONLY', label='الاسم الأجنبي', column='ENG_IMPR_NAME', data_type='VARCHAR2',
         newline=False, span=6, comment='Source: IMPR1120.IMPORTERS.ENG_IMPR_NAME'),
    dict(name='P1120_IMPR_CNTCT_NAME', kind='NATIVE_DISPLAY_ONLY', label='الوكيل المفوض', column='IMPR_CNTCT_NAME', data_type='VARCHAR2', span=6,
         comment='Source: IMPR1120.IMPORTERS.IMPR_CNTCT_NAME'),
    dict(name='P1120_CTRY_CD_OF_ID', kind='NATIVE_HIDDEN', column='CTRY_CD_OF_ID', data_type='NUMBER',
         comment='Source: IMPR1120.IMPORTERS.CTRY_CD_OF_ID (input of the POST-QUERY city lookup)'),
]

# page 1120 IG IMPR_SUSPN (spec 4.3)
SUSPN_COLUMNS = [
    dict(name='PORT_CD', kind='HIDDEN', data_type='NUMBER', pk=True, comment='Source: IMPR1120.IMPR_SUSPN.PORT_CD (CopyValueFrom IMPORTERS.PORT_CD)'),
    dict(name='IMPR_NBR', kind='HIDDEN', data_type='NUMBER', pk=True, comment='Source: IMPR1120.IMPR_SUSPN.IMPR_NBR (CopyValueFrom IMPORTERS.IMPR_NBR)'),
    dict(name='SUSPN_SEQ', kind='HIDDEN', data_type='NUMBER', pk=True, comment='Source: IMPR1120.IMPR_SUSPN.SUSPN_SEQ (PRE-INSERT MAX + 1)'),
    dict(name='SUSPN_STRT_DT', kind='TEXT', data_type='VARCHAR2', heading='بداية الإيقاف', req=True, maxlen=10, css='hijri-date-default',
         default_plsql='IMPR1120.SUSPN_STRT_DT_DEFAULT', read_only=R_ROW,
         comment='Source: IMPR1120.IMPR_SUSPN.SUSPN_STRT_DT (Hijri, MI-MM-RRRR text; WHEN-NEW-ITEM-INSTANCE default)'),
    dict(name='SUSPN_END_DT', kind='TEXT', data_type='VARCHAR2', heading='نهاية الإيقاف', req=True, maxlen=10, css='hijri-date-default',
         read_only=R_ROW, comment='Source: IMPR1120.IMPR_SUSPN.SUSPN_END_DT (Hijri, MI-MM-RRRR text)'),
    dict(name='SUSPN_RSN_CD', kind='SELECT', data_type='NUMBER', heading='السبب', lov_key='9120:lov:LOV_IMPR_SUSPN_RSN_CD',
         default_plsql='IMPR1120.SUSPN_RSN_CD_DEFAULT(%s)' % SITE, read_only=R_ROW,
         comment='Source: IMPR1120.IMPR_SUSPN.SUSPN_RSN_CD (list CG_REF_CODES IMPR_SUSPN_RSN_CD; WHEN-NEW-ITEM-INSTANCE default)'),
    dict(name='SUSPN_RSN_TEXT', kind='TEXT', data_type='VARCHAR2', heading='ملاحظات', req=True, maxlen=100,
         default_plsql='IMPR1120.SUSPN_RSN_TEXT_DEFAULT(%s)' % SITE, read_only=R_ROW,
         comment='Source: IMPR1120.IMPR_SUSPN.SUSPN_RSN_TEXT (Required = Yes)'),
    dict(name='SUSPN_SIDE_CD', kind='SELECT', data_type='NUMBER', heading='الجهة', lov_key='9120:lov:LOV_SUSPN_SIDE_CD',
         default_plsql='IMPR1120.SUSPN_SIDE_CD_DEFAULT(%s)' % SITE,
         read_only=R_ROW + ' OR IMPR1120.SUSPN_SIDE_CD_IS_READ_ONLY(%s)' % KEYS,
         comment='Source: IMPR1120.IMPR_SUSPN.SUSPN_SIDE_CD (pop list CG_REF_CODES SUSPN SIDE CD; read only once stored)'),
]
SUSPN_SQL = '\n'.join([
    'SELECT s.port_cd,',
    '       s.impr_nbr,',
    '       s.suspn_seq,',
    "       TO_CHAR(s.suspn_strt_dt, 'MI-MM-RRRR') AS suspn_strt_dt,",
    "       TO_CHAR(s.suspn_end_dt,  'MI-MM-RRRR') AS suspn_end_dt,",
    '       s.suspn_rsn_cd,',
    '       s.suspn_rsn_text,',
    '       s.suspn_side_cd',
    '  FROM impr_suspns s',
    ' WHERE s.port_cd  = :P1120_PORT_CD',
    '   AND s.impr_nbr = :P1120_IMPR_NBR',
    '   AND s.suspn_rlse_dt IS NULL',
    ' ORDER BY s.suspn_seq'])
SEARCH_SQL = '\n'.join([
    '-- one search text over every shown column (user request 2026-11-23); no rows until a search is made, as Forms',
    '-- opens the block in Enter-Query mode: the dialog opens without reading IMPORTERS. No sort clause (user request',
    '-- 2026-11-23: the whole result is not sorted; the grid columns can still be sorted)',
    "SELECT TRANSLATE(ROWIDTOCHAR(i.ROWID), '+/', '-_') AS row_id,   -- URL-safe: a '+' in f?p arrives as a space",
    '       i.port_cd, p.port_name, i.impr_nbr, i.hq_impr_nbr,',
    '       i.arbc_impr_name, i.eng_impr_name, i.impr_cntct_name,',
    '       i.impr_type_cd, it.impr_type_name, i.bus_id_type_cd, i.bus_id, i.bus_id_brnch,',
    '       i.ctry_cd, c.crty_arbc_name, i.city_code_of_id, i.impr_expr_type',
    '  FROM importers i, sd_ports p, impr_types it, countries c',
    ' WHERE :P112001_SEARCH IS NOT NULL',
    '   AND i.port_cd = NVL((SELECT IMPR1120.IMPORTERS_PRE_QUERY_PORT_CD(PORT_CD        => NULL,',
    '                                                                    P_CURR_PORT_CD => :P_CURR_PORT_CD)',
    '                          FROM dual), i.port_cd)',
    '   AND p.port_cd (+)       = i.port_cd',
    '   AND it.impr_type_cd (+) = i.impr_type_cd',
    '   AND c.ctry_cd (+)       = i.ctry_cd',
    "   AND (INSTR(UPPER(i.port_cd || '|' || p.port_name || '|' || i.impr_nbr || '|' || i.hq_impr_nbr || '|' ||",
    "                    i.arbc_impr_name || '|' || i.eng_impr_name || '|' || i.impr_cntct_name || '|' ||",
    "                    i.impr_type_cd || '|' || it.impr_type_name || '|' || i.bus_id_type_cd || '|' || i.bus_id || '|' ||",
    "                    i.bus_id_brnch || '|' || i.ctry_cd || '|' || c.crty_arbc_name || '|' || i.city_code_of_id || '|' ||",
    "                    i.impr_expr_type), UPPER(TRIM(:P112001_SEARCH))) > 0",
    "        OR i.impr_name_std LIKE '%' || (SELECT IMPR1120.IMPORTERS_PRE_QUERY_NAME_STD(",
    '                                                   ARBC_IMPR_NAME => TRIM(:P112001_SEARCH))',
    "                                          FROM dual) || '%')"])
SEARCH_COLUMNS = [
    ('ROW_ID', None, 'VARCHAR2'), ('PORT_CD', 'رمز الجمرك', 'NUMBER'), ('PORT_NAME', 'اسم الجمرك', 'VARCHAR2'),
    ('IMPR_NBR', 'الرقم الجمركى', 'NUMBER'), ('HQ_IMPR_NBR', 'الرقم الموحد بالمصلحة', 'NUMBER'),
    ('ARBC_IMPR_NAME', 'الاسم العربى', 'VARCHAR2'), ('ENG_IMPR_NAME', 'الاسم الأجنبي', 'VARCHAR2'),
    ('IMPR_CNTCT_NAME', 'الوكيل المفوض', 'VARCHAR2'), ('IMPR_TYPE_CD', 'رمز النشاط التجارى', 'NUMBER'),
    ('IMPR_TYPE_NAME', 'النشاط التجارى', 'VARCHAR2'), ('BUS_ID_TYPE_CD', 'نوع الرقم الاستدلالى', 'NUMBER'),
    ('BUS_ID', 'الرقم الاستدلالى', 'VARCHAR2'), ('BUS_ID_BRNCH', 'الفرع', 'VARCHAR2'), ('CTRY_CD', 'الجنسيه', 'NUMBER'),
    ('CRTY_ARBC_NAME', 'الدولة', 'VARCHAR2'), ('CITY_CODE_OF_ID', 'مصدر الرقم الإستدلالي', 'NUMBER'),
    ('IMPR_EXPR_TYPE', 'النشاط الجمركي', 'NUMBER')]
NEW_LOVS = [  # spec 6
    ('LOV_IMPR_SUSPN_RSN_CD', "SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'IMPR_SUSPN_RSN_CD' ORDER BY 2",
     'list item IMPR_SUSPN.SUSPN_RSN_CD (CGDV$POPULATE_DYNAMIC_LISTS)'),
    ('LOV_SUSPN_SIDE_CD', "SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'SUSPN SIDE CD' ORDER BY 2",
     'pop list IMPR_SUSPN.SUSPN_SIDE_CD (CGDV$POPULATE_DYNAMIC_LISTS)')]
MSG_IS_1_IMP_FK = 'بيانات الربط مع ملف المستوردين غير صحيحة - أعد إدخال البيانات'

SAVE_ROW = ('IMPR1120.IMPR_SUSPN_SAVE_ROW(APEX$ROW_STATUS => :APEX$ROW_STATUS, PORT_CD => :PORT_CD, IMPR_NBR => :IMPR_NBR, '
            'SUSPN_SEQ => :SUSPN_SEQ, SUSPN_STRT_DT => :SUSPN_STRT_DT, SUSPN_END_DT => :SUSPN_END_DT, '
            'SUSPN_RSN_CD => :SUSPN_RSN_CD, SUSPN_RSN_TEXT => :SUSPN_RSN_TEXT, SUSPN_SIDE_CD => :SUSPN_SIDE_CD, '
            'P_HQ_IMPR_NBR => :P1120_HQ_IMPR_NBR, P_PORT_NAME => :P1120_PORT_NAME, P_BUS_ID => :P1120_BUS_ID, '
            'P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, '
            'P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);')

# ----------------------------------------------------------------------------- generation
def gen():
    out = []
    W = out.append
    W('''-- =============================================================================
-- REVIEW BEFORE IMPORT
-- File        : apex/IMPR1120/f345_impr1120.sql
-- Generated by: Claude Code (scripts/gen_apex_impr1120.py, step 04 revision 1) from
--               analysis/IMPR1120/IMPR1120_apex_page_spec.md, %s, form IMPR1120
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / 4c, docs/f345_reference_standard.md 3-9: read-only Form region (ROWID),
--               editable Interactive Grid with PL/SQL row DML, FOS + native dynamic actions,
--               one-line calls into package IMPR1120 (version 007). No JavaScript, no AJAX callback.
-- Contents    : component export INTO the application installed from f345 AND already holding the
--               IMPR1110 export (page group IMPR, LOV_SD_PORTS, LOV_ALLOWED_EXPORT are reused):
--               pages 1120 (main) and 112001 (search) + 2 LOVs + 1 Text Message.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR1120/import_notes.md
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
    for name, sql, s in NEW_LOVS:
        nid('9120:lov:' + name, 5)
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), call('create_list_of_values', [
            ('p_id', ref('9120:lov:' + name)), ('p_lov_name', q(name)), ('p_source_type', q('SQL')), ('p_location', q('LOCAL')),
            ('p_lov_query', lit(sql)), ('p_return_column_name', q('R')), ('p_display_column_name', q('D'))],
            'Source: IMPR1120 ' + s + ' / spec 6')))
    nid('9120:msg:IS_1_IMP_FK', 3)
    W(block('application/shared_components/globalization/messages/is_1_imp_fk',
            call('create_message', [('p_id', ref('9120:msg:IS_1_IMP_FK')), ('p_name', q('IS_1_IMP_FK')),
                                    ('p_message_language', q('ar-sa')), ('p_message_text', q(MSG_IS_1_IMP_FK))],
                 'Source: IMPR1120.IMPR_SUSPN.ON-ERROR (ORA-02291 on constraint IS_1_IMP_FK) / spec 11')))
    UNCERTAIN.add('wwv_flow_api.create_message (Text Message; f345 has none; IMPR1110 uses it) - p_message_language ar-sa')

    # ---------------------------------------------------------------- page 1120 (spec 2-12)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG)
    A(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM)), ('p_alias', q(FORM)),
        ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('Y')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_step_template', fid('PAGE_MAIN')),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1120.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR1120.fmb - spec 2 / f345 standard 4'))
    hero = ('<div class="cg-hero-row"><div class="cg-hero-top"><span class="cg-hero-ic fa fa-ban" aria-hidden="true"></span>'
            '<div><div class="cg-hero-k">المستوردون</div><div class="cg-hero-t">&P1120_HERO_TITLE.</div>'
            '<div class="cg-hero-d">إضافة وتعديل وإلغاء توقيفات المستورد</div></div></div></div>')
    nid('1120:plug:IMPORTERS_HERO', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1120:plug:IMPORTERS_HERO')), ('p_plug_name', q('الهيدر')), ('p_region_name', q('IMPORTERS_HERO')),
        ('p_region_css_classes', q('cg-hero')), ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '10'), ('p_plug_source', q(hero)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src('IMPR1120.TITLE (OLB) -> f345 hero / spec 3'))]))
    nid('1120:plug:IMPORTERS', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1120:plug:IMPORTERS')), ('p_plug_name', q('بيانات المستورد')), ('p_region_name', q('IMPORTERS')),
        ('p_region_css_classes', q('zatca-forms cg-form cg-card')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_FORM')), ('p_plug_display_sequence', '20'), ('p_query_type', q('TABLE')),
        ('p_query_table', q('IMPORTERS')), ('p_include_rowid_column', 'true'), ('p_is_editable', 'false'),
        ('p_plug_source_type', q('NATIVE_FORM')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1120.IMPORTERS (single record, Update / Delete Allowed = No, items not insertable: read only; key mode ROWID) / spec 3'))]))
    UNCERTAIN.add('read-only NATIVE_FORM region: p_is_editable => false (no Process form); the row is fetched by Initialize form')
    UNCERTAIN.add('ROWID primary key of the Form region: p_include_rowid_column, item source ROWID / p_source_data_type ROWID (as IMPR1110)')
    nid('1120:plug:IMPR_SUSPN', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1120:plug:IMPR_SUSPN')), ('p_plug_name', q('توقيفات المستوردين')), ('p_region_name', q('IMPR_SUSPN')),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', '30'), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(SUSPN_SQL)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q('P1120_PORT_CD,P1120_IMPR_NBR')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_display_condition_type', q('ITEM_IS_NOT_NULL')), ('p_plug_display_when_condition', q('P0_PAGE_PK')),
        ('p_plug_comment', src('IMPR1120.IMPR_SUSPN (relation CGFK$IS_1_IMP_FK, WHERE SUSPN_RLSE_DT IS NULL) / spec 3'))]))
    # IG columns: right after their own region (APEX attaches a region column to the region created last; f345 AGR1100)
    for c in ig_row_columns(PG):
        A(c)
    for i, c in enumerate(SUSPN_COLUMNS):
        A(ig_column(PG, c, (i + 3) * 10))
    for c in ig(PG, '1120:plug:IMPR_SUSPN', True, ['APEX$ROW_ACTION', 'APEX$ROW_SELECTOR'] + [c['name'] for c in SUSPN_COLUMNS],
                'لا توجد توقيفات سارية'):
        A(c)
    nid('1120:plug:FUNCS', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1120:plug:FUNCS')), ('p_plug_name', q('الوظائف')), ('p_region_name', q('FUNCS')),
        ('p_region_css_classes', q('cg-funcs')), ('p_region_template_options', q('#DEFAULT#:js-dialog-size480x320')),
        ('p_plug_template', fid('REGION_DIALOG')), ('p_plug_display_sequence', '990'), ('p_plug_source_type', q('NATIVE_LIST')),
        ('p_list_id', fid('LIST_PAGE_FUNS')), ('p_list_template_id', fid('LIST_FUNS_TPL')), ('p_plug_query_num_rows', '15'),
        ('p_plug_comment', src('IMPR1120.LSIDE / TMPLT function menu (FORM.KEY-F9), opened by page 0 FUNCS; f345 list Page Functions / spec 3'))]))
    # branches (spec 12)
    nid('1120:branch:QUERY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1120:branch:QUERY')), ('p_branch_name', q('EXECUTE-QUERY')),
        ('p_branch_action', q('f?p=&APP_ID.:1120:&SESSION.::&DEBUG.:1120::')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '10'),
        ('p_branch_condition_type', q('REQUEST_IN_CONDITION')), ('p_branch_condition', q('EXECUTE_QUERY,CREATE')),
        ('p_branch_comment', src('IMPR1120.IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY: clear cache 1120, P0_PAGE_PK kept / spec 12'))]))
    nid('1120:branch:STAY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1120:branch:STAY')), ('p_branch_name', q('IMPR1120 - stay in the form')),
        ('p_branch_action', q('f?p=&APP_ID.:1120:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '20'),
        ('p_branch_comment', src('Forms stays in the form after COMMIT / spec 12'))]))
    UNCERTAIN.add('branch p_branch_condition_type => REQUEST_IN_CONDITION (IMPR1110 uses REQUEST_EQUALS_CONDITION)')
    # items (spec 4.1, 4.2)
    for i, it in enumerate(MASTER_ITEMS, 1):
        A(page_item(PG, '1120:plug:IMPORTERS', i * 10, it, form_region=True))
    for seq, it in [(10, dict(name='P1120_HERO_TITLE', kind='NATIVE_HIDDEN', value_protected='Y',
                              comment='Source: IMPR1120.TITLE (OLB) - shown by the hero region (&P1120_HERO_TITLE.)')),
                    (20, dict(name='P1120_MODULE_ID', kind='NATIVE_HIDDEN', value_protected='Y', protect='S',
                              comment='Source: IMPR1120 :PARAMETER.P_MODULE_ID (f345, kept by SCREEN ENTRY RESET)')),
                    (30, dict(name='P1120_P_CURRENT_SIDE', kind='NATIVE_HIDDEN', value_protected='Y',
                              comment='Source: IMPR1120 :PARAMETER.CURRENT_SIDE (launcher: SC_PORT_SETTING VAR_NAME CURRENT_SIDE)'))]:
        A(page_item(PG, '1120:plug:IMPORTERS_HERO', seq, it))
    # validations (spec 7)
    A(validation(PG, 10, 'IMPR_NBR VALIDATION',
                 'return IMPR1120.IMPR_NBR_VALIDATION(P_PORT_CD => :P1120_PORT_CD, P_IMPR_NBR => :P1120_IMPR_NBR);',
                 ('EXECUTE_QUERY,CREATE', 'REQUEST_IN_CONDITION'), assoc_item='P1120_IMPR_NBR',
                 s='IMPR1120.IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM / spec 7'))
    row_cond = (":APEX$ROW_STATUS IN ('C', 'U')", 'EXPRESSION')
    for seq, col, code, s in [
        (110, 'SUSPN_STRT_DT', 'return IMPR1120.SUSPN_STRT_DT_VALIDATION(SUSPN_STRT_DT => :SUSPN_STRT_DT, %s);' % KEYS,
         'IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM'),
        (120, 'SUSPN_END_DT', 'return IMPR1120.SUSPN_END_DT_VALIDATION(SUSPN_STRT_DT => :SUSPN_STRT_DT, SUSPN_END_DT => :SUSPN_END_DT, %s);' % KEYS,
         'IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM'),
        (130, 'SUSPN_RSN_CD', 'return IMPR1120.SUSPN_RSN_CD_VALIDATION(SUSPN_RSN_CD => :SUSPN_RSN_CD, '
                              'P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, %s);' % KEYS,
         'IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM'),
        (140, 'SUSPN_SIDE_CD', 'return IMPR1120.SUSPN_SIDE_CD_VALIDATION(SUSPN_SIDE_CD => :SUSPN_SIDE_CD, %s, %s);' % (SITE, KEYS),
         'IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-LIST-CHANGED + WHEN-VALIDATE-ITEM')]:
        A(validation(PG, seq, 'IMPR_SUSPN %s VALIDATION' % col, code, row_cond, ig_region='1120:plug:IMPR_SUSPN',
                     assoc_column=col, s='IMPR1120.%s / spec 7' % s))
    # processes (spec 8)
    NEW = 'NULL;  -- f345 session setup (SSO_APP_USER, P_CURR_PORT_CD, V_USR_TYPE ...) is done by the application; disabled as in AGR1100'
    BH, AS = 'BEFORE_HEADER', 'AFTER_SUBMIT'
    procs = [
        (BH, 10, 'New', NEW, ('', 'NEVER'), 'f345 session setup copied from AGR1100 (condition Never, as in AGR1100 / IMPR1110) / standard 6', {}),
        (BH, 20, 'P0_PAGE_PK CHECK', 'IMPR1120.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK, P_CURR_PORT_CD => :P_CURR_PORT_CD);',
         None, 'f345; IMPORTERS.PRE-QUERY port rule / spec 8', {}),
        (BH, 40, 'PARAMETERS', ':P1120_MODULE_ID := IMPR1120.GET_MODULE_ID(P_MODULE_ID => :P1120_MODULE_ID);', None, 'f345 / spec 8', {}),
        (BH, 45, 'PARAMETERS CURRENT_SIDE',
         ':P1120_P_CURRENT_SIDE := IMPR1120.GET_CURRENT_SIDE(P_MODULE_ID => :P1120_MODULE_ID, P_CURR_PORT_CD => :P_CURR_PORT_CD);',
         ('P1120_P_CURRENT_SIDE', 'ITEM_IS_NULL'), 'IMPR1120 :PARAMETER.CURRENT_SIDE (launcher SC_PORT_SETTING) / spec 8', {}),
        (BH, 60, 'WHEN-NEW-FORM-INSTANCE',
         'IMPR1120.INIT_FORM(P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, P_CURR_PORT_CD => :P_CURR_PORT_CD);',
         None, 'IMPR1120.FORM.WHEN-NEW-FORM-INSTANCE / spec 8', {}),
        (BH, 70, 'P0_PAGE_PK', ':P1120_ROW_ID := :P0_PAGE_PK;', None, 'f345 (key = ROWID) / spec 8', {}),
        (BH, 80, 'Initialize form', None, None, 'IMPR1120 block IMPORTERS fetch / spec 8', dict(ptype='NATIVE_FORM_INIT', region='1120:plug:IMPORTERS')),
        (BH, 82, 'POST-QUERY',
         'IMPR1120.IMPORTERS_POST_QUERY(P_PORT_CD => :P1120_PORT_CD, P_IMPR_TYPE_CD => :P1120_IMPR_TYPE_CD, '
         'P_BUS_ID_TYPE_CD => :P1120_BUS_ID_TYPE_CD, P_CTRY_CD => :P1120_CTRY_CD, P_CTRY_CD_OF_ID => :P1120_CTRY_CD_OF_ID, '
         'P_CITY_CODE_OF_ID => :P1120_CITY_CODE_OF_ID, P_PORT_NAME => :P1120_PORT_NAME, '
         'P_IMPR_TYPE_NAME => :P1120_IMPR_TYPE_NAME, P_BUS_ID_TYPE_NAME => :P1120_BUS_ID_TYPE_NAME, '
         'P_CRTY_ARBC_NAME => :P1120_CRTY_ARBC_NAME, P_ID_CITY_NAME => :P1120_ID_CITY_NAME);',
         ('P1120_ROW_ID', 'ITEM_IS_NOT_NULL'), 'IMPR1120.IMPORTERS.POST-QUERY / spec 8', {}),
        (BH, 84, 'IMPORTERS WHEN-CREATE-RECORD',
         'IMPR1120.IMPORTERS_WHEN_CREATE_RECORD(P_CURR_PORT_CD => :P_CURR_PORT_CD, P_PORT_CD => :P1120_PORT_CD, '
         'P_PORT_NAME => :P1120_PORT_NAME);',
         (':P1120_ROW_ID IS NULL AND :P1120_PORT_CD IS NULL', 'EXPRESSION', 'PLSQL'), 'IMPR1120.IMPORTERS.WHEN-CREATE-RECORD / spec 8', {}),
        (BH, 100, 'HEADER TITLE', 'IMPR1120.HEADER_TITLE(P_MODULE_ID => :P1120_MODULE_ID, P_HERO_TITLE => :P1120_HERO_TITLE);',
         None, 'f345 (OLB block TITLE) / spec 8', {}),
        (AS, 10, 'EXECUTE-QUERY',
         'IMPR1120.IMPR_NBR_WHEN_VALIDATE_ITEM(P_PORT_CD => :P1120_PORT_CD, P_IMPR_NBR => :P1120_IMPR_NBR, P_PAGE_PK => :P0_PAGE_PK);',
         ('EXECUTE_QUERY,CREATE', 'REQUEST_IN_CONDITION'),
         'IMPR1120.IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM -> Exec_Query_Now -> EXECUTE_QUERY; page 0 CREATE / spec 0 #3, 8', {}),
        (AS, 30, 'PRE-DELETE', 'IMPR1120.PRE_DELETE;', ('DELETE', 'REQUEST_EQUALS_CONDITION'),
         'IMPR1120 block IMPORTERS Delete Allowed = No (FRM-41049) / spec 8', {}),
        (AS, 100, 'IMPR_SUSPN MASTER KEYS', ':PORT_CD := :P1120_PORT_CD; :IMPR_NBR := :P1120_IMPR_NBR;',
         (":REQUEST = 'SAVE' AND :APEX$ROW_STATUS = 'C'", 'EXPRESSION', 'PLSQL'),
         'IMPR1120.IMPR_SUSPN CopyValueFrom IMPORTERS.PORT_CD / IMPR_NBR (f345 standard 6) / spec 8', dict(region='1120:plug:IMPR_SUSPN')),
        (AS, 110, 'IMPR_SUSPN - Save Interactive Grid Data', None, ('SAVE', 'REQUEST_EQUALS_CONDITION'),
         'IMPR1120.IMPR_SUSPN PRE-INSERT, POST-INSERT, PRE-UPDATE, ON-DELETE (row by row, IMPR_SUSPN_SAVE_ROW) / spec 0 #4, 8',
         dict(ptype='NATIVE_IG_DML', region='1120:plug:IMPR_SUSPN',
              extra=[('p_attribute_01', q('PLSQL_CODE')), ('p_attribute_04', lit(SAVE_ROW)), ('p_attribute_05', q('Y')),
                     ('p_attribute_06', q('N')), ('p_attribute_08', q('Y')),
                     ('p_process_success_message', q('تم الحفظ بنجاح'))])),
    ]
    UNCERTAIN.add('NATIVE_IG_DML Target Type PL/SQL Code: p_attribute_01 => PLSQL_CODE, code in p_attribute_04 '
                  '(f345 shows only TABLE / p_attribute_03); p_attribute_05 Y (lost update), 06 N (lock row), 08 Y')
    for point, seq, name, code, cond, s, kw in procs:
        key = '1120:proc:%s:%s' % (point, name)
        A(process(PG, key, seq, point, name, code, cond, s, ptype=kw.get('ptype', 'NATIVE_PLSQL'),
                  extra=kw.get('extra'), region=kw.get('region')))
    # dynamic actions (spec 10)
    A(da(PG, 10, 'IMPR_NBR WHEN-VALIDATE-ITEM', ('ITEM', 'P1120_IMPR_NBR'), 'change', [
        fos('IMPR1120.CHECK_ERROR(IMPR1120.IMPR_NBR_VALIDATION(P_PORT_CD => :P1120_PORT_CD, P_IMPR_NBR => :P1120_IMPR_NBR));',
            ['P1120_PORT_CD', 'P1120_IMPR_NBR']),
        [('p_action', q('NATIVE_SUBMIT_PAGE')), ('p_attribute_01', q('EXECUTE_QUERY')), ('p_attribute_02', q('Y'))]],
        'IMPR1120.IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM + IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE (EXECUTE_QUERY) / spec 10', cond='NOT_NULL'))
    UNCERTAIN.add('NATIVE_SUBMIT_PAGE attributes 01 (request) / 02 (show processing) (not in f345; IMPR1110 uses them)')
    grid = '1120:plug:IMPR_SUSPN'
    for seq, name, col, code, submit, ret, s in [
        (110, 'IMPR_SUSPN SUSPN_STRT_DT WHEN-VALIDATE-ITEM', 'SUSPN_STRT_DT',
         'IMPR1120.CHECK_ERROR(IMPR1120.SUSPN_STRT_DT_VALIDATION(SUSPN_STRT_DT => :SUSPN_STRT_DT, %s));' % KEYS,
         ['SUSPN_STRT_DT', 'PORT_CD', 'IMPR_NBR', 'SUSPN_SEQ'], None, 'IMPR_SUSPN.SUSPN_STRT_DT.WHEN-VALIDATE-ITEM'),
        (120, 'IMPR_SUSPN SUSPN_END_DT WHEN-VALIDATE-ITEM', 'SUSPN_END_DT',
         'IMPR1120.CHECK_ERROR(IMPR1120.SUSPN_END_DT_VALIDATION(SUSPN_STRT_DT => :SUSPN_STRT_DT, SUSPN_END_DT => :SUSPN_END_DT, %s));' % KEYS,
         ['SUSPN_STRT_DT', 'SUSPN_END_DT', 'PORT_CD', 'IMPR_NBR', 'SUSPN_SEQ'], None, 'IMPR_SUSPN.SUSPN_END_DT.WHEN-VALIDATE-ITEM'),
        (130, 'IMPR_SUSPN SUSPN_RSN_CD WHEN-VALIDATE-ITEM', 'SUSPN_RSN_CD',
         'IMPR1120.SUSPN_RSN_CD_VALIDATE_ITEM(SUSPN_RSN_CD => :SUSPN_RSN_CD, P_CURRENT_SIDE => :P1120_P_CURRENT_SIDE, '
         '%s, SUSPN_RSN_TEXT => :SUSPN_RSN_TEXT);' % KEYS,
         ['SUSPN_RSN_CD', 'P1120_P_CURRENT_SIDE', 'PORT_CD', 'IMPR_NBR', 'SUSPN_SEQ'], ['SUSPN_RSN_TEXT'],
         'IMPR_SUSPN.SUSPN_RSN_CD.WHEN-VALIDATE-ITEM'),
        (140, 'IMPR_SUSPN SUSPN_SIDE_CD WHEN-LIST-CHANGED', 'SUSPN_SIDE_CD',
         'IMPR1120.CHECK_ERROR(IMPR1120.SUSPN_SIDE_CD_VALIDATION(SUSPN_SIDE_CD => :SUSPN_SIDE_CD, %s, %s));' % (SITE, KEYS),
         ['SUSPN_SIDE_CD', 'P1120_P_CURRENT_SIDE', 'PORT_CD', 'IMPR_NBR', 'SUSPN_SEQ'], None, 'IMPR_SUSPN.SUSPN_SIDE_CD.WHEN-LIST-CHANGED')]:
        A(da(PG, seq, name, ('COLUMN', grid, col), 'change', [fos(code, submit, ret)], 'IMPR1120.%s / spec 10' % s))
    UNCERTAIN.add('FOS Items to Return = IG column SUSPN_RSN_TEXT (AGR1100 returns only page items from column DAs)')
    W(block('application/pages/page_01120', '\n'.join(P)))

    # ---------------------------------------------------------------- page 112001 (search, spec 3 / 4.4)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_SEARCH)
    A(call('create_page', [
        ('p_id', str(PG_SEARCH)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM + '_SEARCH')), ('p_alias', q(FORM + '-SEARCH')),
        ('p_page_mode', q('MODAL')), ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_height', q('800')),
        ('p_dialog_width', q('1800')), ('p_protection_level', q('C')), ('p_first_item', q('AUTO_FIRST_ITEM')),
        ('p_page_comment', src('IMPR1120 Enter-Query / Execute-Query of block IMPORTERS / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: f345 search page <page>01 (page 0 SEARCH)'))
    nid('112001:plug:CRIT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('112001:plug:CRIT')), ('p_plug_name', q('بحث')), ('p_region_name', q('IMPORTERS_SEARCH_CRITERIA')),
        ('p_region_css_classes', q('zatca-forms cg-form')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_HERO')), ('p_plug_display_sequence', '10'), ('p_attribute_01', q('N')),
        ('p_attribute_02', q('TEXT')), ('p_attribute_03', q('Y')),
        ('p_plug_comment', src('IMPR1120.IMPORTERS.PRE-QUERY criteria, as one search text over all columns / spec 3'))]))
    nid('112001:plug:IG', 1)
    A(call('create_page_plug', [
        ('p_id', ref('112001:plug:IG')), ('p_plug_name', q('المستوردون')), ('p_region_name', q('IMPORTERS_SEARCH')),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', '20'), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(SEARCH_SQL)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q('P112001_SEARCH')),
        ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1120.IMPORTERS block query + PRE-QUERY (block ORDER BY dropped); one search text over all columns, '
                               'no query until a search, no total row count / spec 3'))]))
    for i, (c, h, dt) in enumerate(SEARCH_COLUMNS):
        if c == 'ROW_ID':
            col = dict(name=c, kind='HIDDEN', data_type=dt, pk=True)
        elif c == 'IMPR_NBR':
            col = dict(name=c, kind='LINK', data_type=dt, heading=h,
                       link_target='f?p=&APP_ID.:1120:&SESSION.::&DEBUG.:1120:P0_PAGE_PK:&ROW_ID.', link_text='&IMPR_NBR.')
        else:
            col = dict(name=c, kind='DISPLAY', data_type=dt, heading=h)
        A(ig_column(PG_SEARCH, col, (i + 1) * 10))
    for c in ig(PG_SEARCH, '112001:plug:IG', False, [c for c, _, _ in SEARCH_COLUMNS], 'لا توجد نتائج - أدخل نص البحث ثم اضغط بحث'):
        A(c)
    A(page_item(PG_SEARCH, '112001:plug:CRIT', 10, dict(
        name='P112001_SEARCH', kind='NATIVE_TEXT_FIELD', label='بحث في كل الأعمدة', maxlen=200, span=6,
        comment='Source: IMPR1120.IMPORTERS query criteria (PORT_CD, PORT_NAME, ARBC_IMPR_NAME ...) as one text over all columns; '
                'port rule of PRE-QUERY in the region SQL (user request 2026-11-23)')))
    nid('112001:btn:SEARCH', 2)
    A(call('create_page_button', [
        ('p_id', ref('112001:btn:SEARCH')), ('p_button_sequence', '40'), ('p_button_plug_id', ref('112001:plug:CRIT')),
        ('p_button_name', q('SEARCH')), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
        ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q('بحث')), ('p_button_position', q('BODY')),
        ('p_icon_css_classes', q('fa-search')), ('p_button_css_classes', q('cg-b-search')),
        ('p_button_comment', src('IMPR1120 TOOLBAR.EXECUTE (Execute Query of block IMPORTERS) / spec 5'))]))
    nid('112001:btn:CLEAR', 2)
    A(call('create_page_button', [
        ('p_id', ref('112001:btn:CLEAR')), ('p_button_sequence', '50'), ('p_button_plug_id', ref('112001:plug:CRIT')),
        ('p_button_name', q('CLEAR')), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
        ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q('مسح البحث')), ('p_button_position', q('BODY')),
        ('p_icon_css_classes', q('fa-eraser')), ('p_button_css_classes', q('cg-b-clear')),
        ('p_button_comment', src('IMPR1120 TOOLBAR.CLEAR_ALL for the search (user request 2026-11-23) / spec 5'))]))
    A(da(PG_SEARCH, 10, 'SEARCH WHEN-BUTTON-PRESSED', ('BUTTON', '112001:btn:SEARCH'), 'click',
         [[('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('112001:plug:IG'))]],
         'IMPR1120 TOOLBAR.EXECUTE / spec 10'))
    A(da(PG_SEARCH, 12, 'SEARCH KEY-ENTER', ('ITEM', 'P112001_SEARCH'), 'keyup',
         [[('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('112001:plug:IG'))]],
         'IMPR1120 KEY-EXEQRY (Enter in the search text; f345 AGR1100_SEARCH "SEARCH REFRESH" keyup pattern) / spec 10', cond='ENTER'))
    A(da(PG_SEARCH, 15, 'CLEAR WHEN-BUTTON-PRESSED', ('BUTTON', '112001:btn:CLEAR'), 'click',
         [[('p_action', q('NATIVE_CLEAR')), ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q('P112001_SEARCH'))],
          [('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('112001:plug:IG'))]],
         'IMPR1120 TOOLBAR.CLEAR_ALL (search criteria) / spec 10'))
    UNCERTAIN.add('NATIVE_CLEAR action with p_affected_elements (page 112001 CLEAR; not in f345 / IMPR1110)')
    UNCERTAIN.add('search IG: p_lazy_loading true, p_show_total_row_count false, toolbar ACTIONS_MENU:RESET (search field removed)')
    UNCERTAIN.add('button DA: p_triggering_button_id (page 112001 SEARCH; IMPR1110 uses it)')
    ek, ak = '112001:da:Hide', '112001:daa:Hide:10'
    nid(ek, 8); nid(ak, 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('Hide')), ('p_event_sequence', '20'),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('ready')),
                                    ('p_da_event_comment', src('f345 AGR1100_SEARCH "Hide" (page 0 toolbar not used in a dialog)'))]))
    A(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('Y')), ('p_action', q('NATIVE_HIDE')),
                                     ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', fid('P0_ACTIONS'))]))
    W(block('application/pages/page_112001', '\n'.join(P)))

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
    problems = []
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
    if re.search(r'pkg_|FORMS_APX\.', code, re.I): problems.append('page calls pkg_ / FORMS_APX')
    for bad in ('ON_DEMAND', 'p_javascript_file_urls', 'AJAX_FUNCTION', 'NATIVE_JAVASCRIPT_CODE', 'create_security_scheme'):
        if bad in code: problems.append('not allowed: ' + bad)
    defined = re.findall(r'[ ,]p_id=>wwv_flow_api\.id\((\d+)\)', text)
    if len(defined) != len(set(defined)): problems.append('duplicate p_id')
    ref_ids = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', ref_txt))
    ids_1110 = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', i1110))
    if set(defined) & ref_ids: problems.append('ids clash with f345')
    if set(defined) & ids_1110: problems.append('ids clash with the IMPR1110 export')
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
    if re.search(r"create_message\(\n p_id=>[^\n]*\n,p_name=>'IS_1_IMP_FK'", i1110): problems.append('message IS_1_IMP_FK in IMPR1110')
    if names_of(text, 'create_flow_item'): problems.append('application item created (none expected)')
    # package members and parameter names
    sigs = {}
    for m in re.finditer(r'(?:PROCEDURE|FUNCTION)\s+([A-Z0-9_$]+)\s*(\((.*?)\))?\s*(?:RETURN\s+\w+\s*)?;', pkg_txt, re.S):
        sigs[m.group(1).upper()] = set(re.findall(r'\b([A-Z][A-Z0-9_$]*)\s+(?:IN|OUT)\b', m.group(3) or ''))
    plain = '\n'.join(unq(v) for v in re.findall(r"(?:unistr\('(?:[^']|'')*'\)|'(?:[^']|'')*')", code))
    for m in set(re.findall(r'IMPR1120\.([A-Z_0-9$]+)', plain)):
        if m not in sigs: problems.append('IMPR1120.%s not in impr1120_spec.sql' % m)
    for m in re.finditer(r'IMPR1120\.(?!CHECK_ERROR)([A-Z0-9_$]+)\(([^()]*)\)', plain):
        name, args = m.groups()
        given = re.findall(r'([A-Z0-9_$]+)\s*=>', args)
        if name in sigs and given and set(given) != sigs[name]:
            problems.append('call %s: parameters %s vs spec %s' % (name, sorted(set(given) ^ sigs[name]), ''))
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
    path = os.path.join(ROOT, 'apex', 'IMPR1120', 'f%s_impr1120_import.sql' % vals['app_id'])
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
