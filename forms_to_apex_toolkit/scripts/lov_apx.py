# -*- coding: utf-8 -*-
"""
lov_apx.py - shared LOVs of the project (user decision 2026-11-24, CLAUDE.md §4d):
every SQL shared LOV has the type "PL/SQL Function Body returning SQL Query" and only calls one function of the
common package LOV_APX (plsql_templates/lov_apx.sql, owner LIB_APX_USR), common to all systems:

    return LOV_APX.CITIES(P_COUNTRY_ITEM => 'P1110_ADD_CTRY_CD');

  call(function, **items)   the PL/SQL call text (string values quoted, True / False as BOOLEAN)
  lov_attributes(call_text) create_list_of_values parameters after p_id / p_lov_name
  check(text)               problems of one export file (called by every generator): each SQL LOV uses
                            FUNC_BODY_RETURNING_SQL + R / D and calls a function that exists in lov_apx.sql with
                            parameter names of that function.
Static LOVs (values from the XML) stay STATIC.
"""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACKAGE_FILE = os.path.join(ROOT, 'plsql_templates', 'lov_apx.sql')
SOURCE_TYPE = 'FUNC_BODY_RETURNING_SQL'
UNCERTAIN = ("shared LOV p_source_type 'FUNC_BODY_RETURNING_SQL' with the function body in p_lov_query "
             "(no function-body LOV in f345 or the real 21.2 export f202604; p_function_body_language left out = PL/SQL)")


def call(function, **items):
    def value(v):
        if v is True: return 'TRUE'
        if v is False: return 'FALSE'
        return "'%s'" % str(v).replace("'", "''")
    args = ', '.join('%s => %s' % (k, value(v)) for k, v in items.items())
    return 'LOV_APX.%s%s' % (function, '(%s)' % args if args else '')


def body(call_text):
    return 'return %s;' % call_text


def lov_attributes(call_text, q):
    """(name, value) pairs of create_list_of_values for a LOV_APX function body; q quotes a PL/SQL literal"""
    return [('p_lov_query', q(body(call_text))), ('p_source_type', q(SOURCE_TYPE)), ('p_location', q('LOCAL')),
            ('p_return_column_name', q('R')), ('p_display_column_name', q('D'))]


def column_definitions(cols):
    """create_list_of_values_cols rows (column, heading, data type, visible) for the list columns cols.
    APEX fetches only the defined columns for a Popup LOV: as in the real 21.2 export (f202604, every LOV with
    column definitions defines its return and display columns), D (code, visible) and R (return, hidden) are
    always defined. A LOV without list columns (Select List) gets none."""
    if not cols:
        return []
    rows = [(c, h, dt, True) for c, h, dt in cols]
    if 'D' not in [c for c, _, _ in cols]:
        raise SystemExit('LOV columns must start with the display column D: %s' % cols)
    d = [r for r in rows if r[0] == 'D'][0]
    return rows + [('R', d[1], d[2], False)]


def column_attributes(visible):
    return [] if visible else [('p_is_visible', "'N'")]


def package_functions():
    """{FUNCTION: [PARAMETER, ...]} from the package spec"""
    spec = open(PACKAGE_FILE, encoding='utf-8').read().split('CREATE OR REPLACE PACKAGE BODY')[0]
    spec = re.sub(r'--[^\n]*', '', spec)
    out = {}
    for name, formals in re.findall(r'FUNCTION\s+(\w+)\s*(?:\((.*?)\))?\s*RETURN', spec, re.S):
        out[name.upper()] = [f.split()[0].upper() for f in formals.split(',') if f.strip()]
    return out


def check(text):
    problems = []
    functions = package_functions()
    lov_columns = dict(re.findall(r"p_lov_name=>'(\w+)'(.*?)\nend;", text, re.S))
    for block in re.findall(r'wwv_flow_api\.create_list_of_values\((.*?)\n\);', text, re.S):
        name = re.search(r"p_lov_name=>'(\w+)'", block).group(1)
        if "p_location=>'STATIC'" in block:
            continue
        if "p_source_type=>'%s'" % SOURCE_TYPE not in block:
            problems.append('LOV %s: not a LOV_APX function body (p_source_type %s)' % (name, SOURCE_TYPE))
            continue
        m = re.search(r"p_lov_query=>'return LOV_APX\.(\w+)(?:\((.*?)\))?;'", block)
        if not m:
            problems.append('LOV %s: p_lov_query is not "return LOV_APX.<FUNCTION>(...);"' % name)
            continue
        function, args = m.group(1).upper(), m.group(2) or ''
        if function not in functions:
            problems.append('LOV %s: LOV_APX.%s is not in plsql_templates/lov_apx.sql' % (name, function))
            continue
        for parameter in re.findall(r'(\w+)\s*=>', args):
            if parameter.upper() not in functions[function]:
                problems.append('LOV %s: LOV_APX.%s has no parameter %s' % (name, function, parameter))
        cols = re.findall(r"p_query_column_name=>'(\w+)'", lov_columns.get(name, ''))
        if cols and not {'D', 'R'} <= set(cols):
            problems.append('LOV %s: column definitions without D and R (Popup LOV shows no rows), has %s' % (name, cols))
        for k in ("p_return_column_name=>'R'", "p_display_column_name=>'D'"):
            if k not in block:
                problems.append('LOV %s: without %s' % (name, k))
    return problems
