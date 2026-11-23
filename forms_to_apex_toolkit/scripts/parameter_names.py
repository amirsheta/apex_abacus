# -*- coding: utf-8 -*-
"""
parameter_names.py - the parameter naming rule of the form packages (CLAUDE.md §4, user decision 2026-11-23).

Rule
  * no mode prefix: the mode is written as IN / IN OUT / OUT, so I_ / IO_ / O_ are not used;
  * a parameter that carries a page item P<page>_<X> is named P_<X>
      P1120_PORT_CD -> P_PORT_CD, P0_PAGE_PK -> P_PAGE_PK,
      P1120_P_CURRENT_SIDE (page item of the Forms parameter CURRENT_SIDE) -> P_CURRENT_SIDE (no doubled P_P_);
  * when one member receives both the page item P<page>_P_X and the application item P_X, the
    application-item parameter is named APP_P_X (IMPR1110.PARAMETERS_ENTRY: APP_P_PRSNL_IMPR => :P_PRSNL_IMPR);
  * application items and IG columns keep their name (P_CURR_PORT_CD, SSO_APP_USER, PORT_CD);
  * names that would be SQL keywords get a full word (ERR -> ERROR_TEXT, VALUE -> ITEM_VALUE, LABEL -> ITEM_LABEL);
  * inside every SQL statement a parameter is qualified with its member name (IMPR_SUSPN_ON_DELETE.PORT_CD),
    because an unqualified name that matches a column resolves to the column.
Internal members keep p_<name>.

Functions
  new_name(old)                         old parameter name -> new name
  The bind of a parameter cannot be derived from the new name alone (P_CODE may carry P1110_P_CODE), so a
  generator derives binds from the original names: binds_by_member() gives {member: {new name: original}}.
  mapping_from_spec(spec_text)          {old: new} for every parameter of a package spec (raises on a clash)
  rename_package(text, mapping)         rename parameters in package source (code; formals in comments)
  rename_formals(text, mapping)         rename named-notation formals in callers / docs
  qualify_sql(spec_text, body_text)     qualify parameters inside SQL statements of the public members
  unqualified_in_sql(spec, body)        list of (member, parameter, line) still unqualified (must be empty)
  private_functions_in_sql(spec, body)  list of (member, function, line): a function declared only in the body and
                                        called inside a SQL statement (ORA-00904 / PLS-00231; must be empty)
"""
import re

SPECIAL = {'ERR': 'ERROR_TEXT', 'VALUE': 'ITEM_VALUE', 'LABEL': 'ITEM_LABEL'}
MODE_PREFIX = re.compile(r'^(IO|I|O)_')
PAGE_ITEM = re.compile(r'^P(\d+)_(.+)$')
PARAM_DECL = re.compile(r'\b([A-Za-z][A-Za-z0-9_$#]*)\s+(?:IN\s+OUT|IN|OUT)\b(?!\s*\()')
SQL_START = re.compile(r'\b(SELECT|INSERT|UPDATE|DELETE|MERGE)\b', re.I)


def new_name(old):
    x = MODE_PREFIX.sub('', old)
    if x in SPECIAL:
        return SPECIAL[x]
    m = PAGE_ITEM.match(x)
    if m:
        rest = m.group(2)
        return rest if rest.startswith('P_') else 'P_' + rest
    return x


def _is_page_item(old):
    return bool(PAGE_ITEM.match(MODE_PREFIX.sub('', old)))


def member_names(params):
    """{old: new} for the parameters of one member, with the APP_ rule for a clash"""
    out = {p: new_name(p) for p in params}
    page_names = {out[p] for p in params if _is_page_item(p)}
    for p in params:
        if not _is_page_item(p) and out[p] in page_names:
            out[p] = 'APP_' + out[p]
    return out


def binds_by_member(old_spec_text):
    """{member: {new name: original name}} from a spec that still has the original names"""
    return {mem: {v: k for k, v in member_names(ps).items()} for mem, ps in members(old_spec_text)}


def _strip_comments(t):
    return re.sub(r'--[^\n]*', '', t)


def members(spec_text):
    """[(member, [parameter names])] of the public members, in spec order"""
    out = []
    for m in re.finditer(r'\b(?:PROCEDURE|FUNCTION)\s+([A-Z0-9_$#]+)\s*(\((.*?)\))?\s*(?:RETURN\s+[\w.%]+\s*)?;',
                         _strip_comments(spec_text), re.S | re.I):
        out.append((m.group(1).upper(), [p for p in PARAM_DECL.findall(m.group(3) or '')]))
    return out


def mapping_from_spec(spec_text):
    mp, problems = {}, []
    for mem, params in members(spec_text):
        seen = {}
        names = member_names(params)
        for p in params:
            n = names[p]
            if len(n.encode()) > 30:
                problems.append('%s: %s is longer than 30 bytes' % (mem, n))
            if n in seen and seen[n] != p:
                problems.append('%s: %s and %s both become %s' % (mem, seen[n], p, n))
            seen[n] = p
            if p != n:
                if mp.get(p, n) != n:
                    problems.append('%s maps to %s and %s' % (p, mp[p], n))
                mp[p] = n
    if problems:
        raise ValueError('; '.join(problems))
    return mp


