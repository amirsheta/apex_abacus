"""
build_spec.py - step 03 rev 2: generated tables of analysis/IMPR1110/IMPR1110_apex_page_spec.md and the
registry script registry/IMPR1110_registry.sql (f345 standard, CLAUDE.md §4b / §4c).

Inputs : plsql/IMPR1110/impr1110_spec.sql (members and parameters), work/step02/entries.json,
         rollback/IMPR1110/step03_rev1/IMPR1110_apex_page_spec.md (item metadata from the XML, §4),
         rollback/IMPR1110/step03_rev1/IMPR1110_registry.sql (one row per Forms object)
Output : work/step03/gen_*.md (tables pasted into the spec by assemble), work/step03/page_design.json
         (the design as data, for the step-04 generator), registry/IMPR1110_registry.sql
Usage  : python3 -I work/step03/build_spec.py
"""
import re, json, collections, sys

PAGE, PKG = 1110, 'IMPR1110'
P = 'P%d_' % PAGE
OLD_SPEC = 'rollback/IMPR1110/step03_rev1/IMPR1110_apex_page_spec.md'
OLD_REG = 'rollback/IMPR1110/step03_rev1/IMPR1110_registry.sql'

# ------------------------------------------------------------------ package spec: members + parameters
spec = open('plsql/IMPR1110/impr1110_spec.sql', encoding='utf-8').read()
def code_only(t):
    return re.sub(r'--[^\n]*', '', t)
MEMBERS = collections.OrderedDict()
for m in re.finditer(r'(?ms)^    (PROCEDURE|FUNCTION)\s+(\w+)\s*(\((.*?)\))?\s*(RETURN\s+(\w+))?\s*;', code_only(spec)):
    params = []
    for p in re.split(r',(?![^(]*\))', m.group(4) or ''):
        p = p.strip()
        if not p: continue
        w = p.split()
        mode = 'IN OUT' if ' IN OUT ' in ' %s ' % p.upper() else ('OUT' if w[1].upper() == 'OUT' else 'IN')
        params.append((w[0].upper(), mode, 'DEFAULT' in p.upper()))
    MEMBERS[m.group(2).upper()] = dict(kind=m.group(1), params=params, returns=m.group(6))
ENTRIES = json.load(open('work/step02/entries.json', encoding='utf-8'))

APP_ITEMS = {'P_CURR_PORT_CD', 'SSO_APP_USER', 'P_GLOBAL_V_WS_ID', 'P_CLASS_CD', 'V_USR_TYPE', 'P_BRKR_PORT_CD',
             'P_LIC_TYPE', 'P_BRKR_NBR', 'P_PRSNL_IMPR', 'P_LETTER_NBR', 'P0_PAGE_PK'}
# Binds come from the ORIGINAL parameter names (work/step02/parameter_binds.json, written by build_package.py):
# the new name alone does not say which item it carries (P_CODE carries P1110_P_CODE, APP_P_PRSNL_IMPR the
# application item P_PRSNL_IMPR). The rule below is the one used before the renaming, on the original name.
BINDS = json.load(open('work/step02/parameter_binds.json', encoding='utf-8'))
def bind(param, literal=None, member=None):
    """parameter name (package 008) -> APEX bind"""
    if literal and param in literal: return literal[param]
    old = BINDS.get(member, {}).get(param)
    if old is None: raise KeyError('no original name for %s.%s' % (member, param))
    name = re.sub(r'^(IO|I|O)_', '', old)
    if old == 'I_FUNCTION_CODE': return ':%sFUNCTION_CODE' % P
    m = re.match(r'(\w+)_LOCKED$', name)
    if m and not name.startswith('P1110_'): return ':%s%s_LOCKED' % (P, m.group(1))
    if name == 'VALUE': return None
    return ':' + name
def call(member, literal=None, skip_defaults=True, overrides=None):
    """named-parameter call text of a spec member"""
    overrides = overrides or {}
    args = []
    for p, mode, has_default in MEMBERS[member]['params']:
        if p in overrides:
            if overrides[p] is not None: args.append('%s => %s' % (p, overrides[p]))
            continue
        b = bind(p, literal, member)
        if b is None: continue
        args.append('%s => %s' % (p, b))
    return '%s.%s(%s)' % (PKG, member, ', '.join(args))
def binds_of(member, modes, overrides=None):
    overrides = overrides or {}
    out = []
    for p, mode, _ in MEMBERS[member]['params']:
        if mode in modes and p not in overrides:
            b = bind(p, None, member)
            if b and b.startswith(':P'): out.append(b[1:])
    return out

# ------------------------------------------------------------------ items (metadata from the XML, rev 1 §4)
old = open(OLD_SPEC, encoding='utf-8').read()
sec = old.split('## 4. Items')[1].split('\n## 5.')[0]
ROWS = collections.OrderedDict()
for line in sec.splitlines():
    if not line.startswith('| `P1110_'): continue
    c = [x.strip() for x in line.strip().strip('|').split('|')]
    ROWS[c[0].strip('`')] = dict(column=c[1], type=c[2], label=c[3], req=c[4], mask=c[5], default=c[6], lov=c[7],
                                 parents=c[8], maxlen=c[9], layout=c[10], source=c[12].replace('`', ''), notes=c[13])
for gone in ('REC_STATUS', 'FORM_OPEN', 'NEED_FETCH', 'UI_STATE', 'NEXT_FUN', 'CODE', 'LETTER_NBR', 'PRSNL_IMPR'):
    ROWS.pop(P + gone, None)
SERVER_ONLY = 'Display Only, CSS u-hidden (Send On Page Submit = No)'

# read-only rules (work/step02/read_only_rules.md, extraction report §3)
FLAG_GROUPS = collections.OrderedDict([
    ('IMPR_TYPE_CD', ['IMPR_TYPE_CD']), ('BUS_ID_EXPRD_DT', ['BUS_ID_EXPRD_DT']),
    ('COMM_RGSTRTN_TYPE', ['COMM_RGSTRTN_TYPE']), ('CITY_CODE_OF_ID', ['CITY_CODE_OF_ID']), ('BUS_ID', ['BUS_ID']),
    ('BRNH_CITY_CD', ['BRNH_CITY_CD']), ('BUS_ID_BRNCH', ['BUS_ID_BRNCH']), ('CTRY_CD', ['CTRY_CD']),
    ('ARBC_IMPR_NAME', ['ARBC_IMPR_NAME']),
    ('REGISTER_ITEMS', ['IMPR_POB_NBR', 'IMPR_ZIP_CD', 'IMPR_FAX_NBR', 'IMPR_TELEX_NBR']),
    ('IMPR_TEL_NBR', ['IMPR_TEL_NBR']), ('ACTIVITY', ['ACTIVITY']), ('B_ID_NBR', ['B_ID_NBR']),
    ('CAR_AGENT_FLAG', ['CAR_AGENT_FLAG'])])
