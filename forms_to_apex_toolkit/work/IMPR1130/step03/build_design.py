"""Step 03 - page design of IMPR1130 (page 1130 + search page 113001) as data.

Reads  : forms/IMPR/IMPR1130_fmb.xml (labels, lengths, canvas positions, data types)
         plsql/IMPR1130/impr1130_spec.sql (members and their parameters: every call below is built from them)
         work/IMPR1130/step02/classification.md (trace of the code units)
Writes : work/IMPR1130/step03/page_design.json  (same schema as IMPR1110 work/step03/page_design.json; read by
         scripts/gen_apex_impr1130.py and by build_spec.py)
Usage  : python3 -I work/IMPR1130/step03/build_design.py
"""
import json, re, html, sys
import xml.etree.ElementTree as ET

FORM, PG = 'IMPR1130', 1130
PI = 'P%d_' % PG
NS = '{http://xmlns.oracle.com/Forms}'
fm = ET.parse('forms/IMPR/IMPR1130_fmb.xml').getroot().find(NS + 'FormModule')
blk = [b for b in fm.findall(NS + 'Block') if b.get('Name') == 'IMPORTERS'][0]
XI = {i.get('Name'): i for i in blk.findall(NS + 'Item')}


def prompt(item):
    return html.unescape(XI[item].get('Prompt') or '').strip() or '-'


# ----------------------------------------------------------------------------- package members
spec = open('plsql/IMPR1130/impr1130_spec.sql', encoding='utf-8').read()
spec_code = re.sub(r'--[^\n]*', '', spec)
MEMBERS = {}
for m in re.finditer(r'\b(PROCEDURE|FUNCTION)\s+([A-Z0-9_$#]+)\s*(\((.*?)\))?\s*(RETURN\s+\w+)?\s*;', spec_code, re.S):
    params = []
    for p in (m.group(4) or '').split(','):
        p = p.strip()
        if not p:
            continue
        pm = re.match(r'([A-Z0-9_$#]+)\s+(IN\s+OUT|OUT|IN)\s+', p)
        params.append((pm.group(1), re.sub(r'\s+', ' ', pm.group(2))))
    MEMBERS[m.group(2)] = dict(kind=m.group(1), params=params)
APP_ITEMS = {'P_CURR_PORT_CD', 'SSO_APP_USER', 'P_GLOBAL_V_WS_ID', 'G_ALLOW_MCI', 'G_ALLOW_MOI', 'G_PORT_CD',
             'G_SUPP_TITLE_CD', 'G_LETTER_NBR', 'G_LETTER_DT'}


def bind(param):
    if param in APP_ITEMS:
        return ':' + param
    if param == 'P_PAGE_PK':
        return ':P0_PAGE_PK'
    if param.startswith('APP_P_'):
        return ':' + param[4:]
    if param in ('P_PRSNL_IMPR', 'P_LETTER_NBR'):
        return ':%sP_%s' % (PI, param[2:])
    if param.startswith('P_'):
        return ':%s%s' % (PI, param[2:])
    raise SystemExit('no bind for ' + param)


def call(member, fixed=None, assign=None):
    """named-parameter call of IMPR1130.<member>; fixed = {param: literal}; returns code, submit, ret"""
    if member not in MEMBERS:
        raise SystemExit('not in the spec: ' + member)
    fixed = fixed or {}
    args, submit, ret = [], [], []
    for p, mode in MEMBERS[member]['params']:
        v = fixed.get(p, bind(p))
        args.append('%s => %s' % (p, v))
        if v.startswith(':') and v[1:].startswith('P%d_' % PG):
            if 'IN' in mode:
                submit.append(v[1:])
            if 'OUT' in mode:
                ret.append(v[1:])
    text = '%s.%s(%s)' % (FORM, member, ', '.join(args))
    if MEMBERS[member]['kind'] == 'FUNCTION':
        text = ('%s := %s;' % (assign, text)) if assign else text
    else:
        text += ';'
    return text, submit, ret


# ----------------------------------------------------------------------------- items
def flagtext(group):
    return 'DA `%s READ ONLY` (flag `%s%s_LOCKED`)' % (group, PI, group)


def ro_expr(member):
    code, _, _ = call(member)
    return 'PL/SQL Expression `%s`' % code


