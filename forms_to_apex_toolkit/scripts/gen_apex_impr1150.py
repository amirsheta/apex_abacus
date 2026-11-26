# -*- coding: utf-8 -*-
"""
gen_apex_impr1150.py - step 04: APEX 21.2 component export of IMPR1150 (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c, docs/f345_reference_standard.md).
Helpers (q, lit, nid, call, page_item, da_event, process, selfcheck) follow scripts/gen_apex_impr1130.py.

Design: analysis/IMPR1150/IMPR1150_apex_page_spec.md. The design data is in this file (ITEMS, VALIDATIONS,
PROCESSES, COMPUTATIONS, DAS, LOVS): change it here, re-run, and keep the spec in step.

Reads
  apex/Reference/f345.sql             template ids, existing ids / items / LOVs (checks)
  apex/*/f345_*.sql                   the other component exports (page group IMPR, id clashes, LOV names)
  plsql/IMPR1150/impr1150_spec.sql    members of package IMPR1150 (checks)
Writes
  apex/IMPR1150/f345_impr1150.sql     component export, REVIEW BEFORE IMPORT (4 placeholders)
  apex/IMPR1150/f<app>_impr1150_import.sql  with --workspace-id --app-id --id-offset --schema
  work/IMPR1150/step04/uncertain.json parameters f345 does not show (import_notes.md)

Declarative: read-only native Form region on the HQ table (database link, key IMPR_NBR), read-only IG of the
documents, FOS + native actions, validations and processes = one call into IMPR1150. No JavaScript file, no
AJAX callback. IDs are deterministic: re-running gives the same file.

Usage (from forms_to_apex_toolkit):  python3 -I scripts/gen_apex_impr1150.py [--workspace-id=.. --app-id=.. --id-offset=.. --schema=..]
"""
import os, re, sys, json, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
import number_only      # Number Field items: CSS class number_only + one page-load handler on page 0
import functions_drawer # the FUNCS region is on page 0, never on a form page
import item_icons       # Post Text icon next to every entry item
import items_to_submit  # every page item a query / LOV / FOS call reads is in its Items to Submit
import client_condition  # an item in an item-type client-side condition has a default value (user rule 2026-11-26)
import lov_apx          # shared LOVs: function body returning SQL, code in LOV_APX (CLAUDE.md 4d)
import forms_apx_helpers
import parameter_names

REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')
PKG = os.path.join(ROOT, 'plsql', 'IMPR1150', 'impr1150_spec.sql')
OUT = os.path.join(ROOT, 'apex', 'IMPR1150', 'f345_impr1150.sql')
OTHER_EXPORTS = sorted(f for f in glob.glob(os.path.join(ROOT, 'apex', '*', 'f345_*.sql'))
                       if os.sep + 'IMPR1150' + os.sep not in f and os.sep + 'Reference' + os.sep not in f)
DATE, STAMP = '2026-11-25', '20261125000000'
FORM = 'IMPR1150'
PG, PG_SEARCH = 1150, 115001
PI = 'P1150_'
SHARED_BASE = 9150                 # IMPR1110 9000, IMPR1116 9116, IMPR1120 9120, IMPR1125 9125, IMPR1130 9130, IMPR1140 9140, IMPR2110 9210
IMPR1110_IDS = dict(PAGE_GROUP_IMPR='900001000010')   # created by the IMPR1110 export: reused
HQ_TABLE = 'CUSTOMS.IMPORTERS_CENTRAL@HQPRD.HQ.CUSTOMS.GOV'   # user decision 2026-11-25: keep the database link

F345 = dict(
    UI='11622010846008869795', PAGE_MAIN='11622270914969205733', REGION_HERO='11621859120066869682',
    REGION_FORM='11621909206693869707', REGION_GRID='11621913486616869708',
    LABEL_REQ='11621984380233869750', LABEL_OPT='11621983529556869749',
    BUTTON='11621986167597869752', P0_ACTIONS='73488102084440079322')
ITEM_OPTS = '#DEFAULT#:t-Form-fieldContainer--stretchInputs'