FLAG_OF = {i: g for g, its in FLAG_GROUPS.items() for i in its}
RO_CONDITION = {'BUS_ID_TYPE_CD': 'BUS_ID_TYPE_CD_IS_READ_ONLY', 'IMPR_EXPR_TYPE': 'IMPR_EXPR_TYPE_IS_READ_ONLY',
                'EXPRESS_POST': 'EXPRESS_POST_IS_READ_ONLY'}
RO_ALWAYS = {'PORT_CD': 'WHEN-NEW-FORM-INSTANCE (SET_ITEM_PROPERTY ENABLED FALSE)',
             'ADD_CTRY_CD': 'value 100, disabled by the "CTRY 100" block'}
DYN_REQUIRED = collections.OrderedDict([
    ('BUS_ID_EXPRD_DT', 'BUS_ID_EXPRD_DT_IS_REQUIRED'), ('COMM_RGSTRTN_TYPE', 'COMM_RGSTRTN_TYPE_IS_REQUIRED'),
    ('CITY_CODE_OF_ID', 'CITY_CODE_OF_ID_IS_REQUIRED'), ('BRNH_CITY_CD', 'BRNH_CITY_CD_IS_REQUIRED'),
    ('BUS_ID_BRNCH', 'BUS_ID_BRNCH_IS_REQUIRED'), ('ACTIVITY', 'ACTIVITY_IS_REQUIRED')])
HIJRI = {'BUS_ID_EXPRD_DT', 'BUS_ID_ISSUE_DT'}

def item_type(name, r):
    t = r['type']
    it = name[len(P):]
    if it in HIJRI and not t.startswith('Display Only'):
        return 'Text Field, CSS class `hijri-date-default` (f345 Hijri picker)'
    if t.startswith('Text Field (Hijri)'):
        return 'Text Field, CSS class `hijri-date-default` (f345 Hijri picker)'
    return t.replace('Popup LOV (manual entry allowed, display = code)', 'Popup LOV (display = return value, manual entry)')

items = []
for name, r in ROWS.items():
    it = name[len(P):]
    if name == P + 'ROW_ID':
        r.update(column='ROWID (primary key)', type='Hidden (Value Protected = Yes)',
                 notes='Form region primary key, type ROWID (Forms key mode ROWID); = P0_PAGE_PK')
    ro = '-'
    if it in RO_ALWAYS: ro = 'Always (%s)' % RO_ALWAYS[it]
    elif it in RO_CONDITION: ro = 'PL/SQL Expression `%s`' % call(RO_CONDITION[it])
    elif it in FLAG_OF: ro = 'DA `%s READ ONLY` (flag `%s%s_LOCKED`)' % (FLAG_OF[it], P, FLAG_OF[it])
    req = 'Yes' if r['req'].startswith('Yes') else 'No'
    if it in DYN_REQUIRED: req = 'Validation `%s REQUIRED` (`%s`)' % (it, DYN_REQUIRED[it])
    cond = ''
    if it == 'WASL_CITY_NAME': cond = 'Server-side condition: `%s`' % call('WASL_CITY_IS_SHOWN')
    if it in ('CITY_CODE', 'CITY_NAME'): cond = 'Server-side condition: NOT `%s`' % call('WASL_CITY_IS_SHOWN')
    mask = r['mask']
    if it == 'LST_TRAN_DT': mask = 'YYYY/MM/DD HH24:MI:SS'
    if it in HIJRI: mask = '&%sHIJRI_DATE_FORMAT.' % P     # Application Setting HIJRI_DATE_FORMAT (user request 2026-11-23)
    items.append(dict(name=name, column=r['column'], type=item_type(name, r), label=r['label'], required=req,
                      mask=mask, default=r['default'], lov=r['lov'].replace('LOV_CTRY_CD (inline)', 'LOV_COUNTRIES_GULF'),
                      parents=r['parents'], maxlen=r['maxlen'], layout=r['layout'], read_only=ro, condition=cond,
                      source=r['source'], notes=r['notes']))
NEW_ITEMS = [
    (P + 'P_CODE', 'Hidden (Value Protected = No)', ':PARAMETER.CODE - function mode set by EXEC_FUNS; kept until SAVE / CLEAR / another record (extraction §7 #2)'),
    (P + 'P_LETTER_NBR', 'Hidden (Value Protected = Yes)', ':PARAMETER.LETTER_NBR (PARAMETERS ENTRY, EXEC_FUNS)'),
    (P + 'P_PRSNL_IMPR', 'Hidden (Value Protected = Yes)', ':PARAMETER.PRSNL_IMPR (PARAMETERS ENTRY), default 0'),
    (P + 'MODULE_ID', 'Hidden (Value Protected = Yes)', 'f345: SC_SYSTEM_OBJECTS id of the form; kept by SCREEN ENTRY RESET'),
    (P + 'HIJRI_DATE_FORMAT', 'Hidden (Value Protected = Yes)', 'Hijri date format (Application Setting HIJRI_DATE_FORMAT, default YYYY-MM-MI): format mask &P1110_HIJRI_DATE_FORMAT. of the Hijri date items'),
    (P + 'HERO_TITLE', 'Display Only (region IMPORTERS_HERO)', 'f345 HEADER TITLE'),
    (P + 'FORM_OPEN', 'Hidden (Value Protected = Yes)', 'Y after WHEN-NEW-FORM-INSTANCE ran (once per entry; SCREEN ENTRY RESET clears it)'),
    (P + 'ADJ_FUNS', 'Hidden (Value Protected = Yes)', 'f345 Page Functions filter (comma list of SYS_OS_FILE_NAME)'),
    (P + 'MOBILE_URL', 'Hidden (Value Protected = Yes)', 'URL of dialog page 111002 (function IMPR1110_MOB)'),
    (P + 'FUNCTION_CODE', 'Hidden (Value Protected = No)', 'function being executed (Set Value by the function DAs, drives DA EXEC_FUNS)'),
    (P + 'FUNCTION_PENDING', 'Hidden (Value Protected = No)', 'function waiting for the SUPPORT_ENTRY dialog (F1, F2, F3, F5)'),
    (P + 'CONFIRM_TEXT', 'Hidden (Value Protected = No)', 'question computed by a *_CONFIRM_TEXT function'),
    (P + 'ANSWER', 'Hidden (Value Protected = No)', 'answer of the last confirm: 1 = yes, 2 = no (Forms ALERT_BUTTON1 / 2)'),
    (P + 'SUSPEND_ANSWER', 'Hidden (Value Protected = No)', 'answer of the BUS_ID suspended-importer question')]
