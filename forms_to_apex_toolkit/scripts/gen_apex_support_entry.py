# -*- coding: utf-8 -*-
"""
gen_apex_support_entry.py - step 04: APEX 21.2 component export of SUPPORT_ENTRY (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c, docs/f345_reference_standard.md).

Reads
  analysis/SUPPORT_ENTRY/SUPPORT_ENTRY_apex_page_spec.md   the design (written into this script as data)
  apex/Reference/f345.sql                 template ids, existing ids / items / LOVs (checks)
  plsql/SUPPORT_ENTRY/support_entry_spec.sql  members of package SUPPORT_ENTRY (checks)
  plsql_templates/forms_apx.sql           members of FORMS_APX (checks)
Writes
  apex/SUPPORT_ENTRY/f345_support_entry.sql         component export, REVIEW BEFORE IMPORT (4 placeholders)
  apex/SUPPORT_ENTRY/f<app>_support_entry_import.sql  with --workspace-id --app-id --id-offset --schema

Page 9001 never submits (page spec 0.2): AGREE / CANCEL are FOS + native Close Dialog; no validations,
no After Submit processes, no JavaScript action. IDs are deterministic: 9001<kind 2><seq 6>.

Usage (from forms_to_apex_toolkit):
  python3 -I scripts/gen_apex_support_entry.py [--workspace-id=.. --app-id=.. --id-offset=.. --schema=..]
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
import item_icons      # Post Text icon next to every entry item, from the item name (f202604 convention)
import items_to_submit # every page item a query / LOV / FOS call reads is in its Items to Submit (user rule 2026-11-25)
import client_condition  # an item in an item-type client-side condition has a default value (user rule 2026-11-26)
import lov_apx         # shared LOVs: function body returning SQL, code in LOV_APX (CLAUDE.md 4d)
REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')
PKG = os.path.join(ROOT, 'plsql', 'SUPPORT_ENTRY', 'support_entry_spec.sql')
OUT_DIR = os.path.join(ROOT, 'apex', 'SUPPORT_ENTRY')
OUT = os.path.join(OUT_DIR, 'f345_support_entry.sql')
OTHER_EXPORTS = [os.path.join(ROOT, 'apex', d, f) for d, f in
                 (('IMPR1110', 'f345_impr1110.sql'), ('IMPR1120', 'f345_impr1120.sql'))]
DATE, STAMP = '2026-11-24', '20261124000000'
FORM, PG = 'SUPPORT_ENTRY', 9001

F345 = dict(
    UI='11622010846008869795', REGION_BLANK='11621859120066869682', REGION_BUTTONS='11621861869875869684',
    LABEL_OPT='11621983529556869749', BUTTON='11621986167597869752', P0_ACTIONS='73488102084440079322')
ITEM_OPTS = '#DEFAULT#:t-Form-fieldContainer--stretchInputs'
TITLE = 'بيانات المساندة الفنية'

# parameters / values used here that do not appear in f345 (verify after import, import_notes.md)
UNCERTAIN = {
    "DA action NATIVE_DIALOG_CLOSE (Close Dialog; IMPR1110 uses NATIVE_DIALOG_CANCEL, not in f345 either)",
    "DA triggering element type JQUERY_SELECTOR with p_triggering_element '#AGREE,#AGREE_EDIT' / '#CANCEL,#CANCEL_EDIT'",
    "p_item_default on a Hidden item (P9001_P_MODE default 1; used by IMPR1110, not in f345)",
    "create_list_of_values_cols for the return / display column D as well (shows the code in the Popup LOV)",
    lov_apx.UNCERTAIN,
}

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

_ids = {}
def nid(key, kind):
    """deterministic id 9001<kind 2><seq 6>"""
    if key in _ids:
        raise KeyError('id defined twice ' + key)
    n = sum(1 for v in _ids.values() if v[4:6] == '%02d' % kind) + 1
    _ids[key] = '%d%02d%06d' % (PG, kind, n * 10)
    return 'wwv_flow_api.id(%s)' % _ids[key]
def ref(key):
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

# kinds: 01 region 02 button 04 item 05 computation 07 process 08 da event 09 da action
#        91 page group 92 application item 95 LOV 96 LOV column

# ----------------------------------------------------------------------------- design (page spec 2-10)
ITEMS = [  # name, display_as, label, extra params, comment
    ('P9001_P_PORT_CD', 'NATIVE_POPUP_LOV', 'جمرك الخطاب',
     [('p_named_lov', q('LOV_SD_PORTS_TYPES')), ('p_lov_display_null', q('YES')), ('p_cSize', '30'), ('p_cMaxlength', '23'),
      ('p_begin_on_new_line', q('YES')), ('p_colspan', '3'),
      ('p_attribute_01', q('DIALOG')), ('p_attribute_02', q('FIRST_ROWSET')), ('p_attribute_03', q('N'))],
     'SUPPORT_ENTRY.RP.P_PORT_CD (LOV LOV_SD_PORTS) / spec 4'),
    ('P9001_P_PORT_NAME', 'NATIVE_DISPLAY_ONLY', None,
     [('p_begin_on_new_line', q('NO')), ('p_colspan', '9'),
      ('p_attribute_01', q('N')), ('p_attribute_02', q('VALUE')), ('p_attribute_04', q('N')), ('p_attribute_05', q('PLAIN'))],
     'SUPPORT_ENTRY.RP.P_PORT_NAME (display, Enabled = false) / spec 4'),
    ('P9001_SUPP_TITLE_CD', 'NATIVE_POPUP_LOV', 'جهة الخطاب',
     [('p_named_lov', q('LOV_SUPP_TITLES')), ('p_lov_display_null', q('YES')), ('p_cSize', '30'), ('p_cMaxlength', '23'),
      ('p_begin_on_new_line', q('YES')), ('p_colspan', '3'),
      ('p_attribute_01', q('DIALOG')), ('p_attribute_02', q('FIRST_ROWSET')), ('p_attribute_03', q('N'))],
     'SUPPORT_ENTRY.RP.SUPP_TITLE_CD (LOV LOV_SUPP_TITLES) / spec 4'),
    ('P9001_SUPP_TITLE_NM', 'NATIVE_DISPLAY_ONLY', None,
     [('p_begin_on_new_line', q('NO')), ('p_colspan', '9'),
      ('p_attribute_01', q('N')), ('p_attribute_02', q('VALUE')), ('p_attribute_04', q('N')), ('p_attribute_05', q('PLAIN'))],
     'SUPPORT_ENTRY.RP.SUPP_TITLE_NM (display, Enabled = false) / spec 4'),
    ('P9001_LETTER_NBR', 'NATIVE_TEXT_FIELD', 'رقم الخطاب',
     [('p_cSize', '30'), ('p_cMaxlength', '50'), ('p_begin_on_new_line', q('YES')), ('p_colspan', '6'),
      ('p_attribute_01', q('N')), ('p_attribute_02', q('N')), ('p_attribute_04', q('TEXT')), ('p_attribute_05', q('BOTH'))],
     'SUPPORT_ENTRY.RP.LETTER_NBR / spec 4'),
    ('P9001_LETTER_DT', 'NATIVE_TEXT_FIELD', 'تاريخ الخطاب',
     [('p_format_mask', q('&P9001_HIJRI_DATE_FORMAT.')), ('p_cSize', '30'), ('p_cMaxlength', '10'),
      ('p_tag_css_classes', q('hijri-date-default')), ('p_begin_on_new_line', q('NO')), ('p_colspan', '6'),
      ('p_tag_attributes', q('placeholder="سنة-شهر-يوم"')),
      ('p_attribute_01', q('N')), ('p_attribute_02', q('N')), ('p_attribute_04', q('TEXT')), ('p_attribute_05', q('BOTH'))],
     'SUPPORT_ENTRY.RP.LETTER_DT (Datetime, mask MI-MM-RRRR) - f345 Hijri picker, format FORMS_APX.HIJRI_DATE_FORMAT / spec 0.5, 4'),
    ('P9001_P_MODE', 'NATIVE_HIDDEN', None,
     [('p_item_default', q('1')), ('p_protection_level', q('S')), ('p_attribute_01', q('Y'))],
     'SUPPORT_ENTRY :PARAMETER.P_MODE (default 1; 0 = new letter) - URL from SUPPORT_ENTRY.OPEN_DIALOG, checksum / spec 4'),
    ('P9001_P_CURR_PORT_CD', 'NATIVE_HIDDEN', None,
     [('p_protection_level', q('S')), ('p_attribute_01', q('Y'))],
     'SUPPORT_ENTRY :PARAMETER.P_CURR_PORT_CD (caller passes the importer port) - URL from OPEN_DIALOG, checksum / spec 4'),
    ('P9001_HIJRI_DATE_FORMAT', 'NATIVE_HIDDEN', None,
     [('p_protection_level', q('S')), ('p_attribute_01', q('Y'))],
     'format of P9001_LETTER_DT = FORMS_APX.HIJRI_DATE_FORMAT (computation) / spec 9'),
]

BUTTONS = [  # name, label, position, hot, icon, css, mode-0 (True) / edit (False), comment
    ('AGREE', 'موافق', 'NEXT', True, 'fa-check', 'cg-b-save', True, 'SUPPORT_ENTRY.RP.AGREE (label in mode 0)'),
    ('AGREE_EDIT', 'تعديل', 'NEXT', True, 'fa-pencil', 'cg-b-save', False, 'SUPPORT_ENTRY.RP.AGREE (label تعديل, WHEN-NEW-FORM-INSTANCE)'),
    ('CANCEL', 'تراجع', 'PREVIOUS', False, 'fa-undo', 'cg-b-funcs', True, 'SUPPORT_ENTRY.RP.CANCEL (label in mode 0)'),
    ('CANCEL_EDIT', 'إغلاق', 'PREVIOUS', False, 'fa-times', 'cg-b-funcs', False, 'SUPPORT_ENTRY.RP.CANCEL (label إغلاق, WHEN-NEW-FORM-INSTANCE)'),
]

FOS = lambda code, submit=None, ret=None: [
    ('p_action', q('PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE')), ('p_attribute_01', q(code)),
    ('p_attribute_02', q(submit) if submit else None), ('p_attribute_03', q(ret) if ret else None),
    ('p_attribute_05', q('#SQLERRM#')), ('p_attribute_15', q('suppressChangeEvent:escape-message')),
    ('p_wait_for_result', q('Y'))]
CLOSE = [('p_action', q('NATIVE_DIALOG_CLOSE'))]

DAS = [  # name, trigger (kind, value), event, actions, comment
    ('P_PORT_CD WHEN-VALIDATE-ITEM', ('ITEM', 'P9001_P_PORT_CD'), 'change', [
        FOS('FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.P_PORT_CD_VALIDATION(P_PORT_CD => :P9001_P_PORT_CD));', 'P9001_P_PORT_CD'),
        FOS('SUPPORT_ENTRY.P_PORT_CD_WHEN_VALIDATE_ITEM(P_PORT_CD => :P9001_P_PORT_CD, P_PORT_NAME => :P9001_P_PORT_NAME);',
            'P9001_P_PORT_CD,P9001_P_PORT_NAME', 'P9001_P_PORT_NAME')],
     'SUPPORT_ENTRY.RP.P_PORT_CD.WHEN-VALIDATE-ITEM / spec 10 #1'),
    ('SUPP_TITLE_CD WHEN-VALIDATE-ITEM', ('ITEM', 'P9001_SUPP_TITLE_CD'), 'change', [
        FOS('FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.SUPP_TITLE_CD_VALIDATION(P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD));',
            'P9001_SUPP_TITLE_CD'),
        FOS('SUPPORT_ENTRY.SUPP_TITLE_CD_VALIDATE_ITEM(P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD, P_SUPP_TITLE_NM => :P9001_SUPP_TITLE_NM);',
            'P9001_SUPP_TITLE_CD,P9001_SUPP_TITLE_NM', 'P9001_SUPP_TITLE_NM')],
     'SUPPORT_ENTRY.RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM / spec 10 #2'),
    ('LETTER_DT WHEN-VALIDATE-ITEM', ('ITEM', 'P9001_LETTER_DT'), 'change', [
        FOS('FORMS_APX.CHECK_ERROR(SUPPORT_ENTRY.LETTER_DT_VALIDATION(P_LETTER_DT => :P9001_LETTER_DT));', 'P9001_LETTER_DT')],
     'SUPPORT_ENTRY.RP.LETTER_DT format mask MI-MM-RRRR (WHEN-VALIDATE-ITEM empty) / spec 10 #3'),
    ('AGREE WHEN-BUTTON-PRESSED', ('JQUERY_SELECTOR', '#AGREE,#AGREE_EDIT'), 'click', [
        FOS('SUPPORT_ENTRY.AGREE_WHEN_BUTTON_PRESSED(P_PORT_CD => :P9001_P_PORT_CD, P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD, '
            'P_LETTER_NBR => :P9001_LETTER_NBR, P_LETTER_DT => :P9001_LETTER_DT);',
            'P9001_P_PORT_CD,P9001_SUPP_TITLE_CD,P9001_LETTER_NBR,P9001_LETTER_DT'),
        CLOSE],
     'SUPPORT_ENTRY.RP.AGREE.WHEN-BUTTON-PRESSED (EXIT_FORM -> Close Dialog, both modes: decision D1) / spec 10 #4'),
    ('CANCEL WHEN-BUTTON-PRESSED', ('JQUERY_SELECTOR', '#CANCEL,#CANCEL_EDIT'), 'click', [
        FOS('SUPPORT_ENTRY.CANCEL_WHEN_BUTTON_PRESSED(P_MODE => :P9001_P_MODE);'),
        CLOSE],
     'SUPPORT_ENTRY.RP.CANCEL.WHEN-BUTTON-PRESSED (EXIT_FORM(NO_VALIDATE) -> Close Dialog) / spec 10 #5'),
]

# ----------------------------------------------------------------------------- generation
def gen():
    out = []
    out.append("""-- =============================================================================