# ============================================================================= design data (spec sections 4-10)
RECORD = ':P0_PAGE_PK IS NOT NULL'   # a record is shown (Forms record status QUERY)
# items of page 1150 in canvas order (rows by Y, right to left by X): name, column, type, label, data type,
# newline, span, extra
ITEMS = [
    ('PENDING_ACTIVE', 'PENDING_ACTIVE', 'NATIVE_SELECT_LIST', 'حالة المستورد', 'NUMBER', True, 4,
     dict(lov='LOV_PENDING_ACTIVE', read_only='ALWAYS', default='0',
          src='IMPORTERS_CENTRAL.PENDING_ACTIVE (List Item; values of CG_REF_CODES domain PENDING_ACTIVE, CGDV$POPULATE_DYNAMIC_LISTS)')),
    ('BUS_ID', 'BUS_ID', 'NATIVE_TEXT_FIELD', 'الـرقم الإستدلالي', 'VARCHAR2', False, 4,
     dict(maxlen=15, read_only=RECORD, src='IMPORTERS_CENTRAL.BUS_ID (query key of a new record; Update Allowed = false)')),
    ('IMPR_NBR', 'IMPR_NBR', 'NATIVE_NUMBER_FIELD', 'الرقم الجمركي', 'NUMBER', False, 4,
     dict(maxlen=11, read_only=RECORD, pk=True,
          src='IMPORTERS_CENTRAL.IMPR_NBR (query key of a new record; Form region primary key = P0_PAGE_PK)')),
    ('IMPR_TYPE_CD', 'IMPR_TYPE_CD', 'NATIVE_DISPLAY_ONLY', 'رمز النشاط التجارى', 'NUMBER', True, 2,
     dict(src='IMPORTERS_CENTRAL.IMPR_TYPE_CD')),
    ('IMPR_TYPE_NAME', None, 'NATIVE_DISPLAY_ONLY', None, None, False, 6, dict(src='IMPORTERS_CENTRAL.IMPR_TYPE_NAME (POST-QUERY)')),
    ('BUS_ID_BRNCH', 'BUS_ID_BRNCH', 'NATIVE_DISPLAY_ONLY', 'الـرقم الــفــرعي', 'VARCHAR2', False, 4,
     dict(src='IMPORTERS_CENTRAL.BUS_ID_BRNCH')),
    ('HQ_IMPR_NBR', 'HQ_IMPR_NBR', 'NATIVE_DISPLAY_ONLY', 'الرقم الموحد بالمصلحة', 'NUMBER', True, 8,
     dict(src='IMPORTERS_CENTRAL.HQ_IMPR_NBR')),
    ('BUS_ID_EXPRD_DT', 'BUS_ID_EXPRD_DT', 'NATIVE_DISPLAY_ONLY', 'إنتهاء النشاط', 'DATE', False, 4,
     dict(mask='&P1150_HIJRI_DATE_FORMAT.', src='IMPORTERS_CENTRAL.BUS_ID_EXPRD_DT (CGSO$HDATE_ARB_DO; WHEN-VALIDATE-ITEM unreachable: not enterable)')),
    ('BUS_ID_TYPE_CD', 'BUS_ID_TYPE_CD', 'NATIVE_DISPLAY_ONLY', 'نوع الرقم الإستدلالي', 'NUMBER', True, 2,
     dict(src='IMPORTERS_CENTRAL.BUS_ID_TYPE_CD')),
    ('BUS_ID_TYPE_NAME', None, 'NATIVE_DISPLAY_ONLY', None, None, False, 6, dict(src='IMPORTERS_CENTRAL.BUS_ID_TYPE_NAME (POST-QUERY)')),
    ('CTRY_CD', 'CTRY_CD', 'NATIVE_DISPLAY_ONLY', 'الجنسيــــــــــه', 'NUMBER', False, 2, dict(src='IMPORTERS_CENTRAL.CTRY_CD')),
    ('CRTY_ARBC_NAME', None, 'NATIVE_DISPLAY_ONLY', None, None, False, 2, dict(src='IMPORTERS_CENTRAL.CRTY_ARBC_NAME (POST-QUERY)')),
    ('ARBC_IMPR_NAME', 'ARBC_IMPR_NAME', 'NATIVE_DISPLAY_ONLY', 'اسم المستورد', 'VARCHAR2', True, 12,
     dict(src='IMPORTERS_CENTRAL.ARBC_IMPR_NAME')),
    ('IMPR_ADDRESS', 'IMPR_ADDRESS', 'NATIVE_DISPLAY_ONLY', 'العنوان', 'VARCHAR2', True, 12, dict(src='IMPORTERS_CENTRAL.IMPR_ADDRESS')),
    ('ADD_CTRY_CD', 'ADD_CTRY_CD', 'NATIVE_DISPLAY_ONLY', 'دولة الأقامه', 'NUMBER', True, 2, dict(src='IMPORTERS_CENTRAL.ADD_CTRY_CD')),
    ('ADD_CRTY_ARBC_NAME', None, 'NATIVE_DISPLAY_ONLY', None, None, False, 6, dict(src='IMPORTERS_CENTRAL.ADD_CRTY_ARBC_NAME (POST-QUERY)')),
    ('CITY_CODE', 'CITY_CODE', 'NATIVE_DISPLAY_ONLY', 'المدينه', 'NUMBER', False, 2, dict(src='IMPORTERS_CENTRAL.CITY_CODE')),
    ('CITY_NAME', None, 'NATIVE_DISPLAY_ONLY', None, None, False, 2, dict(src='IMPORTERS_CENTRAL.CITY_NAME (POST-QUERY)')),
    ('IMPR_TEL_NBR', 'IMPR_TEL_NBR', 'NATIVE_DISPLAY_ONLY', 'تليفون', 'VARCHAR2', True, 8, dict(src='IMPORTERS_CENTRAL.IMPR_TEL_NBR')),
    ('MOBILE_NO', 'MOBILE_NO', 'NATIVE_DISPLAY_ONLY', 'رقم الجوال', 'NUMBER', False, 4, dict(src='IMPORTERS_CENTRAL.MOBILE_NO')),
    ('ACTIVITY', 'ACTIVITY', 'NATIVE_DISPLAY_ONLY', 'نشاط المستورد', 'VARCHAR2', True, 12,
     dict(src='IMPORTERS_CENTRAL.ACTIVITY (CGSO$CHAR_ARB_MLINE; make_field_entrable FALSE / TRUE in EXEC_FUNS: never enterable)')),
    ('IMPR_REJCT_RESON', 'IMPR_REJCT_RESON_CD', 'NATIVE_SELECT_LIST', 'سبب رفض التفعيل', 'NUMBER', True, 12,
     dict(lov='LOV_IMPR_REJCT_RESON', read_only='ALWAYS',
          src='IMPORTERS_CENTRAL.IMPR_REJCT_RESON (column IMPR_REJCT_RESON_CD, LOV CGDV$IMPORTERS_CENTRAL_IMPR_RE; '
              'Insert / Update / Query Allowed = false; button IMPR_REJCT_RESON2 dropped)')),
    ('REJCT_RESON', None, 'NATIVE_TEXT_FIELD', 'سبب رفض التفعيل', None, True, 12,
     dict(value_submit=True, src='IMPORTERS_CENTRAL.REJCT_RESON (non-database item, hidden by PRE-FORM; shown by function '
                                 'IMPR1150_REJECT - DA "IMPR1150_REJECT EXECUTE-FUNCTION")')),
]
HIDDEN = [   # name, column, data type, value protected, source
    ('PORT_CD', 'PORT_CD', 'NUMBER', 'Y', 'IMPORTERS_CENTRAL.PORT_CD (not displayed; 99 after the query)'),
    ('BIRTH_DT', 'BIRTH_DT', 'DATE', 'Y', 'IMPORTERS_CENTRAL.BIRTH_DT (not displayed)'),
    ('MODULE_ID', None, None, 'Y', 'f345 Page Functions: P<page>_MODULE_ID'),
    ('HIJRI_DATE_FORMAT', None, None, 'Y', 'FORMS_APX.HIJRI_DATE_FORMAT (format mask of BUS_ID_EXPRD_DT)'),
    ('HERO_TITLE', None, None, 'Y', 'f345 hero title (FORMS_APX.HEADER_TITLE)'),
    ('ADJ_FUNS', None, None, 'Y', 'PU ADJ_FUNS: enabled functions of the Page Functions list'),
]
LOVS = [   # name, LOV_APX call, source
    ('LOV_PENDING_ACTIVE', lov_apx.call('REFERENCE_CODES', P_DOMAIN='PENDING_ACTIVE'),
     'IMPORTERS_CENTRAL.PENDING_ACTIVE list (CGDV$POPULATE_DYNAMIC_LISTS, CG_REF_CODES domain PENDING_ACTIVE)'),
    ('LOV_IMPR_REJCT_RESON', lov_apx.call('REFERENCE_CODES', P_DOMAIN='IMPR_REJCT_RESON'),
     'LOV CGDV$IMPORTERS_CENTRAL_IMPR_RE / record group CGDV$IMPR_REJCT_RESON (CG_REF_CODES domain IMPR_REJCT_RESON)'),
]
VALIDATIONS = [   # name, item, code, source  (request EXECUTE_QUERY)
    ('IMPR_NBR VALIDATION', 'IMPR_NBR',
     'RETURN IMPR1150.IMPR_NBR_VALIDATION(P_PORT_CD => :P1150_PORT_CD, P_IMPR_NBR => :P1150_IMPR_NBR);',
     'IMPORTERS_CENTRAL.IMPR_NBR.WHEN-VALIDATE-ITEM'),
    ('BUS_ID VALIDATION', 'BUS_ID', 'RETURN IMPR1150.BUS_ID_VALIDATION(P_BUS_ID => :P1150_BUS_ID);',
     'IMPORTERS_CENTRAL.BUS_ID.WHEN-VALIDATE-ITEM'),
]
POST_QUERY = ('IMPR1150.POST_QUERY(P_IMPR_TYPE_CD => :P1150_IMPR_TYPE_CD, P_IMPR_TYPE_NAME => :P1150_IMPR_TYPE_NAME, '
              'P_BUS_ID_TYPE_CD => :P1150_BUS_ID_TYPE_CD, P_BUS_ID_TYPE_NAME => :P1150_BUS_ID_TYPE_NAME, '
              'P_CTRY_CD => :P1150_CTRY_CD, P_CRTY_ARBC_NAME => :P1150_CRTY_ARBC_NAME, '
              'P_ADD_CTRY_CD => :P1150_ADD_CTRY_CD, P_ADD_CRTY_ARBC_NAME => :P1150_ADD_CRTY_ARBC_NAME, '
              'P_CITY_CODE => :P1150_CITY_CODE, P_CITY_NAME => :P1150_CITY_NAME);')