NEW_ITEMS += [(P + g + '_LOCKED', 'Hidden (Value Protected = No)', 'read-only flag Y / N of ' + ', '.join(its))
              for g, its in FLAG_GROUPS.items()]
for n, t, note in NEW_ITEMS:
    assert len(n) <= 30, n
    items.append(dict(name=n, column='-', type=t, label='-', required='No', mask='-', default='Static: 0' if n.endswith('P_PRSNL_IMPR') else '-',
                      lov='-', parents='-', maxlen='-', layout='hidden', read_only='-', condition='', source='-', notes=note))
ITEM_TYPE = {i['name']: i['type'] for i in items}
def enterable(n):
    t = ITEM_TYPE.get(n, '')
    return not (t.startswith('Display Only') or t.startswith('Hidden')) or n in (
        P + 'ANSWER', P + 'SUSPEND_ANSWER', P + 'FUNCTION_CODE', P + 'CONFIRM_TEXT')
for i in items:
    i['submit'] = 'Yes' if enterable(i['name']) else 'No (server value)'

# ------------------------------------------------------------------ validations
validations = []
for e in ENTRIES:
    if e['name'].endswith('_VALIDATION'):
        it = e['name'][:-len('_VALIDATION')]
        validations.append(dict(name='%s VALIDATION' % it, item=P + it, member=e['name'],
                                code='RETURN %s;' % call(e['name']), source=e['source']))
for it, f in DYN_REQUIRED.items():
    lbl = ROWS.get(P + it, {}).get('label', it)
    validations.append(dict(name='%s REQUIRED' % it, item=P + it, member='REQUIRED_VALIDATION',
                            code="RETURN FORMS_APX.REQUIRED_VALIDATION(ITEM_VALUE => :%s%s, ITEM_LABEL => '%s');" % (P, it, lbl),
                            condition=call(f), source='SET_ITEM_PROPERTY(%s, REQUIRED) - read_only_rules.md' % it))

# ------------------------------------------------------------------ dynamic actions
FLAGS_CALL = call('READ_ONLY_FLAGS')
FLAGS_RET = binds_of('READ_ONLY_FLAGS', ('OUT', 'IN OUT'))
FLAGS_SUB = [b for b in binds_of('READ_ONLY_FLAGS', ('IN',)) if enterable(b)]
def fos(member, ret=True, overrides=None, literal=None, note=''):
    sub = [b for b in binds_of(member, ('IN', 'IN OUT'), overrides) if enterable(b)]
    rtn = binds_of(member, ('IN OUT', 'OUT'), overrides) if ret else []
    return dict(action='FOS - Execute PL/SQL Code', code=call(member, literal, overrides=overrides) + ';',
                submit=sub, ret=rtn, note=note)
def flags_action():
    return dict(action='FOS - Execute PL/SQL Code (change events ON)', code=FLAGS_CALL + ';', submit=FLAGS_SUB,
                ret=FLAGS_RET, note='returns the P1110_<GROUP>_LOCKED flags; their change events run the READ ONLY DAs')
def js(lines, why):
    return dict(action='Execute JavaScript Code', code='\n'.join(lines), submit=[], ret=[], note=why, js=len(lines))
FLAG_DRIVERS = {'IMPR_TYPE_CD', 'BUS_ID_TYPE_CD', 'BUS_ID', 'BUS_ID_BRNCH', 'BUS_ID_EXPRD_DT'}
das = []
def da(name, event, selection, actions, source, condition='-', fire_init='No'):
    das.append(dict(name=name, event=event, selection=selection, condition=condition, actions=actions,
                    source=source, fire_init=fire_init))
by_name = {e['name']: e for e in ENTRIES}
for e in ENTRIES:
    n = e['name']
    if not (n.endswith('_WHEN_VALIDATE_ITEM') or n.endswith('_VALIDATE_ITEM')) or n.endswith('_VALIDATION'): continue
    it = re.sub(r'_(WHEN_VALIDATE_ITEM|VALIDATE_ITEM)$', '', n)
    acts = []
    if it == 'IMPR_TYPE_CD':
        acts.append(fos('IMPR_TYPE_CD_LOV_RETURN', note='KEY-LISTVAL post-select logic (TODO-VERIFY: Forms runs it only after an LOV pick)'))
    if it == 'BUS_ID':
        acts.append(fos('BUS_ID_SUSPENDED_CONFIRM_TEXT', note='Items to Return: P1110_CONFIRM_TEXT (function result)'))
        acts[-1]['code'] = ':%sCONFIRM_TEXT := %s;' % (P, call('BUS_ID_SUSPENDED_CONFIRM_TEXT'))
        acts[-1]['ret'] = [P + 'CONFIRM_TEXT']
        acts.append(js(["var t = $v('P1110_CONFIRM_TEXT'), go = function (a) { $s('P1110_SUSPEND_ANSWER', a); apex.event.trigger('#P1110_BUS_ID', 'impr1110-bus-id-validate'); };",
                        "if (t) { apex.message.confirm(t, function (ok) { go(ok ? '1' : '2'); }); } else { go('1'); }"],
                       'WARNING alert with a text computed on the server (importer number); the answer is needed before the WHEN-VALIDATE-ITEM code runs'))
        da('BUS_ID WHEN-VALIDATE-ITEM', 'Change', 'Item P1110_BUS_ID', acts, e['source'])
        da('BUS_ID WHEN-VALIDATE-ITEM CONFIRMED', 'Custom: impr1110-bus-id-validate', 'Item P1110_BUS_ID',
           [fos(n), flags_action()], e['source'] + ' (after the suspended-importer question)')
        continue
    acts.append(fos(n))
    if it == 'IMPR_NBR':
        acts.append(dict(action='Submit Page', code='request EXECUTE_QUERY', submit=[], ret=[],
                         note='runs only when the FOS succeeded (the number exists) - Forms :GLOBAL.EXEC_QUERY_NOW -> EXECUTE_QUERY'))
    if it in FLAG_DRIVERS: acts.append(flags_action())
    da('%s WHEN-VALIDATE-ITEM' % it, 'Change', 'Item P1110_%s' % it, acts, e['source'])