_STRING = re.compile(r"'(?:[^']|'')*'")


def _sub_names(text, mapping, formal_only):
    for o in sorted(mapping, key=len, reverse=True):
        tail = r'(?=\s*=>)' if formal_only else r'(?![\w$#])'
        text = re.sub(r'(?<![\w$#:])' + re.escape(o) + tail, mapping[o], text)
    return text


def rename_formals(text, mapping):
    """callers, docs, generators: rename only named-notation formals (OLD => ...); binds :X stay"""
    return _sub_names(text, mapping, True)


def rename_package(text, mapping):
    """package source: rename every parameter in code outside string literals; in -- comments only the
    named-notation formals (comments also name page items, which keep their names)"""
    out = []
    for line in text.split('\n'):
        parts, pos, code = [], 0, line
        # split off the comment (a -- outside string literals)
        cut = None
        for m in re.finditer(r"'(?:[^']|'')*'|--", line):
            if m.group(0) == '--':
                cut = m.start()
                break
        code, comment = (line, '') if cut is None else (line[:cut], line[cut:])
        pieces, last = [], 0
        for m in _STRING.finditer(code):
            pieces.append(_sub_names(code[last:m.start()], mapping, False))
            pieces.append(m.group(0))
            last = m.end()
        pieces.append(_sub_names(code[last:], mapping, False))
        out.append(''.join(pieces) + _sub_names(comment, mapping, True))
    return '\n'.join(out)


def _member_segments(body_text):
    """(start, end, member, segment) of every top-level member of the package body"""
    for m in re.finditer(r'\n    (PROCEDURE|FUNCTION)\s+([A-Za-z0-9_$#]+)\b(.*?)\n    END\s+\2\s*;', body_text, re.S | re.I):
        yield m.start(), m.end(), m.group(2).upper(), m.group(0)


def _sql_lines(segment):
    """indexes of the code lines of the segment that belong to a SQL statement (after the IS / AS)"""
    lines = segment.split('\n')
    start = next((i for i, l in enumerate(lines) if re.match(r'\s*(IS|AS)\s*$', l, re.I)), 0) + 1
    inside, idx = False, []
    for i in range(start, len(lines)):
        code = lines[i].split('--')[0]
        if not code.strip():
            continue
        if not inside and SQL_START.search(_STRING.sub("''", code)):     # a word inside '...' starts nothing
            inside = True
        if inside:
            idx.append(i)
            if code.rstrip().endswith(';') or re.search(r'\bLOOP\s*$', code, re.I):
                inside = False
    return lines, idx


def _public_params(spec_text):
    # lower-case p_<name> parameters follow the internal convention and never match a column: not qualified
    return {m: [x for x in ps if not x.startswith('p_')] for m, ps in members(spec_text)}


def qualify_sql(spec_text, body_text):
    params = _public_params(spec_text)
    out, pos, count = [], 0, 0
    for s, e, mem, seg in _member_segments(body_text):
        ps = sorted(params.get(mem, []), key=len, reverse=True)
        if ps:
            lines, idx = _sql_lines(seg)
            for i in idx:
                code, sep, comment = lines[i].partition('--')
                for p in ps:
                    code, k = re.subn(r'(?<![\w$#.:])' + re.escape(p) + r'(?![\w$#])(?!\s*=>)', mem + '.' + p, code)
                    count += k
                lines[i] = code + sep + comment
            seg = '\n'.join(lines)
        out.append(body_text[pos:s]); out.append(seg); pos = e
    out.append(body_text[pos:])
    return ''.join(out), count


def unqualified_in_sql(spec_text, body_text):
    params = _public_params(spec_text)
    miss = []
    for s, e, mem, seg in _member_segments(body_text):
        lines, idx = _sql_lines(seg)
        for i in idx:
            code = lines[i].split('--')[0]
            for p in params.get(mem, []):
                if re.search(r'(?<![\w$#.:])' + re.escape(p) + r'(?![\w$#])(?!\s*=>)', code):
                    miss.append((mem, p, lines[i].strip()))
    return miss


def private_functions_in_sql(spec_text, body_text):
    """functions declared only in the body may not be called inside SQL statements (ORA-00904 / PLS-00231)"""
    public = {m for m, _ in members(spec_text)}
    private = {f.upper() for f in re.findall(r'(?im)^\s+FUNCTION\s+([A-Za-z0-9_$#]+)', body_text)} - public
    hits = []
    for s, e, mem, seg in _member_segments(body_text):
        lines, idx = _sql_lines(seg)
        for i in idx:
            code = _STRING.sub("''", lines[i].split('--')[0])
            for f in private:
                if re.search(r'(?<![\w$#.])' + re.escape(f) + r'\s*\(', code, re.I):
                    hits.append((mem, f, lines[i].strip()))
    return hits
