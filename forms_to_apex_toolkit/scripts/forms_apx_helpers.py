# -*- coding: utf-8 -*-
"""
forms_apx_helpers.py - the helpers common to every form package live in FORMS_APX (version 004,
user decision 2026-11-24). A form package does not define them; it calls FORMS_APX.<NAME>.

  MOVED                       {name in a form package: FORMS_APX member}
  remove_members(text, names) drop the definitions / declarations (with their comment block) of the names
  qualify(text)               qualify the remaining calls with FORMS_APX. (code only: comments and string
                              literals are left alone; an already qualified name is not touched)
  leftovers(text)             names of MOVED still defined in the text (must be empty)

Form-specific helpers stay in the form package (add_activity, P0_PAGE_PK_CHECK, importer_row_id ...).
"""
import re

# name in a form package -> FORMS_APX member (case-insensitive; the IMPR1110 aliases INFO, GET_GLOBAL ...
# were one-line wrappers of FORMS_APX)
MOVED = {
    'CHECK_ERROR': 'CHECK_ERROR', 'REQUIRED_VALIDATION': 'REQUIRED_VALIDATION',
    'GET_MODULE_ID': 'GET_MODULE_ID', 'HEADER_TITLE': 'HEADER_TITLE',
    'HIJRI_DATE_FORMAT': 'HIJRI_DATE_FORMAT', 'DATE_FORMAT_MESSAGE': 'DATE_FORMAT_MESSAGE',
    'HIJRI_TEXT_TO_DATE': 'HIJRI_TEXT_TO_DATE', 'HIJRI_TEXT': 'HIJRI_TEXT', 'HIJRI_DATE_ERROR': 'HIJRI_DATE_ERROR',
    'CUR_HIJ_DATE': 'CUR_HIJ_DATE', 'ARABIC_MESSAGE': 'ARABIC_MESSAGE',
    'DISPLAY_ARABIC_ERROR': 'DISPLAY_ARABIC_ERROR', 'DISPLAY_ARABIC_INFO': 'DISPLAY_ARABIC_INFO',
    'CG_MESSAGE': 'CG_MESSAGE', 'FORM_TRIGGER_FAILURE': 'FORM_TRIGGER_FAILURE', 'INFO': 'MESSAGE',
    'GET_GLOBAL': 'GET_GLOBAL', 'SET_GLOBAL': 'SET_GLOBAL',
}
NEEDS_PAREN = {'INFO', 'GET_GLOBAL', 'SET_GLOBAL'}     # only calls: these words may appear otherwise

_TOKEN = re.compile(r"--[^\n]*|'(?:[^']|'')*'", re.S)


def _member_re(name):
    # optional comment block right above, the header, and either ';' (declaration) or IS ... END name;
    # (a section banner '-- ====' above it is kept)
    return re.compile(r'(?:\n(?:[ \t]*--(?![ \t]*=)[^\n]*\n)*)?[ \t]*(?:PROCEDURE|FUNCTION)[ \t]+%s\b' % re.escape(name), re.I)


def remove_members(text, names):
    """drop every declaration and definition of the names (top level of a package spec or body)"""
    for name in names:
        while True:
            m = _member_re(name).search(text)
            if not m:
                break
            start = m.start()
            # header ends at ';' (declaration) or at IS / AS (definition)
            hdr = re.compile(r'(;)|\b(IS|AS)\b', re.I).search(text, m.end())
            if hdr.group(1):
                end = hdr.end()
            else:
                e = re.compile(r'\bEND[ \t]+%s[ \t]*;' % re.escape(name), re.I).search(text, hdr.end())
                if not e:
                    raise ValueError('no END %s;' % name)
                end = e.end()
            text = text[:start] + text[end:]
    return re.sub(r'\n{3,}', '\n\n', text)


def _sub_code(code):
    for name, target in MOVED.items():
        tail = r'(?=\s*\()' if name in NEEDS_PAREN else r'(?![\w$#])'
        code = re.sub(r'(?<![\w$#.])' + name + tail, 'FORMS_APX.' + target, code, flags=re.I)
    return code


def qualify(text):
    out, pos = [], 0
    for m in _TOKEN.finditer(text):
        out.append(_sub_code(text[pos:m.start()]))
        out.append(m.group(0))
        pos = m.end()
    out.append(_sub_code(text[pos:]))
    return ''.join(out)


def leftovers(text):
    code = _TOKEN.sub('', text)
    return sorted({n for n in MOVED if re.search(r'\b(?:PROCEDURE|FUNCTION)\s+%s\b' % n, code, re.I)})


FORMS_APX_FILE = 'plsql_templates/forms_apx.sql'


def forms_apx_members(root='.'):
    """{MEMBER: set of parameter names} of the FORMS_APX spec"""
    import os
    t = open(os.path.join(root, FORMS_APX_FILE), encoding='utf-8').read()
    spec = re.sub(r'--[^\n]*', '', t[:t.index('CREATE OR REPLACE PACKAGE BODY')])
    out = {}
    for m in re.finditer(r'\b(?:PROCEDURE|FUNCTION)\s+([A-Za-z0-9_$#]+)\s*(\((.*?)\))?\s*(?:RETURN\s+[\w.%]+\s*)?;', spec, re.S | re.I):
        out[m.group(1).upper()] = {p.upper() for p in re.findall(r'\b([A-Za-z][A-Za-z0-9_$#]*)\s+(?:IN\s+OUT|IN|OUT)\b', m.group(3) or '')}
    return out


def unknown_calls(text, root='.'):
    """FORMS_APX.<NAME> used in the text but not in the FORMS_APX spec (must be empty)"""
    known = forms_apx_members(root)
    code = _TOKEN.sub(lambda m: m.group(0) if m.group(0).startswith("'") else '', text)
    return sorted({n.upper() for n in re.findall(r'\bFORMS_APX\.([A-Za-z0-9_$#]+)', code, re.I)} - set(known))