NAV = {'IMPR_TYPE_CD_NEW_ITEM_INSTANCE': ('IMPR_TYPE_CD WHEN-NEW-ITEM-INSTANCE', 'Get Focus'),
       'BUS_ID_WHEN_NEW_ITEM_INSTANCE': ('BUS_ID WHEN-NEW-ITEM-INSTANCE', 'Get Focus'),
       'BUS_ID_BRNCH_NEW_ITEM_INSTANCE': ('BUS_ID_BRNCH WHEN-NEW-ITEM-INSTANCE', 'Get Focus'),
       'BANK_IBAN_NEW_ITEM_INSTANCE': ('BANK_IBAN WHEN-NEW-ITEM-INSTANCE', 'Get Focus'),
       'ARBC_IMPR_NAME_KEY_NEXT_ITEM': ('ARBC_IMPR_NAME KEY-NEXT-ITEM', 'Lose Focus'),
       'COMM_RGSTRTN_TYPE_LIST_CHANGED': ('COMM_RGSTRTN_TYPE WHEN-LIST-CHANGED', 'Change')}
for n, (name, ev) in NAV.items():
    it = name.split(' ')[0]
    acts = [fos(n)]
    if n == 'COMM_RGSTRTN_TYPE_LIST_CHANGED': acts.append(flags_action())
    da(name, ev, 'Item P1110_%s' % it, acts, by_name[n]['source'])
for g, its in FLAG_GROUPS.items():
    da('%s READ ONLY' % g, 'Change', 'Item %s%s_LOCKED' % (P, g),
       [dict(action='Disable', code='items ' + ', '.join(P + i for i in its), submit=[], ret=[], note='True action'),
        dict(action='Enable', code='items ' + ', '.join(P + i for i in its), submit=[], ret=[], note='False action')],
       'read_only_rules.md (Make_Field_Entrable / SET_ITEM_PROPERTY ENABLED)',
       condition='Item %s%s_LOCKED = Y' % (P, g), fire_init='Yes')
# functions (f345 Page Functions list -> custom event = SYS_OS_FILE_NAME)
WNRI_OVR = {'P_ANSWER': ':%sANSWER' % P}
for code, kind in [('IMPR1110F1', 'support'), ('IMPR1110F2', 'support'), ('IMPR1110F3', 'support'),
                   ('IMPR1110F5', 'support'), ('IMPR1110F4', 'mode'), ('IMPR_CAR_AGENT', 'mode'),
                   ('CREATE_BRKR_IMPR_AUTH', 'direct'), ('IMPR1115_GZT', 'direct'), ('IMPR_MCI_SERVICE', 'mci'),
                   ('IMPR1110_MOB', 'mobile'), ('IMPR1115_SCR', 'page')]:
    if kind == 'mode':
        acts = [dict(action='Set Value', code="Static NULL -> P1110_FUNCTION_CODE, Suppress Change Event = Yes", submit=[], ret=[], note='so the next value always fires a change'),
                dict(action='Set Value', code="Static '%s' -> P1110_FUNCTION_CODE" % code, submit=[], ret=[], note='fires DA EXEC_FUNS')]
    elif kind == 'support':
        acts = [dict(action='Set Value', code="Static '%s' -> P1110_FUNCTION_PENDING" % code, submit=[], ret=[], note=''),
                js(["apex.navigation.redirect($v('P1110_SUPPORT_URL'));"],
                   'open the SUPPORT_ENTRY dialog (form converted separately, decision §15 #12; its page and URL item are TODO)')]
    elif kind == 'direct':
        acts = [fos('EXEC_FUNS', overrides={'FUNCTION_CODE': "'%s'" % code})]
    elif kind == 'mci':
        a = fos('UPDATE_IMPORTER_CONFIRM_TEXT'); a['code'] = ':%sCONFIRM_TEXT := %s;' % (P, call('UPDATE_IMPORTER_CONFIRM_TEXT')); a['ret'] = [P + 'CONFIRM_TEXT']
        acts = [a, js(["apex.message.confirm($v('P1110_CONFIRM_TEXT'), function (ok) {",
                       "    if (ok) { $s('P1110_ANSWER', '1'); apex.event.trigger(document, 'impr1110-update-importer'); } });"],
                      'question text computed on the server (UPDATE_IMPORTER_MSG)')]
    elif kind == 'mobile':
        acts = [fos('EXEC_FUNS', overrides={'FUNCTION_CODE': "'%s'" % code}, note='checks IMPR_NBR > 3000000'),
                js(["apex.navigation.redirect($v('P1110_MOBILE_URL'));"], 'open dialog page 111002 (URL from apex_page.get_url, modal)')]
    else:
        acts = [dict(action='-', code='no DA: the f345 list links to page IMPR1110 itself when a page named IMPR1115 exists', submit=[], ret=[], note='TODO: IMPR1115 not converted')]
    if kind != 'page':
        da('%s EXECUTE-FUNCTION' % code, 'Custom: %s' % code, 'JavaScript Expression: document', acts,
           'PU EXEC_FUNS / TMPLT EXECUTE_FUNCTION (%s)' % code)
da('SUPPORT_ENTRY DIALOG CLOSED', 'Dialog Closed', 'JavaScript Expression: document',
   [dict(action='Set Value', code="Static NULL -> P1110_FUNCTION_CODE, Suppress Change Event = Yes", submit=[], ret=[], note=''),
    dict(action='Set Value', code="JavaScript Expression $v('P1110_FUNCTION_PENDING') -> P1110_FUNCTION_CODE", submit=[], ret=[], note='fires DA EXEC_FUNS')],
   'CALL_FORM(SUPPORT_ENTRY) return (functions F1, F2, F3, F5)', condition='TODO: dialog = SUPPORT_ENTRY page')
da('EXEC_FUNS', 'Change', 'Item P1110_FUNCTION_CODE',
   [fos('EXEC_FUNS'),
    dict(fos('NEW_RECORD_CONFIRM_TEXT'), code=':%sCONFIRM_TEXT := %s;' % (P, call('NEW_RECORD_CONFIRM_TEXT')), ret=[P + 'CONFIRM_TEXT']),
    js(["var t = $v('P1110_CONFIRM_TEXT'), go = function (a) { $s('P1110_ANSWER', a); apex.event.trigger(document, 'impr1110-new-record-instance'); };",
        "if (t) { apex.message.confirm(t, function (ok) { go(ok ? '1' : '2'); }); } else { go('1'); }"],
       'CONFIRM alert of IMPR1110F1 / F5 with a computed text (new name), then WHEN-NEW-RECORD-INSTANCE')],
   'PU EXEC_FUNS + IMPORTERS.WHEN-NEW-RECORD-INSTANCE', condition='Item P1110_FUNCTION_CODE is not null')