-- REVIEW BEFORE IMPORT
-- File        : apex/SUPPORT_ENTRY/f345_support_entry.sql
-- Generated by: Claude Code (scripts/gen_apex_support_entry.py, step 04 revision 1) from
--               analysis/SUPPORT_ENTRY/SUPPORT_ENTRY_apex_page_spec.md, %s, form SUPPORT_ENTRY
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / 4c, docs/f345_reference_standard.md 3-9: FOS + native dynamic actions,
--               one-line calls into package SUPPORT_ENTRY (version 002) and FORMS_APX (004).
--               No JavaScript file, no AJAX callback process, no JavaScript action.
-- Contents    : component export INTO the application installed from f345: page 9001 SUPPORT_ENTRY
--               (shared modal dialog), page group SC, application item G_SUPPORT_ENTRY_CALLER,
--               LOVs LOV_SD_PORTS_TYPES and LOV_SUPP_TITLES.
--               Needs the application items G_PORT_CD, G_SUPP_TITLE_CD, G_LETTER_NBR, G_LETTER_DT
--               (created by the IMPR1110 export) - see import_notes.md.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/SUPPORT_ENTRY/import_notes.md
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
""" % DATE)

    # ---- shared components
    out.append(block('application/shared_components/user_interface/page_groups/sc', call('create_page_group', [
        ('p_id', nid('group', 91)), ('p_group_name', q('SC')),
        ('p_group_desc', q('Forms application SC (shared dialogs such as SUPPORT_ENTRY)'))],
        'Source: Support_Entry.fmb in forms/SC / spec 2')))
    out.append(block('application/shared_components/logic/application_items', call('create_flow_item', [
        ('p_id', nid('item:G_SUPPORT_ENTRY_CALLER', 92)), ('p_name', q('G_SUPPORT_ENTRY_CALLER')),
        ('p_protection_level', q('I')),
        ('p_item_comment', src('SUPPORT_ENTRY - caller page for G_LAST_PAGE KEEP (f345 SCREEN ENTRY RESET), set by SUPPORT_ENTRY.OPEN_DIALOG / spec 0.2, 13.2'))])))
    lovs = [
        ('LOV_SD_PORTS_TYPES', 'SUPPORT_ENTRY LOV LOV_SD_PORTS / RG LOV_SD_PORTS (decision D2) / spec 6',
         lov_apx.call('LOV_SD_PORTS_TYPES'),
         [('D', 'رمز الجمرك', 'NUMBER'), ('RV_MEANING', 'نوع الجمرك', 'VARCHAR2'), ('PORT_NAME', 'اسم الجمرك', 'VARCHAR2')]),
        ('LOV_SUPP_TITLES', 'SUPPORT_ENTRY LOV LOV_SUPP_TITLES / RG LOV_SUPP_TITLES / spec 6',
         lov_apx.call('LOV_SUPP_TITLES'),
         [('D', 'رمز معتمد الخطاب', 'NUMBER'), ('SUPP_TITLE_NM', 'معتمد الخطاب', 'VARCHAR2')]),
    ]
    for name, comment, sql, cols in lovs:
        body = [call('create_list_of_values', [
            ('p_id', nid('lov:' + name, 95)), ('p_lov_name', q(name))] + lov_apx.lov_attributes(sql, q),
            'Source: ' + comment)]
        for i, (col, head, dtype, visible) in enumerate(lov_apx.column_definitions(cols)):
            body.append(call('create_list_of_values_cols', [
                ('p_id', nid('lovcol:%s:%s' % (name, col), 96)), ('p_lov_id', ref('lov:' + name)),
                ('p_query_column_name', q(col)), ('p_heading', q(head)),
                ('p_display_sequence', str((i + 1) * 10)), ('p_data_type', q(dtype))] + lov_apx.column_attributes(visible)))
        out.append(block('application/shared_components/user_interface/lovs/' + name.lower(), '\n'.join(body)))

    # ---- page 9001
    p = ['wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG]
    p.append(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM)), ('p_alias', q(FORM)),
        ('p_page_mode', q('MODAL')), ('p_step_title', q(TITLE)), ('p_warn_on_unsaved_changes', q('N')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', ref('group')), ('p_first_item', q('AUTO_FIRST_ITEM')),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')),
        ('p_dialog_width', q('720')), ('p_protection_level', q('C')),
        ('p_page_comment', src('Support_Entry.fmb, window RP_WINDOW (shared dialog of IMPR1110 F1/F2/F3/F5, later IMPR1130; contract: spec 0.4) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))]))
    p.append(call('create_page_plug', [
        ('p_id', nid('region:RP', 1)), ('p_plug_name', q(TITLE)), ('p_region_name', q('RP')),
        ('p_region_css_classes', q('zatca-forms cg-form')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_BLANK')), ('p_plug_display_sequence', '10'),
        ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')), ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')),
        ('p_plug_comment', src('SUPPORT_ENTRY.RP (control block, canvas CANVAS1) / spec 3'))]))
    p.append(call('create_page_plug', [
        ('p_id', nid('region:RP_BUTTONS', 1)), ('p_plug_name', q('RP_BUTTONS')), ('p_region_name', q('RP_BUTTONS')),
        ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_BUTTONS')),
        ('p_plug_display_sequence', '20'), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')),
        ('p_plug_comment', src('SUPPORT_ENTRY.RP buttons AGREE / CANCEL / spec 3, 5'))]))
    for i, (name, label, pos, hot, icon, css, new_mode, comment) in enumerate(BUTTONS):
        cond = 'return %sSUPPORT_ENTRY.IS_NEW_LETTER(P_MODE => :P9001_P_MODE);' % ('' if new_mode else 'NOT ')
        p.append(call('create_page_button', [
            ('p_id', nid('button:' + name, 2)), ('p_button_sequence', str((i + 1) * 10)),
            ('p_button_plug_id', ref('region:RP_BUTTONS')), ('p_button_name', q(name)),
            ('p_button_static_id', q(name)), ('p_button_action', q('DEFINED_BY_DA')),
            ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')), ('p_button_template_id', fid('BUTTON')),
            ('p_button_is_hot', q('Y') if hot else None), ('p_button_image_alt', q(label)),
            ('p_button_position', q(pos)), ('p_button_condition', q(cond)), ('p_button_condition2', q('PLSQL')),
            ('p_button_condition_type', q('FUNCTION_BODY')), ('p_icon_css_classes', q(icon)),
            ('p_button_css_classes', q(css)), ('p_button_comment', src(comment + ' / spec 5'))]))
    for i, (name, disp, label, extra, comment) in enumerate(ITEMS):
        hidden = disp == 'NATIVE_HIDDEN'
        params = [('p_id', nid('pitem:' + name, 4)), ('p_name', q(name)), ('p_item_sequence', str((i + 1) * 10)),
                  ('p_item_plug_id', ref('region:RP')), ('p_prompt', q(label) if label else None),
                  ('p_display_as', q(disp))]
        params += [e for e in extra if e[0] not in ('p_attribute_01', 'p_attribute_02', 'p_attribute_03',
                                                     'p_attribute_04', 'p_attribute_05')]
        if not hidden:
            params += [('p_field_template', fid('LABEL_OPT')), ('p_item_template_options', q(ITEM_OPTS))]
        if item_icons.post_text(name, disp):
            params.append(('p_post_element_text', q(item_icons.post_text(name, disp))))
        params.append(('p_is_persistent', q('N')))
        params += [e for e in extra if e[0].startswith('p_attribute_')]
        params.append(('p_item_comment', src(comment)))
        p.append(call('create_page_item', params))
    p.append(call('create_page_computation', [
        ('p_id', nid('comp:HIJRI', 5)), ('p_computation_sequence', '10'), ('p_computation_item', q('P9001_HIJRI_DATE_FORMAT')),
        ('p_computation_point', q('BEFORE_HEADER')), ('p_computation_type', q('EXPRESSION')),
        ('p_computation_language', q('PLSQL')), ('p_computation', q('FORMS_APX.HIJRI_DATE_FORMAT')),
        ('p_computation_comment', src('SUPPORT_ENTRY.RP.LETTER_DT FormatMask MI-MM-RRRR -> FORMS_APX.HIJRI_DATE_FORMAT / spec 9'))]))
    p.append(call('create_page_process', [
        ('p_id', nid('proc:WNFI', 7)), ('p_process_sequence', '60'), ('p_process_point', q('BEFORE_HEADER')),
        ('p_process_type', q('NATIVE_PLSQL')), ('p_process_name', q('WHEN-NEW-FORM-INSTANCE')),
        ('p_process_sql_clob', q('SUPPORT_ENTRY.INIT_FORM(P_MODE => :P9001_P_MODE, P_CURR_PORT_CD => :P9001_P_CURR_PORT_CD, '
                                 'P_PORT_CD => :P9001_P_PORT_CD, P_PORT_NAME => :P9001_P_PORT_NAME, '
                                 'P_SUPP_TITLE_CD => :P9001_SUPP_TITLE_CD, P_SUPP_TITLE_NM => :P9001_SUPP_TITLE_NM, '
                                 'P_LETTER_NBR => :P9001_LETTER_NBR, P_LETTER_DT => :P9001_LETTER_DT);')),
        ('p_process_clob_language', q('PLSQL')), ('p_error_display_location', q('INLINE_IN_NOTIFICATION')),
        ('p_process_comment', src('SUPPORT_ENTRY.WHEN-NEW-FORM-INSTANCE (labels -> button conditions IS_NEW_LETTER) / spec 8'))]))
    p.append(call('create_page_process', [
        ('p_id', nid('proc:KEEP', 7)), ('p_process_sequence', '10'), ('p_process_point', q('AFTER_HEADER')),
        ('p_process_type', q('NATIVE_PLSQL')), ('p_process_name', q('G_LAST_PAGE KEEP')),
        ('p_process_sql_clob', q(':G_LAST_PAGE := NVL(:G_SUPPORT_ENTRY_CALLER, :G_LAST_PAGE);')),
        ('p_process_clob_language', q('PLSQL')), ('p_error_display_location', q('INLINE_IN_NOTIFICATION')),
        ('p_process_comment', src('f345 SCREEN ENTRY RESET on a shared page: OPEN_DIALOG set G_LAST_PAGE := 9001, this puts the caller back / spec 0.2, 8'))]))
    seq = 0
    for name, (tkind, tval), ev, actions, comment in DAS:
        seq += 10
        eparams = [('p_id', nid('da:' + name, 8)), ('p_name', q(name)), ('p_event_sequence', str(seq))]
        if tkind == 'ITEM':
            eparams += [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q(tval))]
        else:
            eparams += [('p_triggering_element_type', q('JQUERY_SELECTOR')), ('p_triggering_element', q(tval))]
        eparams += [('p_bind_type', q('bind')), ('p_bind_event_type', q(ev)), ('p_da_event_comment', src(comment))]
        p.append(call('create_page_da_event', eparams))
        for j, a in enumerate(actions):
            p.append(call('create_page_da_action', [
                ('p_id', nid('daa:%s:%d' % (name, j), 9)), ('p_event_id', ref('da:' + name)), ('p_event_result', q('TRUE')),
                ('p_action_sequence', str((j + 1) * 10)), ('p_execute_on_page_init', q('N'))] + a))
    seq += 10
    p.append(call('create_page_da_event', [
        ('p_id', nid('da:Hide', 8)), ('p_name', q('Hide')), ('p_event_sequence', str(seq)),
        ('p_bind_type', q('bind')), ('p_bind_event_type', q('ready')),
        ('p_da_event_comment', src('f345 AGR1100_SEARCH "Hide" (page 0 toolbar not used in a dialog; as IMPR1110 page 111002) / spec 0.6'))]))
    p.append(call('create_page_da_action', [
        ('p_id', nid('daa:Hide:0', 9)), ('p_event_id', ref('da:Hide')), ('p_event_result', q('TRUE')),
        ('p_action_sequence', '10'), ('p_execute_on_page_init', q('Y')), ('p_action', q('NATIVE_HIDE')),
        ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', fid('P0_ACTIONS'))]))
    out.append(block('application/pages/page_%05d' % PG, '\n'.join(p)))
    out.append("""prompt --application/end_environment