ITEM_RULE = {   # displayed item -> type, lov, parents, required, read_only, default, notes
    'PORT_CD': ('Popup LOV (display = return value, manual entry)', 'LOV_SD_PORTS', '-', 'Yes', 'Always (value P_CURR_PORT_CD; UpdateAllowed false)', '-', ''),
    'PORT_NAME': ('Display Only (Send On Page Submit = No)', '-', '-', 'No', '-', '-', ''),
    'HQ_IMPR_NBR': ('Display Only (Send On Page Submit = No)', '-', '-', 'No', '-', '-', 'set by PRE-INSERT (CREATE_UNI_IMPR_NEBRAS) / PRE-UPDATE'),
    'IMPR_NBR': ('Number Field', '-', '-', 'No', ro_expr('IMPR_NBR_IS_READ_ONLY'), '-', 'new record: number of an importer to query (request EXECUTE_QUERY)'),
    'SUSPN_STATUS': ('Display Only (Send On Page Submit = No)', '-', '-', 'No', '-', '-', 'POST-QUERY'),
    'STATUS_DESC': ('Display Only (Send On Page Submit = No)', '-', '-', 'No', '-', '-', 'POST-QUERY'),
    'IMPR_TYPE_CD': ('Popup LOV (display = return value, manual entry)', 'LOV_IMPR_TYPE', '-', 'Yes', ro_expr('IMPR_TYPE_CD_IS_READ_ONLY'), '-', ''),
    'IMPR_TYPE_NAME': ('Display Only (Send On Page Submit = No)', '-', '-', 'No', '-', '-', ''),
    'BUS_ID_EXPRD_DT': ('Text Field, CSS class `hijri-date-default` (f345 Hijri picker)', '-', '-', 'No', flagtext('BUS_ID_EXPRD_DT'), '-', 'required on insert: PRE-INSERT 9-220'),
    'BUS_ID_TYPE_CD': ('Select List', 'LOV_IMPR1130_IMPR_TYPE_BUS_ID', 'P%sIMPR_TYPE_CD' % PI[1:], 'Yes', ro_expr('BUS_ID_TYPE_CD_IS_READ_ONLY'), '-', 'Forms: display-only item chosen with LOV_Impr_Type (button BUTT)'),
    'BUS_ID_TYPE_NAME': ('Display Only (Send On Page Submit = No)', '-', '-', 'No', '-', '-', ''),
    'COMM_RGSTRTN_TYPE': ('Select List', 'LOV_COMM_RGSTRTN_TYPE', '-', 'Validation `COMM_RGSTRTN_TYPE REQUIRED` (`COMM_RGSTRTN_TYPE_IS_REQUIRED`)', flagtext('COMM_RGSTRTN_TYPE'), '-', ''),
    'CTRY_CD': ('Popup LOV (display = return value, manual entry)', 'LOV_IMPR1130_COUNTRIES_GULF', 'P%sIMPR_TYPE_CD, P%sBUS_ID_TYPE_CD' % (PI[1:], PI[1:]), 'Yes', flagtext('CTRY_CD'), '-', 'KEY-LISTVAL: CALL_LOV_COUN_GULF for type 4 / identity 16 and type 12, else CALL_LOV_COUNTRIES'),
    'CRTY_ARBC_NAME': ('Display Only (Send On Page Submit = No)', '-', '-', 'No', '-', '-', ''),
    'CITY_CODE_OF_ID': ('Popup LOV (display = return value, manual entry)', 'LOV_IMPR1130_CITIES_OF_ID', 'P%sCTRY_CD' % PI[1:], 'No', flagtext('CITY_CODE_OF_ID'), '-', 'KEY-LISTVAL: LOV_CITIES with CTRY_CD'),
    'ID_CITY_NAME': ('Display Only (Send On Page Submit = No)', '-', '-', 'No', '-', '-', ''),
    'IMPR_EXPR_TYPE': ('Select List', 'LOV_ALLOWED_EXPORT', '-', 'Yes', '-', 'Static: 0', 'pop list CGSO$POP_MD, initial value 0'),
    'NATIONAL_NBR': ('Text Field', '-', '-', 'Yes', '-', '-', 'new in IMPR1130: must start with 7; Ministry of Commerce lookup'),
    'BUS_ID': ('Text Field', '-', '-', 'Yes', flagtext('BUS_ID'), '-', ''),
    'BUS_ID_BRNCH': ('Text Field', '-', '-', 'No', flagtext('BUS_ID_BRNCH'), '-', ''),
    'ARBC_IMPR_NAME': ('Text Field', '-', '-', 'Yes', ro_expr('ARBC_IMPR_NAME_IS_READ_ONLY'), '-', ''),
    'ENG_IMPR_NAME': ('Text Field (dir=ltr)', '-', '-', 'No', ro_expr('ENG_IMPR_NAME_IS_READ_ONLY'), '-', ''),
    'IMPR_CNTCT_NAME': ('Text Field', '-', '-', 'No', '-', '-', ''),
    'IMPR_ADDRESS': ('Text Field', '-', '-', 'No', '-', '-', ''),
    'BUS_ID_ISSUE_DT': ('Text Field, CSS class `hijri-date-default` (f345 Hijri picker)', '-', '-', 'No', '-', '-', 'enterable in IMPR1130 (KEY-LISTVAL / KEY-F4 calendars)'),
    'IMPR_NBR_PARENT': ('Popup LOV (display = return value, manual entry)', 'LOV_IMPR', '-', 'No', '-', '-', ''),
    'IMPR_NAME_PARENT': ('Display Only (Send On Page Submit = No)', '-', '-', 'No', '-', '-', ''),
    'ADD_CTRY_CD': ('Popup LOV (display = return value, manual entry)', 'LOV_COUNTRIES', '-', 'Yes', flagtext('ADD_CTRY_CD'), '-', 'value 100 from WHEN-NEW-FORM-INSTANCE'),
    'ADD_CRTY_ARBC_NAME': ('Display Only (Send On Page Submit = No)', '-', '-', 'No', '-', '-', ''),
    'CITY_CODE': ('Popup LOV (display = return value, manual entry)', 'LOV_IMPR1130_CITIES', 'P%sADD_CTRY_CD' % PI[1:], 'No', '-', '-', 'required by CITY_CODE VALIDATION (Forms WVI)'),
    'CITY_NAME': ('Display Only (Send On Page Submit = No)', '-', '-', 'No', '-', '-', ''),
    'IMPR_POB_NBR': ('Number Field', '-', '-', 'No', flagtext('REGISTER_ITEMS'), '-', ''),
    'IMPR_ZIP_CD': ('Number Field', '-', '-', 'No', flagtext('REGISTER_ITEMS'), '-', ''),
    'IMPR_TEL_NBR': ('Text Field', '-', '-', 'No', '-', '-', 'required by IMPR_TEL_NBR VALIDATION (Forms WVI)'),
    'IMPR_FAX_NBR': ('Text Field', '-', '-', 'No', flagtext('REGISTER_ITEMS'), '-', ''),
    'IMPR_TELEX_NBR': ('Text Field', '-', '-', 'No', flagtext('REGISTER_ITEMS'), '-', ''),
    'EMAIL': ('Text Field (subtype E-Mail, dir=ltr)', '-', '-', 'No', '-', '-', 'displayed in IMPR1130'),
    'MOBILE_NO': ('Text Field (subtype Phone)', '-', '-', 'No', '-', '-', 'displayed in IMPR1130; required by MOBILE_NO VALIDATION'),
    'CAR_AGENT_FLAG': ('Select List', 'LOV_CAR_AGENT_FLAG', '-', 'Yes', '-', 'Static: 0', 'required in IMPR1130'),
    'EXPRESS_POST': ('Select List', 'LOV_EXPRESS_POST', '-', 'No', '-', 'Static: 0', ''),
}
HIDDEN_DB = ['BUS_ID_STATUS', 'IMPR_NAME_STD', 'LST_TRAN_DT', 'IMPD_STMT_NBR', 'IMPR_DATA_SRCE', 'CTRY_CD_OF_ID', 'ID_NBR',
             'EXPD_STMT_NBR', 'WVR_ENTRY_NBR', 'ACTIVITY', 'BANK_IBAN', 'CUSTOMS_ENTERED', 'CREATION_FLAG', 'BIRTH_DT']
