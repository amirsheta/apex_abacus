# -*- coding: utf-8 -*-
"""
gen_apex_impr1110.py - step 04 generator for IMPR1110 (Forms -> APEX 21.2, wwv_flow_api),
built to the f345 reference standard (CLAUDE.md 4b, docs/f345_reference_standard.md).

Reads
  analysis/IMPR1110/IMPR1110_apex_page_spec.md   section 4 (page items)
  apex/Reference/f345.sql                        template ids, ids, app items, LOV names (checks)
  plsql/IMPR1110/impr1110_spec.sql               members of package IMPR1110 (checks)
Writes
  apex/IMPR1110/f345_impr1110.sql                component export, REVIEW BEFORE IMPORT

Pages: 1110 IMPR1110 (main), 111001 IMPR1110_SEARCH (modal, page 0 SEARCH button),
       111002 IMPR1110_MOBILE (modal, function IMPR1110_MOB).
IDs are deterministic: re-running gives the same file.

Usage (from forms_to_apex_toolkit):  python3 -I scripts/gen_apex_impr1110.py
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(ROOT, 'analysis', 'IMPR1110', 'IMPR1110_apex_page_spec.md')
REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')
PKG = os.path.join(ROOT, 'plsql', 'IMPR1110', 'impr1110_spec.sql')
OUT = os.path.join(ROOT, 'apex', 'IMPR1110', 'f345_impr1110.sql')
DATE = '2026-11-18'
FORM = 'IMPR1110'
PG, PG_SEARCH, PG_MOB = 1110, 111001, 111002

# ----------------------------------------------------------------------------- f345 ids
# docs/f345_reference_standard.md 3 - all checked against f345.sql by selfcheck()
F345 = dict(
    UI='11622010846008869795',               # user interface Desktop
    PAGE_MAIN='11622270914969205733',        # page template Zatca-Minimal_No_Navigation (as AGR1100)
    REGION_HERO='11621859120066869682',      # Blank with Attributes
    REGION_FORM='11621909206693869707',      # Interactive Report (single-record block, as AGR1100)
    REGION_GRID='11621913486616869708',      # Standard (IG / search results)
    REGION_DIALOG='11621894586660869699',    # Inline Dialog (FUNCS)
    REGION_BUTTONS='11621861869875869684',   # Buttons Container
    LABEL_REQ='11621984380233869750',        # Required - Above
    LABEL_OPT='11621983529556869749',        # Optional - Above
    BUTTON='11621986167597869752',           # Text with Icon
    LIST_FUNS_TPL='63163863023905992916',    # list template Moy Functions Nav
    LIST_PAGE_FUNS='73054485650159247603',   # shared list "Page Functions"
    P0_ACTIONS='73488102084440079322',       # page 0 region P0_ACTIONS (toolbar)
)
ITEM_OPTS = '#DEFAULT#:t-Form-fieldContainer--stretchInputs'

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
    """Long literal (code). Split into 3000-char pieces joined with ||."""
    if s is None:
        return 'null'
    if len(s) <= 3000:
        return q(s)
    parts = [s[i:i + 3000] for i in range(0, len(s), 3000)]
    return '\n||'.join(q(p) for p in parts)

_ids = {}
def nid(key, kind):
    """Deterministic id: <page or 9000><kind 2><seq 6>."""
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

def fid(name):
    return 'wwv_flow_api.id(%s)' % F345[name]

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
# :GLOBAL.X -> application item G_X (f345 convention, FORMS_COMPAT.global_item)
GLOBALS = ['FLAGUPDATE', 'EXEC_QUERY_NOW', 'PORT_CD', 'IMPR_NBR', 'VALID', 'FUNS_IMP', 'FUNS_BUSID',
           'CHK_IMP_TYP', 'CHK_DUP_BUSID', 'OLD_IMPR_TYPE_CD', 'OLD_PORT_CD', 'ALLOW_MCI', 'ALLOW_MOI',
           'SET', 'MINS_COMM_CD', 'LETTER_NBR', 'SUPP_TITLE_CD', 'LETTER_DT', 'MOBILE_NO', 'IMPR_NBR_B',
           'IMPR_NAME_B', 'BRKR_ATHRZTN_NBR_B', 'CHEK', 'STAT_QUE', 'STAT_CLR', 'IMP0F4',
           'EXE_DETAIL_QUERY', 'INS']
# menu parameters the f345 application does not have yet (IMPR1110_APX.ai), and the two
# Forms parameters callers hand to the page (PARAMETERS ENTRY)
NEW_PARAMS = [('P_BRKR_PORT_CD', ':PARAMETER.P_BRKR_PORT_CD of the menu (CIC_MENU)'),
              ('P_LIC_TYPE', ':PARAMETER.P_LIC_TYPE of the menu (CIC_MENU)'),
              ('P_PRSNL_IMPR', ':PARAMETER.PRSNL_IMPR of IMPR1110 (set by the caller, read once)'),
              ('P_LETTER_NBR', ':PARAMETER.LETTER_NBR of IMPR1110 (set by the caller, read once)')]

# (name, sql, extra columns [(col, heading, type)], source) - binds use f345 item names
LOVS = [
    ('LOV_SD_PORTS',
     'SELECT port_cd d, port_cd r, port_name FROM sd_ports WHERE port_status = 1 '
     'AND port_type = NVL(:P_PORT_TYPE, port_type) ORDER BY port_cd',
     [('PORT_NAME', 'اسم الجمرك', 'VARCHAR2')], 'LOV form LOV_SD_PORTS / CGFK$IMPORTERS_PORT_CD'),
    ('LOV_IMPR_TYPE',
     'SELECT DISTINCT itidt.impr_type_cd d, itidt.impr_type_cd r, it.impr_type_name '
     'FROM impr_type_id_types itidt, impr_types it WHERE it.impr_type_cd = itidt.impr_type_cd '
     "AND itidt.impr_type_cd > 0 AND (:G_CHK_IMP_TYP = '1' OR itidt.status = 1) ORDER BY 2",
     [('IMPR_TYPE_NAME', 'النشاط التجاري', 'VARCHAR2')], 'LOV form LOV_Impr_Type (type part) / CGFK$IMPORTERS_IMPR_TYPE_CD'),
    ('LOV_IMPR_TYPE_BUS_ID',
     'SELECT bit.bus_id_type_name d, itidt.bus_id_type_cd r FROM impr_type_id_types itidt, bus_id_types bit '
     'WHERE bit.bus_id_type_cd = itidt.bus_id_type_cd AND itidt.impr_type_cd = :P1110_IMPR_TYPE_CD '
     "AND itidt.impr_type_cd > 0 AND (:G_CHK_IMP_TYP = '1' OR itidt.status = 1) ORDER BY itidt.bus_id_type_cd",
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
     'WHERE port_cd = :P_CURR_PORT_CD',
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

# function codes = custom events fired by the f345 "Page Functions" list (SYS_OS_FILE_NAME)
FUN_CODES = ['IMPR1110F1', 'IMPR1110F2', 'IMPR1110F3', 'IMPR1110F4', 'IMPR1110F5', 'IMPR_CAR_AGENT',
             'IMPR_MCI_SERVICE', 'CREATE_BRKR_IMPR_AUTH', 'IMPR1115_GZT', 'IMPR1115_SCR', 'IMPR1110_MOB']

VALIDATIONS = [  # (item, source)
    ('PORT_CD', 'IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM'),
    ('HQ_IMPR_NBR', 'IMPORTERS.HQ_IMPR_NBR.POST-CHANGE'),
    ('IMPR_NBR', 'IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM'),
    ('IMPR_TYPE_CD', 'IMPORTERS.IMPR_TYPE_CD.POST-CHANGE + WHEN-VALIDATE-ITEM'),
    ('BUS_ID_EXPRD_DT', 'IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM'),
    ('BUS_ID_TYPE_CD', 'IMPORTERS.BUS_ID_TYPE_CD.POST-CHANGE'),
    ('CITY_CODE_OF_ID', 'IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM'),
    ('BUS_ID', 'IMPORTERS.BUS_ID.POST-CHANGE + WHEN-VALIDATE-ITEM'),
    ('BRNH_CITY_CD', 'IMPORTERS.BRNH_CITY_CD.WHEN-VALIDATE-ITEM'),
    ('BUS_ID_BRNCH', 'IMPORTERS.BUS_ID_BRNCH.POST-CHANGE + WHEN-VALIDATE-ITEM'),
    ('CTRY_CD', 'IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM'),
    ('IMPR_EXPR_TYPE', 'IMPORTERS.IMPR_EXPR_TYPE.POST-CHANGE'),
    ('ARBC_IMPR_NAME', 'IMPORTERS.ARBC_IMPR_NAME.WHEN-VALIDATE-ITEM'),
    ('ENG_IMPR_NAME', 'IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM'),
    ('BUS_ID_ISSUE_DT', 'IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM'),
    ('IMPR_NBR_PARENT', 'IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM'),
    ('ADD_CTRY_CD', 'IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM'),
    ('CITY_CODE', 'IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM'),
    ('IMPR_TEL_NBR', 'IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM'),
    ('B_EMAIL', 'IMPORTERS.B_EMAIL.POST-CHANGE + WHEN-VALIDATE-ITEM'),
    ('EMAIL', 'IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM'),
    ('B_MOBILE_NO', 'IMPORTERS.B_MOBILE_NO.POST-CHANGE + WHEN-VALIDATE-ITEM'),
    ('BANK_IBAN', 'IMPORTERS.BANK_IBAN.WHEN-VALIDATE-ITEM'),
    ('B_ID_NBR', 'IMPORTERS.B_ID_NBR.POST-CHANGE + WHEN-VALIDATE-ITEM'),
    ('CTRY_CD_OF_ID', 'IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM'),
]
# item DAs (POST-CHANGE + WVI on change) - spec section 10
DA_VALIDATE = ['PORT_CD', 'HQ_IMPR_NBR', 'IMPR_NBR', 'IMPR_TYPE_CD', 'BUS_ID_EXPRD_DT', 'CITY_CODE_OF_ID',
               'BUS_ID', 'BRNH_CITY_CD', 'BUS_ID_BRNCH', 'CTRY_CD', 'IMPR_EXPR_TYPE', 'ARBC_IMPR_NAME',
               'ENG_IMPR_NAME', 'BUS_ID_ISSUE_DT', 'IMPR_NBR_PARENT', 'ADD_CTRY_CD', 'CITY_CODE',
               'IMPR_TEL_NBR', 'B_EMAIL', 'B_MOBILE_NO', 'BANK_IBAN', 'B_ID_NBR']
DA_POST_CHANGE_ONLY = {'HQ_IMPR_NBR', 'IMPR_EXPR_TYPE'}
DA_WNII = ['IMPR_TYPE_CD', 'CITY_CODE_OF_ID', 'BUS_ID', 'BRNH_CITY_CD', 'BUS_ID_BRNCH', 'BANK_IBAN']

# ----------------------------------------------------------------------------- generation
def item_call(page, plug_key, seq, it):
    k = it['kind']
    p = [('p_id', 'wwv_flow_api.id(%s)' % nid('%s:item:%s' % (page, it['name']), 4)),
         ('p_name', q(it['name'])), ('p_item_sequence', str(seq)),
         ('p_item_plug_id', ref(plug_key)), ('p_item_default', q(it.get('default'))),
         ('p_prompt', q(it.get('label'))), ('p_post_element_text', q(it.get('post'))),
         ('p_format_mask', q(it.get('mask'))), ('p_display_as', q(k))]
    if it.get('lov'):
        p.append(('p_named_lov', q(it['lov'])))
        p.append(('p_lov_display_null', q('YES')))
        if k != 'NATIVE_POPUP_LOV':
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
        elif it.get('grid_css'):
            p.append(('p_grid_column_css_classes', q(it['grid_css'])))
        # f345: Required - Above / Optional - Above + stretchInputs (standard 3)
        p.append(('p_field_template', fid('LABEL_REQ' if it.get('req') else 'LABEL_OPT')))
        p.append(('p_item_template_options', q(ITEM_OPTS)))
    if it.get('tag'):
        p.append(('p_tag_attributes', q(it['tag'])))
    if it.get('req'):
        p.append(('p_is_required', 'true'))
    p.append(('p_protection_level', q(it.get('protect', 'N'))))
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
        # Hidden instead of Display Only so the page-load DA can read it with $v() (import_notes 7)
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
    if it['default'] and 'AI_' in it['default']:
        raise ValueError('AI_ item in default of ' + r['name'])
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
    # the step-03 spec still uses the old package names (pkg_ prefix dropped 2026-11-18)
    it['comment'] = re.sub(r'(?i)\bpkg_impr1110_apx\b', 'IMPR1110_APX',
                           re.sub(r'(?i)\bpkg_impr1110\b', 'IMPR1110',
                                  re.sub(r'(?i)\bpkg_forms_compat\b', 'FORMS_COMPAT', it['comment'])))
    return seq, it

def proc_call(page, key, seq, point, name, code, cond, s, ptype='NATIVE_PLSQL', extra=None):
    nid(key, 7)
    prm = [('p_id', ref(key)), ('p_process_sequence', str(seq)), ('p_process_point', q(point)),
           ('p_process_type', q(ptype)), ('p_process_name', q(name)),
           ('p_process_sql_clob', q(code) if code else None),
           ('p_process_clob_language', q('PLSQL') if code else None),
           ('p_error_display_location', q('INLINE_IN_NOTIFICATION'))]
    if cond:
        prm += [('p_process_when', q(cond[0])), ('p_process_when_type', q(cond[1])),
                ('p_process_when2', q(cond[2]) if len(cond) > 2 else None)]
    prm += (extra or [])
    prm.append(('p_process_comment', src(s)))
    return call('create_page_process', prm)

def da_pair(page, i, name, trg, action, s, affected=None):
    """One DA event + one action. trg: ev + item/button/js/custom"""
    ek, ak = '%s:da:%d' % (page, i), '%s:daa:%d' % (page, i)
    nid(ek, 8)
    nid(ak, 9)
    prm = [('p_id', ref(ek)), ('p_name', q(name)), ('p_event_sequence', str((i + 1) * 10))]
    if 'item' in trg:
        prm += [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q(trg['item']))]
    elif 'js' in trg:
        prm += [('p_triggering_element_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_element', q(trg['js']))]
    prm += [('p_bind_type', q('bind')), ('p_bind_event_type', q(trg['ev'])),
            ('p_bind_event_type_custom', q(trg.get('custom'))),
            ('p_da_event_comment', src(s))]
    ev = call('create_page_da_event', prm)
    if affected:
        act = [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
               ('p_action_sequence', '10'), ('p_execute_on_page_init', q(action[1])),
               ('p_action', q(action[0])), ('p_affected_elements_type', q('REGION')),
               ('p_affected_region_id', affected)]
    else:
        act = [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
               ('p_action_sequence', '10'), ('p_execute_on_page_init', q('N')),
               ('p_action', q('NATIVE_JAVASCRIPT_CODE')), ('p_attribute_01', q(action))]
    return ev + '\n' + call('create_page_da_action', act)

def hide_toolbar_da(page, i):
    # f345 search page: hide the page 0 toolbar inside the dialog
    return da_pair(page, i, 'Hide', dict(ev='ready'), ('NATIVE_HIDE', 'Y'),
                   'f345 AGR1100_SEARCH "Hide" (page 0 region P0_ACTIONS not used in a dialog)',
                   affected=fid('P0_ACTIONS'))

def gen():
    out = []
    W = out.append
    W('''-- =============================================================================
-- REVIEW BEFORE IMPORT
-- File        : apex/IMPR1110/f345_impr1110.sql
-- Generated by: Claude Code (scripts/gen_apex_impr1110.py) from
--               analysis/IMPR1110/IMPR1110_apex_page_spec.md, %s, form IMPR1110
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / docs/f345_reference_standard.md - template ids, page 0 toolbar,
--               search page <page>01, package IMPR1110, G_/P_ application items
-- Contents    : component export INTO the application installed from f345: pages 1110 (main),
--               111001 (search), 111002 (mobile) + the shared components they need.
--               Page SUPPORT_ENTRY (IMPR1110F1/F2/F3/F5) is not generated.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__
--               - see apex/IMPR1110/import_notes.md
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
                 'Source: IMPR1110.fmb module group IMPR / spec section 0')))

    body = []
    for g in GLOBALS:
        n = 'G_' + g
        nid('9000:ai:' + n, 2)
        body.append(call('create_flow_item', [('p_id', ref('9000:ai:' + n)), ('p_name', q(n)),
                                              ('p_protection_level', q('I')),
                                              ('p_item_comment', src(':GLOBAL.%s / spec 13.1 (f345: G_<name>)' % g))]))
    for n, s in NEW_PARAMS:
        nid('9000:ai:' + n, 2)
        body.append(call('create_flow_item', [('p_id', ref('9000:ai:' + n)), ('p_name', q(n)),
                                              ('p_protection_level', q('I')),
                                              ('p_item_comment', src(s + ' / f345 P_<name>'))]))
    W(block('application/shared_components/logic/application_items', '\n'.join(body)))

    # authorization: none generated. Page access comes from the application's own privileges
    # (user decision 2026-11-18); function rights come from the f345 "Page Functions" list.
    # The id is still reserved so the ids of the components after it (LOVs ...) do not change.
    nid('9000:auth:IMPR1110_ACCESS', 3)

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

    # ---------------------------------------------------------------- page 1110 (main)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG)
    A(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')),
        ('p_name', q(FORM)), ('p_alias', q(FORM)), ('p_step_title', q('&SYS_ANAME.')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', ref('9000:pg:IMPR')),
        ('p_javascript_file_urls', q('#APP_FILES#impr1110#MIN#.js')),
        ('p_step_template', fid('PAGE_MAIN')), ('p_page_css_classes', q('zf')),
        ('p_page_template_options', q('#DEFAULT#')),
        ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1110.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q('20261118000000'))],
        'Source: IMPR1110.fmb - spec 2 / f345 standard 4'))
    hero = ('<div class="cg-hero-row"><div class="cg-hero-top"><span class="cg-hero-ic fa fa-id-card-o" '
            'aria-hidden="true"></span><div><div class="cg-hero-k">المستوردون</div>'
            '<div class="cg-hero-t">&P1110_HERO_TITLE.</div>'
            '<div class="cg-hero-d">إضافة وتعديل بيانات المستورد وبيانات النشاط والعنوان</div></div></div></div>')
    nid('1110:plug:HERO', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1110:plug:HERO')), ('p_plug_name', q('الهيدر')), ('p_region_css_classes', q('cg-hero')),
        ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '5'), ('p_plug_source', q(hero)),
        ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')), ('p_attribute_01', q('N')),
        ('p_attribute_02', q('HTML')), ('p_plug_comment', src('f345 hero region (HEADER TITLE) / standard 3'))]))
    nid('1110:plug:IMPORTERS', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1110:plug:IMPORTERS')), ('p_plug_name', q('بيانات المستورد')),
        ('p_region_name', q('IMPORTERS')), ('p_region_css_classes', q('zatca-forms cg-form cg-card')),
        ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_FORM')),
        ('p_plug_display_sequence', '10'), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')),
        ('p_plug_comment', src('IMPR1110.IMPORTERS (canvas CG$PAGE_1). Static region, not NATIVE_FORM: '
                               'the DML is done by IMPR1110.ON_INSERT/ON_UPDATE/KEY_DELREC / spec 3'))]))
    nid('1110:plug:FUNCS', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1110:plug:FUNCS')), ('p_plug_name', q('الوظائف')), ('p_region_name', q('FUNCS')),
        ('p_region_css_classes', q('cg-funcs')), ('p_region_template_options', q('#DEFAULT#:js-dialog-size600x400')),
        ('p_plug_template', fid('REGION_DIALOG')), ('p_plug_display_sequence', '990'),
        ('p_plug_source_type', q('NATIVE_LIST')), ('p_list_id', fid('LIST_PAGE_FUNS')),
        ('p_list_template_id', fid('LIST_FUNS_TPL')), ('p_plug_query_num_rows', '15'),
        ('p_plug_comment', src('IMPR1110.LSIDE / TMPLT function menu (FORM.KEY-F9). Opened by page 0 '
                               'button FUNCS; rows and rights from the f345 list "Page Functions" / spec 13.4'))]))

    nid('1110:branch:STAY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1110:branch:STAY')), ('p_branch_name', q('IMPR1110 - stay on the record')),
        ('p_branch_action', q('f?p=&APP_ID.:1110:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')),
        ('p_branch_sequence', '10'),
        ('p_branch_comment', src('Forms stays in the form after COMMIT (no re-query) / spec 12'))]))

    rows = read_items()
    items = sorted((spec_item(r) for r in rows), key=lambda x: x[0])
    names = set()
    for seq, it in items:
        names.add(it['name'])
        A(item_call(PG, '1110:plug:IMPORTERS', seq, it))
    extra_items = [
        (1300, dict(name='P1110_MODULE_ID', kind='NATIVE_HIDDEN', value_protected='Y', protect='I',
                    comment='Source: f345 P<page>_MODULE_ID (kept by SCREEN ENTRY RESET; SC_SYSTEM_OBJECTS.SYSOBJ_ID of IMPR1110)')),
        (1305, dict(name='P1110_HERO_TITLE', kind='NATIVE_HIDDEN', value_protected='Y', protect='I',
                    comment='Source: f345 HEADER TITLE (hero region)')),
        (1310, dict(name='P1110_URL_MOB', kind='NATIVE_HIDDEN', value_protected='Y', protect='I',
                    comment='Source: IMPR1110 PU LOV_UPDATE_MOBLIE (CALL_FORM LOV_UPDATE_IMPR_MOBILE) - URL of page 111002 with checksum')),
    ]
    for seq, it in extra_items:
        names.add(it['name'])
        A(item_call(PG, '1110:plug:IMPORTERS', seq, it))
    nid('1110:comp:URL_MOB', 5)
    A(call('create_page_computation', [
        ('p_id', ref('1110:comp:URL_MOB')), ('p_computation_sequence', '10'),
        ('p_computation_item', q('P1110_URL_MOB')), ('p_computation_point', q('AFTER_HEADER')),
        ('p_computation_type', q('EXPRESSION')), ('p_computation_language', q('PLSQL')),
        ('p_computation', q('IMPR1110.MOBILE_URL(I_P1110_IMPR_NBR => :P1110_IMPR_NBR)')),
        ('p_computation_comment', src('IMPR1110 PU LOV_UPDATE_MOBLIE - dialog URL (presentation only) / spec 12'))]))

    # validations - spec 7, f345 names "<ITEM> VALIDATION"; CREATE inserts, SAVE updates
    for i, (itm, s) in enumerate(VALIDATIONS):
        key = '1110:val:' + itm
        nid(key, 6)
        iname = 'P1110_' + itm
        if iname not in names:
            raise KeyError(iname)
        A(call('create_page_validation', [
            ('p_id', ref(key)), ('p_validation_name', q('%s VALIDATION' % itm)),
            ('p_validation_sequence', str((i + 1) * 10)),
            ('p_validation', q('return IMPR1110.%s_VALIDATION(I_%s => :%s);' % (itm, iname, iname))),
            ('p_validation2', q('PLSQL')), ('p_validation_type', q('FUNC_BODY_RETURNING_ERR_TEXT')),
            ('p_validation_condition', q('CREATE,SAVE')), ('p_validation_condition_type', q('REQUEST_IN_CONDITION')),
            ('p_associated_item', 'wwv_flow_api.id(%s)' % _ids['1110:item:' + iname]),
            ('p_error_display_location', q('INLINE_WITH_FIELD_AND_NOTIFICATION')),
            ('p_validation_comment', src('IMPR1110.' + s + ' / spec 7'))]))
    nid('1110:val:REQUIRED', 6)
    A(call('create_page_validation', [
        ('p_id', ref('1110:val:REQUIRED')), ('p_validation_name', q('IMPORTERS REQUIRED')),
        ('p_validation_sequence', '1000'), ('p_validation', q('return IMPR1110.REQUIRED_ITEMS_VALIDATION;')),
        ('p_validation2', q('PLSQL')), ('p_validation_type', q('FUNC_BODY_RETURNING_ERR_TEXT')),
        ('p_validation_condition', q('CREATE,SAVE')), ('p_validation_condition_type', q('REQUEST_IN_CONDITION')),
        ('p_error_display_location', q('INLINE_IN_NOTIFICATION')),
        ('p_validation_comment', src('IMPR1110 Forms FRM-40202 at commit (static Required + SET_ITEM_PROPERTY REQUIRED) / spec 7'))]))

    # processes - f345 standard 6 order
    BH, AS, OD = 'BEFORE_HEADER', 'AFTER_SUBMIT', 'ON_DEMAND'
    procs = [
        (BH, 20, 'P0_PAGE_PK CHECK', 'IMPR1110.P0_PAGE_PK_CHECK(IO_P0_PAGE_PK => :P0_PAGE_PK);', None,
         'f345 P0_PAGE_PK CHECK (key of another port or a deleted importer is dropped)'),
        (BH, 40, 'PARAMETERS', ':P1110_MODULE_ID := IMPR1110.GET_MODULE_ID(I_P1110_MODULE_ID => :P1110_MODULE_ID);', None,
         'f345 PARAMETERS (module id for the function list)'),
        (BH, 50, 'PARAMETERS ENTRY',
         'IMPR1110.PARAMETERS_ENTRY(IO_P_PRSNL_IMPR => :P_PRSNL_IMPR, IO_P_LETTER_NBR => :P_LETTER_NBR, '
         'IO_P1110_PRSNL_IMPR => :P1110_PRSNL_IMPR, IO_P1110_LETTER_NBR => :P1110_LETTER_NBR);',
         (':P_PRSNL_IMPR is not null or :P_LETTER_NBR is not null', 'EXPRESSION', 'PLSQL'),
         'IMPR1110 :PARAMETER.PRSNL_IMPR / LETTER_NBR (f345 PARAMETERS ENTRY)'),
        (BH, 60, 'WHEN-NEW-FORM-INSTANCE', 'IMPR1110.WHEN_NEW_FORM_INSTANCE;',
         ('P1110_FORM_OPEN', 'ITEM_IS_NULL'), 'FORM.WHEN-NEW-FORM-INSTANCE'),
        (BH, 70, 'P0_PAGE_PK', 'IMPR1110.SET_PAGE_PK(I_P0_PAGE_PK => :P0_PAGE_PK);', None,
         'f345 P0_PAGE_PK (record chosen on the search page 111001)'),
        (BH, 80, 'POST-QUERY', 'IMPR1110.POST_QUERY;', ('P1110_NEED_FETCH', 'VAL_OF_ITEM_IN_COND_EQ_COND2', 'Y'),
         'IMPORTERS.PRE-QUERY, POST-QUERY, PRE-RECORD, WHEN-NEW-RECORD-INSTANCE'),
        (BH, 85, 'WHEN-CREATE-RECORD', 'IMPR1110.WHEN_CREATE_RECORD;',
         (':P1110_ROW_ID IS NULL AND :P1110_REC_STATUS IS NULL', 'EXPRESSION', 'PLSQL'),
         'IMPORTERS.WHEN-CREATE-RECORD, PRE-RECORD, WHEN-NEW-RECORD-INSTANCE'),
        (BH, 100, 'HEADER TITLE',
         'IMPR1110.HEADER_TITLE(I_P1110_MODULE_ID => :P1110_MODULE_ID, IO_P1110_HERO_TITLE => :P1110_HERO_TITLE);',
         None, 'f345 HEADER TITLE'),
        (AS, 10, 'ON-INSERT', 'IMPR1110.ON_INSERT;',
         (":P0_PAGE_PK is null and :REQUEST = 'CREATE'", 'EXPRESSION', 'PLSQL'),
         'IMPORTERS.PRE-INSERT, INSERT, POST-INSERT (page 0 button CREATE)'),
        (AS, 20, 'ON-UPDATE', 'IMPR1110.ON_UPDATE;',
         (":P0_PAGE_PK is not null and :REQUEST = 'SAVE'", 'EXPRESSION', 'PLSQL'),
         'IMPORTERS.PRE-UPDATE, UPDATE, POST-UPDATE (page 0 button SAVE)'),
        (AS, 30, 'KEY-DELREC', 'IMPR1110.KEY_DELREC;', ('DELETE', 'REQUEST_EQUALS_CONDITION'),
         'IMPORTERS.KEY-DELREC, PRE-DELETE (page 0 button DELETE, confirmed there)'),
        (AS, 80, 'P0_PAGE_PK AFTER INSERT', ':P0_PAGE_PK := :P1110_IMPR_NBR;',
         (":REQUEST = 'CREATE' and :P1110_ROW_ID is not null", 'EXPRESSION', 'PLSQL'),
         'f345 P0_PAGE_PK AFTER INSERT (toolbar switches to SAVE / DELETE)'),
        (AS, 85, 'P0_PAGE_PK AFTER DELETE', ':P0_PAGE_PK := null;', ('DELETE', 'REQUEST_EQUALS_CONDITION'),
         'f345 P0_PAGE_PK AFTER DELETE'),
        (AS, 90, 'EXECUTE-QUERY',
         'IMPR1110.EXECUTE_QUERY(I_REQUEST => :REQUEST, I_P1110_IMPR_NBR => :P1110_IMPR_NBR);',
         ('QUERY,QUERY_NBR', 'REQUEST_IN_CONDITION'), 'IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM + WNII re-query'),
        (OD, 10, 'IMPR1110_ITEM', 'IMPR1110.AJAX_ITEM;', None, 'all item triggers (spec 10), called by impr1110.js'),
        (OD, 20, 'IMPR1110_CONFIRM', 'IMPR1110.AJAX_CONFIRM;', None, 'CONFIRM / WARNING alerts, called by impr1110.js'),
        (OD, 30, 'IMPR1110_FUNCTION', 'IMPR1110.AJAX_FUNCTION;', None, 'PU EXEC_FUNS, called by impr1110.js'),
    ]
    for pt, seq, name, code, cond, s in procs:
        A(proc_call(PG, '1110:proc:' + name, seq, pt, name, code, cond, 'IMPR1110.' + s + ' / spec 8'))

    # dynamic actions - behaviour in impr1110.js (the f345 FOS plug-in cannot ask the Forms
    # confirm questions between the server calls; see import_notes)
    das = []
    das.append(('IMPORTERS UI-STATE', dict(ev='ready'),
                "impr1110.init({confirmNew: ['','NEW','INSERT'].indexOf('&P1110_REC_STATUS.') >= 0"
                " && '&P_CLASS_CD.' === '1' && '&V_USR_TYPE.' === '3'});",
                'all Make_Field_Entrable / SET_ITEM_PROPERTY / GO_ITEM of WNFI, WCR, POST-QUERY, WNRI, DML triggers (DA 1)'))
    for itm in DA_VALIDATE:
        trg = 'POST-CHANGE' if itm in DA_POST_CHANGE_ONLY else 'WHEN-VALIDATE-ITEM'
        das.append(('%s %s' % (itm, trg), dict(ev='change', item='P1110_' + itm),
                    "impr1110.validate('%s');" % itm,
                    'IMPORTERS.%s %s (DA 2)' % (itm, 'POST-CHANGE' if trg == 'POST-CHANGE' else 'POST-CHANGE + WHEN-VALIDATE-ITEM')))
    das.append(('IMPR_TYPE_CD KEY-LISTVAL', dict(ev='change', item='P1110_BUS_ID_TYPE_CD'),
                "impr1110.lovReturn('BUS_ID_TYPE_CD');",
                'IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL after LOV_Impr_Type + BUS_ID_TYPE_CD.POST-CHANGE (DA 5)'))
    for itm in DA_WNII:
        das.append(('%s WHEN-NEW-ITEM-INSTANCE' % itm, dict(ev='focusin', item='P1110_' + itm),
                    "impr1110.wnii('%s');" % itm, 'IMPORTERS.%s.WHEN-NEW-ITEM-INSTANCE (DA 6)' % itm))
    das.append(('COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED', dict(ev='change', item='P1110_COMM_RGSTRTN_TYPE'),
                "impr1110.listChanged('COMM_RGSTRTN_TYPE');", 'IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED (DA 7)'))
    das.append(('ARBC_IMPR_NAME KEY-NEXT-ITEM', dict(ev='keydown', item='P1110_ARBC_IMPR_NAME'),
                "impr1110.keyNext(this.browserEvent, 'ENG_IMPR_NAME');",
                'IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM - net effect GO_ITEM(ENG_IMPR_NAME) (DA 8)'))
    das.append(('PRE-INSERT CONFIRM', dict(ev='apexbeforepagesubmit'),
                'impr1110.beforeSubmit(this.data);',
                'TOOLBAR.SAVE + IMPORTERS.PRE-INSERT confirm, for the page 0 buttons CREATE / SAVE (DA 9)'))
    for code in FUN_CODES:
        das.append((code, dict(ev='custom', js='document', custom=code), "impr1110.fun('%s');" % code,
                    'function %s (TMPLT EXECUTE_FUNCTION), fired by the f345 "Page Functions" list (DA 11)' % code))
    das.append(('DIALOG CLOSED', dict(ev='apexafterclosedialog', js='document'),
                'impr1110.dialogClosed(this.data);', 'PU LOV_UPDATE_MOBLIE after CALL_FORM (DA 14)'))
    for i, (name, trg, js, s) in enumerate(das):
        A(da_pair(PG, i, name, trg, js, 'IMPR1110.' + s + ' / spec 10'))
    W(block('application/pages/page_01110', '\n'.join(P)))

    # ---------------------------------------------------------------- page 111001 (search)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_SEARCH)
    A(call('create_page', [
        ('p_id', str(PG_SEARCH)), ('p_user_interface_id', fid('UI')),
        ('p_name', q(FORM + '_SEARCH')), ('p_alias', q(FORM + '-SEARCH')), ('p_page_mode', q('MODAL')),
        ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', ref('9000:pg:IMPR')),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')),
        ('p_dialog_height', q('800')), ('p_dialog_width', q('1800')),
        ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1110 Enter-Query / Execute-Query of block IMPORTERS (TOOLBAR.RE_ENTER_QUERY) / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q('20261118000000'))],
        'Source: f345 search page <page>01 (opened by page 0 button SEARCH)'))
    nid('111001:plug:CRIT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('111001:plug:CRIT')), ('p_plug_name', q('بحث')), ('p_region_css_classes', q('zatca-forms cg-form')),
        ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '10'), ('p_attribute_01', q('N')), ('p_attribute_02', q('TEXT')),
        ('p_attribute_03', q('Y')), ('p_plug_comment', src('IMPR1110.IMPORTERS.PRE-QUERY (name criterion) / spec 3'))]))
    ig_sql = '\n'.join([
        'select i.impr_nbr PK, i.impr_nbr, i.arbc_impr_name, i.eng_impr_name, i.bus_id, i.bus_id_brnch,',
        "       i.impr_type_cd || ' - ' || it.impr_type_name impr_type, i.hq_impr_nbr",
        '  from importers i, impr_types it',
        ' where it.impr_type_cd(+) = i.impr_type_cd',
        '   and i.port_cd = :P_CURR_PORT_CD',
        "   and (:P1110_PRSNL_IMPR is null or :P1110_PRSNL_IMPR <> '1' or i.impr_type_cd = 4)",
        '   and (:P111001_SEARCH is null',
        '        or i.impr_name_std like str_db.strformat(:P111001_SEARCH, 1)',
        '        or to_char(i.impr_nbr) = :P111001_SEARCH',
        "        or i.bus_id like :P111001_SEARCH || '%')",
        ' order by i.impr_nbr desc'])
    nid('111001:plug:IG', 1)
    A(call('create_page_plug', [
        ('p_id', ref('111001:plug:IG')), ('p_plug_name', q('المستوردون')), ('p_region_name', q('IMPORTERS_SEARCH')),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', '20'), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(ig_sql)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q('P111001_SEARCH')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1110.IMPORTERS block query (WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD, '
                               'ORDER BY IMPR_NBR DESC) + PRE-QUERY (name, PRSNL_IMPR) / spec 3'))]))
    cols = [('PK', None, 'VARCHAR2'), ('IMPR_NBR', 'الرقم الجمركي', 'NUMBER'),
            ('ARBC_IMPR_NAME', 'الاسم العربي', 'VARCHAR2'), ('ENG_IMPR_NAME', 'الاسم الأجنبي', 'VARCHAR2'),
            ('BUS_ID', 'الرقم الإستدلالي', 'VARCHAR2'), ('BUS_ID_BRNCH', 'الرقم الفرعي', 'VARCHAR2'),
            ('IMPR_TYPE', 'النشاط التجاري', 'VARCHAR2'), ('HQ_IMPR_NBR', 'الرقم الموحد', 'VARCHAR2')]
    filt = [('p_enable_filter', 'true'), ('p_filter_operators', q('C:S:CASE_INSENSITIVE:REGEXP')),
            ('p_filter_is_required', 'false'), ('p_filter_text_case', q('MIXED')),
            ('p_filter_lov_type', q('NONE')), ('p_use_as_row_header', 'false'),
            ('p_enable_sort_group', 'true'), ('p_enable_control_break', 'true'), ('p_enable_hide', 'true'),
            ('p_is_primary_key', 'false'), ('p_duplicate_value', 'true'), ('p_include_in_export', 'true')]
    for i, (c, h, dt) in enumerate(cols):
        key = '111001:col:' + c
        nid(key, 2)
        prm = [('p_id', ref(key)), ('p_name', q(c)), ('p_source_type', q('DB_COLUMN')),
               ('p_source_expression', q(c)), ('p_data_type', q(dt)), ('p_is_query_only', 'false')]
        if c == 'PK':
            prm += [('p_item_type', q('NATIVE_HIDDEN')), ('p_display_sequence', '10'), ('p_attribute_01', q('N')),
                    ('p_use_as_row_header', 'false'), ('p_enable_sort_group', 'false'),
                    ('p_is_primary_key', 'false'), ('p_duplicate_value', 'true'), ('p_include_in_export', 'false')]
        elif c == 'IMPR_NBR':
            prm += [('p_item_type', q('NATIVE_LINK')), ('p_heading', q(h)), ('p_heading_alignment', q('CENTER')),
                    ('p_display_sequence', str((i + 1) * 10)), ('p_value_alignment', q('CENTER')),
                    ('p_link_target', q('f?p=&APP_ID.:1110:&SESSION.::&DEBUG.:1110:P0_PAGE_PK:&PK.')),
                    ('p_link_text', q('&IMPR_NBR.')), ('p_link_attributes', q('target="_top"'))] + filt
        else:
            prm += [('p_item_type', q('NATIVE_DISPLAY_ONLY')), ('p_heading', q(h)), ('p_heading_alignment', q('CENTER')),
                    ('p_display_sequence', str((i + 1) * 10)), ('p_value_alignment', q('CENTER')),
                    ('p_attribute_02', q('VALUE')), ('p_attribute_05', q('PLAIN'))] + filt
        A(call('create_region_column', prm))     # f345: no p_region_id, follows its region
    nid('111001:ig', 3)
    A(call('create_interactive_grid', [
        ('p_id', ref('111001:ig')), ('p_internal_uid', '111001000201'), ('p_is_editable', 'false'),
        ('p_lazy_loading', 'false'), ('p_requires_filter', 'false'), ('p_select_first_row', 'true'),
        ('p_fixed_row_height', 'true'), ('p_pagination_type', q('SET')), ('p_show_total_row_count', 'true'),
        ('p_no_data_found_message', q('لا يوجد مستوردون')), ('p_show_toolbar', 'true'),
        ('p_toolbar_buttons', q('SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET')),
        ('p_enable_save_public_report', 'false'), ('p_enable_subscriptions', 'true'),
        ('p_enable_flashback', 'true'), ('p_define_chart_view', 'true'), ('p_enable_download', 'true'),
        ('p_download_formats', q('CSV:HTML:XLSX:PDF')), ('p_enable_mail_download', 'true'),
        ('p_fixed_header', q('PAGE')), ('p_show_icon_view', 'false'), ('p_show_detail_view', 'false')]))
    nid('111001:igr', 3)
    A(call('create_ig_report', [
        ('p_id', ref('111001:igr')), ('p_interactive_grid_id', ref('111001:ig')),
        ('p_static_id', q('111001000202')), ('p_type', q('PRIMARY')), ('p_default_view', q('GRID')),
        ('p_show_row_number', 'false'), ('p_settings_area_expanded', 'true')]))
    nid('111001:igv', 3)
    A(call('create_ig_report_view', [
        ('p_id', ref('111001:igv')), ('p_report_id', ref('111001:igr')), ('p_view_type', q('GRID')),
        ('p_stretch_columns', 'true'), ('p_srv_exclude_null_values', 'false'),
        ('p_srv_only_display_columns', 'true'), ('p_edit_mode', 'false')]))
    for i, (c, h, dt) in enumerate(cols):
        key = '111001:igc:' + c
        nid(key, 3)
        A(call('create_ig_report_column', [
            ('p_id', ref(key)), ('p_view_id', ref('111001:igv')), ('p_display_seq', str((i + 1) * 10)),
            ('p_column_id', ref('111001:col:' + c)), ('p_is_visible', 'false' if c == 'PK' else 'true'),
            ('p_is_frozen', 'false')]))
    A(item_call(PG_SEARCH, '111001:plug:CRIT', 10, dict(
        name='P111001_SEARCH', kind='NATIVE_TEXT_FIELD', label='بحث', maxlen=200,
        post='<span class="cg-ic fa fa-search" aria-hidden="true"></span>', grid_css='col-lg-3 col-sm-6 col-xxs-12',
        comment='Source: IMPR1110.IMPORTERS.ARBC_IMPR_NAME (PRE-QUERY: IMPR_NAME_STD LIKE STR.StrFormat(name, TRUE)) + IMPR_NBR / BUS_ID')))
    A(da_pair(PG_SEARCH, 0, 'SEARCH REFRESH', dict(ev='keyup', item='P111001_SEARCH'), ('NATIVE_REFRESH', 'N'),
              'IMPR1110 EXECUTE_QUERY of block IMPORTERS / spec 3', affected=ref('111001:plug:IG')))
    A(hide_toolbar_da(PG_SEARCH, 1))
    W(block('application/pages/page_111001', '\n'.join(P)))

    # ---------------------------------------------------------------- page 111002 (mobile)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_MOB)
    A(call('create_page', [
        ('p_id', str(PG_MOB)), ('p_user_interface_id', fid('UI')),
        ('p_name', q(FORM + '_MOBILE')), ('p_alias', q(FORM + '-MOBILE')), ('p_page_mode', q('MODAL')),
        ('p_step_title', q('&SYS_ANAME.')), ('p_autocomplete_on_off', q('OFF')), ('p_group_id', ref('9000:pg:IMPR')),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_width', q('480')),
        ('p_protection_level', q('C')),
        ('p_page_comment', src('LOV_UPDATE_IMPR_MOBILE.fmb (called by IMPR1110 function IMPR1110_MOB) / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q('20261118000000'))]))
    for sid, title, seq, t, cls, s in [
            ('BLK', 'تعديل رقم الجوال', 10, 'REGION_FORM', 'zatca-forms cg-form cg-card', 'LOV_UPDATE_IMPR_MOBILE.BLK'),
            ('CTRL_BLK', 'CTRL_BLK', 20, 'REGION_BUTTONS', None, 'LOV_UPDATE_IMPR_MOBILE.CTRL_BLK')]:
        nid('111002:plug:' + sid, 1)
        A(call('create_page_plug', [
            ('p_id', ref('111002:plug:' + sid)), ('p_plug_name', q(title)), ('p_region_name', q(sid)),
            ('p_region_css_classes', q(cls)), ('p_region_template_options', q('#DEFAULT#')),
            ('p_plug_template', fid(t)), ('p_plug_display_sequence', str(seq)),
            ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')), ('p_attribute_01', q('N')),
            ('p_attribute_02', q('HTML')), ('p_plug_comment', src(s + ' / spec 3'))]))
    for i, (nm, lbl, hot, icon, cls, s) in enumerate([
            ('PB_OK', 'موافق', 'Y', 'fa-check', 'cg-b-save', 'CTRL_BLK.PB_OK'),
            ('PB_CANCEL', 'إلغاء', 'N', 'fa-times', 'cg-b-funcs', 'CTRL_BLK.PB_CANCEL')]):
        nid('111002:btn:' + nm, 2)
        A(call('create_page_button', [
            ('p_id', ref('111002:btn:' + nm)), ('p_button_sequence', str((i + 1) * 10)),
            ('p_button_plug_id', ref('111002:plug:CTRL_BLK')), ('p_button_name', q(nm)),
            ('p_button_action', q('SUBMIT')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
            ('p_button_template_id', fid('BUTTON')), ('p_button_is_hot', q(hot) if hot == 'Y' else None),
            ('p_button_image_alt', q(lbl)), ('p_button_position', q('NEXT')),
            ('p_icon_css_classes', q(icon)), ('p_button_css_classes', q(cls)),
            ('p_button_execute_validations', q('N') if nm == 'PB_CANCEL' else None),
            ('p_button_comment', src('LOV_UPDATE_IMPR_MOBILE.%s.WHEN-BUTTON-PRESSED / spec 3' % s))]))
    A(item_call(PG_MOB, '111002:plug:BLK', 10, dict(
        name='P111002_MOBILE_NO', kind='NATIVE_TEXT_FIELD', label='رقم الجوال', subtype='PHONE', maxlen=31, span=6,
        comment='Source: LOV_UPDATE_IMPR_MOBILE.BLK.MOBILE_NO')))
    A(item_call(PG_MOB, '111002:plug:BLK', 20, dict(
        name='P111002_IMPR_NBR', kind='NATIVE_HIDDEN', value_protected='Y', protect='S',
        comment='Source: IMPR1110 :IMPORTERS.IMPR_NBR passed to LOV_UPDATE_IMPR_MOBILE (link with checksum)')))
    nid('111002:comp:MOB', 3)
    A(call('create_page_computation', [
        ('p_id', ref('111002:comp:MOB')), ('p_computation_sequence', '10'),
        ('p_computation_item', q('P111002_MOBILE_NO')), ('p_computation_point', q('BEFORE_HEADER')),
        ('p_computation_type', q('FUNCTION_BODY')), ('p_computation_language', q('PLSQL')),
        ('p_computation', q('RETURN IMPR1110.CENTRAL_MOBILE(I_P111002_IMPR_NBR => :P111002_IMPR_NBR);')),
        ('p_compute_when', q('P111002_MOBILE_NO')), ('p_compute_when_type', q('ITEM_IS_NULL')),
        ('p_computation_comment', src('LOV_UPDATE_IMPR_MOBILE.BLK.WHEN-NEW-BLOCK-INSTANCE (MOBILE_NO := :PARAMETER.P_CENTRAL_MOBILE) / spec 9'))]))
    A(proc_call(PG_MOB, '111002:proc:KEEP', 10, 'AFTER_HEADER', 'G_LAST_PAGE KEEP', ':G_LAST_PAGE := 1110;', None,
                'f345 SCREEN ENTRY RESET keeps the open record only for <page> and <page>01. Without this, '
                'the next load of page 1110 after this dialog would clear P0_PAGE_PK and the record'))
    A(proc_call(PG_MOB, '111002:proc:OK', 20, 'AFTER_SUBMIT', 'PB_OK WHEN-BUTTON-PRESSED',
                'IMPR1110.MOBILE_OK(I_P111002_MOBILE_NO => :P111002_MOBILE_NO);', None,
                'LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_OK.WHEN-BUTTON-PRESSED / spec 8',
                extra=[('p_process_when_button_id', ref('111002:btn:PB_OK'))]))
    A(proc_call(PG_MOB, '111002:proc:CANCEL', 30, 'AFTER_SUBMIT', 'PB_CANCEL WHEN-BUTTON-PRESSED',
                'IMPR1110.MOBILE_CANCEL;', None,
                'LOV_UPDATE_IMPR_MOBILE.CTRL_BLK.PB_CANCEL.WHEN-BUTTON-PRESSED / spec 8',
                extra=[('p_process_when_button_id', ref('111002:btn:PB_CANCEL'))]))
    A(proc_call(PG_MOB, '111002:proc:CLOSE', 40, 'AFTER_SUBMIT', 'Close Dialog', None,
                ('PB_OK,PB_CANCEL', 'REQUEST_IN_CONDITION'),
                'LOV_UPDATE_IMPR_MOBILE EXIT_FORM after OK / CANCEL / spec 8', ptype='NATIVE_CLOSE_WINDOW'))
    A(hide_toolbar_da(PG_MOB, 0))
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
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    return text

# ----------------------------------------------------------------------------- checks
def selfcheck(text):
    problems = []
    ref_txt = open(REF, encoding='utf-8', errors='replace').read()
    pkg_txt = open(PKG, encoding='utf-8').read()
    if 'wwv_flow_imp' in text:
        problems.append('wwv_flow_imp found')
    if '{{' in text:
        problems.append('{{ found')
    allowed = {'__WORKSPACE_ID__', '__APP_ID__', '__SCHEMA_NAME__', '__ID_OFFSET__'}
    ph = set(re.findall(r'__[A-Z_]+__', text))
    if ph - allowed:
        problems.append('unexpected placeholders %s' % sorted(ph - allowed))
    if re.search(r'password|pwd', text, re.I):
        problems.append('password text found')
    # name checks run on code only (Source: comments legitimately name Forms objects)
    code = '\n'.join(l for l in text.splitlines()
                     if not l.startswith('--') and not re.match(r'^[ ,]p_\w*comment=>', l))
    if re.search(r"\bAI_[A-Z]", code):
        problems.append('AI_ item name found (f345: G_ / P_)')
    if re.search(r'pkg_|IMPR1110_APX\.|FORMS_COMPAT\.', code, re.I):
        problems.append('page calls pkg_* / IMPR1110_APX / FORMS_COMPAT directly (must call IMPR1110)')
    # ids: defined here, or defined in f345 (templates, UI, page 0, shared list)
    defined = re.findall(r'[ ,]p_id=>wwv_flow_api\.id\((\d+)\)', text)
    if len(defined) != len(set(defined)):
        problems.append('duplicate p_id')
    ref_ids = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', ref_txt))
    clash = set(defined) & ref_ids
    if clash:
        problems.append('ids clash with f345: %s' % sorted(clash)[:5])
    used = set(re.findall(r'wwv_flow_api\.id\((\d+)\)', text))
    missing = used - set(defined) - ref_ids
    if missing:
        problems.append('ids used but defined nowhere: %s' % sorted(missing))
    for k, v in F345.items():
        if v not in ref_ids:
            problems.append('f345 id %s (%s) not in f345.sql' % (k, v))
    # shared components must not duplicate f345 ones
    ref_items = set(re.findall(r"create_flow_item\(\n[^)]*?p_name=>'([^']+)'", ref_txt))
    for n in re.findall(r"create_flow_item\(\n[^)]*?p_name=>'([^']+)'", text):
        if n in ref_items:
            problems.append('application item %s already in f345' % n)
    ref_lovs = set(re.findall(r"p_lov_name=>'([^']+)'", ref_txt))
    for n in re.findall(r"p_lov_name=>'([^']+)'", text):
        if n in ref_lovs:
            problems.append('LOV %s already in f345' % n)
    # every IMPR1110.<member> called must exist in the package spec
    members = set(m.upper() for m in re.findall(r'^\s*(?:PROCEDURE|FUNCTION)\s+(\w+)', pkg_txt, re.M))
    for m in set(re.findall(r'IMPR1110\.([A-Z_0-9]+)', code)):
        if m not in members:
            problems.append('IMPR1110.%s not in impr1110_spec.sql' % m)
    for name in re.findall(r"p_(?:name|process_name|validation_name)=>'([^']*)'", text):
        if '.' in name and not name.startswith('P') and ' ' not in name:
            problems.append('dot notation in component name %s (f345: space separated)' % name)
    if text.count('\nbegin\n') != text.count('\nend;\n/'):
        problems.append('begin/end not balanced')
    counts = {k: len(re.findall(r'wwv_flow_api\.%s\(' % k, text)) for k in [
        'create_page', 'create_page_plug', 'create_page_item', 'create_page_button', 'create_page_validation',
        'create_page_process', 'create_page_da_event', 'create_page_da_action', 'create_page_computation',
        'create_page_branch', 'create_region_column', 'create_interactive_grid', 'create_ig_report_column',
        'create_list_of_values', 'create_list_of_values_cols', 'create_static_lov_data',
        'create_flow_item', 'create_security_scheme', 'create_page_group']}
    return problems, counts, sorted(ph)

def ready_copy(text, args):
    """Write an import-ready copy with the 4 placeholders replaced (App Builder cannot read
    the tokens: ORA-06502 character to number conversion error on upload)."""
    vals = {}
    for a in args:
        k, _, v = a.lstrip('-').partition('=')
        vals[k.replace('-', '_').lower()] = v.strip()
    need = ['workspace_id', 'app_id', 'id_offset', 'schema']
    missing = [k for k in need if not vals.get(k)]
    if missing:
        sys.exit('missing: ' + ', '.join('--%s=' % m.replace('_', '-') for m in missing))
    for k in ('workspace_id', 'app_id', 'id_offset'):
        if not re.fullmatch(r'-?\d+', vals[k]):
            sys.exit('--%s must be a number, got %r' % (k.replace('_', '-'), vals[k]))
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_$#]{0,29}', vals['schema']):
        sys.exit('--schema is not a valid schema name: %r' % vals['schema'])
    out = (text.replace('__WORKSPACE_ID__', vals['workspace_id'])
               .replace('__APP_ID__', vals['app_id'])
               .replace('__ID_OFFSET__', vals['id_offset'])
               .replace('__SCHEMA_NAME__', vals['schema'].upper()))
    left = set(re.findall(r'__[A-Z_]+__', out))
    if left:
        sys.exit('placeholders left: %s' % sorted(left))
    path = os.path.join(ROOT, 'apex', 'IMPR1110', 'f%s_impr1110_import.sql' % vals['app_id'])
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(out)
    print('import-ready copy:', path)

if __name__ == '__main__':
    # optional: --workspace-id=N --app-id=N --id-offset=N --schema=NAME -> import-ready copy
    sys.stdout.reconfigure(encoding='utf-8')
    t = gen()
    probs, counts, ph = selfcheck(t)
    print('written', OUT, len(t.splitlines()), 'lines')
    for k, v in counts.items():
        print('  %-28s %d' % (k, v))
    print('placeholders:', ', '.join(ph))
    print('problems:', probs or 'none')
    if probs:
        sys.exit(1)
    if len(sys.argv) > 1:
        ready_copy(t, sys.argv[1:])