da('WHEN-NEW-RECORD-INSTANCE', 'Custom: impr1110-new-record-instance', 'JavaScript Expression: document',
   [fos('WHEN_NEW_RECORD_INSTANCE', overrides=WNRI_OVR), flags_action()], 'IMPORTERS.PRE-RECORD + WHEN-NEW-RECORD-INSTANCE after a function')
da('UPDATE_IMPORTER', 'Custom: impr1110-update-importer', 'JavaScript Expression: document',
   [fos('UPDATE_IMPORTER', overrides={'P_ANSWER': ':%sANSWER' % P})], 'PU UPDATE_IMPORTER (function IMPR_MCI_SERVICE)')
da('LOV_UPDATE_IMPR_MOBILE DIALOG CLOSED', 'Dialog Closed', 'JavaScript Expression: document',
   [fos('LOV_UPDATE_MOBLIE')], 'PU LOV_UPDATE_MOBLIE after CALL_FORM(LOV_UPDATE_IMPR_MOBILE)', condition='dialog page 111002')
da('PRE-INSERT CONFIRM', 'Before Page Submit', '-',
   [js(["apex.event.gCancelFlag = true;",
        "apex.message.confirm($v('P1110_PRE_INSERT_QUESTION'), function (ok) { if (ok) { $s('P1110_ANSWER', '1'); apex.page.submit('CREATE'); } });"],
       'f345 known case: page 0 CREATE submits directly, the question must come before the submit')],
   'IMPORTERS.PRE-INSERT (CONFIRM for brokers, class 1 / type 3)',
   condition="JavaScript expression: this.data === 'CREATE' && $v('P1110_BROKER_USER') === 'Y' && $v('P1110_ANSWER') !== '1'")
items.append(dict(name=P + 'BROKER_USER', column='-', type='Hidden (Value Protected = Yes)', label='-', required='No', mask='-',
                  default='-', lov='-', parents='-', maxlen='-', layout='hidden', read_only='-', condition='', source='-',
                  notes='Y for brokers (class 1, type 3): client condition of DA PRE-INSERT CONFIRM', submit='No (server value)'))
items.append(dict(name=P + 'PRE_INSERT_QUESTION', column='-', type='Hidden (Value Protected = Yes)', label='-', required='No', mask='-',
                  default='-', lov='-', parents='-', maxlen='-', layout='hidden', read_only='-', condition='', source='-',
                  notes='text of the broker question (Text Message IMPR1110_PRE_INSERT_CONFIRM), read by DA PRE-INSERT CONFIRM', submit='No (server value)'))
items.append(dict(name=P + 'SUPPORT_URL', column='-', type='Hidden (Value Protected = Yes)', label='-', required='No', mask='-',
                  default='-', lov='-', parents='-', maxlen='-', layout='hidden', read_only='-', condition='', source='-',
                  notes='URL of the SUPPORT_ENTRY dialog (TODO: page of the separately converted form)', submit='No (server value)'))

# ------------------------------------------------------------------ processes / computations
def proc(seq, point, name, code, cond, source):
    return dict(seq=seq, point=point, name=name, code=code, condition=cond, source=source)