HIDDEN_LOOKUP = ['ID_MINS_COMM_CD']
DEFAULTS = {'CTRY_CD_OF_ID': 'Static: 100', 'CREATION_FLAG': 'Static: 1'}
MASKS = {'LST_TRAN_DT': 'YYYY/MM/DD HH24:MI:SS', 'BIRTH_DT': 'YYYY/MM/DD HH24:MI:SS'}

# layout from the canvas CG$PAGE_1: rows by Y, right-to-left by X (12 columns over X 1500..7500)
pos = []
for name in ITEM_RULE:
    x = XI[name]
    pos.append((round(float(x.get('YPosition')) / 120), float(x.get('XPosition')), float(x.get('Width')), name))
rows = {}
for y, x, w, n in pos:
    rows.setdefault(y, []).append((x, w, n))
layout = {}
seq = 0
for y in sorted(rows):
    cells = sorted(rows[y])
    spans = []
    for k, (x, w, n) in enumerate(cells):
        nxt = cells[k + 1][0] if k + 1 < len(cells) else 7500
        span = max(1, int(round((nxt - x) / 500.0)))
        spans.append(max(span, 2) if prompt(n) != '-' else span)      # an item with a label needs 2 columns
    while sum(spans) > 12:                                              # take the extra columns from the widest item
        spans[spans.index(max(spans))] -= 1
    col = 1
    for k, ((x, w, n), span) in enumerate(zip(cells, spans)):
        seq += 10
        layout[n] = '%d / row %s / col %d span %d' % (seq, 'Yes' if k == 0 else 'No', col, span)
        col += span

items = []


def add(name, column, typ, label, required, mask, default, lov, parents, maxlen, lay, ro, cond, source, notes, submit):
    items.append(dict(name=name, column=column, type=typ, label=label, required=required, mask=mask, default=default,
                      lov=lov, parents=parents, maxlen=maxlen, layout=lay, read_only=ro, condition=cond, source=source,
                      notes=notes, submit=submit))


for n, (typ, lov, parents, req, ro, default, notes) in ITEM_RULE.items():
    x = XI[n]
    col = x.get('ColumnName') or (n if x.get('DatabaseItem') != 'false' and n not in (
        'PORT_NAME', 'SUSPN_STATUS', 'STATUS_DESC', 'IMPR_TYPE_NAME', 'BUS_ID_TYPE_NAME', 'CRTY_ARBC_NAME', 'ID_CITY_NAME',
        'IMPR_NAME_PARENT', 'ADD_CRTY_ARBC_NAME', 'CITY_NAME') else '-')
    if n in ('PORT_NAME', 'SUSPN_STATUS', 'STATUS_DESC', 'IMPR_TYPE_NAME', 'BUS_ID_TYPE_NAME', 'CRTY_ARBC_NAME',
             'ID_CITY_NAME', 'IMPR_NAME_PARENT', 'ADD_CRTY_ARBC_NAME', 'CITY_NAME'):
        col = '-'
    mask = '&%sHIJRI_DATE_FORMAT.' % PI if 'hijri' in typ else '-'
    label = prompt(n) if not typ.startswith('Display Only') or prompt(n) != '-' else '-'
    add(PI + n, col, typ, label, req, mask, default, lov, parents, x.get('MaximumLength') or '-', layout[n], ro, '',
        'IMPORTERS.%s (%s)' % (n, x.get('ParentName')), notes, 'No (server value)' if typ.startswith('Display Only') else 'Yes')
hseq = 1000
for n in HIDDEN_DB + HIDDEN_LOOKUP:
    hseq += 10
    x = XI[n]
    add(PI + n, n if n in HIDDEN_DB else '-', 'Display Only, CSS u-hidden (Send On Page Submit = No)', '-', 'No',
        MASKS.get(n, '-'), DEFAULTS.get(n, '-'), '-', '-', x.get('MaximumLength') or '-', '%d / hidden' % hseq, '-', '',
        'IMPORTERS.%s (%s)' % (n, x.get('ParentName')), 'non-displayed item', 'No (server value)')
hseq += 10
add(PI + 'ROW_ID', 'ROWID (primary key)', 'Hidden (Value Protected = Yes)', '-', 'No', '-', '-', '-', '-', '-',
    '%d / hidden' % hseq, '-', '', '-', 'Form region primary key, type ROWID (Forms key mode ROWID); = P0_PAGE_PK', 'No (server value)')
CONTROL = [
    ('P_LETTER_NBR', 'Yes', '-', ':PARAMETER.LETTER_NBR (PARAMETERS ENTRY; SUPPORT_ENTRY letter)'),
    ('P_PRSNL_IMPR', 'Yes', 'Static: 0', ':PARAMETER.PRSNL_IMPR (PARAMETERS ENTRY)'),
    ('MODULE_ID', 'Yes', '-', 'f345 Page Functions: P<page>_MODULE_ID'),
    ('HIJRI_DATE_FORMAT', 'Yes', '-', 'FORMS_APX.HIJRI_DATE_FORMAT (format mask of the Hijri items)'),
    ('HERO_TITLE', 'Yes', '-', 'f345 hero title (FORMS_APX.HEADER_TITLE)'),
    ('FORM_OPEN', 'Yes', '-', 'first view of the form (WHEN-NEW-FORM-INSTANCE once)'),
    ('SUPPORT_ENTRY_OPEN', 'Yes', '-', 'Y on the first view: open SUPPORT_ENTRY (WNFI CALL_FORM P_MODE 0)'),
    ('ADJ_FUNS', 'Yes', '-', 'PU ADJ_FUNS: enabled functions of the Page Functions list'),
    ('SUPPORT_URL', 'No', '-', 'URL of page 9001 returned by SUPPORT_ENTRY.OPEN_DIALOG'),
    ('CONFIRM_TEXT', 'No', '-', 'question computed on the server (CITY_CODE_OF_ID 9-120, UPDATE_IMPORTER)'),
    ('ANSWER', 'No', '-', 'answer of the question: 1 = ALERT_BUTTON1, 2 = ALERT_BUTTON2'),
]
FLAG_GROUPS = {'COMM_RGSTRTN_TYPE': ['COMM_RGSTRTN_TYPE'], 'CTRY_CD': ['CTRY_CD'], 'ADD_CTRY_CD': ['ADD_CTRY_CD'],
               'CITY_CODE_OF_ID': ['CITY_CODE_OF_ID'], 'BUS_ID': ['BUS_ID'], 'BUS_ID_BRNCH': ['BUS_ID_BRNCH'],
               'BUS_ID_EXPRD_DT': ['BUS_ID_EXPRD_DT'],
               'REGISTER_ITEMS': ['IMPR_POB_NBR', 'IMPR_ZIP_CD', 'IMPR_FAX_NBR', 'IMPR_TELEX_NBR']}
