# -*- coding: utf-8 -*-
"""
build_full_app.py - one FULL application export = the f345 reference application + the
converted forms' component exports, under a new application id.

    python3 -I scripts/build_full_app.py --app-id=202530 [--alias=IMPR-202530] \
        apex/IMPR1110/f345_impr1110.sql [more component exports ...]

Writes apex/f<app-id>_full.sql (REVIEW BEFORE IMPORT).

How it works: the component blocks (everything between component_begin and end_environment)
are inserted into f345.sql just before its deployment section. Both use wwv_flow_api.id(<n>)
with f345 numbering, so whatever ID offset APEX applies at import time applies to both alike.
The component files may still contain their __PLACEHOLDERS__: only their body is used.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
import number_only      # page 0 DA "NUMBER ONLY" (user decision 2026-11-24)
import functions_drawer # page 0 region FUNCS: the functions side drawer of every page (user request 2026-11-24)
import report_toolbar   # page 0 buttons on report pages: PRINT, CLEAR, BACK only (user request 2026-11-25)
REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')

def main(argv):
    opts = dict(a.lstrip('-').split('=', 1) for a in argv if a.startswith('--'))
    comps = [a for a in argv if not a.startswith('--')]
    app_id = opts.get('app-id', '')
    if not re.fullmatch(r'\d+', app_id) or not comps:
        sys.exit(__doc__)
    alias = opts.get('alias', 'MOAYEEN-REACT-%s' % app_id)
    ref = open(REF, encoding='utf-8', errors='strict').read()

    # ---- f345 header -> new application id / alias (the alias must be unique in the workspace)
    n = 0
    for old, new in [(',p_default_application_id=>345\n', ',p_default_application_id=>%s\n' % app_id),
                     ('prompt APPLICATION 345 - ', 'prompt APPLICATION %s - ' % app_id),
                     ('--   Application:     345\n', '--   Application:     %s\n' % app_id),
                     ("get_application_alias,'MOAYEEN-REACT123202604345')",
                      "get_application_alias,'%s')" % alias)]:
        if ref.count(old) != 1:
            sys.exit('f345.sql: expected exactly one %r' % old)
        ref = ref.replace(old, new)
        n += 1

    # ---- page 0 (global page): add the DA "NUMBER ONLY" for the CSS class number_only. The component exports
    # cannot change page 0, so it is added here; apex/Reference/f345.sql itself stays unchanged.
    p0 = ref.index('prompt --application/pages/page_00000\n')
    p0_end = ref.index('\nend;\n/\nprompt --', p0)
    if "p_name=>'NUMBER ONLY'" in ref[p0:p0_end]:
        sys.exit('f345.sql page 0 already has a NUMBER ONLY dynamic action')
    if re.search(r'wwv_flow_api\.id\((%s|%s)\)' % (number_only.PAGE0_EVENT_ID, number_only.PAGE0_ACTION_ID), ref):
        sys.exit('page 0 NUMBER ONLY ids already used in f345.sql')
    ref = ref[:p0_end] + '\n' + number_only.page0_dynamic_action() + ref[p0_end:]
    # page 0 region FUNCS (functions side drawer, scripts/functions_drawer.py): f345 has the FUNCS button but no
    # region; the form pages no longer carry their own. It lists the f345 list Page Functions as it is (the copied
    # list with an icon per function was removed 2026-11-24: it failed at import).
    p0_end = ref.index('\nend;\n/\nprompt --', p0)
    if "p_region_name=>'FUNCS'" in ref[p0:p0_end] or 'wwv_flow_api.id(%s)' % functions_drawer.PAGE0_REGION_ID in ref:
        sys.exit('f345.sql page 0 already has a FUNCS region / its id is used')
    ref = ref[:p0_end] + '\n' + functions_drawer.page0_region() + '\n' + functions_drawer.page0_dynamic_action() + ref[p0_end:]
    # page 0 toolbar on report pages (P<page>_REPORT): PRINT, CLEAR, BACK only (user request 2026-11-25, DEC-018,
    # scripts/report_toolbar.py): CREATE / SEARCH not on report pages, REPORT_SHOW Never
    ref = report_toolbar.patch_page0(ref)
    if report_toolbar.check(ref):
        sys.exit('; '.join(report_toolbar.check(ref)))

    # ---- component bodies
    bodies, pages = [], []
    for c in comps:
        t = open(os.path.join(ROOT, c) if not os.path.isabs(c) else c, encoding='utf-8').read()
        m = re.search(r'wwv_flow_api\.component_begin \(.*?\n\);\nend;\n/\n(.*)\nprompt --application/end_environment',
                      t, re.S)
        if not m:
            sys.exit('%s: no component_begin ... end_environment section' % c)
        body = m.group(1)
        if functions_drawer.check_form_page(body):
            sys.exit('%s: %s' % (c, functions_drawer.check_form_page(body)[0]))
        if re.search(r'component_(begin|end)|import_(begin|end)', body):
            sys.exit('%s: nested begin/end calls' % c)
        bodies.append('-- ' + '=' * 77 + '\n-- merged from %s\n-- ' % c + '=' * 77 + '\n' + body)
        pages += re.findall(r'^prompt --application/pages/page_(\d+)', body, re.M)

    # ---- no page may exist twice
    ref_pages = re.findall(r'^prompt --application/pages/page_(\d+)', ref, re.M)
    dup = set(int(p) for p in pages) & set(int(p) for p in ref_pages)
    if dup:
        sys.exit('pages already in f345: %s' % sorted(dup))
    # merged ids must not collide with f345 ids
    ref_ids = set(re.findall(r'(?:^|[ ,])p_id=>wwv_flow_api\.id\((\d+)\)', ref, re.M))
    new_ids = re.findall(r'(?:^|[ ,])p_id=>wwv_flow_api\.id\((\d+)\)', '\n'.join(bodies), re.M)
    if set(new_ids) & ref_ids or len(new_ids) != len(set(new_ids)):
        sys.exit('id clash between f345 and the component exports')

    marker = 'prompt --application/deployment/definition\n'
    if ref.count(marker) != 1:
        sys.exit('f345.sql: deployment marker not found')
    note = ('-- REVIEW BEFORE IMPORT - generated by Claude Code (scripts/build_full_app.py):\n'
            '--   f345 reference application as application %s + %s\n'
            '--   Importing it REPLACES application %s completely (remove_flow).\n' % (app_id, ', '.join(comps), app_id))
    out = note + ref.replace(marker, '\n'.join(bodies) + '\n' + marker)
    if re.search(r'__[A-Z_]+__', out.replace('__APP_ID__', '')) or '__APP_ID__' in out:
        left = sorted(set(re.findall(r'__[A-Z_]+__', out)))
        sys.exit('placeholders left in merged file: %s' % left)
    if out.count('\nbegin\n') != out.count('\nend;\n/'):
        sys.exit('begin/end not balanced')

    # ---- --shift-ids=K: bake a new ID offset into the file, for App Builder imports.
    # APEX ids are unique in the whole instance and App Builder keeps the file's ids when the
    # application id is reused, so a second copy of f345 fails with ORA-00001. Adding K to every
    # wwv_flow_api.id(n) gives the copy its own id range (the header offset is set to 0 so the
    # file's ids are used as they are).
    shift = opts.get('shift-ids', '')
    if shift:
        if not re.fullmatch(r'\d+', shift):
            sys.exit('--shift-ids must be a number')
        k = int(shift)
        raw = set(int(x) for x in re.findall(r'wwv_flow_api\.id\((\d+)\)', ref))
        ids = set(int(x) for x in re.findall(r'wwv_flow_api\.id\((\d+)\)', out))
        if {i + k for i in ids} & raw:
            sys.exit('--shift-ids=%s makes ids clash with f345 (app 345)' % shift)
        out = re.sub(r'wwv_flow_api\.id\((\d+)\)', lambda m: 'wwv_flow_api.id(%d)' % (int(m.group(1)) + k), out)
        old = ',p_default_id_offset=>64111868204433090374\n'
        if out.count(old) != 1:
            sys.exit('f345 header offset not found')
        out = out.replace(old, ',p_default_id_offset=>0\n')
        out = out.replace('--   Importing it REPLACES', '--   Component ids shifted by %s (own id range, App Builder import).\n'
                                                       '--   Importing it REPLACES' % shift, 1)
    path = os.path.join(ROOT, 'apex', 'f%s_full.sql' % app_id)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(out)
    print('written', path, len(out.splitlines()), 'lines; pages added:', ', '.join(pages))

    # ---- install wrapper: a NEW id offset is mandatory. APEX ids are unique in the whole
    # instance; f345 is already installed (app 345, offset 0), so importing this file with the
    # file's own ids fails with ORA-00001 (WWV_FLOW_LISTS_PK, ...).
    ws, schema = opts.get('workspace-id', ''), opts.get('schema', '')
    if ws or schema:
        if not re.fullmatch(r'\d+', ws) or not re.fullmatch(r'[A-Za-z][A-Za-z0-9_$#]{0,29}', schema):
            sys.exit('install wrapper needs --workspace-id=<number> and --schema=<name>')
        wrapper = os.path.join(ROOT, 'apex', 'f%s_install.sql' % app_id)
        with open(wrapper, 'w', encoding='utf-8', newline='\n') as f:
            f.write("""-- =============================================================================
-- Install application %(app)s from f%(app)s_full.sql with a NEW ID offset (REVIEW BEFORE RUNNING)
-- Generated by Claude Code (scripts/build_full_app.py). Run in SQLcl / SQL*Plus as %(schema)s
-- (or a user with APEX_ADMINISTRATOR_ROLE), from the apex/ folder:
--     sql %(schema)s@<tns> @f%(app)s_install.sql
-- Existing application %(app)s is REPLACED. Export it first if you need a backup.
-- =============================================================================
begin
    apex_application_install.set_workspace_id(%(ws)s);
    apex_application_install.set_application_id(%(app)s);
    apex_application_install.generate_offset;          -- new ids: no clash with app 345 / f345
    apex_application_install.set_schema('%(schema)s');
    apex_application_install.set_application_alias('%(alias)s');
end;
/
@f%(app)s_full.sql
""" % dict(app=app_id, ws=ws, schema=schema.upper(), alias=alias))
        print('install wrapper:', wrapper)

if __name__ == '__main__':
    main(sys.argv[1:])
