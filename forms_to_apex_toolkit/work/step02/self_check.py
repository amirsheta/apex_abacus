"""Structural self-check of plsql/IMPR1110/impr1110_spec.sql + _body.sql (step 02 rev 2, prompt 02 self-checks).
Usage: python3 -I work/step02/self_check.py   -> prints findings, writes work/step02/self_check.json"""
import re, json, collections

spec = open('plsql/IMPR1110/impr1110_spec.sql', encoding='utf-8').read()
body = open('plsql/IMPR1110/impr1110_body.sql', encoding='utf-8').read()
old = open('rollback/IMPR1110/step02_rev1/impr1110_body.sql', encoding='utf-8').read()

def code_only(t):
    t = re.sub(r'--[^\n]*', '', t)
    return re.sub(r"'(?:[^']|'')*'", "''", t)

def members(t):
    out = []
    lines = t.split('\n')
    cur = None
    for i, l in enumerate(lines):
        d = re.match(r'^    (PROCEDURE|FUNCTION)\s+([A-Za-z0-9_$#]+)', l)
        if d and cur is None:
            cur = dict(kind=d.group(1), name=d.group(2).upper(), start=i)
            # a declaration (spec or forward) ends with ';' before any IS / AS
            hdr = []
            for j in range(i, min(i + 60, len(lines))):
                hdr.append(lines[j])
                s = code_only(' '.join(hdr))
                if re.search(r'\)\s*(RETURN\s+\w+(\.\w+%TYPE)?)?\s*;|^\s*(PROCEDURE|FUNCTION)\s+\w+\s*(RETURN\s+\w+)?\s*;', s.strip()):
                    cur['decl_only'] = True; break
                if re.search(r'\b(IS|AS)\s*$', s.strip()) or re.search(r'\b(IS|AS)\b', s.split(')')[-1]):
                    cur['decl_only'] = False; break
            if cur.get('decl_only'):
                cur['end'] = j
                cur['text'] = '\n'.join(lines[i:j + 1])
                out.append(cur); cur = None
            continue
        if cur is not None:
            e = re.match(r'^    END\s+([A-Za-z0-9_$#]+)\s*;', l)
            if e and e.group(1).upper() == cur['name']:
                cur['end'] = i
                cur['text'] = '\n'.join(lines[cur['start']:i + 1])
                out.append(cur); cur = None
    return out

def signature(m):
    hdr = code_only(m['text'])
    h = re.match(r'(?is)\s*(PROCEDURE|FUNCTION)\s+[\w$#]+\s*', hdr)
    rest = hdr[h.end():]
    params = ''
    if rest.startswith('('):
        depth = 0
        for i, ch in enumerate(rest):
            depth += ch == '('
            depth -= ch == ')'
            if depth == 0:
                params = rest[1:i]; break
    parts, depth, cur = [], 0, ''
    for ch in params:
        if ch == ',' and depth == 0:
            parts.append(cur); cur = ''
            continue
        depth += ch == '('; depth -= ch == ')'; cur += ch
    parts.append(cur)
    names = tuple(p.strip().split()[0].upper() for p in parts if p.strip())
    return (m['name'], names)

findings = collections.OrderedDict()
def add(k, v): findings.setdefault(k, []).append(v)

sm = members(spec)
bm = members(body)
impl = [m for m in bm if not m.get('decl_only')]
fwd = [m for m in bm if m.get('decl_only')]
impl_sigs = collections.Counter(signature(m) for m in impl)

# 1 every spec / forward declaration has exactly one implementation with the same parameter names
for m in sm + fwd:
    if impl_sigs[signature(m)] != 1:
        add('declaration without matching body', signature(m))
# 2 every private implementation is declared (spec or forward) or defined before its first use
declared = set(signature(m) for m in sm + fwd)
for m in impl:
    if signature(m) not in declared and m['name'] != 'PKG_VERSION':
        first_use = re.search(r'(?<![\w.$#])%s\s*[(;]' % re.escape(m['name']), code_only('\n'.join(body.split('\n')[:m['start']])), re.I)
        if first_use and m['name'] not in ('YES_NO',):
            add('private member used before its body without forward declaration', m['name'])
# 3 duplicated implementations (same name + same parameter names)
for s, n in impl_sigs.items():
    if n > 1: add('duplicate implementation', s)
# 4 code that must be gone
c = code_only(body) + code_only(spec)
gone = ['UI_RESET', 'UI', 'ENTRABLE', 'UI_FOCUS', 'UI_JSON', 'UI_COUNT', 'UI_ENTRY', 'ITEM_VALUE', 'SET_ITEM',
        'NUMBER_ITEM', 'DATE_ITEM', 'GET_RECORD', 'SET_RECORD', 'GET_CONTEXT', 'SET_CONTEXT', 'STATE_PUT', 'STATE_GET',
        'STATE_RESET', 'SAVE_UI', 'KEEP_UI', 'REPLY', 'RUN_VALIDATE', 'PAGE_DML', 'PAGE_FETCH', 'LOAD_ROW',
        'IMPORTERS_INSERT', 'IMPORTERS_UPDATE', 'IMPORTERS_PRE_QUERY', 'TYPE_ENTRABLE_QUERY', 'LOCK_KEY_ITEMS',
        'CR_FIELDS_ENTRABLE', 'APPLICATION_ITEM', 'ANSWER']
