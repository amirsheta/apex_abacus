"""Map every subprogram of the current IMPR1110 body: section, size, record/context/UI-recorder usage, calls.
Usage: python3 -I work/step02/member_map.py [body.sql]  -> work/step02/member_map.json + summary"""
import re, json, sys, collections
path = sys.argv[1] if len(sys.argv) > 1 else 'plsql/IMPR1110/impr1110_body.sql'
t = open(path, encoding='utf-8').read()
lines = t.split('\n')
sec = None
members = []
cur = None
for i, l in enumerate(lines, 1):
    m = re.match(r'\s{4}-- (?:=+)?\s*$', l)
    s = re.match(r'\s{4}-- ([A-Z][A-Z0-9 /().,_\-]+?)\s*(?:\(|$)', l)
    if s and len(s.group(1)) > 4 and not re.match(r'\s{4}-- (Source|Original|APEX|TODO)', l):
        prev = lines[i - 2] if i > 1 else ''
        if re.match(r'\s{4}-- =+', prev):
            sec = s.group(1).strip()
    d = re.match(r'^    (PROCEDURE|FUNCTION)\s+([A-Za-z0-9_$#]+)', l)
    if d:
        cur = dict(kind=d.group(1), name=d.group(2).upper(), start=i, section=sec)
        members.append(cur)
    e = re.match(r'^    END\s+([A-Za-z0-9_$#]+)\s*;', l)
    if e and cur and e.group(1).upper() == cur['name']:
        cur['end'] = i
names = set(m['name'] for m in members)
for m in members:
    body = '\n'.join(lines[m['start'] - 1:m.get('end', m['start'])])
    code = re.sub(r'--[^\n]*', '', body)
    code = re.sub(r"'(?:[^']|'')*'", "''", code)
    m['lines'] = m.get('end', m['start']) - m['start'] + 1
    m['rec_read'] = sorted(set(f.upper() for f in re.findall(r'\bp_rec\.(\w+)', code, re.I)))
    m['rec_write'] = sorted(set(f.upper() for f in re.findall(r'\bp_rec\.(\w+)\s*:=', code, re.I)))
    m['ctx'] = sorted(set(f.upper() for f in re.findall(r'\bp_ctx\.(\w+)', code, re.I)))
    m['ui_calls'] = len(re.findall(r'(?i)(?<![\w.])(ui|entrable|ui_focus|set_function_enabled)\s*\(', code))
    m['session'] = len(re.findall(r"(?i)\b(v\s*\(\s*'|apex_util\.(get|set)_session_state|ITEM_VALUE\s*\(|SET_ITEM\s*\(|NUMBER_ITEM\s*\(|DATE_ITEM\s*\(|apex_collection)", code))
    m['calls'] = sorted(set(c.upper() for c in re.findall(r'(?<![\w.$#])([A-Za-z][A-Za-z0-9_$#]*)\s*\(', code) if c.upper() in names and c.upper() != m['name']))
    m['params'] = re.sub(r'\s+', ' ', re.search(r'(?is)^\s*(?:PROCEDURE|FUNCTION)\s+\S+\s*(\(.*?\))?\s*(RETURN|IS|AS)\b', body).group(1) or '')[:200]
json.dump(members, open('work/step02/member_map.json', 'w'), indent=0)
by = collections.OrderedDict()
for m in members:
    by.setdefault(m['section'], []).append(m)
for s, ms in by.items():
    print('== %s: %d members, %d lines, ui_calls %d, session %d' % (s, len(ms), sum(x['lines'] for x in ms), sum(x['ui_calls'] for x in ms), sum(x['session'] for x in ms)))