for g in FLAG_GROUPS:
    CONTROL.append((g + '_LOCKED', 'No', '-', 'READ_ONLY_FLAGS: Y = %s read-only' % ', '.join(FLAG_GROUPS[g])))
for n, prot, default, src in CONTROL:
    add(PI + n, '-', 'Hidden (Value Protected = %s)' % prot, '-', 'No', '-', default, '-', '-', '-', 'hidden', '-', '', '-',
        src, 'Yes' if n in ('CONFIRM_TEXT', 'ANSWER') else 'No (server value)')
for it in items:
    if it['name'] == PI + 'HERO_TITLE':
        it['type'] = 'Display Only (region IMPORTERS_HERO)'

# ----------------------------------------------------------------------------- validations (spec 7)
validations = []


def val(item, member, source, condition=None, fixed=None):
    code, _, _ = call(member, fixed)
    validations.append(dict(name='%s VALIDATION' % item, item=PI + item, member=member, code='RETURN ' + code, source=source,
                            **({'condition': condition} if condition else {})))


CREATE_ONLY = ":REQUEST = 'CREATE'"
val('IMPR_NBR', 'IMPR_NBR_VALIDATION', 'IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM', CREATE_ONLY)
val('IMPR_TYPE_CD', 'IMPR_TYPE_CD_VALIDATION', 'IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM', CREATE_ONLY)
val('BUS_ID_EXPRD_DT', 'BUS_ID_EXPRD_DT_VALIDATION', 'IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM')
val('BUS_ID_TYPE_CD', 'BUS_ID_TYPE_CD_VALIDATION', 'IMPORTERS.BUS_ID_TYPE_CD.WHEN-VALIDATE-ITEM', CREATE_ONLY)
validations.append(dict(name='COMM_RGSTRTN_TYPE REQUIRED', item=PI + 'COMM_RGSTRTN_TYPE', member='COMM_RGSTRTN_TYPE_IS_REQUIRED',
                        code="RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :%sCOMM_RGSTRTN_TYPE, ITEM_LABEL => '%s');"
                        % (PI, prompt('COMM_RGSTRTN_TYPE')),
                        condition=call('COMM_RGSTRTN_TYPE_IS_REQUIRED')[0],
                        source='IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM SET_ITEM_PROPERTY(COMM_RGSTRTN_TYPE, REQUIRED)'))
val('CTRY_CD', 'CTRY_CD_VALIDATION', 'IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM', CREATE_ONLY)
val('CITY_CODE_OF_ID', 'CITY_CODE_OF_ID_VALIDATION', 'IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM', CREATE_ONLY)
val('NATIONAL_NBR', 'NATIONAL_NBR_VALIDATION', 'IMPORTERS.NATIONAL_NBR.WHEN-VALIDATE-ITEM')
val('BUS_ID', 'BUS_ID_VALIDATION', 'IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM')
val('BUS_ID_BRNCH', 'BUS_ID_BRNCH_VALIDATION', 'IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM')
val('ENG_IMPR_NAME', 'ENG_IMPR_NAME_VALIDATION', 'IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM')
val('BUS_ID_ISSUE_DT', 'BUS_ID_ISSUE_DT_VALIDATION', 'IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM')
val('CITY_CODE', 'CITY_CODE_VALIDATION', 'IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM')
val('IMPR_TEL_NBR', 'IMPR_TEL_NBR_VALIDATION', 'IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM')
val('MOBILE_NO', 'MOBILE_NO_VALIDATION', 'IMPORTERS.MOBILE_NO.WHEN-VALIDATE-ITEM')

# ----------------------------------------------------------------------------- processes (spec 8, f345 standard 6)
processes = []


def proc(seq, point, name, code, condition, source):
    processes.append(dict(seq=seq, point=point, name=name, code=code, condition=condition, source=source))


ROW = ':%sROW_ID' % PI
proc(10, 'Before Header', 'New', 'f345 session setup, copied from AGR1100 (condition Never)', '-', 'f345 standard §6')
proc(20, 'Before Header', 'P0_PAGE_PK CHECK', call('P0_PAGE_PK_CHECK')[0], '-', 'f345 key (ROWID of IMPORTERS, port scope)')
proc(40, 'Before Header', 'PARAMETERS', ":%sMODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :%sMODULE_ID, FORM_NAME => '%s');" % (PI, PI, FORM), '-', 'f345 module id of the Page Functions list')
proc(50, 'Before Header', 'PARAMETERS ENTRY', call('PARAMETERS_ENTRY')[0], '-', 'CALL_FORM parameters PRSNL_IMPR, LETTER_NBR')
proc(70, 'Before Header', 'P0_PAGE_PK', '%s := :P0_PAGE_PK;' % ROW, '-', 'f345 (key = ROWID, Forms key mode ROWID)')
proc(80, 'Before Header', 'Initialize form IMPORTERS', 'NATIVE_FORM_INIT, region IMPORTERS', '-', 'block IMPORTERS query (Forms EXECUTE_QUERY)')
proc(82, 'Before Header', 'POST-QUERY', call('POST_QUERY')[0], '%s is not null' % ROW, 'IMPORTERS.POST-QUERY')
proc(84, 'Before Header', 'WHEN-CREATE-RECORD', call('WHEN_CREATE_RECORD')[0], '%s is null' % ROW, 'IMPORTERS.WHEN-CREATE-RECORD')
proc(85, 'Before Header', 'WHEN-NEW-FORM-INSTANCE', call('WHEN_NEW_FORM_INSTANCE')[0], ':%sFORM_OPEN is null' % PI, 'FORM.WHEN-NEW-FORM-INSTANCE (after WHEN-CREATE-RECORD of the first record, as Forms)')
proc(86, 'Before Header', 'FORM OPEN', ":%sFORM_OPEN := 'Y';" % PI, ':%sFORM_OPEN is null' % PI, 'WHEN-NEW-FORM-INSTANCE runs once per form instance')
proc(87, 'Before Header', 'PRE-RECORD', call('PRE_RECORD')[0], '%s is not null' % ROW, 'IMPORTERS.PRE-RECORD')
proc(88, 'Before Header', 'READ ONLY FLAGS', call('READ_ONLY_FLAGS')[0], '-', 'Make_Field_Entrable of WNFI / WCR / WNRI / POST-QUERY (rules)')
proc(100, 'Before Header', 'HEADER TITLE', "FORMS_APX.HEADER_TITLE(P_MODULE_ID => :%sMODULE_ID, P_HERO_TITLE => :%sHERO_TITLE, DEFAULT_TITLE => '%s');"
     % (PI, PI, html.unescape(fm.get('Title'))), '-', 'f345 hero title (module title)')