for g in gone:
    for x in re.finditer(r'(?<![\w.$#])%s\s*[(;]' % g, c, re.I):
        add('removed member still called', g)
for pat, why in [(r"\bv\s*\(\s*''", "v('...') session state"), (r'apex_util\.(get|set)_session_state', 'session state API'),
                 (r'apex_collection\.', 'APEX collection'), (r'apex_application\.g_x\d', 'AJAX x01..x10'),
                 (r'\bg_ui_\w+|\bg_focus\b|\bg_msgs\b', 'UI recorder variable'),
                 (r'\bc_(state_coll|req_items|dyn_req_items|val_items|mobile_page|post_chg_on_fetch|version)\b', 'adapter constant'),
                 (r':\s*(GLOBAL|PARAMETER|SYSTEM)\.', 'Forms bind'),
                 (r'(?<![\w.])(GO_ITEM|GO_BLOCK|SET_ITEM_PROPERTY|GET_ITEM_PROPERTY|SHOW_ALERT|NAME_IN|DO_KEY|EXECUTE_QUERY|'
                  r'COMMIT_FORM|CLEAR_BLOCK|CALL_FORM|SYNCHRONIZE|FORMS_DDL)\s*\(', 'Forms built-in'),
                 (r'(?<![\w.])COMMIT\s*;', 'COMMIT (APEX commits)')]:
    for x in re.finditer(pat, c, re.I):
        add(why, x.group(0))
# 5 identifiers longer than 30 bytes
for w in set(re.findall(r'[A-Za-z][A-Za-z0-9_$#]*', c)):
    if len(w.encode()) > 30: add('identifier > 30 bytes', w)
# 6 parameter naming (scripts/parameter_names.py, version 008): no I_ / IO_ / O_ prefix, page items as P_<ITEM>
for m in sm:
    for p in signature(m)[1]:
        if re.match(r'(I|IO|O)_', p): add('spec parameter with I_/IO_/O_ prefix', (m['name'], p))
        if re.match(r'P\d+_', p): add('spec parameter named after a page item (use P_<ITEM>)', (m['name'], p))
# 7 member size (one trigger = one member, about 80 lines; generated entries counted without the
#   parameter copy lines)
sizes = []
for m in impl:
    n = m['end'] - m['start'] + 1
    copy = len(re.findall(r'(?m)^\s+(r|c)\.\w+ := [A-Z][A-Z0-9_$#]*;$|^\s+[A-Z][A-Z0-9_$#]* := (r|c)\.\w+;$', m['text']))
    if n - copy > 80: sizes.append((m['name'], n, n - copy))
# 8 balance per member
for m in impl:
    t = code_only(m['text'])
    if t.count('(') != t.count(')'): add('unbalanced parentheses', m['name'])
    ifs = len(re.findall(r'(?<![\w])IF\b', t, re.I)) - 2 * len(re.findall(r'\bEND\s+IF\b', t, re.I))
    if ifs != 0: add('IF / END IF count differs', (m['name'], ifs))
    cases = len(re.findall(r'\bCASE\b', t, re.I)) - 2 * len(re.findall(r'\bEND\s+CASE\b', t, re.I)) - len(re.findall(r'\bEND\b(?!\s+(IF|LOOP|CASE|\w+\s*;))', t, re.I))
    loops = len(re.findall(r'\bLOOP\b', t, re.I)) - 2 * len(re.findall(r'\bEND\s+LOOP\b', t, re.I))
    if loops != 0: add('LOOP / END LOOP count differs', (m['name'], loops))
# 9 package frame
for k, pat, t in [('spec owner', r'CREATE OR REPLACE PACKAGE LIB_APX_USR\.IMPR1110 AS', spec),
                  ('body owner', r'CREATE OR REPLACE PACKAGE BODY LIB_APX_USR\.IMPR1110', body),
                  ('synonym', r'CREATE OR REPLACE PUBLIC SYNONYM IMPR1110 FOR LIB_APX_USR\.IMPR1110;', spec),
                  ('grant LIB_USR', r'GRANT EXECUTE ON LIB_APX_USR\.IMPR1110 TO LIB_USR;', spec),
                  ('grant SECURITY_DEFAULT', r'TO SECURITY_DEFAULT;', spec), ('grant SECURITY_PROD', r'TO SECURITY_PROD;', spec),
                  ('grant CUSTOMS', r'TO CUSTOMS;', spec), ('version 011', r"'VERSION NO\. IS:' \|\| '011'", spec),
                  ('PKG_VERSION body', r'FUNCTION PKG_VERSION\s+RETURN VARCHAR2\s+IS\s+BEGIN\s+RETURN V_INFO;', body)]:
    if not re.search(pat, t): add('package frame missing', k)

result = dict(spec_members=len(sm), body_implementations=len(impl), forward_declarations=len(fwd),
              findings=findings, members_over_80_lines=sizes)
json.dump(result, open('work/step02/self_check.json', 'w', encoding='utf-8'), indent=1, ensure_ascii=False, default=str)
print('spec %d, body %d, forward %d' % (len(sm), len(impl), len(fwd)))
for k, v in findings.items():
    print('!! %s (%d): %s' % (k, len(v), sorted(set(map(str, v)))[:12]))
print('members over 80 lines (net of parameter copies): %d' % len(sizes))
for s in sizes: print('   ', s)
