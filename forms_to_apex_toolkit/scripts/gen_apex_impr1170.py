# -*- coding: utf-8 -*-
"""
gen_apex_impr1170.py - step 04: APEX 21.2 component export of IMPR1170 (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c / 4d, docs/f345_reference_standard.md).
Helpers (q, lit, nid, call, page_item, da, process, ig_region, selfcheck, ready_copy) are those of
scripts/gen_apex_impr1160.py (page_item with read-only ALWAYS of scripts/gen_apex_impr1150.py); the query-only Form
region, the request EXECUTE_QUERY and the read-only detail grid follow scripts/gen_apex_impr1150.py.

Design: analysis/IMPR1170/IMPR1170_apex_page_spec.md. The design data is in this file (ITEMS, HIDDEN, VALIDATIONS,
PROCESSES, COMPUTATIONS, DAS, OWNERS_SQL, SEARCH_SQL): change it here, re-run, and keep the spec in step.

Reads
  apex/Reference/f345.sql             template ids, existing ids / items / LOVs (checks)
  apex/*/f345_*.sql                   the other component exports (page group IMPR, LOV_COMM_RGSTRTN_TYPE, id clashes)
  plsql/IMPR1170/impr1170_spec.sql    members of package IMPR1170 (checks)
Writes
  apex/IMPR1170/f345_impr1170.sql     component export, REVIEW BEFORE IMPORT (4 placeholders)
  apex/IMPR1170/f<app>_impr1170_import.sql  with --workspace-id --app-id --id-offset --schema
  work/IMPR1170/step04/uncertain.json parameters f345 does not show (import_notes.md)

Declarative: query-only native Form region on MCI_DATA (key CR_NBR), read-only IG MCI_OWNERS (detail by CR_NBR),
a change DA that submits the request EXECUTE_QUERY, processes = one call into IMPR1170 / FORMS_APX. No JavaScript
file, no AJAX callback. IDs are deterministic: re-running gives the same file.

Usage (from forms_to_apex_toolkit):  python3 -I scripts/gen_apex_impr1170.py [--workspace-id=.. --app-id=.. --id-offset=.. --schema=..]
"""
import os, re, sys, json, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
import number_only      # Number Field items: CSS class number_only + one page-load handler on page 0
import functions_drawer # the FUNCS region is on page 0, never on a form page
import item_icons       # Post Text icon next to every entry item
import items_to_submit  # every page item a query / LOV / FOS call reads is in its Items to Submit
import lov_apx          # shared LOVs: function body returning SQL, code in LOV_APX (CLAUDE.md 4d)
import forms_apx_helpers
import parameter_names

REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')
PKG = os.path.join(ROOT, 'plsql', 'IMPR1170', 'impr1170_spec.sql')
OUT = os.path.join(ROOT, 'apex', 'IMPR1170', 'f345_impr1170.sql')
OTHER_EXPORTS = sorted(f for f in glob.glob(os.path.join(ROOT, 'apex', '*', 'f345_*.sql'))
                       if os.sep + 'IMPR1170' + os.sep not in f and os.sep + 'Reference' + os.sep not in f)
DATE, STAMP = '2026-11-25', '20261125000000'
FORM = 'IMPR1170'
PG, PG_SEARCH = 1170, 117001
PI = 'P1170_'
SHARED_BASE = 9170                 # IMPR1110 9000, IMPR1116 9116, ... IMPR1150 9150, IMPR1160 9160 (no shared component here)
IMPR1110_IDS = dict(PAGE_GROUP_IMPR='900001000010')   # created by the IMPR1110 export: reused
REUSED_LOVS = ['LOV_COMM_RGSTRTN_TYPE']              # created by the IMPR1130 export: reused by name

F345 = dict(
    UI='11622010846008869795', PAGE_MAIN='11622270914969205733', REGION_HERO='11621859120066869682',
    REGION_FORM='11621909206693869707', REGION_GRID='11621913486616869708',
    LABEL_REQ='11621984380233869750', LABEL_OPT='11621983529556869749',
    BUTTON='11621986167597869752', P0_ACTIONS='73488102084440079322')
ITEM_OPTS = '#DEFAULT#:t-Form-fieldContainer--stretchInputs'
HIJRI_MASK = '&P1170_HIJRI_DATE_FORMAT.'
HIJRI_PLACEHOLDER = 'placeholder="%s"' % 'سنة-شهر-يوم'   # not used: no Hijri entry item on this page
TITLE = 'بيانات السجل التجارى من وزارة التجارة'