WNRI_RENDER = {'P_CODE': 'NULL', 'P_ANSWER': None}
processes = [
    proc(10, 'Before Header', 'New', 'f345 session setup, copied from AGR1100 (`:SSO_APP_USER := GENERAL_UTILITY.ZATCA_SSO(:APP_USER);` + port / user lookups)', '-', 'f345 standard §6'),
    proc(20, 'Before Header', 'P0_PAGE_PK CHECK', call('P0_PAGE_PK_CHECK') + ';', '-', 'f345 (block WHERE clause PORT_CD = :PARAMETER.P_CURR_PORT_CD)'),
    # common helpers in FORMS_APX 004 (user decision 2026-11-24): the form name / default title are parameters
    proc(40, 'Before Header', 'PARAMETERS', ":%sMODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :%sMODULE_ID, FORM_NAME => '%s');" % (P, P, PKG), '-', 'f345'),
    proc(50, 'Before Header', 'PARAMETERS ENTRY', call('PARAMETERS_ENTRY') + ';', '-', 'CALL_FORM parameters PRSNL_IMPR, LETTER_NBR'),
    proc(60, 'Before Header', 'WHEN-NEW-FORM-INSTANCE', call('WHEN_NEW_FORM_INSTANCE') + ';', ':%sFORM_OPEN is null' % P, 'FORM.WHEN-NEW-FORM-INSTANCE'),
    proc(65, 'Before Header', 'FORM OPEN', ":%sFORM_OPEN := 'Y';" % P, ':%sFORM_OPEN is null' % P, 'once per entry (SCREEN ENTRY RESET clears it)'),
    proc(70, 'Before Header', 'P0_PAGE_PK', ':%sROW_ID := :P0_PAGE_PK;' % P, '-', 'f345 (key = ROWID, Forms key mode ROWID)'),
    proc(80, 'Before Header', 'Initialize form IMPORTERS', 'NATIVE_FORM_INIT, region IMPORTERS', '-', 'block IMPORTERS fetch'),
    proc(82, 'Before Header', 'POST-QUERY', call('POST_QUERY') + ';', ':%sROW_ID is not null' % P, 'IMPORTERS.POST-QUERY (+ POST-CHANGE on fetch)'),
    proc(84, 'Before Header', 'WHEN-CREATE-RECORD', call('WHEN_CREATE_RECORD') + ';', ':%sROW_ID is null' % P, 'IMPORTERS.WHEN-CREATE-RECORD'),
    proc(86, 'Before Header', 'WHEN-NEW-RECORD-INSTANCE', call('WHEN_NEW_RECORD_INSTANCE', overrides=WNRI_RENDER) + ';', '-',
         'IMPORTERS.PRE-RECORD + WHEN-NEW-RECORD-INSTANCE. P_CODE => NULL: Forms consumes :PARAMETER.CODE in the first WNRI after the function'),
    proc(88, 'Before Header', 'READ ONLY FLAGS', FLAGS_CALL + ';', '-', 'net read-only state (read_only_rules.md)'),
    proc(100, 'Before Header', 'HEADER TITLE', "FORMS_APX.HEADER_TITLE(P_MODULE_ID => :%sMODULE_ID, P_HERO_TITLE => :%sHERO_TITLE, "
         "DEFAULT_TITLE => 'إضافة وتعديل بيانات مستورد');" % (P, P), '-', 'f345 (OLB block TITLE)'),
    proc(10, 'After Submit', 'EXECUTE-QUERY', ':P0_PAGE_PK := %s;' % call('IMPORTER_ROW_ID'), ":REQUEST = 'EXECUTE_QUERY'", 'IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM -> WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY'),
    proc(20, 'After Submit', 'PRE-INSERT', call('PRE_INSERT') + ';', ":P0_PAGE_PK is null and :REQUEST = 'CREATE'", 'IMPORTERS.PRE-INSERT'),
    proc(30, 'After Submit', 'PRE-UPDATE', call('PRE_UPDATE') + ';', ":P0_PAGE_PK is not null and :REQUEST = 'SAVE'", 'IMPORTERS.PRE-UPDATE'),
    proc(35, 'After Submit', 'KEY-DELREC', call('KEY_DELREC') + ';', ":REQUEST = 'DELETE'", 'IMPORTERS.KEY-DELREC + PRE-DELETE (block Delete Allowed = No: the trigger deletes)'),
    proc(40, 'After Submit', 'Process form IMPORTERS', 'NATIVE_FORM_DML, region IMPORTERS, Prevent Lost Updates = Yes, Lock Row = Yes, Return Primary Key(s) after Insert = Yes',
         ":REQUEST in ('CREATE', 'SAVE')", 'Forms default INSERT / UPDATE of block IMPORTERS'),
    proc(50, 'After Submit', 'POST-INSERT', call('POST_INSERT') + ';', ":P0_PAGE_PK is null and :REQUEST = 'CREATE'", 'IMPORTERS.POST-INSERT'),
    proc(60, 'After Submit', 'POST-UPDATE', call('POST_UPDATE') + ';', ":P0_PAGE_PK is not null and :REQUEST = 'SAVE'", 'IMPORTERS.POST-UPDATE'),
    proc(70, 'After Submit', 'P_CODE RESET', ':%sP_CODE := NULL;' % P, ":REQUEST in ('CREATE', 'SAVE')", 'function mode ends with the commit (extraction §7 #2)'),
    proc(80, 'After Submit', 'P0_PAGE_PK AFTER INSERT', ':P0_PAGE_PK := :%sROW_ID;' % P, ":P0_PAGE_PK is null and :REQUEST = 'CREATE'", 'f345'),
    proc(85, 'After Submit', 'P0_PAGE_PK AFTER DELETE', ':P0_PAGE_PK := NULL;', ":REQUEST = 'DELETE'", 'f345'),
]
computations = [
    dict(item=P + 'HIJRI_DATE_FORMAT', point='Before Header', expression='FORMS_APX.HIJRI_DATE_FORMAT', condition='-',
         source='Hijri date format from one place: Application Setting HIJRI_DATE_FORMAT (Forms mask MI-MM-YYYY)'),
    dict(item=P + 'ADJ_FUNS', point='After Header', expression=call('ADJ_FUNS'), condition='-', source='PU ADJ_FUNS'),
    dict(item=P + 'BROKER_USER', point='Before Header', expression="CASE WHEN %s THEN 'Y' ELSE 'N' END" % call('EXPRESS_POST_IS_READ_ONLY'),
         condition='-', source='PRE-INSERT condition class 1 / type 3 (same rule as EXPRESS_POST)'),
    dict(item=P + 'PRE_INSERT_QUESTION', point='After Header', expression="APEX_LANG.MESSAGE('IMPR1110_PRE_INSERT_CONFIRM')",
         condition=":P1110_BROKER_USER = 'Y'", source='IMPORTERS.PRE-INSERT CONFIRM text (Text Message, translatable)'),
    dict(item=P + 'MOBILE_URL', point='After Header', expression="APEX_PAGE.GET_URL(p_page => 111002, p_clear_cache => '111002', p_items => 'P111002_IMPR_NBR', p_values => :P1110_IMPR_NBR)",
         condition=':P1110_IMPR_NBR is not null', source='CALL_FORM(LOV_UPDATE_IMPR_MOBILE)'),
    dict(item='P111002_CENTRAL_MOBILE', point='Before Header (page 111002)', expression=call('CENTRAL_MOBILE'), condition='-',
         source='PU LOV_UPDATE_MOBLIE (P_CENTRAL_MOBILE parameter)'),
    dict(item='P111002_MOBILE_NO', point='Before Header (page 111002)', expression=':P111002_CENTRAL_MOBILE', condition=':P111002_MOBILE_NO is null',
         source='LOV_UPDATE_IMPR_MOBILE.BLK.WHEN-NEW-BLOCK-INSTANCE'),
]

# ------------------------------------------------------------------ traceability (rows of the rev-1 registry, re-mapped)
def parse_row(s):
    out, cur, q, i = [], '', False, 0
    while i < len(s):
        ch = s[i]
        if q:
            if ch == "'" and s[i + 1:i + 2] == "'": cur += "'"; i += 2; continue
            if ch == "'": q = False
            else: cur += ch
        elif ch == "'": q = True
        elif ch == ',': out.append(cur.strip()); cur = ''
        else: cur += ch
        i += 1
    out.append(cur.strip())
    return [None if x == 'NULL' else x for x in out]
reg_old = open(OLD_REG, encoding='utf-8').read()
trace = [parse_row(r) for r in re.findall(r"^\s+m\((.*)\);\s*$", reg_old, re.M)]
VAL_MAP = {}
for e in ENTRIES:
    if e['name'].endswith('_VALIDATION'):
        VAL_MAP[e['name'][:-len('_VALIDATION')]] = e['name']
WVI_PUBLIC = {re.sub(r'_(WHEN_VALIDATE_ITEM|VALIDATE_ITEM)$', '', e['name']): e['name'] for e in ENTRIES
              if re.search(r'_(WHEN_VALIDATE_ITEM|VALIDATE_ITEM)$', e['name'])}