proc(10, 'After Submit', 'EXECUTE-QUERY', ':P0_PAGE_PK := %s' % call('IMPORTER_ROW_ID')[0] + ';', ":REQUEST = 'EXECUTE_QUERY'", 'IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM + WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY')
proc(20, 'After Submit', 'PRE-INSERT', call('PRE_INSERT')[0], ":P0_PAGE_PK is null and :REQUEST = 'CREATE'", 'IMPORTERS.PRE-INSERT')
proc(30, 'After Submit', 'PRE-UPDATE', call('PRE_UPDATE')[0], ":P0_PAGE_PK is not null and :REQUEST = 'SAVE'", 'IMPORTERS.PRE-UPDATE')
proc(35, 'After Submit', 'KEY-DELREC', call('KEY_DELREC')[0], ":REQUEST = 'DELETE'", 'IMPORTERS.KEY-DELREC + PRE-DELETE')
proc(40, 'After Submit', 'Process form IMPORTERS', 'NATIVE_FORM_DML, region IMPORTERS, Prevent Lost Updates = Yes, Lock Row = Yes, Return Primary Key(s) after Insert = Yes',
     ":REQUEST in ('CREATE', 'SAVE')", 'Forms default INSERT / UPDATE of block IMPORTERS')
proc(50, 'After Submit', 'POST-INSERT', call('POST_INSERT')[0], ":P0_PAGE_PK is null and :REQUEST = 'CREATE'", 'IMPORTERS.POST-INSERT')
proc(80, 'After Submit', 'P0_PAGE_PK AFTER INSERT', ':P0_PAGE_PK := %s;' % ROW, ":P0_PAGE_PK is null and :REQUEST = 'CREATE'", 'f345: the new record stays on the page (Forms stays on the record after COMMIT)')
proc(85, 'After Submit', 'P0_PAGE_PK AFTER DELETE', ':P0_PAGE_PK := NULL;', ":REQUEST = 'DELETE'", 'Forms Delete_record + COMMIT: an empty record follows')

computations = [
    dict(item=PI + 'HIJRI_DATE_FORMAT', point='Before Header', expression='FORMS_APX.HIJRI_DATE_FORMAT', condition='-',
         source='Hijri date format from one place: Application Setting HIJRI_DATE_FORMAT (Forms mask MI-MM-YYYY)'),
    dict(item=PI + 'SUPPORT_ENTRY_OPEN', point='Before Header', expression="CASE WHEN :%sFORM_OPEN IS NULL THEN 'Y' ELSE 'N' END" % PI,
         condition='-', source='FORM.WHEN-NEW-FORM-INSTANCE CALL_FORM(SUPPORT_ENTRY) on the first view (computations run before the processes)'),
    dict(item=PI + 'ADJ_FUNS', point='After Header', expression=call('ADJ_FUNS')[0], condition='-',
         source='PU ADJ_FUNS (TMPLT.ENABLE_FUN / DISABLE_FUN), filter of the f345 Page Functions list'),
]

# ----------------------------------------------------------------------------- dynamic actions (spec 10)
das = []
FLAGS_CALL = call('READ_ONLY_FLAGS')


def fos(member, fixed=None, check=False, events=False, assign=None, note=''):
    code, sub, ret = call(member, fixed, assign)
    if check:
        code = 'FORMS_APX.CHECK_ERROR(%s);' % code
        ret = []
    if assign:
        ret = ret + [assign[1:]]
    return dict(action='FOS - Execute PL/SQL Code' + (' (change events ON)' if events else ''), code=code,
                submit=sorted(set(sub)), ret=ret, note=note)


def flags_action():
    code, sub, ret = FLAGS_CALL
    return dict(action='FOS - Execute PL/SQL Code (change events ON)', code=code, submit=sorted(set(sub)), ret=ret,
                note='last action: the read-only flags fire the DAs "<ITEM> READ ONLY"')


def da(name, event, selection, actions, source, condition='-', fire_init='No'):
    das.append(dict(name=name, event=event, selection=selection, condition=condition, actions=actions, source=source,
                    fire_init=fire_init))


def wvi(item, actions, source=None):
    da('%s WHEN-VALIDATE-ITEM' % item, 'Change', 'Item %s%s' % (PI, item), actions,
       source or 'IMPORTERS.%s.WHEN-VALIDATE-ITEM' % item)


wvi('IMPR_NBR', [fos('IMPR_NBR_VALIDATION', check=True),
                 dict(action='Submit Page', code='request EXECUTE_QUERY', submit=[], ret=[],
                      note='runs only when the FOS succeeded (the number exists) - Forms :GLOBAL.EXEC_QUERY_NOW + EXECUTE_QUERY')])
das[-1]['condition'] = 'Item %sIMPR_NBR is not null' % PI
wvi('IMPR_TYPE_CD', [fos('IMPR_TYPE_CD_VALIDATE_ITEM'), flags_action()],
    'IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL return values)')
wvi('BUS_ID_EXPRD_DT', [fos('BUS_ID_EXPRD_DT_VALIDATION', check=True)])
wvi('BUS_ID_TYPE_CD', [fos('BUS_ID_TYPE_CD_VALIDATE_ITEM'), flags_action()],
    'IMPORTERS.BUS_ID_TYPE_CD.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL return values)')
da('COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED', 'Change', 'Item %sCOMM_RGSTRTN_TYPE' % PI,
   [fos('COMM_RGSTRTN_TYPE_LIST_CHANGED'), flags_action()], 'IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED')