# ============================================================================= design data (spec sections 4-10)
RECORD = ':P0_PAGE_PK IS NOT NULL'   # a record is shown (Forms record status QUERY): CR_NBR Update Allowed = false
DO = 'NATIVE_DISPLAY_ONLY'
# items of page 1170 in canvas order (rows by Y, right to left by X): name, column, type, label, data type, newline, span, extra
ITEMS = [
    ('CR_NBR', 'CR_NBR', 'NATIVE_TEXT_FIELD', 'الرقم الموحد للسجل التجاري', 'VARCHAR2', True, 4,
     dict(req=True, pk=True, maxlen=10, read_only=RECORD,
          src='MCI_DATA.CR_NBR (CGSO$CHAR_ARB, Required, Update Allowed = false; KEY-NEXT-ITEM look-up / web service; '
              'Form region primary key = P0_PAGE_PK)')),
    ('CR_TYPE', 'CR_TYPE', 'NATIVE_SELECT_LIST', 'نوع السجل التجارى', 'VARCHAR2', False, 4,
     dict(lov='LOV_COMM_RGSTRTN_TYPE', lov_null='NO', default='1', read_only='ALWAYS',
          src='MCI_DATA.CR_TYPE (CGSO$COMBO_DO, not navigable, initial value 1; CGDV$POPULATE_DYNAMIC_LISTS CG_REF_CODES '
              'COMM_RGSTRTN_TYPE; XML values 1 رئيسي, 0 فرعي, 2 فرعي)')),
    ('MAIN_CR_NBR', 'MAIN_CR_NBR', DO, 'السجل التجارى الرئيسى', 'VARCHAR2', True, 4, dict(src='MCI_DATA.MAIN_CR_NBR')),
    ('CR_STATUS', 'CR_STATUS', DO, 'حالة السجل التجارى', 'VARCHAR2', False, 2, dict(src='MCI_DATA.CR_STATUS')),
    ('CR_STAT_DESC', None, DO, None, None, False, 2, dict(src='MCI_DATA.CR_STAT_DESC (non-database; POST-QUERY)')),
    ('CR_ISSUE_DATE', 'CR_ISSUE_DATE', DO, 'تاريخ انشاء السجل التجارى', 'DATE', True, 4,
     dict(mask=HIJRI_MASK, src='MCI_DATA.CR_ISSUE_DATE (CGSO$HDATE_ARB_DO Hijri MI-MM-YYYY; WHEN-VALIDATE-ITEM unreachable)')),
    ('CR_CITY_AR', 'CR_CITY_AR', DO, 'اسم المدينة', 'VARCHAR2', True, 4, dict(src='MCI_DATA.CR_CITY_AR')),
    ('CR_CAPITAL', 'CR_CAPITAL', DO, 'رأس المال', 'NUMBER', False, 4, dict(src='MCI_DATA.CR_CAPITAL')),
    ('CR_NAME_AR', 'CR_NAME_AR', DO, 'الاسم التجارى', 'VARCHAR2', True, 8, dict(src='MCI_DATA.CR_NAME_AR')),
    ('LEGAL_TYPE_A', 'LEGAL_TYPE_A', DO, 'نوع المنشأة', 'VARCHAR2', True, 4, dict(src='MCI_DATA.LEGAL_TYPE_A')),
    ('LEGAL_TYPE_E', 'LEGAL_TYPE_E', DO, 'نوع المنشأةEN', 'VARCHAR2', False, 4, dict(src='MCI_DATA.LEGAL_TYPE_E')),
    ('CR_PHONE_NO', 'CR_PHONE_NO', DO, 'التليفون', 'VARCHAR2', True, 4, dict(src='MCI_DATA.CR_PHONE_NO')),
    ('CR_FAX_NO', 'CR_FAX_NO', DO, 'فاكس', 'VARCHAR2', False, 4, dict(src='MCI_DATA.CR_FAX_NO')),
    ('CR_ADDRESS', 'CR_ADDRESS', DO, 'العنوان', 'VARCHAR2', True, 8, dict(src='MCI_DATA.CR_ADDRESS')),
    ('CR_ACTIVITIES', 'CR_ACTIVITIES', DO, 'النشاط التجارى', 'VARCHAR2', True, 8, dict(src='MCI_DATA.CR_ACTIVITIES')),
]
# not displayed: name, column, data type, kind, mask, value protected, source
HIDDEN = [
    ('CR_EXPIRY_DATE', 'CR_EXPIRY_DATE', 'DATE', DO, HIJRI_MASK, None,
     'MCI_DATA.CR_EXPIRY_DATE (Hijri, Visible = false; WHEN-VALIDATE-ITEM unreachable)'),
    ('MODULE_ID', None, None, 'NATIVE_HIDDEN', None, 'Y', 'f345 Page Functions: P<page>_MODULE_ID'),
    ('HIJRI_DATE_FORMAT', None, None, 'NATIVE_HIDDEN', None, 'Y', 'FORMS_APX.HIJRI_DATE_FORMAT (format mask of the Hijri dates)'),
    ('HERO_TITLE', None, None, 'NATIVE_HIDDEN', None, 'Y', 'f345 hero title (FORMS_APX.HEADER_TITLE)'),
]
EXECUTE_QUERY = ":REQUEST = 'EXECUTE_QUERY'"
# processes: point, seq, name, code, condition (PL/SQL expression | NEVER | None), source, success message
PROCESSES = [
    ('BEFORE_HEADER', 10, 'New', None, 'NEVER', 'f345 session setup copied from AGR1100 (condition Never) / standard 6', None),
    ('BEFORE_HEADER', 20, 'P0_PAGE_PK CHECK', 'IMPR1170.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK);', None,
     'f345 key (CR_NBR of a cached MCI_DATA row)', None),
    ('BEFORE_HEADER', 40, 'PARAMETERS',
     ":P1170_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1170_MODULE_ID, FORM_NAME => 'IMPR1170');", None,
     'f345 module id of the Page Functions list', None),
    ('BEFORE_HEADER', 70, 'P0_PAGE_PK', ':P1170_CR_NBR := :P0_PAGE_PK;', None, 'f345 (key = CR_NBR)', None),
    ('BEFORE_HEADER', 80, 'Initialize form', None, None, 'block MCI_DATA query (DEFAULT_WHERE CR_NBR = key)', None),
    ('BEFORE_HEADER', 82, 'POST-QUERY',
     'IMPR1170.POST_QUERY(P_CR_STATUS => :P1170_CR_STATUS, P_CR_STAT_DESC => :P1170_CR_STAT_DESC);', RECORD,
     'MCI_DATA.POST-QUERY', None),
    ('BEFORE_HEADER', 100, 'HEADER TITLE',
     "FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1170_MODULE_ID, P_HERO_TITLE => :P1170_HERO_TITLE, "
     "DEFAULT_TITLE => '%s');" % TITLE, None, 'f345 hero title (OLB block TITLE)', None),
    ('AFTER_SUBMIT', 10, 'CR_NBR KEY-NEXT-ITEM',
     'IMPR1170.CR_NBR_KEY_NEXT_ITEM(P_CR_NBR => :P1170_CR_NBR, P_PAGE_PK => :P0_PAGE_PK);', EXECUTE_QUERY,
     'MCI_DATA.CR_NBR.KEY-NEXT-ITEM (cache of today or MCI web service, then SET_BLOCK_PROPERTY DEFAULT_WHERE + EXECUTE_QUERY)',
     None),
    ('AFTER_SUBMIT', 20, 'PRE-INSERT', 'IMPR1170.PRE_INSERT;', ":REQUEST = 'CREATE'",
     'block MCI_DATA: no insert from this page (page 0 CREATE refused, spec 0 #3)', None),
    ('AFTER_SUBMIT', 30, 'PRE-UPDATE', 'IMPR1170.PRE_UPDATE;', ":REQUEST = 'SAVE'",
     'block MCI_DATA Update Allowed = false (page 0 SAVE refused)', None),
    ('AFTER_SUBMIT', 40, 'PRE-DELETE', 'IMPR1170.PRE_DELETE;', ":REQUEST = 'DELETE'",
     'block MCI_DATA Delete Allowed = false (KEY-DELREC, page 0 DELETE refused)', None),
]
COMPUTATIONS = [   # item, point, expression, source
    ('HIJRI_DATE_FORMAT', 'BEFORE_HEADER', 'FORMS_APX.HIJRI_DATE_FORMAT',
     'Hijri date format from one place: Application Setting HIJRI_DATE_FORMAT (Forms mask MI-MM-YYYY)'),
]
# dynamic actions: name, event, selection, client condition, fire on init, actions, source
DAS = [
    ('CR_NBR KEY-NEXT-ITEM', 'change', ('ITEM', 'P1170_CR_NBR'), ('NOT_NULL', None), False,
     [dict(action='SUBMIT', request='EXECUTE_QUERY')],
     'MCI_DATA.CR_NBR.KEY-NEXT-ITEM (Submit Page EXECUTE_QUERY -> process CR_NBR KEY-NEXT-ITEM; a change also fires with the mouse)'),
]
OWNERS_SQL = '\n'.join([
    '-- block MCI_OWNERS: relation CGFK$MCI_OWNER_MCI_DATA_FK (MCI_DATA.CR_NBR = MCI_OWNERS.CR_NBR), query only;',
    '-- MCI_OWNERS.POST-QUERY (RELATION_DESC from MCI_RELATION_TYPES, WHEN OTHERS -> NULL) as an outer join',
    'SELECT o.owner_isn, o.cr_nbr, o.owner_name, o.national_id, o.owner_nationality_ar, o.owner_nationality_en,',
    '       o.relation_type, rt.relation_name AS relation_desc',
    '  FROM mci_owners o, mci_relation_types rt',
    ' WHERE o.cr_nbr = :P1170_CR_NBR',
    '   AND rt.relation_cd (+) = o.relation_type'])
