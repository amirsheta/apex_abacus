# -*- coding: utf-8 -*-
"""
gen_apex_impr1110.py - step 04 generator for IMPR1110 (Forms -> APEX 21.2, wwv_flow_api).

Reads the item table (section 4) of analysis/IMPR1110/IMPR1110_apex_page_spec.md and writes
apex/IMPR1110/f2000_impr1110.sql (component export, REVIEW BEFORE IMPORT).
Everything else (LOVs, processes, DAs ...) is the data below, copied from the page spec sections
5-13. IDs are deterministic: re-running gives the same file.

Usage (from forms_to_apex_toolkit):  python -I scripts/gen_apex_impr1110.py
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(ROOT, 'analysis', 'IMPR1110', 'IMPR1110_apex_page_spec.md')
OUT = os.path.join(ROOT, 'apex', 'IMPR1110', 'f2000_impr1110.sql')
DATE = '2026-11-18'
FORM = 'IMPR1110'

# ----------------------------------------------------------------------------- helpers
def q(s):
    """SQL string literal. Non-ASCII text -> unistr() like a real APEX export (charset-safe)."""
    if s is None:
        return 'null'
    s = str(s)
    if all(ord(ch) < 128 for ch in s):
        return "'" + s.replace("'", "''") + "'"
    out = []
    for ch in s:
        o = ord(ch)
        if ch == '\\':
            out.append('\\005C')
        elif ch == "'":
            out.append("''")
        elif o < 128:
            out.append(ch)
        else:
            out.append('\\%04X' % o)
    return "unistr('" + ''.join(out) + "')"

def lit(s):
    """Long literal (code). Split into 4000-char pieces joined with ||."""
    if s is None:
        return 'null'
    if len(s) <= 3000:
        return q(s)
    parts = [s[i:i + 3000] for i in range(0, len(s), 3000)]
    return '\n||'.join(q(p) for p in parts)

_ids = {}
def nid(key, kind):
    """Deterministic id: <page/9000><kind 2><seq 6>."""
    if key in _ids:
        return _ids[key]
    page = key.split(':')[0]
    base = int(page) if page.isdigit() else 9000
    n = sum(1 for k in _ids if k.split(':')[0] == page) + 1
    v = '%d%02d%06d' % (base, kind, n * 10)
    _ids[key] = v
    return v

def ref(key):
    if key not in _ids:
        raise KeyError('undefined id ' + key)
    return 'wwv_flow_api.id(%s)' % _ids[key]

def tpl(name):
    return 'wwv_flow_api.id(__TEMPLATE_ID_%s__)' % name

def call(proc, params, comment=None):
    lines = []
    if comment:
        lines.append('-- ' + comment)
    lines.append('wwv_flow_api.%s(' % proc)
    first = True
    for k, v in params:
        if v is None or v == 'null':      # not set -> omitted, APEX applies its default
            continue
        lines.append(('%s%s=>%s' % (' ' if first else ',', k, v)))
        first = False
    lines.append(');')
    return '\n'.join(lines)

def block(title, body):
    return 'prompt --%s\nbegin\n%s\nend;\n/\n' % (title, body)

src = lambda s: q('Source: ' + s)

# ----------------------------------------------------------------------------- spec section 4
def read_items():
    txt = open(SPEC, encoding='utf-8').read()
    sec = txt.split('## 4. Items')[1].split('\n## 5.')[0]
    rows = []
    for line in sec.splitlines():
        if not line.startswith('| `P1110_'):
            continue
        c = [x.strip() for x in line.strip().strip('|').split('|')]
        rows.append(dict(name=c[0].strip('`'), column=c[1], type=c[2], label=c[3], req=c[4],
                         mask=c[5], default=c[6], lov=c[7], parents=c[8], maxlen=c[9],
                         layout=c[10], ssp=c[11], source=c[12].replace('`', ''), notes=c[13]))
    return rows

# ----------------------------------------------------------------------------- shared data
APP_ITEMS_P = ['AI_P_CURR_PORT_CD', 'AI_P_USER_ID', 'AI_P_WS_ID', 'AI_P_CLASS_CD', 'AI_P_USER_TYPE',
               'AI_P_BRKR_PORT_CD', 'AI_P_LIC_TYPE', 'AI_P_BRKR_NBR', 'AI_P_PORT_TYPE']
APP_ITEMS_G = ['AI_FLAGUPDATE', 'AI_EXEC_QUERY_NOW', 'AI_PORT_CD', 'AI_IMPR_NBR', 'AI_VALID',
               'AI_FUNS_IMP', 'AI_FUNS_BUSID', 'AI_CHK_IMP_TYP', 'AI_CHK_DUP_BUSID',
               'AI_OLD_IMPR_TYPE_CD', 'AI_OLD_PORT_CD', 'AI_ALLOW_MCI', 'AI_ALLOW_MOI', 'AI_SET',
               'AI_MINS_COMM_CD', 'AI_LETTER_NBR', 'AI_SUPP_TITLE_CD', 'AI_LETTER_DT', 'AI_MOBILE_NO',
               'AI_IMPR_NBR_B', 'AI_IMPR_NAME_B', 'AI_BRKR_ATHRZTN_NBR_B', 'AI_CHEK', 'AI_STAT_QUE',
               'AI_STAT_CLR', 'AI_IMP0F4', 'AI_EXE_DETAIL_QUERY', 'AI_INS']

# (name, sql, extra columns [(col, heading, type)], source)
LOVS = [
    ('LOV_SD_PORTS',
     'SELECT port_cd d, port_cd r, port_name FROM sd_ports WHERE port_status = 1 '
     'AND port_type = NVL(:AI_P_PORT_TYPE, port_type) ORDER BY port_cd',
     [('PORT_NAME', 'اسم الجمرك', 'VARCHAR2')], 'LOV form LOV_SD_PORTS / CGFK$IMPORTERS_PORT_CD'),
    ('LOV_IMPR_TYPE',
     'SELECT DISTINCT itidt.impr_type_cd d, itidt.impr_type_cd r, it.impr_type_name '
     'FROM impr_type_id_types itidt, impr_types it WHERE it.impr_type_cd = itidt.impr_type_cd '
     "AND itidt.impr_type_cd > 0 AND (:AI_CHK_IMP_TYP = '1' OR itidt.status = 1) ORDER BY 2",
     [('IMPR_TYPE_NAME', 'النشاط التجاري', 'VARCHAR2')], 'LOV form LOV_Impr_Type (type part) / CGFK$IMPORTERS_IMPR_TYPE_CD'),
    ('LOV_IMPR_TYPE_BUS_ID',
     'SELECT bit.bus_id_type_name d, itidt.bus_id_type_cd r FROM impr_type_id_types itidt, bus_id_types bit '
     'WHERE bit.bus_id_type_cd = itidt.bus_id_type_cd AND itidt.impr_type_cd = :P1110_IMPR_TYPE_CD '
     "AND itidt.impr_type_cd > 0 AND (:AI_CHK_IMP_TYP = '1' OR itidt.status = 1) ORDER BY itidt.bus_id_type_cd",
     [], 'LOV form LOV_Impr_Type (bus-id-type part)'),
    ('LOV_CITIES_IMP_ID',
     'SELECT city_cd d, city_cd r, city_arb_name, mins_comm_cd FROM cities WHERE city_status = 1 '
     'AND ctry_cd = NVL(CASE WHEN :P1110_IMPR_TYPE_CD = 3 AND :P1110_BUS_ID_TYPE_CD = 2 THEN 100 '
     'ELSE TO_NUMBER(:P1110_CTRY_CD) END, ctry_cd) ORDER BY ctry_cd, city_cd',
     [('CITY_ARB_NAME', 'المدينة', 'VARCHAR2'), ('MINS_COMM_CD', 'رمز الوزارة', 'NUMBER')],
     'LOV form LOV_CITIES_IMP (CITY_CODE_OF_ID) / CGFK$IMPORTERS_CITY_CODE_OF_ID'),
    ('LOV_CITIES_IMP_BRNH',
     'SELECT city_cd d, city_cd r, city_arb_name, mins_comm_cd FROM cities WHERE city_status = 1 '
     'AND ctry_cd = NVL(:P1110_CTRY_CD, ctry_cd) ORDER BY ctry_cd, city_cd',
     [('CITY_ARB_NAME', 'المدينة', 'VARCHAR2'), ('MINS_COMM_CD', 'رمز الوزارة', 'NUMBER')],
     'LOV form LOV_CITIES_IMP (BRNH_CITY_CD)'),
    ('LOV_CITIES',
     'SELECT city_cd d, city_cd r, city_arb_name FROM cities WHERE city_status = 1 '
     'AND ctry_cd = NVL(:P1110_ADD_CTRY_CD, ctry_cd) ORDER BY ctry_cd, city_cd',
     [('CITY_ARB_NAME', 'المدينة', 'VARCHAR2')], 'LOV form LOV_CITIES / CGFK$IMPORTERS_ADD_CTRY_CD (city part)'),
    ('LOV_COUNTRIES',
     'SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries WHERE ctry_status = 1 '
     'AND ctry_cd NOT IN (-1) ORDER BY ctry_cd',
     [('CRTY_ARBC_NAME', 'الدولة', 'VARCHAR2')], 'LOV form LOV_COUNTRIES / CGFK$IMPORTERS_ADD_CTRY_CD'),
    ('LOV_COUNTRIES_GULF',
     'SELECT ctry_cd d, ctry_cd r, crty_arbc_name FROM countries WHERE '
     '(:P1110_IMPR_TYPE_CD = 4 AND :P1110_BUS_ID_TYPE_CD = 16 AND ctry_cd IN (113,116,117,119,120,100)) '
     'OR (NOT (NVL(:P1110_IMPR_TYPE_CD,0) = 4 AND NVL(:P1110_BUS_ID_TYPE_CD,0) = 16) AND ctry_status = 1) '
     'ORDER BY ctry_cd',
     [('CRTY_ARBC_NAME', 'الدولة', 'VARCHAR2')],
     'PU CALL_LOV_COUNTRIES / CALL_LOV_COUN_GULF (LOV forms LOV_COUNTRIES, LOV_COUNTRIES_GULF) - CTRY_CD'),
    ('LOV_IMPR',
     'SELECT impr_nbr d, impr_nbr r, arbc_impr_name, bus_id, bus_id_brnch, impr_tel_nbr FROM importers '
     'WHERE port_cd = :AI_P_CURR_PORT_CD',
     [('ARBC_IMPR_NAME', 'الاسم', 'VARCHAR2'), ('BUS_ID', 'الرقم الإستدلالي', 'VARCHAR2'),
      ('BUS_ID_BRNCH', 'الرقم الفرعي', 'VARCHAR2'), ('IMPR_TEL_NBR', 'تليفون', 'VARCHAR2')],
     'LOV form LOV_IMPR'),
    ('LOV_COMM_RGSTRTN_TYPE',
     "SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'COMM_RGSTRTN_TYPE' ORDER BY 2",
     [], 'list item IMPORTERS.COMM_RGSTRTN_TYPE (CGDV$POPULATE_DYNAMIC_LISTS)'),
    ('LOV_ALLOWED_EXPORT',
     "SELECT rv_meaning d, rv_low_value r FROM cg_ref_codes WHERE rv_domain = 'ALLOWED EXPORT' ORDER BY 2",
     [], 'list item IMPORTERS.IMPR_EXPR_TYPE (CGDV$POPULATE_DYNAMIC_LISTS)'),
]
STATIC_LOVS = [
    ('LOV_EXPRESS_POST', [('لا', '0'), ('نعم', '1'), ('تم انشاءه بواسطة البريد السريع', '2')],
     'list item IMPORTERS.EXPRESS_POST'),
    ('LOV_CAR_AGENT_FLAG', [('ليس وكيل سيارات', '0'), ('وكيل سيارات', '1')],
     'pop list IMPORTERS.CAR_AGENT_FLAG'),
]
LOV_RENAME = {'LOV_CTRY_CD (inline)': 'LOV_COUNTRIES_GULF'}

FUN_CODES = ['IMPR1110F1', 'IMPR1110F2', 'IMPR1110F3', 'IMPR1110F4', 'IMPR1110F5', 'IMPR_CAR_AGENT',
             'IMPR_MCI_SERVICE', 'CREATE_BRKR_IMPR_AUTH', 'IMPR1115_GZT', 'IMPR1115_SCR', 'IMPR1110_MOB']
FUN_LABELS = {
    'IMPR1110F1': 'تعديل الاسم من السجل التجاري', 'IMPR1110F2': 'تعديل الرقم الإستدلالي / نوع السجل',
    'IMPR1110F3': 'تعديل النشاط التجاري', 'IMPR1110F4': 'تعديل تاريخ انتهاء النشاط',
    'IMPR1110F5': 'تعديل الاسم', 'IMPR_CAR_AGENT': 'وكيل سيارات',
    'IMPR_MCI_SERVICE': 'تحديث البيانات من وزارة التجارة', 'CREATE_BRKR_IMPR_AUTH': 'إنشاء تفويض مخلص',
    'IMPR1115_GZT': 'شهادة الزكاة', 'IMPR1115_SCR': 'IMPR1115', 'IMPR1110_MOB': 'تعديل رقم الجوال'}

VALIDATIONS = [  # (item, name suffix, source)
    ('PORT_CD', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM'),
    ('HQ_IMPR_NBR', 'POST-CHANGE', 'IMPORTERS.HQ_IMPR_NBR.POST-CHANGE'),
    ('IMPR_NBR', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM'),
    ('IMPR_TYPE_CD', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.IMPR_TYPE_CD.POST-CHANGE + WHEN-VALIDATE-ITEM'),
    ('BUS_ID_EXPRD_DT', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM'),
    ('BUS_ID_TYPE_CD', 'POST-CHANGE', 'IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE'),
    ('CITY_CODE_OF_ID', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM'),
    ('BUS_ID', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.BUS_ID.POST-CHANGE + WHEN-VALIDATE-ITEM'),
    ('BRNH_CITY_CD', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM'),
    ('BUS_ID_BRNCH', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.BUS_ID_BRNCH.POST-CHANGE + WHEN-VALIDATE-ITEM'),
    ('CTRY_CD', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM'),
    ('IMPR_EXPR_TYPE', 'POST-CHANGE', 'IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE'),
    ('ARBC_IMPR_NAME', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM'),
    ('ENG_IMPR_NAME', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM'),
    ('BUS_ID_ISSUE_DT', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM'),
    ('IMPR_NBR_PARENT', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM'),
    ('ADD_CTRY_CD', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM'),
    ('CITY_CODE', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM'),
    ('IMPR_TEL_NBR', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM'),
    ('B_EMAIL', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.B_EMAIL.POST-CHANGE + WHEN-VALIDATE-ITEM'),
    ('EMAIL', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM'),
    ('B_MOBILE_NO', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.B_MOBILE_NO.POST-CHANGE + WHEN-VALIDATE-ITEM'),
    ('BANK_IBAN', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM'),
    ('B_ID_NBR', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.B_ID_NBR.POST-CHANGE + WHEN-VALIDATE-ITEM'),
    ('CTRY_CD_OF_ID', 'WHEN-VALIDATE-ITEM', 'IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM'),
]
# DA 2 items (POST-CHANGE + WVI on change) - spec section 10
DA_VALIDATE = ['PORT_CD', 'HQ_IMPR_NBR', 'IMPR_NBR', 'IMPR_TYPE_CD', 'BUS_ID_EXPRD_DT', 'CITY_CODE_OF_ID',
               'BUS_ID', 'BRNH_CITY_CD', 'BUS_ID_BRNCH', 'CTRY_CD', 'IMPR_EXPR_TYPE', 'ARBC_IMPR_NAME',
               'ENG_IMPR_NAME', 'BUS_ID_ISSUE_DT', 'IMPR_NBR_PARENT', 'ADD_CTRY_CD', 'CITY_CODE',
               'IMPR_TEL_NBR', 'B_EMAIL', 'B_MOBILE_NO', 'BANK_IBAN', 'B_ID_NBR']
DA_POST_CHANGE_ONLY = {'HQ_IMPR_NBR', 'IMPR_EXPR_TYPE'}
DA_WNII = ['IMPR_TYPE_CD', 'CITY_CODE_OF_ID', 'BUS_ID', 'BRNH_CITY_CD', 'BUS_ID_BRNCH', 'BANK_IBAN']

# ----------------------------------------------------------------------------- generation
def item_call(page, plug_key, seq, it):
    """it: dict with keys name, kind, label, req, mask, default, lov, maxlen, newline, span,
    hidden, protect, comment, tag, subtype, height"""
    k = it['kind']
    p = [('p_id', None), ('p_name', q(it['name'])), ('p_item_sequence', str(seq)),
         ('p_item_plug_id', ref(plug_key)), ('p_item_default', q(it.get('default'))),
         ('p_prompt', q(it.get('label'))), ('p_format_mask', q(it.get('mask'))),
         ('p_display_as', q(k))]
    p[0] = ('p_id', 'wwv_flow_api.id(%s)' % nid('%s:item:%s' % (page, it['name']), 4))
    if it.get('lov'):
        p.append(('p_named_lov', q(it['lov'])))
        if k == 'NATIVE_POPUP_LOV':
            p.append(('p_lov_display_null', q('YES')))
        else:
            p.append(('p_lov_display_null', q('YES')))
            p.append(('p_lov_null_text', q('-')))
    if k in ('NATIVE_TEXT_FIELD', 'NATIVE_NUMBER_FIELD', 'NATIVE_POPUP_LOV', 'NATIVE_TEXTAREA'):
        p.append(('p_cSize', '30'))
    if it.get('maxlen') and k not in ('NATIVE_DISPLAY_ONLY', 'NATIVE_HIDDEN', 'NATIVE_SELECT_LIST'):
        p.append(('p_cMaxlength', str(it['maxlen'])))
    if it.get('height'):
        p.append(('p_cHeight', str(it['height'])))
    if k != 'NATIVE_HIDDEN':
        p.append(('p_begin_on_new_line', q('YES' if it.get('newline', True) else 'NO')))
        if it.get('span'):
            p.append(('p_colspan', str(it['span'])))
        if it.get('hidden'):
            p.append(('p_grid_column_css_classes', q('u-hidden')))
        p.append(('p_field_template', tpl('LABEL_REQUIRED' if it.get('req') else 'LABEL_OPTIONAL')))
        p.append(('p_item_template_options', q('#DEFAULT#')))
    if it.get('tag'):
        p.append(('p_tag_attributes', q(it['tag'])))
    if it.get('req'):
        p.append(('p_is_required', 'true'))
    p.append(('p_protection_level', q(it.get('protect', 'N'))))
    # plug-in attributes (APEX 21.2 native item types) - see import_notes.md "uncertain parameters"
    if k == 'NATIVE_TEXT_FIELD':
        p += [('p_attribute_01', q('N')), ('p_attribute_02', q('N')),
              ('p_attribute_04', q(it.get('subtype', 'TEXT'))), ('p_attribute_05', q('BOTH'))]
    elif k == 'NATIVE_NUMBER_FIELD':
        p += [('p_attribute_03', q('left'))]
    elif k == 'NATIVE_TEXTAREA':
        p += [('p_attribute_01', q('Y')), ('p_attribute_02', q('N')), ('p_attribute_03', q('N')),
              ('p_attribute_04', q('BOTH'))]
    elif k == 'NATIVE_SELECT_LIST':
        p += [('p_attribute_01', q('NONE')), ('p_attribute_02', q('N'))]
    elif k == 'NATIVE_POPUP_LOV':
        p += [('p_attribute_01', q('DIALOG')), ('p_attribute_02', q('FIRST_ROWSET')),
              ('p_attribute_03', q('N'))]
    elif k == 'NATIVE_DISPLAY_ONLY':
        p += [('p_attribute_01', q('Y')), ('p_attribute_02', q('VALUE')),
              ('p_attribute_04', q('N')), ('p_attribute_05', q('PLAIN'))]
    elif k == 'NATIVE_HIDDEN':
        p += [('p_attribute_01', q(it.get('value_protected', 'Y')))]
    p.append(('p_item_comment', q(it.get('comment'))))
    return call('create_page_item', p)

def spec_item(r):
    t = r['type']
    it = dict(name=r['name'])
    if t.startswith('Popup LOV'):
        it['kind'] = 'NATIVE_POPUP_LOV'
    elif t.startswith('Display Only'):
        it['kind'] = 'NATIVE_DISPLAY_ONLY'
    elif t.startswith('Number Field'):
        it['kind'] = 'NATIVE_NUMBER_FIELD'
    elif t.startswith('Text Field'):
        it['kind'] = 'NATIVE_TEXT_FIELD'
    elif t.startswith('Select List'):
        it['kind'] = 'NATIVE_SELECT_LIST'
    elif t.startswith('Textarea'):
        it['kind'] = 'NATIVE_TEXTAREA'
        it['height'] = 4
    elif t.startswith('Hidden'):
        it['kind'] = 'NATIVE_HIDDEN'
        it['value_protected'] = 'N'
    else:
        raise ValueError('unknown type ' + t)
    if r['name'] == 'P1110_UI_STATE':
        # deviation from spec 4: Hidden instead of Display Only so the page-load DA can read it with
        # $v(); the server only ever writes this item (keep_ui), never reads it.
        it['kind'] = 'NATIVE_HIDDEN'
        it['value_protected'] = 'N'
    tags = []
    if 'E-Mail' in t:
        it['subtype'] = 'EMAIL'
    if 'Phone' in t:
        it['subtype'] = 'PHONE'
    if 'dir=ltr' in t:
        tags.append('dir="ltr"')
    if 'upper case' in t:
        tags.append('style="text-transform:uppercase"')
    if 'Hijri' in t:
        tags.append('placeholder="%s"' % 'يوم-شهر-سنة')
    if tags:
        it['tag'] = ' '.join(tags)
    it['label'] = None if r['label'] == '-' else r['label']
    it['req'] = r['req'].startswith('Yes')
    it['mask'] = None if r['mask'] == '-' else r['mask']
    it['default'] = r['default'].split(':', 1)[1].strip() if r['default'].startswith('Static:') else None
    lov = r['lov']
    it['lov'] = None if lov == '-' else LOV_RENAME.get(lov, lov)
    it['maxlen'] = None if r['maxlen'] == '-' else r['maxlen']
    lay = r['layout']
    seq = int(lay.split('/')[0].strip())
    if 'hidden' in lay:
        it['hidden'] = True
        it['newline'] = True
    else:
        m = re.search(r'row (Yes|No) / col (\d+) span (\d+)', lay)
        it['newline'] = m.group(1) == 'Yes'
        span = int(m.group(3))
        # a labelled item needs at least 2 grid columns to be usable (layout review: import_notes)
        it['span'] = max(span, 2) if it['label'] else span
    if 'Checksum' in r['ssp']:
        it['protect'] = 'S'
    elif r['ssp'].startswith('n/a'):
        it['protect'] = 'I'
    else:
        it['protect'] = 'N'
    if it['kind'] == 'NATIVE_HIDDEN' and r['name'] == 'P1110_UI_STATE':
        it['protect'] = 'N'
    srcs = r['source'] if r['source'] != '-' else r['notes']
    it['comment'] = 'Source: %s.%s' % (FORM, srcs) if r['source'] != '-' else 'Source: %s (%s)' % (FORM, r['notes'])
    return seq, it

def gen():
    out = []
    W = out.append
    W('''-- =============================================================================
-- REVIEW BEFORE IMPORT
-- File        : apex/IMPR1110/f2000_impr1110.sql
-- Generated by: Claude Code (scripts/gen_apex_impr1110.py) from
--               analysis/IMPR1110/IMPR1110_apex_page_spec.md, %s, form IMPR1110
-- Target      : Oracle APEX 21.2  (export version 2021.10.15), Oracle Database 12.1.0.2
-- Contents    : component export for an EXISTING application (pages 1110, 1111, 1112 + the
--               shared components they need). Page 1113 (SUPPORT_ENTRY) is not generated.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __USER_INTERFACE_ID__,
--               __TEMPLATE_ID_<NAME>__  - see apex/IMPR1110/import_notes.md
-- WARNING     : generated wwv_flow_api code is not an officially supported way to build APEX
--               applications. No reference export of the target instance was available, so
--               parameter names come from APEX 21.2 exports in general. Import into a DEV
--               workspace first, back up the application, review every page in Page Designer.
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
,p_default_id_offset=>0
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
                 'Source: IMPR1110.fmb module group IMPR / spec section 0')))

    body = []
    for n in APP_ITEMS_P + APP_ITEMS_G:
        nid('9000:ai:' + n, 2)
        srcx = (':PARAMETER.%s of the menu (CIC_MENU)' % n[3:]) if n in APP_ITEMS_P else (':GLOBAL.%s' % n[3:])
        body.append(call('create_flow_item', [('p_id', ref('9000:ai:' + n)), ('p_name', q(n)),
                                              ('p_protection_level', q('I')),
                                              ('p_item_comment', src('%s / spec 13.1' % srcx))]))
    W(block('application/shared_components/logic/application_items', '\n'.join(body)))

    # authorization schemes - fail closed until the rule source is available (spec 16 Q4/Q6)
    schemes = [('IMPR1110_ACCESS', 'user may open module IMPR1110 (module security of CIC_MENU / SEC_LIB)')] + \
              [('FUN_' + c, 'function %s is in TMPLT.LOAD_FUNCTIONS(P_USER_ID, P_MODULE_ID)' % c) for c in FUN_CODES] + \
              [('FUN_REMOVE', 'TOOLBAR.REMOVE visible + enabled (step 02 H6)')]
    body = []
    for n, rule in schemes:
        nid('9000:auth:' + n, 3)
        code = ('-- Source: %s - spec 13.3. %s\n'
                '-- TODO: MISSING SOURCE - real rule unknown; fails closed (no access) until replaced.\n'
                'RETURN FALSE;' % (n, rule))
        body.append(call('create_security_scheme', [
            ('p_id', ref('9000:auth:' + n)), ('p_name', q(n)), ('p_scheme_type', q('NATIVE_FUNCTION_BODY')),
            ('p_attribute_01', lit(code)), ('p_error_message', q('ليس لديك صلاحية')),
            ('p_caching', q('BY_USER_BY_PAGE_VIEW'))]))
    W(block('application/shared_components/security/authorizations', '\n'.join(body)))

    for name, sql, cols, s in LOVS:
        nid('9000:lov:' + name, 5)
        b = [call('create_list_of_values', [
            ('p_id', ref('9000:lov:' + name)), ('p_lov_name', q(name)), ('p_source_type', q('SQL')),
            ('p_location', q('LOCAL')), ('p_lov_query', lit(sql)), ('p_return_column_name', q('R')),
            ('p_display_column_name', q('D'))], 'Source: ' + s + ' / spec 6')]
        for i, (c, h, dt) in enumerate(cols):
            key = '9000:lovc:%s:%s' % (name, c)
            nid(key, 6)
            b.append(call('create_list_of_values_cols', [
                ('p_id', ref(key)), ('p_lov_id', ref('9000:lov:' + name)), ('p_query_column_name', q(c)),
                ('p_heading', q(h)), ('p_display_sequence', str((i + 1) * 10)), ('p_data_type', q(dt))]))
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), '\n'.join(b)))
    for name, vals, s in STATIC_LOVS:
        nid('9000:lov:' + name, 5)
        b = [call('create_list_of_values', [
            ('p_id', ref('9000:lov:' + name)), ('p_lov_name', q(name)),
            ('p_lov_query', "'.'||%s||'.'" % ref('9000:lov:' + name)), ('p_location', q('STATIC'))],
            'Source: ' + s + ' (values from the XML) / spec 6')]
        for i, (d, r) in enumerate(vals):
            key = '9000:lovd:%s:%s' % (name, r)
            nid(key, 6)
            b.append(call('create_static_lov_data', [
                ('p_id', ref(key)), ('p_lov_disp_sequence', str(i + 1)), ('p_lov_disp_value', q(d)),
                ('p_lov_return_value', q(r))]))
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), '\n'.join(b)))

    # list LIST_IMPR1110_FUNS
    nid('9000:list:FUNS', 7)
    b = [call('create_list', [('p_id', ref('9000:list:FUNS')), ('p_name', q('LIST_IMPR1110_FUNS')),
                              ('p_list_status', q('PUBLIC'))],
              'Source: IMPR1110 LSIDE / TMPLT function menu - spec 13.4 (labels PROPOSED, TODO real titles)')]
    for i, c in enumerate(FUN_CODES):
        key = '9000:li:' + c
        nid(key, 8)
        b.append(call('create_list_item', [
            ('p_id', ref(key)), ('p_list_item_display_sequence', str((i + 1) * 10)),
            ('p_list_item_link_text', q(FUN_LABELS[c])),
            ('p_list_item_link_target', q("javascript:impr1110.fun('%s');" % c)),
            ('p_security_scheme', ref('9000:auth:FUN_' + c)),
            ('p_list_item_current_type', q('TARGET_PAGE'))]))
    W(block('application/shared_components/navigation/lists/list_impr1110_funs', '\n'.join(b)))

    # ---------------------------------------------------------------- page 1110
    W(block('application/pages/delete_01110',
            'wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>1110);'))
    P = []
    A = P.append
    A(call('create_page', [
        ('p_id', '1110'), ('p_user_interface_id', 'wwv_flow_api.id(__USER_INTERFACE_ID__)'),
        ('p_name', q('إضافة وتعديل بيانات مستورد')), ('p_alias', q('IMPR1110')),
        ('p_step_title', q('إضافة وتعديل بيانات مستورد')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', ref('9000:pg:IMPR')),
        ('p_javascript_file_urls', q('#APP_FILES#impr1110#MIN#.js')),
        ('p_step_template', tpl('PAGE_STANDARD')), ('p_page_template_options', q('#DEFAULT#')),
        ('p_required_role', ref('9000:auth:IMPR1110_ACCESS')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1110.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q('20261118000000'))],
        'Source: IMPR1110.fmb - spec 2'))
    regions = [('TOOLBAR', 'TOOLBAR', 10, 'REGION_BUTTONS', 'IMPR1110.TOOLBAR (CIC_OLB toolbar block) / spec 3'),
               ('IMPORTERS', 'إضافة وتعديل بيانات مستورد', 20, 'REGION_STANDARD', 'IMPR1110.IMPORTERS (canvas CG$PAGE_1) / spec 3')]
    for sid, title, seq, t, s in regions:
        nid('1110:plug:' + sid, 1)
        A(call('create_page_plug', [
            ('p_id', ref('1110:plug:' + sid)), ('p_plug_name', q(title)), ('p_region_name', q(sid)),
            ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', tpl(t)),
            ('p_plug_display_sequence', str(seq)), ('p_plug_display_point', q('BODY')),
            ('p_plug_source_type', q('NATIVE_STATIC')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
            ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src(s))]))
    nid('1110:plug:IMPORTERS_FUNS', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1110:plug:IMPORTERS_FUNS')), ('p_plug_name', q('IMPORTERS_FUNS')),
        ('p_region_name', q('IMPORTERS_FUNS')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', tpl('REGION_BLANK')), ('p_plug_display_sequence', '30'),
        ('p_plug_display_point', q('BODY')), ('p_plug_source_type', q('NATIVE_LIST')),
        ('p_list_id', ref('9000:list:FUNS')), ('p_list_template_id', tpl('LIST_MENU_POPUP')),
        ('p_plug_query_num_rows', '15'), ('p_plug_comment', src('IMPR1110.LSIDE (TMPLT side menu) / spec 3, 13.4'))]))

    # buttons (Forms toolbar order) - spec 5
    buttons = [
        ('SAVE', 'حفظ', 'DEFINED_BY_DA', None, 'Y', None, None, 'IMPR1110_ACCESS', 'TOOLBAR.SAVE.WHEN-BUTTON-PRESSED (COMMIT) + PRE-INSERT CONFIRM'),
        ('CREATE', 'جديد', 'DEFINED_BY_DA', None, 'N', None, None, 'IMPR1110_ACCESS', 'Forms CREATE-RECORD (toolbar, OLB)'),
        ('DELETE', 'حذف', 'DEFINED_BY_DA', None, 'N', 'P1110_ROW_ID', 'ITEM_IS_NOT_NULL', 'FUN_REMOVE', 'IMPORTERS.KEY-DELREC'),
        ('QUERY', 'استعلام', 'REDIRECT_PAGE',
         'f?p=&APP_ID.:1111:&SESSION.::&DEBUG.:RP,1111:P1111_PRSNL_IMPR:&P1110_PRSNL_IMPR.',
         'N', None, None, 'IMPR1110_ACCESS', 'TOOLBAR.RE_ENTER_QUERY / ENTER / EXECUTE'),
        ('CLEAR', 'مسح', 'DEFINED_BY_DA', None, 'N', None, None, None, 'FORM.KEY-CLRFRM / TOOLBAR.CLEAR_ALL'),
        ('EXIT', 'خروج', 'REDIRECT_URL', '&HOME_LINK.', 'N', None, None, None, 'TOOLBAR.EXIT.WHEN-BUTTON-PRESSED (EXIT_FORM)'),
        ('FUNCTIONS', 'الوظائف', 'DEFINED_BY_DA', None, 'N', None, None, None, 'FORM.KEY-F9 / TOOLBAR.FUN_BUT'),
    ]
    for i, (nm, lbl, act, url, hot, cond, ctype, auth, s) in enumerate(buttons):
        nid('1110:btn:' + nm, 2)
        prm = [('p_id', ref('1110:btn:' + nm)), ('p_button_sequence', str((i + 1) * 10)),
               ('p_button_plug_id', ref('1110:plug:TOOLBAR')), ('p_button_name', q(nm)),
               ('p_button_static_id', q(nm)), ('p_button_action', q(act)),
               ('p_button_template_options', q('#DEFAULT#')), ('p_button_template_id', tpl('BUTTON_TEXT')),
               ('p_button_is_hot', q(hot) if hot == 'Y' else None), ('p_button_image_alt', q(lbl)),
               ('p_button_position', q('REGION_TEMPLATE_NEXT')),
               ('p_button_redirect_url', q(url) if act == 'REDIRECT_PAGE' else None),
               ('p_button_redirect_url', q(url) if act == 'REDIRECT_URL' else None),
               ('p_warn_on_unsaved_changes', q('I') if act == 'REDIRECT_PAGE' else None),
               ('p_button_execute_validations', q('N') if nm != 'SAVE' else None),
               ('p_button_condition', q(cond)), ('p_button_condition_type', q(ctype)),
               ('p_button_css_classes', q('js-menuButton') if nm == 'FUNCTIONS' else None),
               ('p_button_cattributes', q('data-menu="IMPORTERS_FUNS_menu"') if nm == 'FUNCTIONS' else None),
               ('p_security_scheme', ref('9000:auth:' + auth) if auth else None),
               ('p_button_comment', src('IMPR1110.' + s + ' / spec 5'))]
        A(call('create_page_button', prm))

    nid('1110:branch:STAY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1110:branch:STAY')), ('p_branch_name', q('IMPR1110 - stay on the record')),
        ('p_branch_action', q('f?p=&APP_ID.:1110:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')),
        ('p_branch_sequence', '10'),
        ('p_branch_comment', src('Forms stays in the form after COMMIT / CLEAR (no re-query) / spec 12'))]))

    # items
    rows = read_items()
    items = [spec_item(r) for r in rows]
    items.sort(key=lambda x: x[0])
    names = set()
    for seq, it in items:
        names.add(it['name'])
        A(item_call(1110, '1110:plug:IMPORTERS', seq, it))
    # helper item: prepared URL of the mobile dialog (checksum built on the server)
    A(item_call(1110, '1110:plug:IMPORTERS', 1310, dict(
        name='P1110_URL_MOB', kind='NATIVE_HIDDEN', value_protected='Y', protect='I',
        comment='Source: IMPR1110 PU LOV_UPDATE_MOBLIE (CALL_FORM LOV_UPDATE_IMPR_MOBILE) - URL of page 1112 with checksum / spec 12')))
    nid('1110:comp:URL_MOB', 5)
    A(call('create_page_computation', [
        ('p_id', ref('1110:comp:URL_MOB')), ('p_computation_sequence', '10'),
        ('p_computation_item', q('P1110_URL_MOB')), ('p_computation_point', q('AFTER_HEADER')),
        ('p_computation_type', q('EXPRESSION')), ('p_computation_language', q('PLSQL')),
        ('p_computation', q("apex_page.get_url(p_page => 1112, p_clear_cache => '1112', p_items => 'P1112_IMPR_NBR', p_values => :P1110_IMPR_NBR)")),
        ('p_computation_comment', src('IMPR1110 PU LOV_UPDATE_MOBLIE - dialog URL (presentation only) / spec 12'))]))

    # validations - spec 7
    for i, (itm, suf, s) in enumerate(VALIDATIONS):
        key = '1110:val:' + itm
        nid(key, 6)
        iname = 'P1110_' + itm
        if iname not in names:
            raise KeyError(iname)
        A(call('create_page_validation', [
            ('p_id', ref(key)), ('p_validation_name', q('IMPORTERS.%s.%s' % (itm, suf))),
            ('p_validation_sequence', str((i + 1) * 10)),
            ('p_validation', q("RETURN pkg_impr1110_apx.validate_on_submit('%s');" % itm)),
            ('p_validation2', q('PLSQL')), ('p_validation_type', q('FUNC_BODY_RETURNING_ERR_TEXT')),
            ('p_validation_condition', q('SAVE')), ('p_validation_condition_type', q('REQUEST_EQUALS_CONDITION')),
            ('p_associated_item', 'wwv_flow_api.id(%s)' % _ids['1110:item:' + iname]),
            ('p_error_display_location', q('INLINE_WITH_FIELD_AND_NOTIFICATION')),
            ('p_validation_comment', src('IMPR1110.' + s + ' / spec 7'))]))
    nid('1110:val:REQUIRED', 6)
    A(call('create_page_validation', [
        ('p_id', ref('1110:val:REQUIRED')), ('p_validation_name', q('IMPORTERS.REQUIRED-ITEMS')),
        ('p_validation_sequence', '1000'), ('p_validation', q('RETURN pkg_impr1110_apx.required_items;')),
        ('p_validation2', q('PLSQL')), ('p_validation_type', q('FUNC_BODY_RETURNING_ERR_TEXT')),
        ('p_validation_condition', q('SAVE')), ('p_validation_condition_type', q('REQUEST_EQUALS_CONDITION')),
        ('p_error_display_location', q('INLINE_IN_NOTIFICATION')),
        ('p_validation_comment', src('IMPR1110 Forms FRM-40202 at commit (static Required + SET_ITEM_PROPERTY REQUIRED) / spec 7'))]))

    # processes - spec 8
    procs = [
        ('BEFORE_HEADER', 10, 'WHEN-NEW-FORM-INSTANCE', 'pkg_impr1110_apx.page_wnfi;',
         ('P1110_FORM_OPEN', 'ITEM_IS_NULL', None), 'FORM.WHEN-NEW-FORM-INSTANCE'),
        ('BEFORE_HEADER', 20, 'IMPORTERS.POST-QUERY', 'pkg_impr1110_apx.page_fetch;',
         ('P1110_NEED_FETCH', 'VAL_OF_ITEM_IN_COND_EQ_COND2', 'Y'), 'IMPORTERS.PRE-QUERY, POST-QUERY, PRE-RECORD, WHEN-NEW-RECORD-INSTANCE'),
        ('BEFORE_HEADER', 30, 'IMPORTERS.WHEN-CREATE-RECORD', 'pkg_impr1110_apx.page_new_record;',
         (':P1110_ROW_ID IS NULL AND :P1110_REC_STATUS IS NULL', 'EXPRESSION', 'PLSQL'),
         'IMPORTERS.WHEN-CREATE-RECORD, PRE-RECORD, WHEN-NEW-RECORD-INSTANCE'),
        ('AFTER_SUBMIT', 10, 'IMPORTERS.PRE-INSERT...POST-UPDATE', "pkg_impr1110_apx.page_dml('SAVE');",
         ('SAVE', 'REQUEST_EQUALS_CONDITION', None), 'IMPORTERS.PRE-INSERT, INSERT, POST-INSERT, PRE-UPDATE, UPDATE, POST-UPDATE'),
        ('AFTER_SUBMIT', 20, 'IMPORTERS.KEY-DELREC', "pkg_impr1110_apx.page_dml('DELETE');",
         ('DELETE', 'REQUEST_EQUALS_CONDITION', None), 'IMPORTERS.KEY-DELREC, PRE-DELETE'),
        ('AFTER_SUBMIT', 30, 'IMPORTERS.KEY-CLRBLK', 'pkg_impr1110_apx.page_clear;',
         ('CLEAR,CREATE', 'REQUEST_IN_CONDITION', None), 'FORM.KEY-CLRFRM, IMPORTERS.WHEN-CLEAR-BLOCK, CREATE-RECORD'),
        ('AFTER_SUBMIT', 40, 'IMPORTERS.EXECUTE-QUERY',
         "pkg_impr1110_apx.page_query(CASE :REQUEST WHEN 'QUERY_NBR' THEN TO_NUMBER(:P1110_IMPR_NBR) END);",
         ('QUERY,QUERY_NBR', 'REQUEST_IN_CONDITION', None), 'IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM + WNII re-query, search dialog'),
        ('ON_DEMAND', 10, 'IMPR1110_ITEM', 'pkg_impr1110_apx.ajax_item;', None, 'all item triggers (spec 10)'),
        ('ON_DEMAND', 20, 'IMPR1110_CONFIRM', 'pkg_impr1110_apx.ajax_confirm;', None, 'CONFIRM / WARNING alerts'),
        ('ON_DEMAND', 30, 'IMPR1110_FUN', 'pkg_impr1110_apx.ajax_fun;', None, 'PU EXEC_FUNS'),
    ]
    for pt, seq, name, code, cond, s in procs:
        key = '1110:proc:' + name
        nid(key, 7)
        prm = [('p_id', ref(key)), ('p_process_sequence', str(seq)), ('p_process_point', q(pt)),
               ('p_process_type', q('NATIVE_PLSQL')), ('p_process_name', q(name)),
               ('p_process_sql_clob', q(code)), ('p_process_clob_language', q('PLSQL')),
               ('p_error_display_location', q('INLINE_IN_NOTIFICATION'))]
        if cond:
            prm += [('p_process_when', q(cond[0])), ('p_process_when_type', q(cond[1])),
                    ('p_process_when2', q(cond[2]))]
        prm.append(('p_process_comment', src('IMPR1110.' + s + ' / spec 8')))
        A(call('create_page_process', prm))

    # dynamic actions - spec 10 (behaviour in impr1110.js)
    das = []  # (name, seq, trigger dict, js, comment)
    das.append(('IMPORTERS.UI-STATE', dict(ev='ready'),
                "impr1110.init({confirmNew: ['','NEW','INSERT'].indexOf('&P1110_REC_STATUS.') >= 0"
                " && '&AI_P_CLASS_CD.' === '1' && '&AI_P_USER_TYPE.' === '3'});",
                'all Make_Field_Entrable / SET_ITEM_PROPERTY / GO_ITEM of WNFI, WCR, POST-QUERY, WNRI, DML triggers (DA 1)'))
    for itm in DA_VALIDATE:
        trg = 'POST-CHANGE' if itm in DA_POST_CHANGE_ONLY else 'WHEN-VALIDATE-ITEM'
        das.append(('IMPORTERS.%s.%s' % (itm, trg), dict(ev='change', item='P1110_' + itm),
                    "impr1110.validate('%s');" % itm,
                    'IMPORTERS.%s %s (DA 2%s)' % (itm, 'POST-CHANGE' if trg == 'POST-CHANGE' else 'POST-CHANGE + WHEN-VALIDATE-ITEM',
                                                   ', confirm part = DA 3, re-query = DA 4' if itm in ('BUS_ID', 'IMPR_NBR') else '')))
    das.append(('IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL', dict(ev='change', item='P1110_BUS_ID_TYPE_CD'),
                "impr1110.lovReturn('BUS_ID_TYPE_CD');",
                'IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL after LOV_Impr_Type + BUS_ID_TYPE_CD.POST-CHANGE (DA 5)'))
    for itm in DA_WNII:
        das.append(('IMPORTERS.%s.WHEN-NEW-ITEM-INSTANCE' % itm, dict(ev='focusin', item='P1110_' + itm),
                    "impr1110.wnii('%s');" % itm, 'IMPORTERS.%s.WHEN-NEW-ITEM-INSTANCE (DA 6)' % itm))
    das.append(('IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED', dict(ev='change', item='P1110_COMM_RGSTRTN_TYPE'),
                "impr1110.listChanged('COMM_RGSTRTN_TYPE');", 'IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED (DA 7)'))
    das.append(('IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM', dict(ev='keydown', item='P1110_ARBC_IMPR_NAME'),
                "impr1110.keyNext(this.browserEvent, 'ENG_IMPR_NAME');",
                'IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM - net effect GO_ITEM(ENG_IMPR_NAME) (DA 8)'))
    das.append(('IMPORTERS.PRE-INSERT (confirm) / TOOLBAR.SAVE', dict(ev='click', button='SAVE'),
                'impr1110.save();', 'TOOLBAR.SAVE.WHEN-BUTTON-PRESSED + IMPORTERS.PRE-INSERT CONFIRM (DA 9)'))
    das.append(('IMPORTERS.KEY-DELREC (confirm)', dict(ev='click', button='DELETE'),
                'impr1110.del();', 'IMPORTERS.KEY-DELREC WARNING (DA 10)'))
    das.append(('TOOLBAR.CREATE', dict(ev='click', button='CREATE'),
                "impr1110.clear('CREATE');", 'Forms CREATE-RECORD (toolbar) - warn on unsaved changes'))
    das.append(('FORM.KEY-CLRFRM', dict(ev='click', button='CLEAR'),
                "impr1110.clear('CLEAR');", 'FORM.KEY-CLRFRM / TOOLBAR.CLEAR_ALL - warn on unsaved changes'))
    das.append(('IMPR1110_QUERY dialog closed', dict(ev='apexafterclosedialog', button='QUERY'),
                'impr1110.queryClosed(this.data);', 'Enter / Execute Query of block IMPORTERS (DA 13)'))
    das.append(('IMPR1110_MOBILE / IMPR1110_SUPPORT dialog closed', dict(ev='apexafterclosedialog', js='document'),
                'impr1110.dialogClosed(this.data);',
                'PU LOV_UPDATE_MOBLIE / EXEC_FUNS after CALL_FORM (DA 14, 15)'))
    for i, (name, trg, js, s) in enumerate(das):
        ek = '1110:da:%d' % i
        nid(ek, 8)
        prm = [('p_id', ref(ek)), ('p_name', q(name)), ('p_event_sequence', str((i + 1) * 10))]
        if 'item' in trg:
            prm += [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q(trg['item']))]
        elif 'button' in trg:
            prm += [('p_triggering_element_type', q('BUTTON')),
                    ('p_triggering_button_id', ref('1110:btn:' + trg['button']))]
        elif 'js' in trg:
            prm += [('p_triggering_element_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_element', q(trg['js']))]
        prm += [('p_bind_type', q('bind')), ('p_bind_event_type', q(trg['ev'])),
                ('p_da_event_comment', src('IMPR1110.' + s + ' / spec 10'))]
        A(call('create_page_da_event', prm))
        ak = '1110:daa:%d' % i
        nid(ak, 9)
        A(call('create_page_da_action', [
            ('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
            ('p_action_sequence', '10'), ('p_execute_on_page_init', q('N')),
            ('p_action', q('NATIVE_JAVASCRIPT_CODE')), ('p_attribute_01', q(js)),
            ('p_da_action_comment', src('IMPR1110.' + s + ' - code in impr1110.js'))]))
    W(block('application/pages/page_01110', '\n'.join(P)))

    # ---------------------------------------------------------------- page 1111 (search dialog)
    W(block('application/pages/delete_01111',
            'wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>1111);'))
    P = []
    A = P.append
    A(call('create_page', [
        ('p_id', '1111'), ('p_user_interface_id', 'wwv_flow_api.id(__USER_INTERFACE_ID__)'),
        ('p_name', q('بحث عن مستورد')), ('p_alias', q('IMPR1110_QUERY')), ('p_page_mode', q('MODAL')),
        ('p_step_title', q('بحث عن مستورد')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', ref('9000:pg:IMPR')), ('p_step_template', tpl('PAGE_MODAL')),
        ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_width', q('900')),
        ('p_required_role', ref('9000:auth:IMPR1110_ACCESS')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1110 Enter-Query / Execute-Query of block IMPORTERS / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q('20261118000000'))]))
    nid('1111:plug:QRY', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1111:plug:QRY')), ('p_plug_name', q('IMPORTERS_QRY')), ('p_region_name', q('IMPORTERS_QRY')),
        ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', tpl('REGION_STANDARD')),
        ('p_plug_display_sequence', '10'), ('p_plug_display_point', q('BODY')),
        ('p_plug_source_type', q('NATIVE_STATIC')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')),
        ('p_plug_comment', src('IMPR1110.IMPORTERS.PRE-QUERY (name criterion) / spec 3'))]))
    ir_sql = '\n'.join([
        'SELECT i.impr_nbr, i.arbc_impr_name, i.eng_impr_name, i.bus_id, i.bus_id_brnch,',
        '       i.impr_type_cd, it.impr_type_name, i.bus_id_type_cd, i.ctry_cd, i.hq_impr_nbr',
        '  FROM importers i, impr_types it',
        ' WHERE i.port_cd = :AI_P_CURR_PORT_CD',
        '   AND it.impr_type_cd (+) = i.impr_type_cd',
        "   AND (:P1111_PRSNL_IMPR IS NULL OR :P1111_PRSNL_IMPR <> '1' OR i.impr_type_cd = 4)",
        '   AND (:P1111_ARBC_IMPR_NAME IS NULL',
        '        OR i.impr_name_std LIKE str_db.strformat(:P1111_ARBC_IMPR_NAME, 1))',
        ' ORDER BY i.impr_nbr DESC'])
    nid('1111:plug:IR', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1111:plug:IR')), ('p_plug_name', q('IMPORTERS')), ('p_region_name', q('IMPORTERS')),
        ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', tpl('REGION_STANDARD')),
        ('p_plug_display_sequence', '20'), ('p_plug_display_point', q('BODY')),
        ('p_query_type', q('SQL')), ('p_plug_source', lit(ir_sql)), ('p_plug_source_type', q('NATIVE_IR')),
        ('p_ajax_items_to_submit', q('P1111_ARBC_IMPR_NAME,P1111_PRSNL_IMPR')),
        ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1110.IMPORTERS block query (WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD, ORDER BY IMPR_NBR DESC) + PRE-QUERY / spec 3'))]))
    nid('1111:ws', 2)
    A(call('create_worksheet', [
        ('p_id', ref('1111:ws')), ('p_max_row_count', q('1000000')), ('p_pagination_type', q('ROWS_X_TO_Y')),
        ('p_pagination_display_pos', q('BOTTOM_RIGHT')), ('p_report_list_mode', q('TABS')),
        ('p_show_detail_link', q('C')),
        ('p_detail_link', q("javascript:apex.navigation.dialog.close(true,{IMPR_NBR:'#IMPR_NBR#'});")),
        ('p_detail_link_text', q('<span class="fa fa-check" aria-hidden="true"></span>')),
        ('p_detail_link_attr', q('title="%s"' % 'اختيار'))]))
    cols = [('IMPR_NBR', 'الرقم الجمركي', 'NUMBER'), ('ARBC_IMPR_NAME', 'الاسم العربي', 'STRING'),
            ('ENG_IMPR_NAME', 'الاسم الأجنبي', 'STRING'), ('BUS_ID', 'الرقم الإستدلالي', 'STRING'),
            ('BUS_ID_BRNCH', 'الرقم الفرعي', 'STRING'), ('IMPR_TYPE_CD', 'رمز النشاط', 'NUMBER'),
            ('IMPR_TYPE_NAME', 'النشاط التجاري', 'STRING'), ('BUS_ID_TYPE_CD', 'نوع الرقم الإستدلالي', 'NUMBER'),
            ('CTRY_CD', 'الدولة', 'NUMBER'), ('HQ_IMPR_NBR', 'الرقم الموحد', 'STRING')]
    for i, (c, h, t) in enumerate(cols):
        key = '1111:wsc:' + c
        nid(key, 3)
        A(call('create_worksheet_column', [
            ('p_id', ref(key)), ('p_db_column_name', q(c)), ('p_display_order', str((i + 1) * 10)),
            ('p_column_identifier', q(chr(65 + i))), ('p_column_label', q(h)), ('p_column_type', q(t)),
            ('p_heading_alignment', q('LEFT')), ('p_column_alignment', q('LEFT'))]))
    nid('1111:wsr', 4)
    A(call('create_worksheet_rpt', [
        ('p_id', ref('1111:wsr')), ('p_application_user', q('APXWS_DEFAULT')), ('p_report_seq', '10'),
        ('p_report_alias', q('IMPR1110Q')), ('p_status', q('PUBLIC')), ('p_is_default', q('Y')),
        ('p_report_columns', q(':'.join(c for c, _, _ in cols)))]))
    A(item_call(1111, '1111:plug:QRY', 10, dict(
        name='P1111_ARBC_IMPR_NAME', kind='NATIVE_TEXT_FIELD', label='الاسم العربي', maxlen=200, span=8,
        comment='Source: IMPR1110.IMPORTERS.ARBC_IMPR_NAME (PRE-QUERY: IMPR_NAME_STD LIKE STR.StrFormat(name, TRUE))')))
    A(item_call(1111, '1111:plug:QRY', 20, dict(
        name='P1111_PRSNL_IMPR', kind='NATIVE_HIDDEN', value_protected='Y', protect='S',
        comment='Source: IMPR1110 :PARAMETER.PRSNL_IMPR (PRE-QUERY: IMPR_TYPE_CD = 4 when 1)')))
    nid('1111:btn:SEARCH', 5)
    A(call('create_page_button', [
        ('p_id', ref('1111:btn:SEARCH')), ('p_button_sequence', '10'), ('p_button_plug_id', ref('1111:plug:QRY')),
        ('p_button_name', q('SEARCH')), ('p_button_action', q('DEFINED_BY_DA')),
        ('p_button_template_options', q('#DEFAULT#')), ('p_button_template_id', tpl('BUTTON_TEXT')),
        ('p_button_is_hot', q('Y')), ('p_button_image_alt', q('بحث')), ('p_button_position', q('REGION_TEMPLATE_NEXT')),
        ('p_button_comment', src('IMPR1110 TOOLBAR.EXECUTE (Execute Query) / spec 3'))]))
    for i, (nm, trg) in enumerate([('SEARCH', dict(ev='click', button='SEARCH')),
                                   ('P1111_ARBC_IMPR_NAME', dict(ev='change', item='P1111_ARBC_IMPR_NAME'))]):
        ek, ak = '1111:da:%d' % i, '1111:daa:%d' % i
        nid(ek, 6); nid(ak, 7)
        prm = [('p_id', ref(ek)), ('p_name', q('IMPORTERS.EXECUTE-QUERY (%s)' % nm)), ('p_event_sequence', str((i + 1) * 10))]
        if 'item' in trg:
            prm += [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q(trg['item']))]
        else:
            prm += [('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('1111:btn:SEARCH'))]
        prm += [('p_bind_type', q('bind')), ('p_bind_event_type', q(trg['ev'])),
                ('p_da_event_comment', src('IMPR1110 EXECUTE_QUERY of block IMPORTERS / spec 3'))]
        A(call('create_page_da_event', prm))
        A(call('create_page_da_action', [
            ('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')), ('p_action_sequence', '10'),
            ('p_execute_on_page_init', q('N')), ('p_action', q('NATIVE_REFRESH')),
            ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('1111:plug:IR'))]))
    W(block('application/pages/page_01111', '\n'.join(P)))

    # ---------------------------------------------------------------- page 1112 (mobile dialog)
    W(block('application/pages/delete_01112',
            'wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>1112);'))
    P = []
    A = P.append
    A(call('create_page', [
        ('p_id', '1112'), ('p_user_interface_id', 'wwv_flow_api.id(__USER_INTERFACE_ID__)'),
        ('p_name', q('تعديل رقم الجوال')), ('p_alias', q('IMPR1110_MOBILE')), ('p_page_mode', q('MODAL')),
        ('p_step_title', q('تعديل رقم الجوال')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', ref('9000:pg:IMPR')), ('p_step_template', tpl('PAGE_MODAL')),
        ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_width', q('480')),
        ('p_required_role', ref('9000:auth:FUN_IMPR1110_MOB')), ('p_protection_level', q('C')),
        ('p_page_comment', src('LOV_UPDATE_IMPR_MOBILE.fmb (called by IMPR1110 function IMPR1110_MOB) / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q('20261118000000'))]))
    for sid, seq, t, s in [('BLK', 10, 'REGION_STANDARD', 'LOV_UPDATE_IMPR_MOBILE.BLK'),
                           ('CTRL_BLK', 20, 'REGION_BUTTONS', 'LOV_UPDATE_IMPR_MOBILE.CTRL_BLK')]:
        nid('1112:plug:' + sid, 1)
        A(call('create_page_plug', [
            ('p_id', ref('1112:plug:' + sid)), ('p_plug_name', q(sid)), ('p_region_name', q(sid)),
            ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', tpl(t)),
            ('p_plug_display_sequence', str(seq)), ('p_plug_display_point', q('BODY')),
            ('p_plug_source_type', q('NATIVE_STATIC')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
            ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src(s + ' / spec 3'))]))
    for i, (nm, lbl, hot, s) in enumerate([('PB_OK', 'موافق', 'Y', 'CTRL_BLK.PB_OK'),
                                           ('PB_CANCEL', 'إلغاء', 'N', 'CTRL_BLK.PB_CANCEL')]):
        nid('1112:btn:' + nm, 2)
        A(call('create_page_button', [
            ('p_id', ref('1112:btn:' + nm)), ('p_button_sequence', str((i + 1) * 10)),
            ('p_button_plug_id', ref('1112:plug:CTRL_BLK')), ('p_button_name', q(nm)),
            ('p_button_action', q('SUBMIT')), ('p_button_template_options', q('#DEFAULT#')),
            ('p_button_template_id', tpl('BUTTON_TEXT')), ('p_button_is_hot', q(hot) if hot == 'Y' else None),
            ('p_button_image_alt', q(lbl)), ('p_button_position', q('REGION_TEMPLATE_NEXT')),
            ('p_button_execute_validations', q('N') if nm == 'PB_CANCEL' else None),
            ('p_button_comment', src('LOV_UPDATE_IMPR_MOBILE.%s.WHEN-BUTTON-PRESSED / spec 3' % s))]))
    A(item_call(1112, '1112:plug:BLK', 10, dict(
        name='P1112_MOBILE_NO', kind='NATIVE_TEXT_FIELD', label='رقم الجوال', subtype='PHONE', maxlen=31, span=6,
        comment='Source: LOV_UPDATE_IMPR_MOBILE.BLK.MOBILE_NO')))
    A(item_call(1112, '1112:plug:BLK', 20, dict(
        name='P1112_IMPR_NBR', kind='NATIVE_HIDDEN', value_protected='Y', protect='S',
        comment='Source: IMPR1110 :IMPORTERS.IMPR_NBR passed to LOV_UPDATE_IMPR_MOBILE (link with checksum)')))
    nid('1112:comp:MOB', 3)
    A(call('create_page_computation', [
        ('p_id', ref('1112:comp:MOB')), ('p_computation_sequence', '10'),
        ('p_computation_item', q('P1112_MOBILE_NO')), ('p_computation_point', q('BEFORE_HEADER')),
        ('p_computation_type', q('FUNCTION_BODY')), ('p_computation_language', q('PLSQL')),
        ('p_computation', q('RETURN pkg_impr1110_apx.central_mobile(:P1112_IMPR_NBR);')),
        ('p_compute_when', q('P1112_MOBILE_NO')), ('p_compute_when_type', q('ITEM_IS_NULL')),
        ('p_computation_comment', src('LOV_UPDATE_IMPR_MOBILE.BLK.WHEN-NEW-BLOCK-INSTANCE (MOBILE_NO := :PARAMETER.P_CENTRAL_MOBILE) / spec 9'))]))
    for seq, name, code, req, s in [
            (10, 'CTRL_BLK.PB_OK.WHEN-BUTTON-PRESSED', "pkg_forms_compat.set_global('MOBILE_NO', :P1112_MOBILE_NO);",
             'PB_OK', 'LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_OK.WHEN-BUTTON-PRESSED (:GLOBAL.OK := 1; COPY_SELECTED_VALUES)'),
            (20, 'CTRL_BLK.PB_CANCEL.WHEN-BUTTON-PRESSED', "pkg_forms_compat.set_global('MOBILE_NO', NULL);",
             'PB_CANCEL', 'LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_CANCEL.WHEN-BUTTON-PRESSED (CANCEL_LOV_FORM)')]:
        key = '1112:proc:' + name
        nid(key, 4)
        A(call('create_page_process', [
            ('p_id', ref(key)), ('p_process_sequence', str(seq)), ('p_process_point', q('AFTER_SUBMIT')),
            ('p_process_type', q('NATIVE_PLSQL')), ('p_process_name', q(name)),
            ('p_process_sql_clob', q(code)), ('p_process_clob_language', q('PLSQL')),
            ('p_error_display_location', q('INLINE_IN_NOTIFICATION')),
            ('p_process_when_button_id', ref('1112:btn:' + req)),
            ('p_process_comment', src(s + ' / spec 8'))]))
    nid('1112:proc:CLOSE', 4)
    A(call('create_page_process', [
        ('p_id', ref('1112:proc:CLOSE')), ('p_process_sequence', '30'), ('p_process_point', q('AFTER_SUBMIT')),
        ('p_process_type', q('NATIVE_CLOSE_WINDOW')), ('p_process_name', q('Close Dialog')),
        ('p_error_display_location', q('INLINE_IN_NOTIFICATION')),
        ('p_process_when', q('PB_OK,PB_CANCEL')), ('p_process_when_type', q('REQUEST_IN_CONDITION')),
        ('p_process_comment', src('LOV_UPDATE_IMPR_MOBILE EXIT_FORM after OK / CANCEL / spec 8'))]))
    W(block('application/pages/page_01112', '\n'.join(P)))

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

def selfcheck(text):
    problems = []
    if 'wwv_flow_imp' in text:
        problems.append('wwv_flow_imp found')
    if '{{' in text:
        problems.append('{{ found')
    allowed = {'__WORKSPACE_ID__', '__APP_ID__', '__SCHEMA_NAME__', '__USER_INTERFACE_ID__'}
    ph = set(re.findall(r'__[A-Z_]+__', text))
    bad = [p for p in ph if p not in allowed and not p.startswith('__TEMPLATE_ID_')]
    if bad:
        problems.append('unexpected placeholders %s' % bad)
    if re.search(r'password|pwd', text, re.I):
        problems.append('password text found')
    defined = set(re.findall(r'[ ,]p_id=>wwv_flow_api\.id\((\d+)\)', text))
    used = set(re.findall(r'wwv_flow_api\.id\((\d+)\)', text))
    if used - defined:
        problems.append('ids used but not defined: %s' % sorted(used - defined))
    if len(defined) != len(re.findall(r'[ ,]p_id=>wwv_flow_api\.id\((\d+)\)', text)):
        problems.append('duplicate p_id')
    if text.count('\nbegin\n') + text.count('\nbegin\r\n') != text.count('\nend;\n/'):
        problems.append('begin/end not balanced')
    for m in re.finditer(r"p_(?:lov_name|name|process_name|validation_name)=>'([^']*)'", text):
        pass
    counts = {k: len(re.findall(r'wwv_flow_api\.%s\(' % k, text)) for k in [
        'create_page', 'create_page_plug', 'create_page_item', 'create_page_button', 'create_page_validation',
        'create_page_process', 'create_page_da_event', 'create_page_da_action', 'create_page_computation',
        'create_page_branch', 'create_list_of_values', 'create_list_of_values_cols', 'create_static_lov_data',
        'create_flow_item', 'create_security_scheme', 'create_list', 'create_list_item', 'create_worksheet',
        'create_worksheet_column', 'create_worksheet_rpt', 'create_page_group']}
    return problems, counts, sorted(ph)

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    t = gen()
    probs, counts, ph = selfcheck(t)
    print('written', OUT, len(t.splitlines()), 'lines')
    for k, v in counts.items():
        print('  %-28s %d' % (k, v))
    print('placeholders:', ', '.join(ph))
    print('problems:', probs or 'none')