wvi('CTRY_CD', [fos('CTRY_CD_WHEN_VALIDATE_ITEM')], 'IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL return values)')
CONFIRM_EVENT = 'impr1130-city-code-of-id-validate'
wvi('CITY_CODE_OF_ID', [
    fos('CITY_CODE_OF_ID_CONFIRM_TEXT', assign=':%sCONFIRM_TEXT' % PI),
    dict(action='Execute JavaScript Code',
         code="var t = $v('%sCONFIRM_TEXT'), go = function (a) { $s('%sANSWER', a); apex.event.trigger('#%sCITY_CODE_OF_ID', '%s'); };\n"
              "if (t) { apex.message.confirm(t, function (ok) { go(ok ? '1' : '2'); }); } else { go('1'); }"
              % (PI, PI, PI, CONFIRM_EVENT), submit=[], ret=[],
         note='STR.DispAlert(9-120, CONFIRM): question text computed on the server, answer in %sANSWER' % PI)],
    'IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM (question 9-120)')
da('CITY_CODE_OF_ID WHEN-VALIDATE-ITEM CONFIRMED', 'Custom: ' + CONFIRM_EVENT, 'Item %sCITY_CODE_OF_ID' % PI,
   [fos('CITY_CODE_OF_ID_VALIDATE_ITEM'), flags_action()],
   'IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM (after the answer) + WHEN-NEW-ITEM-INSTANCE + CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM')
wvi('NATIONAL_NBR', [fos('NATIONAL_NBR_VALIDATE_ITEM'), flags_action()],
    'IMPORTERS.NATIONAL_NBR.WHEN-VALIDATE-ITEM (GET_MAIN_CR_DATA / GET_BRANCH_CR_DATA / GET_CR_DATA)')
wvi('BUS_ID', [fos('BUS_ID_WHEN_VALIDATE_ITEM'), flags_action()])
wvi('BUS_ID_BRNCH', [fos('BUS_ID_BRNCH_VALIDATE_ITEM'), flags_action()],
    'IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM + KEY-NEXT-ITEM')
wvi('ENG_IMPR_NAME', [fos('ENG_IMPR_NAME_VALIDATE_ITEM')])
wvi('BUS_ID_ISSUE_DT', [fos('BUS_ID_ISSUE_DT_VALIDATION', check=True)])
wvi('IMPR_NBR_PARENT', [fos('IMPR_NBR_PARENT_VALIDATE_ITEM')], 'IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL)')
wvi('ADD_CTRY_CD', [fos('ADD_CTRY_CD_WHEN_VALIDATE_ITEM')], 'IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL)')
wvi('CITY_CODE', [fos('CITY_CODE_WHEN_VALIDATE_ITEM')], 'IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM (+ KEY-LISTVAL)')
wvi('IMPR_TEL_NBR', [fos('IMPR_TEL_NBR_VALIDATION', check=True)])
wvi('EMAIL', [fos('EMAIL_VALIDATION', check=True)])
wvi('MOBILE_NO', [fos('MOBILE_NO_VALIDATION', check=True)])
for g, its in FLAG_GROUPS.items():
    lst = ', '.join(PI + i for i in its)
    da('%s READ ONLY' % g, 'Change', 'Item %s%s_LOCKED' % (PI, g),
       [dict(action='Disable', code='items ' + lst, submit=[], ret=[], note='True action'),
        dict(action='Enable', code='items ' + lst, submit=[], ret=[], note='False action')],
       'INTRFACE.Make_Field_Entrable (%s): READ_ONLY_FLAGS' % ', '.join(its),
       condition='Item %s%s_LOCKED = Y' % (PI, g), fire_init='Yes')
# SUPPORT_ENTRY (page 9001, contract SUPPORT_ENTRY spec 0.4 / D1)
OPEN = 'SUPPORT_ENTRY.OPEN_DIALOG(P_MODE => %s, P_CURR_PORT_CD => :%sPORT_CD, P_SUPPORT_URL => :%sSUPPORT_URL);'
REDIRECT = dict(action='Execute JavaScript Code', code="apex.navigation.redirect($v('%sSUPPORT_URL'));" % PI, submit=[], ret=[],
                note='open the SUPPORT_ENTRY dialog page 9001 (URL from SUPPORT_ENTRY.OPEN_DIALOG)')
da('SUPPORT_ENTRY WHEN-NEW-FORM-INSTANCE', 'Page Load', '-',
   [dict(action='FOS - Execute PL/SQL Code', code=OPEN % ('0', PI, PI), submit=[PI + 'PORT_CD'], ret=[PI + 'SUPPORT_URL'],
         note='CALL_FORM(SUPPORT_ENTRY.FMX) with P_MODE 0 and P_CURR_PORT_CD = :IMPORTERS.PORT_CD'), REDIRECT],
   'FORM.WHEN-NEW-FORM-INSTANCE CALL_FORM(SUPPORT_ENTRY)', condition="JavaScript expression: $v('%sSUPPORT_ENTRY_OPEN') === 'Y'" % PI)
da('SUPPORT_ENTRY WHEN-BUTTON-PRESSED', 'Click', 'Button SUPPORT_ENTRY',
   [dict(action='FOS - Execute PL/SQL Code', code=OPEN % ('CASE WHEN :G_LETTER_NBR IS NULL THEN 0 ELSE 1 END', PI, PI),
         submit=[PI + 'PORT_CD'], ret=[PI + 'SUPPORT_URL'],
         note='edit mode on demand (D1) when a letter exists (Forms OPEN_FORM(SUPPORT_ENTRY.FMX), default P_MODE 1), else a new letter'),
    REDIRECT], 'FORM.WHEN-NEW-FORM-INSTANCE OPEN_FORM(SUPPORT_ENTRY) (edit mode, modeless window in Forms)')
da('SUPPORT_ENTRY DIALOG CLOSED', 'Dialog Closed', 'JavaScript Expression: document',
   [dict(action='FOS - Execute PL/SQL Code', code=':%sP_LETTER_NBR := :G_LETTER_NBR;' % PI, submit=[], ret=[PI + 'P_LETTER_NBR'],
         note=':PARAMETER.LETTER_NBR := :GLOBAL.LETTER_NBR')],
   'FORM.WHEN-NEW-FORM-INSTANCE after CALL_FORM(SUPPORT_ENTRY)', condition='dialog page 9001')