def exec_funs(code):
    return ("IMPR1150.EXEC_FUNS(P_FUNCTION_CODE => '%s', P_PORT_CD => :P1150_PORT_CD, P_IMPR_NBR => :P1150_IMPR_NBR, "
            "P_REJCT_RESON => :P1150_REJCT_RESON, P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, "
            "P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);" % code)
# processes: point, seq, name, code, condition (PL/SQL expression), source, success message
PROCESSES = [
    ('BEFORE_HEADER', 10, 'New', None, None, 'f345 session setup copied from AGR1100 (condition Never) / standard 6', None),
    ('BEFORE_HEADER', 20, 'P0_PAGE_PK CHECK',
     'IMPR1150.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK, P_CURR_PORT_CD => :P_CURR_PORT_CD);', None,
     'f345 key (IMPR_NBR of the HQ importer, block WHERE clause)', None),
    ('BEFORE_HEADER', 40, 'PARAMETERS',
     ":P1150_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1150_MODULE_ID, FORM_NAME => 'IMPR1150');", None,
     'f345 module id of the Page Functions list', None),
    ('BEFORE_HEADER', 70, 'P0_PAGE_PK', ':P1150_IMPR_NBR := :P0_PAGE_PK;', None, 'f345 (key = IMPR_NBR)', None),
    ('BEFORE_HEADER', 80, 'Initialize form IMPORTERS_CENTRAL', None, None,
     'block IMPORTERS_CENTRAL query (QUERY_DATA_SOURCE_NAME = ' + HQ_TABLE + ')', None),
    ('BEFORE_HEADER', 82, 'POST-QUERY', POST_QUERY, RECORD, 'IMPORTERS_CENTRAL.POST-QUERY', None),
    ('BEFORE_HEADER', 100, 'HEADER TITLE',
     "FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1150_MODULE_ID, P_HERO_TITLE => :P1150_HERO_TITLE, "
     "DEFAULT_TITLE => 'تفعيل المستوردين من منصة فسح');", None, 'f345 hero title (module title)', None),
    ('AFTER_SUBMIT', 10, 'EXECUTE-QUERY',
     ':P0_PAGE_PK := IMPR1150.IMPORTER_KEY(P_IMPR_NBR => :P1150_IMPR_NBR, P_BUS_ID => :P1150_BUS_ID, P_CURR_PORT_CD => :P_CURR_PORT_CD);',
     ":REQUEST = 'EXECUTE_QUERY'", 'IMPORTERS_CENTRAL.PRE-QUERY + WHEN-NEW-ITEM-INSTANCE (EXEC_QUERY_NOW -> EXECUTE_QUERY)', None),
    ('AFTER_SUBMIT', 20, 'PRE-INSERT', 'IMPR1150.PRE_INSERT;', ":REQUEST = 'CREATE'",
     'block IMPORTERS_CENTRAL: no insert from this form (page 0 CREATE refused)', None),
    ('AFTER_SUBMIT', 30, 'PRE-UPDATE', 'IMPR1150.PRE_UPDATE(P_REJCT_RESON => :P1150_REJCT_RESON);', ":REQUEST = 'SAVE'",
     'IMPORTERS_CENTRAL.PRE-UPDATE (block Update Allowed = false: no DML)', None),
    ('AFTER_SUBMIT', 40, 'PRE-DELETE', 'IMPR1150.PRE_DELETE;', ":REQUEST = 'DELETE'",
     'block IMPORTERS_CENTRAL Delete Allowed = false (KEY-DELREC)', None),
    ('AFTER_SUBMIT', 50, 'IMPR1150_ACTIVATE EXECUTE-FUNCTION', exec_funs('IMPR1150_ACTIVATE'), ":REQUEST = 'IMPR1150_ACTIVATE'",
     'PU EXECUTE_FUNCTION -> EXEC_FUNS(IMPR1150_ACTIVATE)', 'تم تفعيل المستورد'),
    ('AFTER_SUBMIT', 60, 'IMPR1150_REJECT EXECUTE-FUNCTION', exec_funs('IMPR1150_REJECT'), ":REQUEST = 'IMPR1150_REJECT'",
     'PU EXECUTE_FUNCTION -> EXEC_FUNS(IMPR1150_REJECT), CR-7234', 'تم إيقاف تفعيل المستورد'),
]
COMPUTATIONS = [   # item, point, expression, source
    ('HIJRI_DATE_FORMAT', 'BEFORE_HEADER', 'FORMS_APX.HIJRI_DATE_FORMAT',
     'Hijri date format from one place: Application Setting HIJRI_DATE_FORMAT'),
    ('ADJ_FUNS', 'AFTER_HEADER', 'IMPR1150.ADJ_FUNS(P_PENDING_ACTIVE => :P1150_PENDING_ACTIVE)',
     'PU ADJ_FUNS (IMPORTERS_CENTRAL.WHEN-NEW-RECORD-INSTANCE, KEY-F9): filter of the f345 Page Functions list'),
]
def fos(code, submit, ret=()):
    return dict(action='FOS', code=code, submit=list(submit), ret=list(ret))