MEMBER_MAP = {
    'IMPR1110.IMPORTERS_POST_QUERY': ('PROCESS', 'POST-QUERY', 'IMPR1110.POST_QUERY'),
    'IMPR1110.IMPORTERS_PRE_QUERY': ('REGION', 'IMPORTERS_SEARCH (SQL of page 111001)', None),
    'IMPR1110.IMPORTERS_PRE_INSERT': ('PROCESS', 'PRE-INSERT', 'IMPR1110.PRE_INSERT'),
    'IMPR1110.IMPORTERS_POST_INSERT': ('PROCESS', 'POST-INSERT', 'IMPR1110.POST_INSERT'),
    'IMPR1110.IMPORTERS_PRE_UPDATE': ('PROCESS', 'PRE-UPDATE', 'IMPR1110.PRE_UPDATE'),
    'IMPR1110.IMPORTERS_POST_UPDATE': ('PROCESS', 'POST-UPDATE', 'IMPR1110.POST_UPDATE'),
    'IMPR1110.IMPORTERS_KEY_DELREC': ('PROCESS', 'KEY-DELREC', 'IMPR1110.KEY_DELREC'),
    'IMPR1110.IMPORTERS_PRE_DELETE': ('PROCESS', 'KEY-DELREC', 'IMPR1110.KEY_DELREC'),
    'IMPR1110.IMPORTERS_PRE_RECORD': ('PROCESS', 'WHEN-NEW-RECORD-INSTANCE', 'IMPR1110.WHEN_NEW_RECORD_INSTANCE'),
    'IMPR1110.IMPORTERS_NEW_RECORD_INSTANCE': ('PROCESS', 'WHEN-NEW-RECORD-INSTANCE + DA WHEN-NEW-RECORD-INSTANCE', 'IMPR1110.WHEN_NEW_RECORD_INSTANCE'),
    'IMPR1110.IMPORTERS_WHEN_CREATE_RECORD': ('PROCESS', 'WHEN-CREATE-RECORD', 'IMPR1110.WHEN_CREATE_RECORD'),
    'IMPR1110.IMPORTERS_ON_ERROR': ('PLSQL', 'error text of every <ITEM> VALIDATION (PRIVATE_ERROR_TEXT)', None),
}
NOTE_FIX = [(r'IMPR1110\.AJAX_FUNCTION -> exec_funs', 'one DA per function code -> IMPR1110.EXEC_FUNS'),
            (r'ON-INSERT \(CREATE\) / ON-UPDATE \(SAVE\)', 'PRE-/POST- processes around Process form IMPORTERS'),
            (r'Process "ON-INSERT"', 'Process around native Process form'), (r'Process "ON-UPDATE"', 'Process around native Process form'),
            (r'page 0 SAVE / CREATE -> ON-UPDATE / ON-INSERT', 'page 0 SAVE / CREATE -> PRE-*, Process form IMPORTERS, POST-*'),
            (r'DML via IMPR1110\.ON_INSERT / ON_UPDATE / KEY_DELREC', 'native Form DML (Process form IMPORTERS) + KEY-DELREC'),
            (r'Static Content, template Interactive Report', 'Form region on IMPORTERS, primary key ROWID, template Interactive Report'),
            (r'-> ui OPEN_LOV', '-> (LOV opens from the item)'), (r'-> ui REQUERY', '-> page submit EXECUTE_QUERY'),
            (r'\+ entrable/required \(ui\)', '+ read-only / required rules'), (r'; entrable state', '; read-only rules'),
            (r'Entrable state \+ ', ''), (r'\(page_new_record\)', '')]
# package 012 (unused code removed): Forms triggers whose converted code was only UI calls or an unread global
DROPPED_MEMBERS = {
    'IMPR1110.IMPORTERS_WHEN_CLEAR_BLOCK': 'only sets :GLOBAL.STAT_CLR, which no code reads; page 0 CLEAR is a redirect (package 012)',
    'IMPR1110.BRNH_CITY_CD_NEW_ITEM_INSTANCE': 'only UI calls (REQUIRED / VALID of BRNH_CITY_CD, BUS_ID_BRNCH): required rules and validations cover them (package 012)',
    'IMPR1110.CITY_CODE_OF_ID_WHEN_NEW_ITEM': 'only UI calls (BRNH_CITY_CD REQUIRED when COMM_RGSTRTN_TYPE = 2): BRNH_CITY_CD_IS_REQUIRED covers it (package 012)',
}
def remap(r):
    typ, name, comp, comp_name, page, member, status, notes = r
    if member in DROPPED_MEMBERS:
        return [typ, name, None, None, None, None, 'DROPPED', DROPPED_MEMBERS[member]]
    if member in MEMBER_MAP:
        comp, comp_name, member = MEMBER_MAP[member]
    elif member and typ == 'TRIGGER' and member.startswith('IMPR1110.'):
        it = name.split('.')[1] if name.count('.') == 2 else None
        trg = name.split('.')[-1]
        if trg in ('WHEN-VALIDATE-ITEM', 'POST-CHANGE') and it in VAL_MAP:
            comp, comp_name = 'VALIDATION', '%s VALIDATION + DA %s WHEN-VALIDATE-ITEM' % (it, it)
            member = 'IMPR1110.%s / IMPR1110.%s' % (VAL_MAP[it], WVI_PUBLIC[it])
    elif member and typ == 'PROGRAM_UNIT':
        pub = {'EXEC_FUNS': 'IMPR1110.EXEC_FUNS', 'ADJ_FUNS': 'IMPR1110.ADJ_FUNS', 'UPDATE_IMPORTER': 'IMPR1110.UPDATE_IMPORTER / UPDATE_IMPORTER_CONFIRM_TEXT',
               'LOV_UPDATE_MOBLIE': 'IMPR1110.CENTRAL_MOBILE / LOV_UPDATE_MOBLIE'}
        member = pub.get(name, 'IMPR1110 (private %s)' % name)
    if typ == 'CALLED_FORM' and name == 'SUPPORT_ENTRY':
        comp, comp_name, page = 'PAGE', 'SUPPORT_ENTRY page (form converted on its own, SC subsystem - decision §15 #12)', None
        notes = 'TODO: page number and URL item P1110_SUPPORT_URL; on close it must set G_LETTER_NBR / G_SUPP_TITLE_CD / G_LETTER_DT / G_PORT_CD'
    if typ == 'PARAMETER' and name in ('LETTER_NBR', 'CODE', 'PRSNL_IMPR'):
        comp_name = P + 'P_' + name
    if typ == 'ITEM' and name.startswith('IMPORTERS.'):
        it = name.split('.', 1)[1]
        rule = FLAG_OF.get(it) and 'read-only: DA %s READ ONLY' % FLAG_OF[it] or (it in RO_CONDITION and 'read-only: ' + RO_CONDITION[it]) or None
        if rule: notes = (notes + '; ' if notes else '') + rule
    for a, b in NOTE_FIX:
        if notes: notes = re.sub(a, b, notes)
        if comp_name: comp_name = re.sub(a, b, comp_name)
    return [typ, name, comp, comp_name, page, member, status, notes]
trace = [remap(r) for r in trace]
assert not [r for r in trace if any(x and re.search(r'AJAX|ui_json|impr1110\.js|IMPR1110_APX|AI_', x) for x in r)], 'old design left in trace'