OWNERS_COLUMNS = [   # name, heading, data type, kind (X order of the Forms canvas, right to left)
    ('OWNER_ISN', None, 'NUMBER', 'pk'), ('CR_NBR', None, 'VARCHAR2', 'hidden'),
    ('OWNER_NAME', 'اسم المالك', 'VARCHAR2', 'text'), ('NATIONAL_ID', 'رقم الهوية', 'VARCHAR2', 'text'),
    ('OWNER_NATIONALITY_AR', 'جنسية المالك', 'VARCHAR2', 'text'), ('OWNER_NATIONALITY_EN', 'جنسية المالكEN', 'VARCHAR2', 'text'),
    ('RELATION_TYPE', None, 'NUMBER', 'hidden'), ('RELATION_DESC', 'العلاقة', 'VARCHAR2', 'text')]
SEARCH_SQL = '\n'.join([
    '-- one search text over every shown column; no rows until a search is made (Forms Enter-Query). The block has no',
    '-- WHERE clause: every cached registration (MCI_DATA is national, not per port). POST-QUERY status text as outer join.',
    'SELECT x.*',
    '  FROM (SELECT md.cr_nbr, md.cr_name_ar, ct.rv_meaning AS cr_type_name, md.main_cr_nbr,',
    '               st.status_desc AS cr_stat_desc,',
    '               TO_CHAR(md.cr_issue_date, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS cr_issue_date,',
    '               md.cr_city_ar, md.legal_type_a',
    '          FROM mci_data md, cg_ref_codes ct, mci_bus_id_status st',
    "         WHERE ct.rv_domain (+) = 'COMM_RGSTRTN_TYPE'",
    '           AND ct.rv_low_value (+) = TO_CHAR(md.cr_type)',
    '           AND st.bus_id_status (+) = md.cr_status) x',
    ' WHERE :P117001_SEARCH IS NOT NULL',
    "   AND INSTR(UPPER(x.cr_nbr || '|' || x.cr_name_ar || '|' || x.cr_type_name || '|' || x.main_cr_nbr || '|' ||",
    "                   x.cr_stat_desc || '|' || x.cr_issue_date || '|' || x.cr_city_ar || '|' || x.legal_type_a),",
    '             UPPER(TRIM(:P117001_SEARCH))) > 0'])
SEARCH_COLUMNS = [   # name, heading, data type, kind
    ('CR_NBR', 'الرقم الموحد للسجل التجاري', 'VARCHAR2', 'link'), ('CR_NAME_AR', 'الاسم التجارى', 'VARCHAR2', 'text'),
    ('CR_TYPE_NAME', 'نوع السجل التجارى', 'VARCHAR2', 'text'), ('MAIN_CR_NBR', 'السجل التجارى الرئيسى', 'VARCHAR2', 'text'),
    ('CR_STAT_DESC', 'حالة السجل التجارى', 'VARCHAR2', 'text'), ('CR_ISSUE_DATE', 'تاريخ انشاء السجل التجارى', 'VARCHAR2', 'text'),
    ('CR_CITY_AR', 'اسم المدينة', 'VARCHAR2', 'text'), ('LEGAL_TYPE_A', 'نوع المنشأة', 'VARCHAR2', 'text')]

# ============================================================================= helpers (as gen_apex_impr1130.py)
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
    """deterministic id <page or shared base><kind 2><seq 6>"""
    if key in _ids:
        return _ids[key]
    page = key.split(':')[0]
    base = int(page) if page.isdigit() and page != str(SHARED_BASE) else SHARED_BASE
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
UNCERTAIN = set()

def page_item(page, plug_key, seq, it, form_region=False):
    """create_page_item: attributes as gen_apex_impr1140.page_item (+ Hijri text field and textarea of gen_apex_impr1110)
       it: name, kind, label, column, data_type, pk, req, lov, lov_null, default, mask, maxlen, read_only, hijri, send,
           value_protected, protect, span, newline, hidden_column, comment"""
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
    p += [('p_item_default', q(it.get('default'))), ('p_prompt', q(it.get('label'))), ('p_format_mask', q(it.get('mask')))]
    if form_region and it.get('column'):
        p += [('p_source', q(it['column'])), ('p_source_type', q('REGION_SOURCE_COLUMN'))]
    p.append(('p_display_as', q(k)))
    if it.get('lov'):
        p += [('p_named_lov', q(it['lov'])), ('p_lov_display_null', q(it.get('lov_null', 'YES')))]
        if it.get('lov_null', 'YES') == 'YES' and k == 'NATIVE_SELECT_LIST':
            p.append(('p_lov_null_text', q('-')))
    if k in ('NATIVE_TEXT_FIELD', 'NATIVE_NUMBER_FIELD', 'NATIVE_POPUP_LOV', 'NATIVE_TEXTAREA'):
        p.append(('p_cSize', '30'))
    if it.get('maxlen') and k in ('NATIVE_TEXT_FIELD', 'NATIVE_NUMBER_FIELD', 'NATIVE_POPUP_LOV', 'NATIVE_TEXTAREA'):
        p.append(('p_cMaxlength', str(it['maxlen'])))
    if k == 'NATIVE_TEXTAREA':
        p.append(('p_cHeight', '3'))
    css = number_only.add_class(None) if k == 'NATIVE_NUMBER_FIELD' else ('hijri-date-default' if it.get('hijri') else None)
    if css:
        p.append(('p_tag_css_classes', q(css)))
    if item_icons.post_text(name, k):
        p.append(('p_post_element_text', q(item_icons.post_text(name, k))))
    if k != 'NATIVE_HIDDEN':
        p.append(('p_begin_on_new_line', q('YES' if it.get('newline', True) else 'NO')))
        if it.get('span'):
            p.append(('p_colspan', str(it['span'])))
        if it.get('hidden_column'):
            p.append(('p_grid_column_css_classes', q('u-hidden')))
    ro = it.get('read_only')
    if ro == 'ALWAYS':
        p.append(('p_read_only_when_type', q('ALWAYS')))
    elif ro:
        p += [('p_read_only_when', q(ro)), ('p_read_only_when2', q('PLSQL')), ('p_read_only_when_type', q('EXPRESSION'))]
        UNCERTAIN.add('p_read_only_when2 => PLSQL with p_read_only_when_type => EXPRESSION (f345 shows the pattern only for p_display_when)')
    if k != 'NATIVE_HIDDEN':
        p += [('p_field_template', fid('LABEL_REQ' if it.get('req') else 'LABEL_OPT')), ('p_item_template_options', q(ITEM_OPTS))]
    if it.get('hijri'):
        p.append(('p_tag_attributes', q(HIJRI_PLACEHOLDER)))
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
    elif k == 'NATIVE_TEXTAREA':
        p += [('p_attribute_01', q('Y')), ('p_attribute_02', q('N')), ('p_attribute_03', q('N')), ('p_attribute_04', q('BOTH'))]
    elif k == 'NATIVE_DISPLAY_ONLY':
        # p_attribute_01 = Send On Page Submit (N: server value set by processes / FOS; Y: PORT_CD read by FOS)
        p += [('p_attribute_01', q('Y' if it.get('send') else 'N')), ('p_attribute_02', q('VALUE')), ('p_attribute_04', q('N')),
              ('p_attribute_05', q('PLAIN'))]
    elif k == 'NATIVE_HIDDEN':
        p += [('p_attribute_01', q(it.get('value_protected') or 'Y'))]
    p.append(('p_item_comment', q(it.get('comment'))))
    return call('create_page_item', p)