MSG_REASON = 'برجاء إدخال سبب الرفض'
# dynamic actions: name, event, selection, client condition, fire on init, actions, source
DAS = [
    ('PRE-FORM', 'ready', None, None, True,
     [dict(action='NATIVE_HIDE', items='P1150_REJCT_RESON')],
     "FORM.PRE-FORM SET_ITEM_PROPERTY('REJCT_RESON', VISIBLE, PROPERTY_FALSE)"),
    ('IMPR_NBR WHEN-VALIDATE-ITEM', 'change', ('ITEM', 'P1150_IMPR_NBR'), ('NOT_NULL', None), False,
     [fos('FORMS_APX.CHECK_ERROR(IMPR1150.IMPR_NBR_VALIDATION(P_PORT_CD => :P1150_PORT_CD, P_IMPR_NBR => :P1150_IMPR_NBR));',
          ['P1150_IMPR_NBR', 'P1150_PORT_CD']),
      dict(action='SUBMIT', request='EXECUTE_QUERY')],
     'IMPORTERS_CENTRAL.IMPR_NBR.WHEN-VALIDATE-ITEM (+ :GLOBAL.EXEC_QUERY_NOW -> WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY)'),
    ('BUS_ID WHEN-VALIDATE-ITEM', 'change', ('ITEM', 'P1150_BUS_ID'), ('NOT_NULL', None), False,
     [fos('FORMS_APX.CHECK_ERROR(IMPR1150.BUS_ID_VALIDATION(P_BUS_ID => :P1150_BUS_ID));', ['P1150_BUS_ID']),
      dict(action='SUBMIT', request='EXECUTE_QUERY')],
     'IMPORTERS_CENTRAL.BUS_ID.WHEN-VALIDATE-ITEM (+ :GLOBAL.EXEC_QUERY_NOW -> WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY)'),
    ('IMPR1150_ACTIVATE EXECUTE-FUNCTION', 'custom:IMPR1150_ACTIVATE', ('DOCUMENT', None), None, False,
     [dict(action='SUBMIT', request='IMPR1150_ACTIVATE')],
     'PU EXECUTE_FUNCTION / EXEC_FUNS(IMPR1150_ACTIVATE) - event of the f345 Page Functions list'),
    ('IMPR1150_REJECT EXECUTE-FUNCTION', 'custom:IMPR1150_REJECT', ('DOCUMENT', None),
     ('JAVASCRIPT_EXPRESSION', "$v('P1150_REJCT_RESON') === ''"), False,
     [dict(action='NATIVE_HIDE', items='P1150_IMPR_REJCT_RESON'),
      dict(action='NATIVE_SHOW', items='P1150_REJCT_RESON'),
      dict(action='NATIVE_ALERT', text=MSG_REASON),
      dict(action='NATIVE_SET_FOCUS', items='P1150_REJCT_RESON'),
      dict(action='SUBMIT', request='IMPR1150_REJECT', result='FALSE')],
     'PU EXEC_FUNS(IMPR1150_REJECT) CR-7234: no reason -> message + REJCT_RESON shown (true actions); '
     'reason entered -> request IMPR1150_REJECT (false action)'),
]

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
    """create_page_item (same attributes as gen_apex_impr1130.page_item)"""
    name, k = it['name'], it['kind']
    p = [('p_id', 'wwv_flow_api.id(%s)' % nid('%s:item:%s' % (page, name), 4)), ('p_name', q(name))]
    if form_region and it.get('column'):
        p.append(('p_source_data_type', q(it['data_type'])))
        if it.get('pk'):
            p.append(('p_is_primary_key', 'true'))
    p += [('p_item_sequence', str(seq)), ('p_item_plug_id', ref(plug_key))]
    if form_region and it.get('column'):
        p.append(('p_item_source_plug_id', ref(plug_key)))
    p += [('p_item_default', q(it.get('default'))), ('p_prompt', q(it.get('label'))), ('p_format_mask', q(it.get('mask')))]
    if form_region and it.get('column'):
        p += [('p_source', q(it['column'])), ('p_source_type', q('REGION_SOURCE_COLUMN'))]
    p.append(('p_display_as', q(k)))
    if it.get('lov'):
        p += [('p_named_lov', q(it['lov'])), ('p_lov_display_null', q('YES')), ('p_lov_null_text', q('-'))]
    if k in ('NATIVE_TEXT_FIELD', 'NATIVE_NUMBER_FIELD'):
        p.append(('p_cSize', '30'))
    if it.get('maxlen') and k in ('NATIVE_TEXT_FIELD', 'NATIVE_NUMBER_FIELD'):
        p.append(('p_cMaxlength', str(it['maxlen'])))
    if k == 'NATIVE_NUMBER_FIELD':
        p.append(('p_tag_css_classes', q(number_only.add_class(None))))
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
        p += [('p_read_only_when', q(ro)), ('p_read_only_when2', q('PLSQL')), ('p_read_only_when_type', q('EXPRESSION'))]
        UNCERTAIN.add('p_read_only_when2 => PLSQL with p_read_only_when_type => EXPRESSION (f345 shows the pattern only for p_display_when)')
    if k != 'NATIVE_HIDDEN':
        p += [('p_field_template', fid('LABEL_OPT')), ('p_item_template_options', q(ITEM_OPTS))]
    p.append(('p_is_persistent', q('N')))
    if it.get('protect'):
        p.append(('p_protection_level', q(it['protect'])))
    if k == 'NATIVE_TEXT_FIELD':
        p += [('p_attribute_01', q('N')), ('p_attribute_02', q('N')), ('p_attribute_04', q('TEXT')), ('p_attribute_05', q('BOTH'))]
    elif k == 'NATIVE_NUMBER_FIELD':
        p += [('p_attribute_03', q('right'))]
    elif k == 'NATIVE_SELECT_LIST':
        p += [('p_attribute_01', q('NONE')), ('p_attribute_02', q('N'))]
    elif k == 'NATIVE_DISPLAY_ONLY':
        p += [('p_attribute_01', q('N')), ('p_attribute_02', q('VALUE')), ('p_attribute_04', q('N')), ('p_attribute_05', q('PLAIN'))]
    elif k == 'NATIVE_HIDDEN':
        p += [('p_attribute_01', q(it.get('value_protected', 'Y')))]
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
-- File        : apex/IMPR1150/f345_impr1150.sql
-- Generated by: Claude Code (scripts/gen_apex_impr1150.py, step 04) from
--               analysis/IMPR1150/IMPR1150_apex_page_spec.md, %s, form IMPR1150 (module IMPR1150_PROD_CENTRL)
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / 4c, docs/f345_reference_standard.md 3-9: read-only native Form region on the
--               HQ table %s (key IMPR_NBR), read-only IG of the documents,
--               FOS + native dynamic actions, one-line calls into package IMPR1150 (version 001) and FORMS_APX (004).
--               No JavaScript file, no AJAX callback process.
-- Contents    : component export INTO the application installed from f345: pages 1150 (main) and
--               115001 (search) + 2 shared LOVs. Needs the IMPR1110 export (page group IMPR, Application Setting
--               HIJRI_DATE_FORMAT) imported first, and the database link HQPRD.HQ.CUSTOMS.GOV usable by the
--               parsing schema (region queries) and by LIB_APX_USR (package IMPR1150).
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR1150/import_notes.md
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
''' % (DATE, HQ_TABLE))
    # ---------------------------------------------------------------- shared LOVs (spec 6)
    UNCERTAIN.add(lov_apx.UNCERTAIN)
    for name, sql, s in LOVS:
        key = '%d:lov:%s' % (SHARED_BASE, name)
        nid(key, 5)
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), call('create_list_of_values', [
            ('p_id', ref(key)), ('p_lov_name', q(name))] + lov_apx.lov_attributes(sql, q), 'Source: IMPR1150 ' + s + ' / spec 6')))

    # ---------------------------------------------------------------- page 1150
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG)
    A(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM)), ('p_alias', q(FORM)),
        ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_step_template', fid('PAGE_MAIN')),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1150.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR1150.fmb - spec 2 / f345 standard 4'))
    hero = ('<div class="cg-hero-row"><div class="cg-hero-top"><span class="cg-hero-ic fa fa-check-circle-o" aria-hidden="true"></span>'
            '<div><div class="cg-hero-k">المستوردون</div><div class="cg-hero-t">&P1150_HERO_TITLE.</div>'
            '<div class="cg-hero-d">تفعيل أو رفض المستوردين المسجلين من منصة فسح بانتظار التفعيل</div></div></div></div>')
    nid('1150:plug:HERO', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1150:plug:HERO')), ('p_plug_name', q('الهيدر')), ('p_region_name', q('IMPORTERS_CENTRAL_HERO')),
        ('p_region_css_classes', q('cg-hero')), ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '5'), ('p_plug_source', q(hero)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src('IMPR1150.TITLE (OLB) -> f345 hero / spec 3'))]))
    region_sql = '\n'.join([
        '-- block IMPORTERS_CENTRAL: QUERY_DATA_SOURCE_NAME set in WHEN-NEW-FORM-INSTANCE to the HQ table (database link);',
        '-- WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD and PRE-QUERY PORT_CD := :GLOBAL.PORT_CD (99)',
        'SELECT ic.impr_nbr, ic.port_cd, ic.pending_active, ic.bus_id, ic.impr_type_cd, ic.bus_id_brnch, ic.hq_impr_nbr,',
        '       ic.bus_id_exprd_dt, ic.bus_id_type_cd, ic.ctry_cd, ic.arbc_impr_name, ic.impr_address, ic.add_ctry_cd,',
        '       ic.city_code, ic.impr_tel_nbr, ic.mobile_no, ic.activity, ic.impr_rejct_reson_cd, ic.birth_dt',
        '  FROM ' + HQ_TABLE + ' ic',
        ' WHERE ic.port_cd = 99',
        '   AND ic.port_cd = :P_CURR_PORT_CD'])
    nid('1150:plug:IMPORTERS_CENTRAL', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1150:plug:IMPORTERS_CENTRAL')), ('p_plug_name', q('المستوردين من منصة فسح')),
        ('p_region_name', q('IMPORTERS_CENTRAL')), ('p_region_css_classes', q('zatca-forms cg-form cg-card')),
        ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_FORM')), ('p_plug_display_sequence', '10'),
        ('p_query_type', q('SQL')), ('p_plug_source', lit(region_sql)), ('p_is_editable', 'false'),
        ('p_plug_source_type', q('NATIVE_FORM')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1150.IMPORTERS_CENTRAL (single record, query only: Update / Delete Allowed = false; '
                               'HQ table over the database link) / spec 3'))]))
    UNCERTAIN.add('NATIVE_FORM region with p_query_type SQL over a database link and p_is_editable false (f345 AGR1100 uses TABLE, editable)')
    # documents block (multi-record, query only)
    docs_sql = '\n'.join([
        '-- block IMPORTER_DOCS: WHERE IMPORTERS_DOCS.IMPR_NBR = :IMPORTERS_CENTRAL.IMPR_NBR (local table, as Forms);',
        '-- DETIL_DATA (KEY-EXEQRY / KEY-DOWN / KEY-UP): queried with the importer, empty without one',
        "SELECT d.impr_doc_isn, d.impr_nbr, d.doc_name, d.doc_desc, d.doc_path,",
        "       d.doc_path || '\\' || d.doc_name AS doc_full_name   -- PU OPEN_FILE_DOS v_full_name",
        '  FROM importers_docs d',
        ' WHERE d.impr_nbr = :P1150_IMPR_NBR'])
    P.extend(ig_region(PG, '1150:plug:IMPORTER_DOCS', docs_sql, 'P1150_IMPR_NBR',
                       [('IMPR_DOC_ISN', None, 'NUMBER', 'pk'), ('IMPR_NBR', None, 'NUMBER', 'hidden'),
                        ('DOC_NAME', 'اسم الوثيقة', 'VARCHAR2', 'text'), ('DOC_DESC', 'وصف الوثيقة', 'VARCHAR2', 'text'),
                        ('DOC_PATH', 'مسار الوثيقة', 'VARCHAR2', 'text'), ('DOC_FULL_NAME', 'عرض المستند', 'VARCHAR2', 'text')],
                       '115000000101', 'لا توجد وثائق لهذا المستورد', False,
                       'IMPR1150.IMPORTER_DOCS (6 records, query only; button OPEN_DEC -> column DOC_FULL_NAME, TODO open) / spec 3',
                       'وثائق المستورد', 'IMPORTER_DOCS', 20))
    UNCERTAIN.add('read-only IG IMPORTER_DOCS: p_is_editable false with p_lazy_loading false (documents grid of page 1150)')
    nid('1150:branch:STAY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1150:branch:STAY')), ('p_branch_name', q('IMPR1150 - stay in the form')),
        ('p_branch_action', q('f?p=&APP_ID.:1150:&SESSION.::&DEBUG.:1150::&success_msg=#SUCCESS_MSG#')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '20'),
        ('p_branch_comment', src('Forms stays on the record after the functions (EXEC_FUNS REJECT re-queries it); '
                                 'clear cache 1150 resets REJCT_RESON, P0_PAGE_PK kept / spec 12'))]))
    nid('1150:branch:QUERY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1150:branch:QUERY')), ('p_branch_name', q('EXECUTE-QUERY')),
        ('p_branch_action', q('f?p=&APP_ID.:1150:&SESSION.::&DEBUG.:1150::')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '10'),
        ('p_branch_condition_type', q('REQUEST_EQUALS_CONDITION')), ('p_branch_condition', q('EXECUTE_QUERY')),
        ('p_branch_comment', src('IMPR1150.IMPORTERS_CENTRAL.WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY: clear cache 1150, P0_PAGE_PK kept / spec 12'))]))
    # items (spec 4)
    seq = 0
    for name, col, kind, label, dt, newline, span, x in ITEMS:
        seq += 10
        it = dict(name=PI + name, kind=kind, label=label, newline=newline, span=span, column=col, data_type=dt,
                  lov=x.get('lov'), read_only=x.get('read_only'), default=x.get('default'), mask=x.get('mask'),
                  maxlen=x.get('maxlen'), pk=x.get('pk'), comment='Source: %s.%s' % (FORM, x['src']))
        A(page_item(PG, '1150:plug:IMPORTERS_CENTRAL', seq, it, form_region=True))
    seq = 1000
    for name, col, dt, vp, s in HIDDEN:
        seq += 10
        it = dict(name=PI + name, kind='NATIVE_HIDDEN', column=col, data_type=dt, value_protected=vp,
                  protect='S' if name == 'MODULE_ID' else None, comment='Source: %s - %s' % (FORM, s))
        A(page_item(PG, '1150:plug:IMPORTERS_CENTRAL', seq, it, form_region=True))
    # computations (spec 9)
    for n, (item, point, expr, s) in enumerate(COMPUTATIONS, 1):
        key = '1150:comp:' + item
        nid(key, 5)
        A(call('create_page_computation', [
            ('p_id', ref(key)), ('p_computation_sequence', str(n * 10)), ('p_computation_item', q(PI + item)),
            ('p_computation_point', q(point)), ('p_computation_type', q('EXPRESSION')), ('p_computation_language', q('PLSQL')),
            ('p_computation', lit(expr)), ('p_computation_comment', src('IMPR1150 ' + s + ' / spec 9'))]))
    # validations (spec 7): request EXECUTE_QUERY (the only request that uses the typed key)
    for n, (name, item, code, s) in enumerate(VALIDATIONS, 1):
        key = '1150:val:' + name
        nid(key, 6)
        A(call('create_page_validation', [
            ('p_id', ref(key)), ('p_validation_name', q(name)), ('p_validation_sequence', str(n * 10)),
            ('p_validation', lit(code)), ('p_validation2', q('PLSQL')), ('p_validation_type', q('FUNC_BODY_RETURNING_ERR_TEXT')),
            ('p_validation_condition', q('EXECUTE_QUERY')), ('p_validation_condition_type', q('REQUEST_EQUALS_CONDITION')),
            ('p_associated_item', 'wwv_flow_api.id(%s)' % _ids['1150:item:' + PI + item]),
            ('p_error_display_location', q('INLINE_WITH_FIELD_AND_NOTIFICATION')),
            ('p_validation_comment', src('IMPR1150.' + s + ' / spec 7'))]))
    # processes (spec 8, f345 standard 6)
    AGR_NEW = 'NULL;  -- f345 session setup (SSO_APP_USER, P_CURR_PORT_CD, V_USR_TYPE ...) is done by the application; disabled as in AGR1100'
    for point, seq, name, code, cond, s, msg in PROCESSES:
        key = '1150:proc:%s:%s' % (point, name)
        if name == 'New':
            A(process(key, seq, point, 'New', AGR_NEW, 'NEVER', s))
        elif name.startswith('Initialize form'):
            A(process(key, seq, point, 'Initialize form', None, None, 'IMPR1150 ' + s + ' / spec 8', ptype='NATIVE_FORM_INIT',
                      region='1150:plug:IMPORTERS_CENTRAL'))
        else:
            A(process(key, seq, point, name, code, cond, 'IMPR1150 ' + s + ' / spec 8', success=msg))
    # dynamic actions (spec 10)
    for n, d in enumerate(DAS, 1):
        A(da(PG, n, *d))
    W(block('application/pages/page_01150', '\n'.join(P)))

    # ---------------------------------------------------------------- page 115001 (search)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_SEARCH)
    A(call('create_page', [
        ('p_id', str(PG_SEARCH)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM + '_SEARCH')), ('p_alias', q(FORM + '-SEARCH')),
        ('p_page_mode', q('MODAL')), ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_height', q('800')),
        ('p_dialog_width', q('1800')), ('p_protection_level', q('C')), ('p_first_item', q('AUTO_FIRST_ITEM')),
        ('p_page_comment', src('IMPR1150 Enter-Query / Execute-Query of block IMPORTERS_CENTRAL (KEY-ENTQRY, KEY-EXEQRY) / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: f345 search page <page>01 (page 0 SEARCH)'))
    nid('115001:plug:CRIT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('115001:plug:CRIT')), ('p_plug_name', q('بحث')), ('p_region_name', q('IMPORTERS_CENTRAL_SEARCH_CRITERIA')),
        ('p_region_css_classes', q('zatca-forms cg-form')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_HERO')), ('p_plug_display_sequence', '10'), ('p_attribute_01', q('N')),
        ('p_attribute_02', q('TEXT')), ('p_attribute_03', q('Y')),
        ('p_plug_comment', src('IMPR1150.IMPORTERS_CENTRAL query criteria as one search text over all columns / spec 3'))]))
    search_sql = '\n'.join([
        '-- one search text over every shown column; no rows until a search is made (Forms Enter-Query); HQ table',
        '-- over the database link in the block scope (PORT_CD 99 = :P_CURR_PORT_CD), all statuses (Forms QBE)',
        'SELECT ic.impr_nbr, ic.bus_id, ic.bus_id_brnch, ic.arbc_impr_name, ic.hq_impr_nbr,',
        "       ic.pending_active || ' - ' || rc.rv_meaning AS pending_active_name,",
        "       ic.impr_type_cd || ' - ' || it.impr_type_name AS impr_type",
        '  FROM ' + HQ_TABLE + ' ic, impr_types it, cg_ref_codes rc',
        ' WHERE :P115001_SEARCH IS NOT NULL',
        '   AND ic.port_cd = 99',
        '   AND ic.port_cd = :P_CURR_PORT_CD',
        '   AND it.impr_type_cd (+) = ic.impr_type_cd',
        "   AND rc.rv_domain (+) = 'PENDING_ACTIVE'",
        '   AND rc.rv_low_value (+) = TO_CHAR(ic.pending_active)',
        "   AND INSTR(UPPER(ic.impr_nbr || '|' || ic.bus_id || '|' || ic.bus_id_brnch || '|' || ic.arbc_impr_name || '|' ||",
        "                   ic.hq_impr_nbr || '|' || rc.rv_meaning || '|' || it.impr_type_name),",
        '             UPPER(TRIM(:P115001_SEARCH))) > 0'])
    P.extend(ig_region(PG_SEARCH, '115001:plug:IG', search_sql, 'P115001_SEARCH',
                       [('IMPR_NBR', 'الرقم الجمركي', 'NUMBER', 'link'), ('BUS_ID', 'الرقم الإستدلالي', 'VARCHAR2', 'text'),
                        ('BUS_ID_BRNCH', 'الرقم الفرعي', 'VARCHAR2', 'text'), ('ARBC_IMPR_NAME', 'اسم المستورد', 'VARCHAR2', 'text'),
                        ('HQ_IMPR_NBR', 'الرقم الموحد', 'NUMBER', 'text'), ('PENDING_ACTIVE_NAME', 'حالة المستورد', 'VARCHAR2', 'text'),
                        ('IMPR_TYPE', 'النشاط التجاري', 'VARCHAR2', 'text')],
                       '115001000201', 'لا توجد نتائج - أدخل نص البحث ثم اضغط بحث', True,
                       'IMPR1150.IMPORTERS_CENTRAL block query (HQ table, block WHERE + PRE-QUERY PORT_CD 99); one search '
                       'text over all columns, no query until a search / spec 3', 'المستوردون', 'IMPORTERS_CENTRAL_SEARCH', 20,
                       link='f?p=&APP_ID.:1150:&SESSION.::&DEBUG.:1150:P0_PAGE_PK:&IMPR_NBR.'))
    UNCERTAIN.add('search IG 115001: p_lazy_loading true, p_show_total_row_count false, toolbar ACTIONS_MENU:RESET (search field removed)')
    # IG primary key: the search grid has no hidden key column; IMPR_NBR is unique per PORT_CD 99
    A(page_item(PG_SEARCH, '115001:plug:CRIT', 10, dict(
        name='P115001_SEARCH', kind='NATIVE_TEXT_FIELD', label='بحث في كل الأعمدة', maxlen=200, span=6,
        comment='Source: IMPR1150.IMPORTERS_CENTRAL query criteria (QBE of IMPR_NBR, BUS_ID ...) as one text over all columns')))
    for b, seq, label, icon, css, s in [('SEARCH', 20, 'بحث', 'fa-search', 'cg-b-search', 'EXECUTE_QUERY of block IMPORTERS_CENTRAL'),
                                        ('CLEAR', 30, 'مسح البحث', 'fa-eraser', 'cg-b-clear', 'TOOLBAR.CLEAR_ALL for the search')]:
        nid('115001:btn:' + b, 2)
        A(call('create_page_button', [
            ('p_id', ref('115001:btn:' + b)), ('p_button_sequence', str(seq)), ('p_button_plug_id', ref('115001:plug:CRIT')),
            ('p_button_name', q(b)), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
            ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q(label)), ('p_button_position', q('BODY')),
            ('p_icon_css_classes', q(icon)), ('p_button_css_classes', q(css)), ('p_button_comment', src('IMPR1150 %s / spec 3' % s))]))
    refresh = [('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('115001:plug:IG'))]
    for ek, name, seq, trig, extra, acts, s in [
            ('115001:da:SEARCH', 'SEARCH', 10, [('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('115001:btn:SEARCH'))],
             [('p_bind_type', q('bind')), ('p_bind_event_type', q('click'))], [refresh], 'IMPR1150 EXECUTE_QUERY / spec 3'),
            ('115001:da:SEARCH KEY-ENTER', 'SEARCH KEY-ENTER', 12,
             [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q('P115001_SEARCH')),
              ('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_expression', q('this.browserEvent.which === 13'))],
             [('p_bind_type', q('bind')), ('p_bind_event_type', q('keyup'))], [refresh],
             'IMPR1150 KEY-EXEQRY (Enter in the search text; f345 AGR1100_SEARCH keyup pattern) / spec 3'),
            ('115001:da:CLEAR', 'CLEAR WHEN-BUTTON-PRESSED', 15,
             [('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('115001:btn:CLEAR'))],
             [('p_bind_type', q('bind')), ('p_bind_event_type', q('click'))],
             [[('p_action', q('NATIVE_CLEAR')), ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q('P115001_SEARCH'))], refresh],
             'IMPR1150 TOOLBAR.CLEAR_ALL (search criteria) / spec 3')]:
        nid(ek, 8)
        A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q(name)), ('p_event_sequence', str(seq))] + trig + extra
               + [('p_da_event_comment', src(s))]))
        for i, a in enumerate(acts, 1):
            nid('%s:%d' % (ek, i * 10), 9)
            A(call('create_page_da_action', [('p_id', ref('%s:%d' % (ek, i * 10))), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                             ('p_action_sequence', str(i * 10)), ('p_execute_on_page_init', q('N'))] + a))
    UNCERTAIN.add('button DA: p_triggering_button_id (as page 113001 SEARCH; IMPR1110 uses it)')
    UNCERTAIN.add('DA client-side condition JAVASCRIPT_EXPRESSION this.browserEvent.which === 13 (Enter key; not in f345)')
    UNCERTAIN.add('NATIVE_CLEAR action with p_affected_elements (page 115001 CLEAR; not in f345)')
    ek, ak = '115001:da:Hide', '115001:daa:Hide:10'
    nid(ek, 8); nid(ak, 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('Hide')), ('p_event_sequence', '20'),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('ready')),
                                    ('p_da_event_comment', src('f345 AGR1100_SEARCH "Hide" (page 0 toolbar not used in a dialog)'))]))
    A(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('Y')), ('p_action', q('NATIVE_HIDE')),
                                     ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', fid('P0_ACTIONS'))]))
    W(block('application/pages/page_115001', '\n'.join(P)))
    W('''prompt --application/end_environment
begin
wwv_flow_api.component_end;
end;
/
set verify on feedback on define on
prompt  ...done
''')
    text = client_condition.fix(items_to_submit.fix('\n'.join(out)))
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
    problems = items_to_submit.check(text) + client_condition.check(text) + item_icons.check(text) + lov_apx.check(text) + functions_drawer.check_form_page(text)
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
    for m in set(re.findall(r'IMPR1150\.([A-Z_0-9]+)', code)):
        if m not in members: problems.append('IMPR1150.%s not in impr1150_spec.sql' % m)
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
    path = os.path.join(ROOT, 'apex', 'IMPR1150', 'f%s_impr1150_import.sql' % vals['app_id'])
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
    os.makedirs(os.path.join(ROOT, 'work', 'IMPR1150', 'step04'), exist_ok=True)
    json.dump(sorted(UNCERTAIN), open(os.path.join(ROOT, 'work', 'IMPR1150', 'step04', 'uncertain.json'), 'w'), indent=1)
    print('problems:', probs or 'none')
    if probs:
        sys.exit(1)
    if len(sys.argv) > 1:
        ready_copy(t, sys.argv[1:])
