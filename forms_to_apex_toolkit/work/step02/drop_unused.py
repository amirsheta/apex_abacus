"""
drop_unused.py - remove dead code from the converted IMPR1110 logic (package 012, user request 2026-11-24
"build again package impr1110 and remove unused"). Used by build_package.py.

 - drop_ui_stubs(text): the "NULL;  -- APEX (read_only_rules.md): <Forms UI call>" placeholders become comment
   lines "-- APEX-DA: <Forms UI call>" (CLAUDE.md §6.8: UI-only logic is a comment, not PL/SQL; the read-only
   rules and DAs do that work). An IF whose branches then hold only comments is commented out as a whole
   ("-- APEX-DA: " before every line) when its conditions only read values (no call other than the pure
   built-ins below); a branch left empty while another branch still has code gets "NULL;", and so does a
   BEGIN without a statement.
 - drop_parameter(text, member, parameter): removes one formal parameter from a member header.
"""
import re

STUB = re.compile(r'^(\s*)NULL;\s+-- APEX \(read_only_rules\.md\):\s*(.*)$')
TAG = '-- APEX-DA: '
PURE = {'NVL', 'NVL2', 'UPPER', 'LOWER', 'TRIM', 'LTRIM', 'RTRIM', 'SUBSTR', 'INSTR', 'LENGTH', 'TO_NUMBER',
        'TO_CHAR', 'TO_DATE', 'DECODE', 'COALESCE', 'ABS', 'TRUNC', 'ROUND', 'IN'}


def _code(line):
    return re.sub(r'--.*$', '', re.sub(r"'(?:[^']|'')*'", "''", line)).strip()


def _pure(condition):
    calls = set(c.upper() for c in re.findall(r'([A-Za-z][\w$#.]*)\s*\(', condition))
    return calls <= PURE


def _head_end(lines, i):
    """index of the line holding THEN for an IF / ELSIF starting at line i"""
    j = i
    while not re.search(r'\bTHEN\b', _code(lines[j]), re.I):
        j += 1
    return j


def _collapse_once(lines):
    stack = []                       # [start, [branch: {head, end_of_head, cond, has_code}]]
    i = 0
    while i < len(lines):
        c = _code(lines[i])
        if re.match(r'^IF\b', c, re.I) and not re.search(r'\bEND\s+IF\s*;', c, re.I):
            j = _head_end(lines, i)
            cond = ' '.join(_code(x) for x in lines[i:j + 1])
            if stack: stack[-1][1][-1]['has_code'] = True
            stack.append([i, [dict(head=i, end=j, cond=cond, has_code=False)]])
            i = j + 1
            continue
        if stack and re.match(r'^ELSIF\b', c, re.I):
            j = _head_end(lines, i)
            stack[-1][1].append(dict(head=i, end=j, cond=' '.join(_code(x) for x in lines[i:j + 1]), has_code=False))
            i = j + 1
            continue
        if stack and re.match(r'^ELSE$', c, re.I):
            stack[-1][1].append(dict(head=i, end=i, cond='', has_code=False))
            i += 1
            continue
        if stack and re.match(r'^END\s+IF\s*;$', c, re.I):
            start, branches = stack.pop()
            if not any(b['has_code'] for b in branches) and all(_pure(b['cond']) for b in branches):
                block = [re.sub(r'^(\s*)(?:%s)?' % re.escape(TAG), r'\1' + TAG, l, count=1) for l in lines[start:i + 1]]
                return lines[:start] + block + lines[i + 1:], True
            for b in reversed(branches):
                if not b['has_code']:
                    indent = re.match(r'^(\s*)', lines[b['head']]).group(1) + '    '
                    return lines[:b['end'] + 1] + [indent + 'NULL;'] + lines[b['end'] + 1:], True
            i += 1
            continue
        if stack and c:
            stack[-1][1][-1]['has_code'] = True
        i += 1
    return lines, False


def _empty_begin(lines):
    out = []
    for k, l in enumerate(lines):
        out.append(l)
        if re.match(r'^\s*BEGIN\s*$', l):
            j = k + 1
            while j < len(lines) and not _code(lines[j]):
                j += 1
            if j < len(lines) and re.match(r'^(END\b|EXCEPTION\b)', _code(lines[j]), re.I):
                out.append(re.match(r'^(\s*)', l).group(1) + '    NULL;')
    return out


def drop_ui_stubs(text):
    lines, n = [], 0
    for l in text.split('\n'):
        m = STUB.match(l)
        if m:
            lines.append(m.group(1) + TAG + m.group(2))
            n += 1
        else:
            lines.append(l)
    changed = True
    while changed:
        lines, changed = _collapse_once(lines)
    return '\n'.join(_empty_begin(lines)), n


def drop_parameter(text, member, parameter):
    """remove 'parameter <mode> <type>' from every header of member (forward declaration and body)"""
    pat = re.compile(r'((?:PROCEDURE|FUNCTION)\s+%s\s*\()(.*?)(\)\s*(?:;|\n\s*(?:IS|AS|RETURN)\b))' % re.escape(member), re.S | re.I)
    def fix(m):
        formals = re.split(r',', m.group(2))
        keep = [f for f in formals if not re.match(r'\s*%s\b' % parameter, f, re.I)]
        if len(keep) == len(formals):
            return m.group(0)
        if not keep:                                  # no parameter left: no parentheses
            return m.group(1)[:-1].rstrip() + m.group(3)[1:]
        first = formals[0][:len(formals[0]) - len(formals[0].lstrip())]
        keep[0] = first + keep[0].lstrip()
        return m.group(1) + ','.join(keep) + m.group(3)
    return pat.subn(fix, text)