begin
wwv_flow_api.component_end;
end;
/
set verify on feedback on define on
prompt  ...done
""")
    text = client_condition.fix(items_to_submit.fix('\n'.join(out)))   # Items to Submit = every page item read (user rule 2026-11-25)
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

def selfcheck(text):
    problems = items_to_submit.check(text) + client_condition.check(text) + item_icons.check(text) + lov_apx.check(text)
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
    if re.search(r'pkg_|SUPPORT_ENTRY_APX\.', code, re.I): problems.append('page calls pkg_ / SUPPORT_ENTRY_APX')
    import forms_apx_helpers
    fx = forms_apx_helpers.forms_apx_members(ROOT)
    for name in set(re.findall(r'FORMS_APX\.([A-Z0-9_$]+)', code)):
        if name not in fx: problems.append('FORMS_APX.%s not in forms_apx.sql' % name)
    for bad in ('ON_DEMAND', 'p_javascript_file_urls', 'AJAX_FUNCTION', "NATIVE_JAVASCRIPT_CODE", 'p_security_scheme',
                'p_required_role', 'create_security_scheme', "'SUBMIT'"):
        if bad in code: problems.append('not allowed: ' + bad)
    defined = re.findall(r'[ ,]p_id=>wwv_flow_api\.id\((\d+)\)', text)
    if len(defined) != len(set(defined)): problems.append('duplicate p_id')
    ref_ids = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', ref_txt))
    if set(defined) & ref_ids: problems.append('ids clash with f345')
    for other in OTHER_EXPORTS:
        if os.path.exists(other):
            oid = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', open(other, encoding='utf-8').read()))
            if set(defined) & oid: problems.append('ids clash with ' + os.path.basename(other))
    missing = set(re.findall(r'wwv_flow_api\.id\((\d+)\)', text)) - set(defined) - ref_ids
    if missing: problems.append('ids used but defined nowhere: %s' % sorted(missing))
    for k, v in F345.items():
        if v not in ref_ids: problems.append('f345 id %s (%s) not in f345.sql' % (k, v))
    ref_items = set(names_of(ref_txt, 'create_flow_item'))
    other_items, other_lovs, other_groups = set(), set(), set()
    for other in OTHER_EXPORTS:
        if os.path.exists(other):
            t = open(other, encoding='utf-8').read()
            other_items |= set(names_of(t, 'create_flow_item'))
            other_lovs |= set(re.findall(r"p_lov_name=>'([^']+)'", t))
            other_groups |= set(re.findall(r"p_group_name=>'([^']+)'", t))
    for n in names_of(text, 'create_flow_item'):
        if n in ref_items | other_items: problems.append('application item %s already exists' % n)
    ref_lovs = set(re.findall(r"p_lov_name=>'([^']+)'", ref_txt))
    for n in re.findall(r"p_lov_name=>'([^']+)'", text):
        if n in ref_lovs | other_lovs: problems.append('LOV %s already exists' % n)
    for n in re.findall(r"p_group_name=>'([^']+)'", text):
        if n in other_groups or "p_group_name=>'%s'" % n in ref_txt: problems.append('page group %s already exists' % n)
    members = set(m.upper() for m in re.findall(r'(?m)^\s*(?:PROCEDURE|FUNCTION)\s+(\w+)', pkg_txt))
    for m in set(re.findall(r'SUPPORT_ENTRY\.([A-Z_0-9]+)\(', code)):
        if m not in members: problems.append('SUPPORT_ENTRY.%s not in support_entry_spec.sql' % m)
    # named parameters of SUPPORT_ENTRY calls exist in the spec
    spec_params = {}
    for m in re.finditer(r'(?ms)^\s*(?:PROCEDURE|FUNCTION)\s+(\w+)\s*\((.*?)\)\s*(?:RETURN\s+\w+\s*)?;', pkg_txt):
        spec_params[m.group(1).upper()] = set(re.findall(r'(\w+)\s+(?:IN\s+OUT|IN|OUT)\b', m.group(2)))
    for m in re.finditer(r'SUPPORT_ENTRY\.([A-Z_0-9]+)\(([^()]*)\)', code):
        given = set(re.findall(r'(\w+)\s*=>', m.group(2)))
        if m.group(1) in spec_params and given != spec_params[m.group(1)]:
            problems.append('call SUPPORT_ENTRY.%s: parameters %s, spec %s' % (m.group(1), sorted(given), sorted(spec_params[m.group(1)])))
    required_apps = {'G_LAST_PAGE', 'G_PORT_CD', 'G_SUPP_TITLE_CD', 'G_LETTER_NBR', 'G_LETTER_DT'}
    for n in required_apps - ref_items - other_items:
        problems.append('application item %s exists neither in f345 nor in the IMPR1110 export' % n)
    page_items = set(names_of(text, 'create_page_item'))
    app_items = ref_items | other_items | set(names_of(text, 'create_flow_item'))
    for b in set(re.findall(r"(?<![\w$&])[:](P\d+_\w+|G_\w+)\b", code)):
        if b not in page_items | app_items: problems.append('bind :%s has no item' % b)
    for b in re.findall(r"p_attribute_0[23]=>'([^']+)'", code):
        for i in b.split(','):
            if re.match(r'P\d+_', i) and i not in page_items: problems.append('FOS item %s missing' % i)
    for b in re.findall(r"p_triggering_element=>'([^']+)'", code):
        for sel in b.split(','):
            sel = sel.strip()
            if sel.startswith('#') and sel[1:] not in re.findall(r"p_button_static_id=>'([^']+)'", text):
                problems.append('selector %s has no button static id' % sel)
            if re.match(r'P\d+_', sel) and sel not in page_items: problems.append('DA item %s missing' % sel)
    if text.count('\nbegin\n') != text.count('\nend;\n/'): problems.append('begin/end not balanced')
    counts = {k: len(re.findall(r'wwv_flow_api\.%s\(' % k, text)) for k in [
        'create_page', 'create_page_plug', 'create_page_item', 'create_page_button', 'create_page_validation',
        'create_page_process', 'create_page_da_event', 'create_page_da_action', 'create_page_computation',
        'create_list_of_values', 'create_list_of_values_cols', 'create_flow_item', 'create_page_group']}
    counts['NATIVE_JAVASCRIPT_CODE actions'] = text.count("NATIVE_JAVASCRIPT_CODE")
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
    path = os.path.join(OUT_DIR, 'f%s_support_entry_import.sql' % vals['app_id'])
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(out)
    print('import-ready copy:', path)

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    os.makedirs(OUT_DIR, exist_ok=True)
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