# function IMPR_MCI_SERVICE (page 0 FUNCS drawer raises the custom event of the function code)
UPD_EVENT = 'impr1130-update-importer'
da('IMPR_MCI_SERVICE EXECUTE-FUNCTION', 'Custom: IMPR_MCI_SERVICE', 'JavaScript Expression: document',
   [fos('UPDATE_IMPORTER_CONFIRM_TEXT', assign=':%sCONFIRM_TEXT' % PI),
    dict(action='Execute JavaScript Code',
         code="var t = $v('%sCONFIRM_TEXT'), go = function (a) { $s('%sANSWER', a); apex.event.trigger(document, '%s'); };\n"
              "if (t) { apex.message.confirm(t, function (ok) { go(ok ? '1' : '2'); }); } else { go('2'); }" % (PI, PI, UPD_EVENT),
         submit=[], ret=[], note='STR.DISPALERT(V_MSG, CONFIRM) of UPDATE_IMPORTER; no saved importer: only the re-query')],
   'PU EXEC_FUNS / UPDATE_IMPORTER (function IMPR_MCI_SERVICE, enabled by ADJ_FUNS)')
da('UPDATE_IMPORTER', 'Custom: ' + UPD_EVENT, 'JavaScript Expression: document',
   [fos('EXEC_FUNS', fixed={'P_FUNCTION_CODE': "'IMPR_MCI_SERVICE'"}),
    dict(action='Submit Page', code='request EXECUTE_QUERY', submit=[], ret=[],
         note=':GLOBAL.EXEC_QUERY_NOW := 1 -> WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY: the record is read again')],
   'PU UPDATE_IMPORTER (LIB_USR.IMPR_UTILITIES.UPDATE_IMPORTERS_NAMES, then re-query)')

# ----------------------------------------------------------------------------- trace (spec 14)
trace = []
classif = {}
for line in open('work/IMPR1130/step02/classification.md', encoding='utf-8'):
    m = re.match(r'\| `([^`]+)` \| (\w+) \| (\w+) \| (.*?) \| (.*?) \|$', line.rstrip())
    if m:
        classif[m.group(1)] = m.groups()[1:]
for b in fm.findall(NS + 'Block'):
    bn = b.get('Name')
    if bn == 'IMPORTERS':
        trace.append(['BLOCK', bn, 'REGION', 'IMPORTERS', str(PG), None, 'MAPPED', 'Form region on IMPORTERS (ROWID), WHERE PORT_CD = :P_CURR_PORT_CD'])
    else:
        trace.append(['BLOCK', bn, 'REGION', None, None, None, 'DROPPED', 'OLB frame block -> f345 page template / page 0 toolbar / FUNCS'])
    for i in b.findall(NS + 'Item'):
        n = i.get('Name')
        key = '%s.%s' % (bn, n)
        if bn != 'IMPORTERS':
            trace.append(['ITEM', key, 'ITEM', None, None, None, 'DROPPED', 'OLB block ' + bn])
        elif any(it['name'] == PI + n for it in items):
            it = [x for x in items if x['name'] == PI + n][0]
            trace.append(['ITEM', key, 'ITEM', PI + n, str(PG), None, 'MAPPED', it['type']])
        elif n.endswith('2') or n == 'BUTT':
            trace.append(['ITEM', key, 'ITEM', None, None, None, 'DROPPED', 'LOV button -> the Popup LOV / Select List of the item'])
        else:
            trace.append(['ITEM', key, 'ITEM', None, None, None, 'DROPPED',
                          'non-displayed lookup item filled by the Designer FK lookups, read by no code'])
units = json.load(open('work/IMPR1130/units_both.json', encoding='utf-8'))['1130']
for k in sorted(u for u, v in units.items() if v.strip()):
    same, grp, target, note = classif[k]
    typ = 'PROGRAM_UNIT' if k.startswith('PU.') else 'TRIGGER'
    name = k[3:] if k.startswith('PU.') else k
    if grp == 'DROPPED':
        trace.append([typ, name, None, None, None, None, 'DROPPED', note])
    else:
        member = None
        mm = re.findall(r'\b([A-Z][A-Z0-9_$#]{3,})\b', target)
        mm = [x for x in mm if x in MEMBERS]
        if mm:
            member = '%s.%s' % (FORM, mm[0])
        comp = 'PACKAGE' if grp in ('CONVERTED', 'RULES') else 'APEX'
        trace.append([typ, name, comp, target[:120], str(PG), member, 'MAPPED', note])
# triggers without code in the form XML (inherited from the OLB): the screen frame
for b in fm.findall(NS + 'Block'):
    for owner, elems in [(b.get('Name'), b.findall(NS + 'Trigger'))] + [
            ('%s.%s' % (b.get('Name'), i.get('Name')), i.findall(NS + 'Trigger')) for i in b.findall(NS + 'Item')]:
        for tr in elems:
            if not (tr.get('TriggerText') or '').strip():
                trace.append(['TRIGGER', '%s.%s' % (owner, tr.get('Name')), None, None, None, None, 'DROPPED',
                              'no code in the form XML: inherited from CIC_OLB.olb (screen frame)'])
for tr in fm.findall(NS + 'Trigger'):
    if not (tr.get('TriggerText') or '').strip():
        trace.append(['TRIGGER', 'FORM.' + tr.get('Name'), None, None, None, None, 'DROPPED',
                      'no code in the form XML: inherited from CIC_OLB.olb (screen frame)'])
# :GLOBAL variables of the active code
GLOBAL_MAP = {'ALLOW_MCI': 'G_ALLOW_MCI', 'ALLOW_MOI': 'G_ALLOW_MOI', 'LETTER_NBR': 'G_LETTER_NBR', 'LETTER_DT': 'G_LETTER_DT',
              'SUPP_TITLE_CD': 'G_SUPP_TITLE_CD', 'PORT_CD': 'G_PORT_CD (SUPPORT_ENTRY) / page item (query by number)'}
def strip(x):
    return re.sub(r'--[^\n]*', '', re.sub(r'/\*.*?\*/', '', x, flags=re.S))
gl = sorted(set(g.upper() for v in units.values() for g in re.findall(r':GLOBAL\.(\w+)', strip(v), re.I)))
for g in gl:
    if g in GLOBAL_MAP:
        trace.append(['GLOBAL', ':GLOBAL.' + g, 'APP_ITEM', GLOBAL_MAP[g], None, None, 'MAPPED', 'application item (IMPR1110 export)'])
    else:
        trace.append(['GLOBAL', ':GLOBAL.' + g, None, None, None, None, 'MAPPED',
                      'LOV return channel / flag / version stamp -> page items, parameters or requests (logic report §5)'])