def da(page, n, name, event, selection, condition, init, actions, source):
    ek = '%s:da:%s' % (page, name)
    nid(ek, 8)
    prm = [('p_id', ref(ek)), ('p_name', q(name)), ('p_event_sequence', str(n * 10))]
    if selection and selection[0] == 'ITEM':
        prm += [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q(selection[1]))]
    elif selection and selection[0] == 'DOCUMENT':
        prm += [('p_triggering_element_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_element', q('document'))]
    if condition:
        prm.append(('p_triggering_condition_type', q(condition[0])))
        if condition[1]:
            prm.append(('p_triggering_expression', q(condition[1])))
        UNCERTAIN.add('DA client-side condition p_triggering_condition_type / p_triggering_expression (not in f345)')
    if event.startswith('custom:'):
        prm += [('p_bind_type', q('bind')), ('p_bind_event_type', q('custom')), ('p_bind_event_type_custom', q(event[7:]))]
    else:
        prm += [('p_bind_type', q('bind')), ('p_bind_event_type', q(event))]
    prm.append(('p_da_event_comment', src('%s.%s / spec 10' % (FORM, source))))
    out = [call('create_page_da_event', prm)]
    seq = {'TRUE': 0, 'FALSE': 0}
    for a in actions:
        res = a.get('result', 'TRUE')
        seq[res] += 10
        ak = '%s:daa:%s:%s:%d' % (page, name, res, seq[res])
        nid(ak, 9)
        base = [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q(res)),
                ('p_action_sequence', str(seq[res])), ('p_execute_on_page_init', q('Y' if init else 'N'))]
        act = a['action']
        if act == 'FOS':
            base += [('p_action', q('PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE')), ('p_attribute_01', lit(a['code'])),
                     ('p_attribute_02', q(','.join(a['submit']) or None)), ('p_attribute_03', q(','.join(a['ret']) or None)),
                     ('p_attribute_05', q('#SQLERRM#')), ('p_attribute_15', q('suppressChangeEvent:escape-message')),
                     ('p_wait_for_result', q('Y'))]
        elif act == 'SUBMIT':
            base += [('p_action', q('NATIVE_SUBMIT_PAGE')), ('p_attribute_01', q(a['request'])), ('p_attribute_02', q('Y'))]
            UNCERTAIN.add('NATIVE_SUBMIT_PAGE attributes 01 / 02 (not in f345)')
        elif act in ('NATIVE_HIDE', 'NATIVE_SHOW', 'NATIVE_SET_FOCUS'):
            base += [('p_action', q(act)), ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q(a['items']))]
            if act == 'NATIVE_HIDE':
                base.append(('p_attribute_01', q('N')))
            UNCERTAIN.add('NATIVE_SHOW / NATIVE_HIDE / NATIVE_SET_FOCUS with p_affected_elements items (f345 hides a region only)')
        elif act == 'NATIVE_ALERT':
            base += [('p_action', q('NATIVE_ALERT')), ('p_attribute_01', q(a['text']))]
            UNCERTAIN.add('NATIVE_ALERT with the text in p_attribute_01 (as page 1140; not in f345)')
        else:
            raise ValueError(act)
        out.append(call('create_page_da_action', base))
    return '\n'.join(out)

def process(key, seq, point, name, code, cond, s, ptype='NATIVE_PLSQL', extra=None, region=None, success=None):
    nid(key, 7)
    prm = [('p_id', ref(key)), ('p_process_sequence', str(seq)), ('p_process_point', q(point))]
    if region:
        prm.append(('p_region_id', ref(region)))
    prm += [('p_process_type', q(ptype)), ('p_process_name', q(name)),
            ('p_process_sql_clob', lit(code) if code else None), ('p_process_clob_language', q('PLSQL') if code else None)]
    prm += (extra or [])
    prm.append(('p_error_display_location', q('INLINE_IN_NOTIFICATION')))
    if cond == 'NEVER':
        prm.append(('p_process_when_type', q('NEVER')))
    elif cond:
        prm += [('p_process_when', q(cond)), ('p_process_when_type', q('EXPRESSION')), ('p_process_when2', q('PLSQL'))]
    if success:
        prm.append(('p_process_success_message', q(success)))
    prm.append(('p_process_comment', src(s)))
    return call('create_page_process', prm)

