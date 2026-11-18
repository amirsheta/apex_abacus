#!/usr/bin/env python3
"""
expand_orig.py - insert the verbatim Forms code above each package member and self-check.

Usage:
    python -I scripts/expand_orig.py <form_fmb.xml> <body.sql> [<more .sql> ...]

For every line "--@ORIG <unit>" in <body.sql> (unit = "PU NAME", "FORM.TRIGGER",
"BLOCK.TRIGGER" or "BLOCK.ITEM.TRIGGER") the decoded TriggerText / ProgramUnitText from the
XML is inserted right after it as a comment block:
    -- >>> Original Forms code: <unit>
    --   <line>
    -- <<<
Blank lines and comment-only lines of the original are left out; /* ... */ blocks are kept
out as well. Re-running replaces the previously inserted block (idempotent). The XML is
only read, never modified.

Checks (printed; exit code 1 if any fails), run on every .sql file given:
  1. every --@ORIG unit exists in the XML
  2. every Arabic string literal in code or comments occurs verbatim in the original code
  3. no Forms built-in outside comments (CLAUDE.md step-02 self-check list);
     FORMS_COMPAT.<name> wrappers are allowed
  4. no identifier longer than 30 bytes
"""
import html
import re
import sys
import xml.etree.ElementTree as ET

NS = {'f': 'http://xmlns.oracle.com/Forms'}
BEGIN = '-- >>> Original Forms code: '
END = '-- <<<'
FORBIDDEN = re.compile(
    r"(?<!FORMS_COMPAT\.)\b(GO_BLOCK|GO_ITEM|SET_ITEM_PROPERTY|SHOW_ALERT|EXECUTE_QUERY|"
    r"FORM_TRIGGER_FAILURE|NAME_IN|SET_BLOCK_PROPERTY|GET_ITEM_PROPERTY|CALL_FORM|OPEN_FORM|"
    r"NEW_FORM|DO_KEY|CLEAR_BLOCK|CLEAR_FORM|COMMIT_FORM|FORMS_DDL)\b"
    r"|:SYSTEM\.|:GLOBAL\.|:PARAMETER\.|(?<!FORMS_COMPAT\.)\bCOPY\(",
    re.I)
ARABIC = re.compile(r'[؀-ۿ]')


def load_units(xml_path):
    fm = ET.parse(xml_path).getroot().find('f:FormModule', NS)
    units = {}

    def put(name, text):
        units[name] = html.unescape(text or '').replace('\r', '')

    for tr in fm.findall('f:Trigger', NS):
        put('FORM.' + tr.get('Name'), tr.get('TriggerText'))
    for b in fm.findall('f:Block', NS):
        for tr in b.findall('f:Trigger', NS):
            put(b.get('Name') + '.' + tr.get('Name'), tr.get('TriggerText'))
        for it in b.findall('f:Item', NS):
            for tr in it.findall('f:Trigger', NS):
                put(b.get('Name') + '.' + it.get('Name') + '.' + tr.get('Name'), tr.get('TriggerText'))
    for p in fm.findall('f:ProgramUnit', NS):
        put('PU ' + p.get('Name'), p.get('ProgramUnitText'))
    return units


def active_lines(text):
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    out = []
    for line in text.split('\n'):
        s = line.rstrip()
        if not s.strip() or s.strip().startswith('--'):
            continue
        out.append(s.replace('\t', '    '))
    return out


def expand(path, units, problems):
    src = open(path, encoding='utf-8').read().split('\n')
    out, skip = [], False
    for line in src:
        if line.strip().startswith(BEGIN.strip()):
            skip = True
            continue
        if skip:
            if line.strip() == END:
                skip = False
            continue
        out.append(line)
        m = re.match(r'^(\s*)--@ORIG (.+?)\s*$', line)
        if m:
            ind, unit = m.group(1), m.group(2)
            if unit not in units:
                problems.append(f'{path}: --@ORIG unit not found in XML: {unit}')
                continue
            out.append(f'{ind}{BEGIN}{unit}')
            out.extend(f'{ind}--   {l}' for l in active_lines(units[unit]))
            out.append(f'{ind}{END}')
    with open(path, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('\n'.join(out))


def check(path, original_code, problems):
    lines = open(path, encoding='utf-8').read().split('\n')
    in_orig = False
    for no, line in enumerate(lines, 1):
        if line.strip().startswith(BEGIN.strip()):
            in_orig = True
            continue
        if in_orig:
            if line.strip() == END:
                in_orig = False
            continue
        code = line.split('--', 1)[0]
        # Arabic literals (code and comments) must exist verbatim in the original form code
        for lit in re.findall(r"'([^']*)'", line):
            if ARABIC.search(lit) and lit not in original_code:
                problems.append(f'{path}:{no}: Arabic text not found verbatim in the form: {lit!r}')
        if FORBIDDEN.search(code):
            problems.append(f'{path}:{no}: Forms built-in outside a comment: {code.strip()}')
        for ident in re.findall(r'\b[A-Za-z_][A-Za-z0-9_$#]*\b', re.sub(r"'[^']*'", "''", code)):
            if len(ident.encode()) > 30:
                problems.append(f'{path}:{no}: identifier longer than 30 bytes: {ident}')


def main():
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')   # Arabic text on any console
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    units = load_units(sys.argv[1])
    original_code = '\n'.join(units.values())
    problems = []
    for path in sys.argv[2:]:
        expand(path, units, problems)
        check(path, original_code, problems)
    for p in problems:
        print('PROBLEM', p)
    print(f'{len(problems)} problem(s)')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