for t in fm.findall(NS + 'LOV'):
    trace.append(['LOV', t.get('Name'), 'LOV', None, None, None, 'MAPPED', 'replaced by the shared LOV of the item (LOV form, spec 6)'])
for t in fm.findall(NS + 'RecordGroup'):
    trace.append(['RECORD_GROUP', t.get('Name'), 'LOV', None, None, None, 'MAPPED', 'query in LOV_APX (spec 6)'])
for t in fm.findall(NS + 'Alert'):
    trace.append(['ALERT', t.get('Name'), 'MESSAGE', None, None, None, 'MAPPED', 'STR.DispAlert type -> FORMS_APX error / message / confirm (spec 11)'])
for t in fm.findall(NS + 'Canvas'):
    trace.append(['CANVAS', t.get('Name'), 'PAGE', str(PG) if t.get('Name') == 'CG$PAGE_1' else None, None, None,
                  'MAPPED' if t.get('Name') == 'CG$PAGE_1' else 'DROPPED', 'page %d' % PG if t.get('Name') == 'CG$PAGE_1' else 'OLB frame'])
for t in fm.findall(NS + 'Window'):
    trace.append(['WINDOW', t.get('Name'), 'PAGE', str(PG), None, None, 'MAPPED', 'page %d (f345 page template)' % PG])
for t in fm.findall(NS + 'ModuleParameter'):
    n = t.get('Name')
    target = {'PRSNL_IMPR': PI + 'P_PRSNL_IMPR', 'LETTER_NBR': PI + 'P_LETTER_NBR'}.get(n)
    trace.append(['PARAMETER', n, 'ITEM' if target else 'APP_ITEM', target or '(f345 application item)', str(PG) if target else None,
                  None, 'MAPPED' if target or n.startswith('P_') else 'DROPPED', 'f345 parameter mapping (inventory §12)'])
for t in fm.findall(NS + 'AttachedLibrary'):
    trace.append(['LIBRARY', t.get('Name'), None, None, None, None, 'TODO' if t.get('Name') in (
        'OFGTEL', 'SEC_LIB', 'OFGTAB', 'PICKLIST', 'POS', 'SCDLL', 'VCDLL') else 'MAPPED', 'inventory §10.3'])

# ----------------------------------------------------------------------------- LOVs (spec 6)
sys.path.insert(0, 'scripts')
import lov_apx
REUSED = [  # created by the IMPR1110 export (no page item in their query): referenced by name
    ('LOV_SD_PORTS', 'LOV form LOV_SD_PORTS (PORT_CD; read-only here)'),
    ('LOV_IMPR_TYPE', 'LOV form LOV_Impr_Type (IMPR_TYPE_CD)'),
    ('LOV_COUNTRIES', 'LOV form LOV_COUNTRIES (ADD_CTRY_CD)'),
    ('LOV_IMPR', 'LOV form LOV_IMPR (IMPR_NBR_PARENT)'),
    ('LOV_COMM_RGSTRTN_TYPE', 'list item COMM_RGSTRTN_TYPE (CG_REF_CODES)'),
    ('LOV_ALLOWED_EXPORT', 'pop list IMPR_EXPR_TYPE (CG_REF_CODES)'),
    ('LOV_EXPRESS_POST', 'list item EXPRESS_POST (static)'),
    ('LOV_CAR_AGENT_FLAG', 'pop list CAR_AGENT_FLAG (static)')]
NEW = [  # the query names a page item of 1130: own shared LOV (same LOV_APX function as IMPR1110)
    ('LOV_IMPR1130_IMPR_TYPE_BUS_ID',
     lov_apx.call('BUSINESS_ID_TYPES', P_IMPORTER_TYPE_ITEM=PI + 'IMPR_TYPE_CD', P_ALL_STATUSES_ITEM='G_CHK_IMP_TYP'), [],
     'LOV form LOV_Impr_Type with IMPR_TYPE_CD (BUS_ID_TYPE_CD.KEY-LISTVAL, button BUTT)'),
    ('LOV_IMPR1130_COUNTRIES_GULF',
     lov_apx.call('GULF_COUNTRIES', P_IMPORTER_TYPE_ITEM=PI + 'IMPR_TYPE_CD', P_BUSINESS_ID_TYPE_ITEM=PI + 'BUS_ID_TYPE_CD'),
     [('D', 'رمز الدولة', 'NUMBER'), ('CRTY_ARBC_NAME', 'الدولة', 'VARCHAR2')],
     'CTRY_CD.KEY-LISTVAL: CALL_LOV_COUN_GULF / CALL_LOV_COUNTRIES (TODO: type 12 Gulf list, LOV_APX change request)'),
    ('LOV_IMPR1130_CITIES_OF_ID', lov_apx.call('CITIES', P_COUNTRY_ITEM=PI + 'CTRY_CD', P_WITH_MINISTRY_CODE=True),
     [('D', 'رمز المدينة', 'NUMBER'), ('CITY_ARB_NAME', 'المدينة', 'VARCHAR2'), ('MINS_COMM_CD', 'رمز الوزارة', 'NUMBER')],
     'CITY_CODE_OF_ID.KEY-LISTVAL: LOV_CITIES with CTRY_CD'),
    ('LOV_IMPR1130_CITIES', lov_apx.call('CITIES', P_COUNTRY_ITEM=PI + 'ADD_CTRY_CD'),
     [('D', 'رمز المدينة', 'NUMBER'), ('CITY_ARB_NAME', 'المدينة', 'VARCHAR2')],
     'CITY_CODE.KEY-LISTVAL: LOV_CITIES with ADD_CTRY_CD')]
lovs = dict(reused=[dict(name=n, source=s) for n, s in REUSED],
            new=[dict(name=n, call=c, columns=cols, source=s) for n, c, cols, s in NEW])
used = set(it['lov'] for it in items if it['lov'] != '-')
known = set(n for n, _ in REUSED) | set(n for n, _, _, _ in NEW)
if used - known:
    raise SystemExit('LOV not defined: %s' % sorted(used - known))

json.dump(dict(items=items, validations=validations, processes=processes, computations=computations, das=das,
               flag_groups=FLAG_GROUPS, lovs=lovs, trace=trace),
          open('work/IMPR1130/step03/page_design.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('items %d, validations %d, processes %d, computations %d, das %d, trace %d' % (
    len(items), len(validations), len(processes), len(computations), len(das), len(trace)))
for n in ITEM_RULE:
    print('  %-22s %s' % (n, layout[n]))