# ------------------------------------------------------------------ markdown tables
def cell(x):
    return (str(x) if x not in (None, '') else '-').replace('|', '\\|').replace('\n', '<br>')
def table(head, rows):
    out = ['| ' + ' | '.join(head) + ' |', '|' + '---|' * len(head)]
    out += ['| ' + ' | '.join(cell(c) for c in r) + ' |' for r in rows]
    return '\n'.join(out) + '\n'
W = {}
W['items'] = table(['Page item', 'Source column', 'Type', 'Label (Forms prompt)', 'Required', 'Format mask', 'Default', 'LOV',
                    'Cascading parent(s)', 'Max length', 'Seq / layout', 'Read only', 'Condition', 'Submitted', 'Source Forms item', 'Notes'],
                   [['`%s`' % i['name'], i['column'], i['type'], i['label'], i['required'], i['mask'], i['default'], i['lov'],
                     i['parents'], i['maxlen'], i['layout'], i['read_only'], i['condition'], i['submit'],
                     '`%s`' % i['source'] if i['source'] != '-' else '-', i['notes']] for i in items])
W['validations'] = table(['#', 'Validation', 'Item', 'Type', 'Code', 'Server-side condition', 'Source'],
                         [[n + 1, '`%s`' % v['name'], v['item'], 'PL/SQL Function Body returning Error Text',
                           '`%s`' % v['code'], "request in (CREATE, SAVE)" + (' and `%s`' % v['condition'] if v.get('condition') else ''),
                           v['source']] for n, v in enumerate(validations)])
W['processes'] = table(['Point', 'Seq', 'Process', 'Code (one line)', 'Condition', 'Source'],
                       [[p['point'], p['seq'], '`%s`' % p['name'], '`%s`' % p['code'] if p['code'].startswith(('IMPR1110', ':')) else p['code'],
                         p['condition'], p['source']] for p in processes])
W['computations'] = table(['Item', 'Point', 'Type', 'Expression', 'Condition', 'Source'],
                          [[c['item'], c['point'], 'PL/SQL Expression', '`%s`' % c['expression'], c['condition'], c['source']] for c in computations])
rows, njs = [], 0
for n, d in enumerate(das, 1):
    for k, a in enumerate(d['actions'], 1):
        njs += a.get('js', 0) and 1
        rows.append([n if k == 1 else '', '`%s`' % d['name'] if k == 1 else '', d['event'] if k == 1 else '', d['selection'] if k == 1 else '',
                     d['condition'] if k == 1 else '', k, a['action'], '`%s`' % a['code'] if a['action'].startswith(('FOS', 'Execute')) else a['code'],
                     ', '.join(a['submit']) or '-', ', '.join(a['ret']) or '-', d['fire_init'] if k == 1 else '', a['note'] or '-', d['source'] if k == 1 else ''])
W['das'] = table(['#', 'Dynamic action', 'Event', 'Selection', 'Client condition', 'Act', 'Action', 'Code / setting', 'Items to Submit',
                  'Items to Return', 'Fire on init', 'Note', 'Source'], rows)
W['trace'] = table(['#', 'Forms object type', 'Forms object', 'APEX component type', 'APEX component', 'Page', 'PL/SQL member', 'Status', 'Notes'],
                   [[n + 1] + r for n, r in enumerate(trace)])
for k, v in W.items():
    open('work/step03/gen_%s.md' % k, 'w', encoding='utf-8').write(v)
json.dump(dict(items=items, validations=validations, processes=processes, computations=computations, das=das,
               flag_groups=FLAG_GROUPS, trace=trace), open('work/step03/page_design.json', 'w', encoding='utf-8'),
          indent=1, ensure_ascii=False)

# ------------------------------------------------------------------ registry script
def lit(x):
    return 'NULL' if x in (None, '') else "'%s'" % str(x).replace("'", "''")
stat = collections.Counter(r[6] for r in trace)
reg = ['-- =============================================================================',
       '-- IMPR1110 - migration registry rows (scripts/create_migration_registry.sql)',
       '-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object',
       '--           (traceability matrix, analysis/IMPR1110/IMPR1110_apex_page_spec.md section 14)',
       '-- Form    : IMPR1110.fmb',
       '-- Author  : Claude Code',
       '-- Date    : 2026-11-19',
       '-- Version : 3.1 (step 03 revision 2: declarative design - native Form DML, named-parameter calls into package',
       '--           IMPR1110 version 011 (parameter names without I_ / IO_ / O_, page items as P_<ITEM>), no AJAX /',
       '--           JavaScript file; previous version: rollback/IMPR1110/step03_rev1/)',
       '-- Generated by work/step03/build_spec.py - %d object rows (%s).' % (len(trace), ', '.join('%s %d' % kv for kv in sorted(stat.items()))),
       '-- app_id 202530 = the application installed from f345 (apex-instance-ids). Re-runnable: deletes the',
       "-- form's rows first. NOT executed (CLAUDE.md 6.10).",
       '-- =============================================================================',
       'SET DEFINE OFF', '',
       "DELETE FROM mig_object_map    WHERE form_name = 'IMPR1110';",
       "DELETE FROM mig_form_registry WHERE form_name = 'IMPR1110';", '',
       'INSERT INTO mig_form_registry',
       '    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,',
       '     package_name, complexity, status, owner, business_owner, notes)',
       'VALUES',
       "    ('IMPR1110', 'IMPR', 'IMPR', 202530, 1110, 1110, 'IMPR1110',",
       "     'IMPR1110', 'COMPLEX', 'DESIGN', NULL, NULL,",
       "     %s);" % lit('إضافة وتعديل بيانات مستورد - step 03 rev 2 page design (pages 1110, 111001, 111002); package IMPR1110 011 not compiled'),
       '', 'DECLARE',
       '    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,',
       '                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)',
       '    IS', '    BEGIN', '        INSERT INTO mig_object_map',
       '            (form_name, forms_object_type, forms_object_name, apex_comp_type,',
       '             apex_comp_name, page_id, plsql_member, status, notes)',
       "        VALUES ('IMPR1110', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);",
       '    END m;', 'BEGIN']
for r in trace:
    reg.append('    m(%s);' % ', '.join(lit(x) if i != 4 else (x or 'NULL') for i, x in enumerate(r)))
reg += ['END;', '/', '', 'COMMIT;', '']
open('registry/IMPR1110_registry.sql', 'w', encoding='utf-8', newline='\n').write('\n'.join(reg))
print(dict(items=len(items), validations=len(validations), processes=len(processes), computations=len(computations),
           das=len(das), da_actions=len(rows), js_actions=njs, trace=len(trace), status=dict(stat)))
