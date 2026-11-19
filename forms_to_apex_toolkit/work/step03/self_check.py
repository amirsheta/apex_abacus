"""Self-check of the step-03 design (work/step03/page_design.json) against the package spec.
Usage: python3 -I work/step03/self_check.py"""
import re, json, collections
d = json.load(open('work/step03/page_design.json', encoding='utf-8'))
spec = re.sub(r'--[^\n]*', '', open('plsql/IMPR1110/impr1110_spec.sql', encoding='utf-8').read())
public = set(m.upper() for m in re.findall(r'(?m)^    (?:PROCEDURE|FUNCTION)\s+(\w+)', spec))
items = set(i['name'] for i in d['items'])
app_items = {'P_CURR_PORT_CD', 'SSO_APP_USER', 'P_GLOBAL_V_WS_ID', 'P_CLASS_CD', 'V_USR_TYPE', 'P_BRKR_PORT_CD',
             'P_LIC_TYPE', 'P_BRKR_NBR', 'P_PRSNL_IMPR', 'P_LETTER_NBR', 'P0_PAGE_PK', 'G_LAST_PAGE', 'APP_USER',
             'REQUEST', 'P_PORT_TYPE'}
p111002 = {'P111002_IMPR_NBR', 'P111002_MOBILE_NO', 'P111002_CENTRAL_MOBILE'}
known = items | app_items | p111002
F = collections.OrderedDict()
def add(k, v): F.setdefault(k, []).append(v)
codes = [('process ' + p['name'], p['code']) for p in d['processes']] + \
        [('validation ' + v['name'], v['code'] + ' ' + v.get('condition', '')) for v in d['validations']] + \
        [('computation ' + c['item'], c['expression'] + ' ' + c['condition']) for c in d['computations']] + \
        [('DA %s #%d' % (x['name'], n), a['code']) for x in d['das'] for n, a in enumerate(x['actions'], 1)] + \
        [('item ' + i['name'], i['read_only'] + ' ' + i['condition']) for i in d['items']]
used = set()
for where, code in codes:
    for b in re.findall(r'(?<![\w$])[:]([A-Z][A-Z0-9_$#]*)', code):
        if b not in known: add('bind without item', (where, b))
        if len(b.encode()) > 30: add('bind > 30 bytes', b)
    for m in re.findall(r'IMPR1110\.(\w+)', code):
        used.add(m.upper())
        if m.upper() not in public: add('member not in package spec', (where, m))
    for p, b in re.findall(r'(\w+) => :(\w+)', code):
        if p in ('I_VALUE', 'p_values'): continue          # generic parameters (REQUIRED_VALIDATION, APEX_PAGE.GET_URL)
        if re.sub(r'^(IO|I|O)_', '', p) != b and not b.endswith('_LOCKED') and b not in ('P1110_FUNCTION_CODE',):
            add('parameter / bind name differ', (where, p, b))
for x in d['das']:
    for a in x['actions']:
        for i in a['submit'] + a['ret']:
            if i not in known: add('FOS item missing', (x['name'], i))
        if a['action'] == 'Execute JavaScript Code' and len(a['code'].split('\n')) > 3:
            add('JavaScript > 3 lines', x['name'])
# <ITEM>_IS_READ_ONLY of the flag groups are called by READ_ONLY_FLAGS; MOBILE_OK / MOBILE_CANCEL by page 111002
body = open('plsql/IMPR1110/impr1110_body.sql', encoding='utf-8').read()
flags_body = body[body.index('PROCEDURE READ_ONLY_FLAGS'):]
flags_body = flags_body[:flags_body.index('END READ_ONLY_FLAGS')]
not_used = sorted(m for m in public - used - {'PKG_VERSION', 'CHECK_ERROR', 'WHEN_CLEAR_BLOCK', 'MOBILE_OK', 'MOBILE_CANCEL'}
                  if not (m.endswith('_IS_READ_ONLY') and (m + '(') in flags_body))
if not_used: add('public member not used by any component', not_used)
names = [p['name'] for p in d['processes']] + [v['name'] for v in d['validations']] + [x['name'] for x in d['das']]
for n, c in (collections.Counter(p['point'] + '|' + p['name'] for p in d['processes']) + collections.Counter(v['name'] for v in d['validations'])
             + collections.Counter(x['name'] for x in d['das'])).items():
    if c > 1: add('duplicate component name', n)
for n in names:
    if '.' in n or n.lower().startswith('pkg_'): add('component name with dot / pkg_', n)
for i in items:
    if len(i.encode()) > 30: add('item name > 30 bytes', i)
js = sum(1 for x in d['das'] for a in x['actions'] if a['action'] == 'Execute JavaScript Code')
print('items %d, validations %d, processes %d, computations %d, DAs %d, JS actions %d' % (
    len(items), len(d['validations']), len(d['processes']), len(d['computations']), len(d['das']), js))
for k, v in F.items():
    print('!! %s (%d): %s' % (k, len(v), v[:8]))
if not F: print('no findings')