def ig_region(page, rk, sql, items_submit, cols, uid, empty_msg, search, comment, name, static_id, seq, link=None):
    """read-only Interactive Grid (search grid 115001 / documents grid IMPORTER_DOCS)"""
    out = []
    nid(rk, 1)
    out.append(call('create_page_plug', [
        ('p_id', ref(rk)), ('p_plug_name', q(name)), ('p_region_name', q(static_id)),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', str(seq)), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(sql)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q(items_submit)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src(comment))]))
    filt = [('p_enable_filter', 'true'), ('p_filter_operators', q('C:S:CASE_INSENSITIVE:REGEXP')), ('p_filter_is_required', 'false'),
            ('p_filter_text_case', q('MIXED')), ('p_filter_lov_type', q('NONE')), ('p_use_as_row_header', 'false'),
            ('p_enable_sort_group', 'true'), ('p_enable_control_break', 'true'), ('p_enable_hide', 'true'),
            ('p_is_primary_key', 'false'), ('p_duplicate_value', 'true'), ('p_include_in_export', 'true')]
    for i, (c, h, dt, kind) in enumerate(cols):
        key = '%s:col:%s' % (rk, c)
        nid(key, 2)
        prm = [('p_id', ref(key)), ('p_name', q(c)), ('p_source_type', q('DB_COLUMN')), ('p_source_expression', q(c)),
               ('p_data_type', q(dt)), ('p_is_query_only', 'false')]
        if kind == 'pk':
            prm += [('p_item_type', q('NATIVE_HIDDEN')), ('p_display_sequence', str((i + 1) * 10)), ('p_attribute_01', q('N')),
                    ('p_use_as_row_header', 'false'), ('p_enable_sort_group', 'false'), ('p_is_primary_key', 'true'),
                    ('p_duplicate_value', 'true'), ('p_include_in_export', 'false')]
        elif kind == 'hidden':
            prm += [('p_item_type', q('NATIVE_HIDDEN')), ('p_display_sequence', str((i + 1) * 10)), ('p_attribute_01', q('N')),
                    ('p_use_as_row_header', 'false'), ('p_enable_sort_group', 'false'), ('p_is_primary_key', 'false'),
                    ('p_duplicate_value', 'true'), ('p_include_in_export', 'false')]
        elif kind == 'link':
            prm += [('p_item_type', q('NATIVE_LINK')), ('p_heading', q(h)), ('p_heading_alignment', q('CENTER')),
                    ('p_display_sequence', str((i + 1) * 10)), ('p_value_alignment', q('CENTER')),
                    ('p_link_target', q(link)), ('p_link_text', q('&%s.' % c)), ('p_link_attributes', q('target="_top"'))] + filt
        else:
            prm += [('p_item_type', q('NATIVE_DISPLAY_ONLY')), ('p_heading', q(h)), ('p_heading_alignment', q('CENTER')),
                    ('p_display_sequence', str((i + 1) * 10)), ('p_value_alignment', q('CENTER')),
                    ('p_attribute_02', q('VALUE')), ('p_attribute_05', q('PLAIN'))] + filt
        out.append(call('create_region_column', prm))
    gk, rpk, vk = rk + ':ig', rk + ':igr', rk + ':igv'
    nid(gk, 3); nid(rpk, 3); nid(vk, 3)
    out.append(call('create_interactive_grid', [
        ('p_id', ref(gk)), ('p_internal_uid', uid), ('p_is_editable', 'false'), ('p_lazy_loading', 'true' if search else 'false'),
        ('p_requires_filter', 'false'), ('p_select_first_row', 'true'), ('p_fixed_row_height', 'true'), ('p_pagination_type', q('SET')),
        ('p_show_total_row_count', 'false' if search else 'true'), ('p_no_data_found_message', q(empty_msg)),
        ('p_show_toolbar', 'true'),
        ('p_toolbar_buttons', q('ACTIONS_MENU:RESET' if search else 'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET')),
        ('p_enable_save_public_report', 'false'), ('p_enable_subscriptions', 'true'), ('p_enable_flashback', 'true'),
        ('p_define_chart_view', 'true'), ('p_enable_download', 'true'), ('p_download_formats', q('CSV:HTML:XLSX:PDF')),
        ('p_enable_mail_download', 'true'), ('p_fixed_header', q('PAGE')), ('p_show_icon_view', 'false'), ('p_show_detail_view', 'false')]))
    out.append(call('create_ig_report', [('p_id', ref(rpk)), ('p_interactive_grid_id', ref(gk)), ('p_static_id', q(uid[:-1] + '2')),
                                         ('p_type', q('PRIMARY')), ('p_default_view', q('GRID')),
                                         ('p_show_row_number', 'false'), ('p_settings_area_expanded', 'true')]))
    out.append(call('create_ig_report_view', [('p_id', ref(vk)), ('p_report_id', ref(rpk)), ('p_view_type', q('GRID')),
                                              ('p_stretch_columns', 'true'), ('p_srv_exclude_null_values', 'false'),
                                              ('p_srv_only_display_columns', 'true'), ('p_edit_mode', 'false')]))
    for i, (c, h, dt, kind) in enumerate(cols):
        key = '%s:igc:%s' % (rk, c)
        nid(key, 3)
        out.append(call('create_ig_report_column', [('p_id', ref(key)), ('p_view_id', ref(vk)), ('p_display_seq', str((i + 1) * 10)),
                                                    ('p_column_id', ref('%s:col:%s' % (rk, c))),
                                                    ('p_is_visible', 'false' if kind in ('pk', 'hidden') else 'true'),
                                                    ('p_is_frozen', 'false')]))
    return out

# ============================================================================= generation
def gen():
    out = []
    W = out.append
    W('''-- =============================================================================
-- REVIEW BEFORE IMPORT
-- File        : apex/IMPR1170/f345_impr1170.sql
-- Generated by: Claude Code (scripts/gen_apex_impr1170.py, step 04) from
--               analysis/IMPR1170/IMPR1170_apex_page_spec.md, %s, form IMPR1170 (module IMPR1170_CNTRL)
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / 4c, docs/f345_reference_standard.md 3-9: query-only native Form region on MCI_DATA
--               (key CR_NBR), read-only IG of the owners MCI_OWNERS, a change DA that submits the request
--               EXECUTE_QUERY, one-line calls into package IMPR1170 (version 001) and FORMS_APX (004).
--               No JavaScript file, no AJAX callback process.
-- Contents    : component export INTO the application installed from f345: pages 1170 (main) and
--               117001 (search); no shared component. Needs the IMPR1110 export (page group IMPR, Application
--               Setting HIJRI_DATE_FORMAT) and the IMPR1130 export (LOV_COMM_RGSTRTN_TYPE) imported first.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR1170/import_notes.md
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

    # ---------------------------------------------------------------- page 1170
    P = []
    A = P.append
    R = '1170:plug:MCI_DATA'
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG)
    A(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM)), ('p_alias', q(FORM)),
        ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_step_template', fid('PAGE_MAIN')),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1170.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR1170.fmb - spec 2 / f345 standard 4'))
    hero = ('<div class="cg-hero-row"><div class="cg-hero-top"><span class="cg-hero-ic fa fa-building-o" aria-hidden="true"></span>'
            '<div><div class="cg-hero-k">المستوردون</div><div class="cg-hero-t">&P1170_HERO_TITLE.</div>'
            '<div class="cg-hero-d">بيانات السجل التجاري وملاكه من خدمة الربط مع وزارة التجارة</div></div></div></div>')
    nid('1170:plug:HERO', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1170:plug:HERO')), ('p_plug_name', q('الهيدر')), ('p_region_name', q('MCI_DATA_HERO')),
        ('p_region_css_classes', q('cg-hero')), ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '5'), ('p_plug_source', q(hero)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src('IMPR1170.TITLE (OLB) -> f345 hero / spec 3'))]))
    nid(R, 1)
    A(call('create_page_plug', [
        ('p_id', ref(R)), ('p_plug_name', q('بيانات السجل التجارى')), ('p_region_name', q('MCI_DATA')),
        ('p_region_css_classes', q('zatca-forms cg-form cg-card')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_FORM')), ('p_plug_display_sequence', '10'), ('p_query_type', q('TABLE')),
        ('p_query_table', q('MCI_DATA')), ('p_is_editable', 'false'),
        ('p_plug_source_type', q('NATIVE_FORM')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1170.MCI_DATA (single record, query only: Update / Delete Allowed = false, insert '
                               'refused; key CR_NBR = P0_PAGE_PK) / spec 3'))]))
    UNCERTAIN.add('NATIVE_FORM region with p_query_type TABLE and p_is_editable false (query only; IMPR1150 uses SQL + false)')
    P.extend(ig_region(PG, '1170:plug:MCI_OWNERS', OWNERS_SQL, 'P1170_CR_NBR', OWNERS_COLUMNS,
                       '117000000101', 'لا يوجد ملاك لهذا السجل التجاري', False,
                       'IMPR1170.MCI_OWNERS (4 records, query only; detail of MCI_DATA by CR_NBR; POST-QUERY relation name) / spec 3',
                       'ملاك السجل التجارى', 'MCI_OWNERS', 20))
    UNCERTAIN.add('read-only IG MCI_OWNERS: p_is_editable false with p_lazy_loading false (as the IMPORTER_DOCS grid of page 1150)')
    nid('1170:branch:QUERY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1170:branch:QUERY')), ('p_branch_name', q('EXECUTE-QUERY')),
        ('p_branch_action', q('f?p=&APP_ID.:1170:&SESSION.::&DEBUG.:1170::')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '10'),
        ('p_branch_condition_type', q('REQUEST_EQUALS_CONDITION')), ('p_branch_condition', q('EXECUTE_QUERY')),
        ('p_branch_comment', src('IMPR1170.MCI_DATA.CR_NBR.KEY-NEXT-ITEM EXECUTE_QUERY: clear cache 1170, P0_PAGE_PK set by '
                                 'the process / spec 12'))]))
    nid('1170:branch:STAY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1170:branch:STAY')), ('p_branch_name', q('IMPR1170 - stay in the form')),
        ('p_branch_action', q('f?p=&APP_ID.:1170:&SESSION.::&DEBUG.:1170::&success_msg=#SUCCESS_MSG#')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '20'),
        ('p_branch_comment', src('f345: the record stays shown (P0_PAGE_PK kept) / spec 12'))]))
    # items (spec 4)
    seq = 0
    for name, col, kind, label, dt, newline, span, x in ITEMS:
        seq += 10
        it = dict(name=PI + name, kind=kind, label=label, newline=newline, span=span, column=col, data_type=dt,
                  comment='Source: %s.%s' % (FORM, x['src']), **{k: v for k, v in x.items() if k != 'src'})
        A(page_item(PG, R, seq, it, form_region=True))
    seq = 1000
    for name, col, dt, kind, mask, vp, s in HIDDEN:
        seq += 10
        it = dict(name=PI + name, kind=kind, column=col, data_type=dt, mask=mask, value_protected=vp,
                  hidden_column=(kind != 'NATIVE_HIDDEN'),
                  protect='S' if name == 'MODULE_ID' else None, comment='Source: %s - %s' % (FORM, s))
        A(page_item(PG, R, seq, it, form_region=True))
    UNCERTAIN.add('not displayed DATE column CR_EXPIRY_DATE as a Display Only item with p_grid_column_css_classes u-hidden (as IMPR1160)')
    UNCERTAIN.add('p_item_default 1 on the always read-only Select List CR_TYPE (Forms initial value of the new record)')
    # computations (spec 9)
    for n, (item, point, expr, s) in enumerate(COMPUTATIONS, 1):
        key = '1170:comp:' + item
        nid(key, 5)
        A(call('create_page_computation', [
            ('p_id', ref(key)), ('p_computation_sequence', str(n * 10)), ('p_computation_item', q(PI + item)),
            ('p_computation_point', q(point)), ('p_computation_type', q('EXPRESSION')), ('p_computation_language', q('PLSQL')),
            ('p_computation', lit(expr)), ('p_computation_comment', src('IMPR1170 ' + s + ' / spec 9'))]))
    # processes (spec 8, f345 standard 6)
    AGR_NEW = 'NULL;  -- f345 session setup (SSO_APP_USER, P_CURR_PORT_CD, V_USR_TYPE ...) is done by the application; disabled as in AGR1100'
    for point, seq, name, code, cond, s, msg in PROCESSES:
        key = '1170:proc:%s:%s' % (point, name)
        if name == 'New':
            A(process(key, seq, point, 'New', AGR_NEW, 'NEVER', s))
        elif name == 'Initialize form':
            A(process(key, seq, point, name, None, None, 'IMPR1170 ' + s + ' / spec 8', ptype='NATIVE_FORM_INIT', region=R))
        else:
            A(process(key, seq, point, name, code, cond, 'IMPR1170 ' + s + ' / spec 8', success=msg))
    # dynamic actions (spec 10)
    for n, d in enumerate(DAS, 1):
        A(da(PG, n, *d))
    W(block('application/pages/page_01170', '\n'.join(P)))

    # ---------------------------------------------------------------- page 117001 (search)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_SEARCH)
    A(call('create_page', [
        ('p_id', str(PG_SEARCH)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM + '_SEARCH')), ('p_alias', q(FORM + '-SEARCH')),
        ('p_page_mode', q('MODAL')), ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_height', q('800')),
        ('p_dialog_width', q('1800')), ('p_protection_level', q('C')), ('p_first_item', q('AUTO_FIRST_ITEM')),
        ('p_page_comment', src('IMPR1170 Enter-Query / Execute-Query of block MCI_DATA (KEY-ENTQRY, KEY-EXEQRY) / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: f345 search page <page>01 (page 0 SEARCH)'))
    nid('117001:plug:CRIT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('117001:plug:CRIT')), ('p_plug_name', q('بحث')), ('p_region_name', q('MCI_DATA_SEARCH_CRITERIA')),
        ('p_region_css_classes', q('zatca-forms cg-form')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_HERO')), ('p_plug_display_sequence', '10'), ('p_attribute_01', q('N')),
        ('p_attribute_02', q('TEXT')), ('p_attribute_03', q('Y')),
        ('p_plug_comment', src('IMPR1170.MCI_DATA query criteria as one search text over all columns / spec 3'))]))
    P.extend(ig_region(PG_SEARCH, '117001:plug:IG', SEARCH_SQL, 'P117001_SEARCH', SEARCH_COLUMNS,
                       '117001000201', 'لا توجد نتائج - أدخل نص البحث ثم اضغط بحث', True,
                       'IMPR1170.MCI_DATA block query (no WHERE clause: every cached registration) with the POST-QUERY status '
                       'text; one search text over all columns, no query until a search / spec 3', 'السجلات التجارية',
                       'MCI_DATA_SEARCH', 20, link='f?p=&APP_ID.:1170:&SESSION.::&DEBUG.:1170:P0_PAGE_PK:&CR_NBR.'))
    UNCERTAIN.add('search IG 117001: p_lazy_loading true, p_show_total_row_count false, toolbar ACTIONS_MENU:RESET (search field removed)')
    A(page_item(PG_SEARCH, '117001:plug:CRIT', 10, dict(
        name='P117001_SEARCH', kind='NATIVE_TEXT_FIELD', label='بحث في كل الأعمدة', maxlen=200, span=6,
        comment='Source: IMPR1170.MCI_DATA query criteria (QBE of CR_NBR, CR_NAME_AR ...) as one text over all columns')))
    for b, seq, label, icon, css, s in [('SEARCH', 20, 'بحث', 'fa-search', 'cg-b-search', 'EXECUTE_QUERY of block MCI_DATA'),
                                        ('CLEAR', 30, 'مسح البحث', 'fa-eraser', 'cg-b-clear', 'TOOLBAR.CLEAR_ALL for the search')]:
        nid('117001:btn:' + b, 2)
        A(call('create_page_button', [
            ('p_id', ref('117001:btn:' + b)), ('p_button_sequence', str(seq)), ('p_button_plug_id', ref('117001:plug:CRIT')),
            ('p_button_name', q(b)), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
            ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q(label)), ('p_button_position', q('BODY')),
            ('p_icon_css_classes', q(icon)), ('p_button_css_classes', q(css)), ('p_button_comment', src('IMPR1170 %s / spec 3' % s))]))
    refresh = [('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('117001:plug:IG'))]
    for ek, name, seq, trig, extra, acts, s in [
            ('117001:da:SEARCH', 'SEARCH', 10, [('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('117001:btn:SEARCH'))],
             [('p_bind_type', q('bind')), ('p_bind_event_type', q('click'))], [refresh], 'IMPR1170 EXECUTE_QUERY / spec 3'),
            ('117001:da:SEARCH KEY-ENTER', 'SEARCH KEY-ENTER', 12,
             [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q('P117001_SEARCH')),
              ('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_expression', q('this.browserEvent.which === 13'))],
             [('p_bind_type', q('bind')), ('p_bind_event_type', q('keyup'))], [refresh],
             'IMPR1170 KEY-EXEQRY (Enter in the search text; f345 AGR1100_SEARCH keyup pattern) / spec 3'),
            ('117001:da:CLEAR', 'CLEAR WHEN-BUTTON-PRESSED', 15,
             [('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('117001:btn:CLEAR'))],
             [('p_bind_type', q('bind')), ('p_bind_event_type', q('click'))],
             [[('p_action', q('NATIVE_CLEAR')), ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q('P117001_SEARCH'))], refresh],
             'IMPR1170 TOOLBAR.CLEAR_ALL (search criteria) / spec 3')]:
        nid(ek, 8)
        A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q(name)), ('p_event_sequence', str(seq))] + trig + extra
               + [('p_da_event_comment', src(s))]))
        for i, a in enumerate(acts, 1):
            nid('%s:%d' % (ek, i * 10), 9)
            A(call('create_page_da_action', [('p_id', ref('%s:%d' % (ek, i * 10))), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                             ('p_action_sequence', str(i * 10)), ('p_execute_on_page_init', q('N'))] + a))
    UNCERTAIN.add('button DA: p_triggering_button_id (as page 113001 SEARCH; IMPR1110 uses it)')
    UNCERTAIN.add('DA client-side condition JAVASCRIPT_EXPRESSION this.browserEvent.which === 13 (Enter key; not in f345)')
    UNCERTAIN.add('NATIVE_CLEAR action with p_affected_elements (page 117001 CLEAR; not in f345)')
    ek, ak = '117001:da:Hide', '117001:daa:Hide:10'
    nid(ek, 8); nid(ak, 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('Hide')), ('p_event_sequence', '20'),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('ready')),
                                    ('p_da_event_comment', src('f345 AGR1100_SEARCH "Hide" (page 0 toolbar not used in a dialog)'))]))
    A(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('Y')), ('p_action', q('NATIVE_HIDE')),
                                     ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', fid('P0_ACTIONS'))]))
    W(block('application/pages/page_117001', '\n'.join(P)))
    W('''prompt --application/end_environment
begin
wwv_flow_api.component_end;
end;
/
set verify on feedback on define on
prompt  ...done
''')
    text = items_to_submit.fix('\n'.join(out))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    return text

# ============================================================================= checks
def names_of(text, api):
    out = []
    for chunk in text.split('wwv_flow_api.%s(' % api)[1:]:
        m = re.search(r"\n[ ,]p_name=>'([^']+)'", chunk[:chunk.find('\n);')])
        if m: out.append(m.group(1))
    return out

def selfcheck(text):
    problems = items_to_submit.check(text) + item_icons.check(text) + lov_apx.check(text) + functions_drawer.check_form_page(text)
    ref_txt = open(REF, encoding='utf-8', errors='replace').read()
    others = '\n'.join(open(f, encoding='utf-8', errors='replace').read() for f in OTHER_EXPORTS)
    pkg_txt = re.sub(r'--[^\n]*', '', open(PKG, encoding='utf-8').read())
    if 'wwv_flow_imp' in text: problems.append('wwv_flow_imp found')
    allowed = {'__WORKSPACE_ID__', '__APP_ID__', '__SCHEMA_NAME__', '__ID_OFFSET__'}
    ph = set(re.findall(r'__[A-Z_]+__', text))
    if ph - allowed: problems.append('unexpected placeholders %s' % sorted(ph - allowed))
    if re.search(r'password|pwd', text, re.I): problems.append('password text found')
    code = '\n'.join(l for l in text.splitlines() if not l.startswith('--') and not re.match(r'^[ ,]p_\w*comment=>', l))
    if re.search(r'\bAI_[A-Z]', code): problems.append('AI_ item name found')
    if re.search(r'pkg_|IMPR1110\.', code, re.I): problems.append('page calls pkg_ / IMPR1110')
    fx = forms_apx_helpers.forms_apx_members(ROOT)
    for name in set(re.findall(r'FORMS_APX\.([A-Z0-9_$]+)', code)):
        if name not in fx: problems.append('FORMS_APX.%s not in forms_apx.sql' % name)
    for m in re.finditer(r'FORMS_APX\.([A-Z0-9_$]+)\(([^()]*(?:\([^()]*\)[^()]*)*)\)', code):
        name, args = m.groups()
        given = set(re.findall(r'(?<![.\w])([A-Z0-9_$]+)\s*=>', re.sub(r'\([^()]*\)', '()', args)))
        if name in fx and given and not given <= fx[name]:
            problems.append('call FORMS_APX.%s: unknown parameters %s' % (name, sorted(given - fx[name])))
    for bad in ('ON_DEMAND', 'p_javascript_file_urls', 'AJAX_FUNCTION', 'NATIVE_JAVASCRIPT_CODE'):
        if bad in code: problems.append('not allowed: ' + bad)
    defined = re.findall(r'[ ,]p_id=>wwv_flow_api\.id\((\d+)\)', text)
    if len(defined) != len(set(defined)): problems.append('duplicate p_id')
    ref_ids = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', ref_txt))
    if set(defined) & ref_ids: problems.append('ids clash with f345')
    other_ids = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', others))
    if set(defined) & other_ids: problems.append('ids clash with the other component exports: %s' % sorted(set(defined) & other_ids)[:5])
    for k, v in IMPR1110_IDS.items():
        if v not in other_ids: problems.append('IMPR1110 id %s (%s) not in the IMPR1110 export' % (k, v))
    missing = set(re.findall(r'wwv_flow_api\.id\((\d+)\)', text)) - set(defined) - ref_ids - other_ids
    if missing: problems.append('ids used but defined nowhere: %s' % sorted(missing))
    for k, v in F345.items():
        if v not in ref_ids: problems.append('f345 id %s (%s) not in f345.sql' % (k, v))
    ref_items = set(names_of(ref_txt, 'create_flow_item')) | set(names_of(others, 'create_flow_item'))
    for n in ('SSO_APP_USER', 'P_CURR_PORT_CD', 'P_GLOBAL_V_WS_ID'):
        if n not in ref_items: problems.append('application item %s not in f345' % n)
    lovs_here = set(re.findall(r"p_lov_name=>'([^']+)'", text))
    other_lovs = set(re.findall(r"p_lov_name=>'([^']+)'", ref_txt + others))
    for n in lovs_here & other_lovs: problems.append('LOV %s already exists (f345 / other export)' % n)
    for n in set(re.findall(r"p_named_lov=>'([^']+)'", text)):
        if n not in lovs_here | other_lovs: problems.append('named LOV %s not defined' % n)
    members = set(m.upper() for m in re.findall(r'(?m)^\s*(?:PROCEDURE|FUNCTION)\s+(\w+)', pkg_txt))
    for m in set(re.findall(r'IMPR1170\.([A-Z_0-9]+)', code)):
        if m not in members: problems.append('IMPR1170.%s not in impr1170_spec.sql' % m)
    for name in re.findall(r"p_(?:name|process_name|validation_name)=>'([^']*)'", text):
        if '.' in name and ' ' not in name and not name.startswith('P'): problems.append('dot in component name ' + name)
    page_items = set(names_of(text, 'create_page_item'))
    app_items = ref_items | {'APP_USER', 'REQUEST', 'APP_ID'}
    for b in set(re.findall(r"(?<![\w$&])[:](P\d+_\w+|P_\w+|G_\w+|SSO_APP_USER|V_USR_TYPE|P0_PAGE_PK)\b", code)):
        if b not in page_items | app_items and not b.startswith('P0_'): problems.append('bind :%s has no item' % b)
    for b in set(re.findall(r"p_attribute_0[23]=>'([^']+)'", code)):
        for i in b.split(','):
            if re.match(r'P\d+_', i) and i not in page_items: problems.append('FOS item %s missing' % i)
    if text.count('\nbegin\n') != text.count('\nend;\n/'): problems.append('begin/end not balanced')
    if "p_name=>'NUMBER ONLY'" in text: problems.append('NUMBER ONLY DA on a form page (it belongs to page 0)')
    for c in text.split('wwv_flow_api.create_page_item(')[1:]:
        c = c[:c.find('\n);')]
        if "p_display_as=>'NATIVE_NUMBER_FIELD'" in c and number_only.CLASS not in c:
            problems.append('number field without class %s' % number_only.CLASS)
    # page items named after the Forms items; the package: parameter names, qualified parameters inside SQL
    spec_raw = open(PKG, encoding='utf-8').read()
    body_raw = open(PKG.replace('_spec.sql', '_body.sql'), encoding='utf-8').read()
    for p in parameter_names.unqualified_in_sql(spec_raw, body_raw):
        problems.append('package body: parameter not qualified inside SQL: %s' % (p,))
    for p in parameter_names.private_functions_in_sql(spec_raw, body_raw):
        problems.append('package body: private function inside SQL: %s' % (p,))
    if re.search(r'\b[IO]{1,2}_[A-Z]\w*\s+(IN|OUT)\b', spec_raw): problems.append('I_ / IO_ / O_ parameter in the spec')
    for name in re.findall(r'(?m)^\s*(?:PROCEDURE|FUNCTION)\s+(\w+)', spec_raw + body_raw):
        if len(name.encode()) > 30: problems.append('identifier longer than 30 bytes: ' + name)
    problems += ['package: FORMS_APX helper copy %s' % (x,) for x in forms_apx_helpers.leftovers(body_raw)]
    problems += ['package: %s' % (x,) for x in forms_apx_helpers.unknown_calls(body_raw, ROOT)]
    counts = {k: len(re.findall(r'wwv_flow_api\.%s\(' % k, text)) for k in [
        'create_page', 'create_page_plug', 'create_page_item', 'create_page_button', 'create_page_validation',
        'create_page_process', 'create_page_da_event', 'create_page_da_action', 'create_page_computation', 'create_page_branch',
        'create_region_column', 'create_interactive_grid', 'create_ig_report_column', 'create_list_of_values', 'create_flow_item']}
    counts['FOS actions'] = text.count("p_action=>'PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE'")
    return problems, counts, sorted(ph)

def ready_copy(text, args):
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
    path = os.path.join(ROOT, 'apex', 'IMPR1170', 'f%s_impr1170_import.sql' % vals['app_id'])
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
    os.makedirs(os.path.join(ROOT, 'work', 'IMPR1170', 'step04'), exist_ok=True)
    json.dump(sorted(UNCERTAIN), open(os.path.join(ROOT, 'work', 'IMPR1170', 'step04', 'uncertain.json'), 'w'), indent=1)
    print('problems:', probs or 'none')
    if probs:
        sys.exit(1)
    if len(sys.argv) > 1:
        ready_copy(t, sys.argv[1:])
