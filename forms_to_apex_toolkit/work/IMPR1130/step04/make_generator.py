"""Write scripts/gen_apex_impr1130.py from scripts/gen_apex_impr1110.py (step 04).

The IMPR1110 generator was imported into application 202530 (2026-11-18) - its helpers and wwv_flow_api parameter
patterns are reused unchanged. Every replacement below must match exactly once (asserted), so a change of the
IMPR1110 generator shows up here instead of producing a wrong file.
Usage: python3 -I work/IMPR1130/step04/make_generator.py
"""
import re

SRC = 'scripts/gen_apex_impr1110.py'
OUT = 'scripts/gen_apex_impr1130.py'
t = open(SRC, encoding='utf-8').read()


def rep(a, b, count=1):
    global t
    n = t.count(a)
    if n != count:
        raise SystemExit('expected %d x, found %d: %r' % (count, n, a[:90]))
    t = t.replace(a, b)


def sub_section(start, end, new):
    """replace the text from the line starting with start up to (not including) the line starting with end"""
    global t
    i = t.index(start)
    j = t.index(end, i)
    t = t[:i] + new + t[j:]


# ---------------------------------------------------------------- header, paths, constants
rep('''gen_apex_impr1110.py - step 04 revision 2: APEX 21.2 component export of IMPR1110 (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c, docs/f345_reference_standard.md).''',
    '''gen_apex_impr1130.py - step 04: APEX 21.2 component export of IMPR1130 (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c, docs/f345_reference_standard.md).
Written by work/IMPR1130/step04/make_generator.py from scripts/gen_apex_impr1110.py (do not edit by hand:
change make_generator.py and re-run it).''')
rep('''  work/step03/page_design.json        the page design of step 03 (items, validations, processes,
                                      computations, dynamic actions) - analysis/.../IMPR1110_apex_page_spec.md
  forms/IMPR/IMPR1110_fmb.xml         item data types (source data type of the Form region columns)
  apex/Reference/f345.sql             template ids, existing ids / items / LOVs (checks)
  plsql/IMPR1110/impr1110_spec.sql    members of package IMPR1110 (checks)
Writes
  apex/IMPR1110/f345_impr1110.sql     component export, REVIEW BEFORE IMPORT (4 placeholders)
  apex/IMPR1110/f<app>_impr1110_import.sql  with --workspace-id --app-id --id-offset --schema''',
    '''  work/IMPR1130/step03/page_design.json   the page design of step 03 (items, validations, processes,
                                      computations, dynamic actions, LOVs) - analysis/IMPR1130/IMPR1130_apex_page_spec.md
  forms/IMPR/IMPR1130_fmb.xml         item data types (source data type of the Form region columns)
  apex/Reference/f345.sql             template ids, existing ids / items / LOVs (checks)
  apex/IMPR1110/f345_impr1110.sql, apex/SUPPORT_ENTRY/f345_support_entry.sql, apex/IMPR1120/f345_impr1120.sql
                                      shared components reused (page group IMPR, application items, LOVs), id clashes
  plsql/IMPR1130/impr1130_spec.sql    members of package IMPR1130 (checks)
Writes
  apex/IMPR1130/f345_impr1130.sql     component export, REVIEW BEFORE IMPORT (4 placeholders)
  apex/IMPR1130/f<app>_impr1130_import.sql  with --workspace-id --app-id --id-offset --schema''')
rep('Submit Page, validations and processes = one call into IMPR1110.', 'Submit Page, validations and processes = one call into IMPR1130.')
rep('python3 -I scripts/gen_apex_impr1110.py [', 'python3 -I scripts/gen_apex_impr1130.py [')
rep("DESIGN = os.path.join(ROOT, 'work', 'step03', 'page_design.json')",
    "DESIGN = os.path.join(ROOT, 'work', 'IMPR1130', 'step03', 'page_design.json')")
rep("XML = os.path.join(ROOT, 'forms', 'IMPR', 'IMPR1110_fmb.xml')", "XML = os.path.join(ROOT, 'forms', 'IMPR', 'IMPR1130_fmb.xml')")
rep("PKG = os.path.join(ROOT, 'plsql', 'IMPR1110', 'impr1110_spec.sql')\nOUT = os.path.join(ROOT, 'apex', 'IMPR1110', 'f345_impr1110.sql')",
    "PKG = os.path.join(ROOT, 'plsql', 'IMPR1130', 'impr1130_spec.sql')\nOUT = os.path.join(ROOT, 'apex', 'IMPR1130', 'f345_impr1130.sql')\n"
    "OTHER_EXPORTS = [os.path.join(ROOT, 'apex', f) for f in ('IMPR1110/f345_impr1110.sql', 'SUPPORT_ENTRY/f345_support_entry.sql',\n"
    "                                                           'IMPR1120/f345_impr1120.sql')]")
rep("DATE, STAMP = '2026-11-19', '20261119000000'\nFORM = 'IMPR1110'\nPG, PG_SEARCH, PG_MOB = 1110, 111001, 111002",
    "DATE, STAMP = '2026-11-24', '20261124000000'\nFORM = 'IMPR1130'\nPG, PG_SEARCH = 1130, 113001\nPI = 'P1130_'\n"
    "SHARED_BASE = 9130                 # IMPR1110 uses 9000, IMPR1120 9120 for their shared components\n"
    "# created by the IMPR1110 export (already in application 202530): reused, not re-created\n"
    "IMPR1110_IDS = dict(PAGE_GROUP_IMPR='900001000010')")
rep("    base = int(page) if page.isdigit() else 9000", "    base = int(page) if page.isdigit() else SHARED_BASE")

# ---------------------------------------------------------------- items: page prefix
rep("    if i['name'] == 'P1110_HERO_TITLE':", "    if i['name'] == PI + 'HERO_TITLE':")
rep("# shown by the hero region (&P1110_HERO_TITLE.), as AGR1100", "# shown by the hero region (&P1130_HERO_TITLE.), as AGR1100")
rep("        it['cascade'] = ','.join(x.strip() if x.strip().startswith('P1110_') else 'P1110_' + x.strip()",
    "        it['cascade'] = ','.join(x.strip() if x.strip().startswith(PI) else PI + x.strip()")
rep("        it.update(column=col, data_type=source_type(i['name'][len('P1110_'):], i['source']))",
    "        it.update(column=col, data_type=source_type(i['name'][len(PI):], i['source']))")
rep("    if item in ('BUS_ID_EXPRD_DT', 'BUS_ID_ISSUE_DT', 'LST_TRAN_DT'):", "    if item in ('BUS_ID_EXPRD_DT', 'BUS_ID_ISSUE_DT', 'LST_TRAN_DT', 'BIRTH_DT'):")
rep("    if i['name'] in ('P1110_MODULE_ID',):", "    if i['name'] in (PI + 'MODULE_ID',):")

# ---------------------------------------------------------------- DA events: page load, button
rep("EVENT = {'Change': 'change', 'Get Focus': 'focusin', 'Lose Focus': 'focusout', 'Dialog Closed': 'apexafterclosedialog',\n         'Before Page Submit': 'apexbeforepagesubmit'}",
    "EVENT = {'Change': 'change', 'Get Focus': 'focusin', 'Lose Focus': 'focusout', 'Dialog Closed': 'apexafterclosedialog',\n"
    "         'Before Page Submit': 'apexbeforepagesubmit', 'Page Load': 'ready', 'Click': 'click'}")
rep("""    elif sel.startswith('JavaScript Expression'):
        prm += [('p_triggering_element_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_element', q('document'))]""",
    """    elif sel.startswith('JavaScript Expression'):
        prm += [('p_triggering_element_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_element', q('document'))]
    elif sel.startswith('Button '):
        prm += [('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('%s:btn:%s' % (page, sel[7:])))]
        UNCERTAIN.add('button DA: p_triggering_button_id (as page 113001 SEARCH; IMPR1110 uses it)')""")

# ---------------------------------------------------------------- shared components: only the new LOVs
sub_section("# ----------------------------------------------------------------------------- shared components\nGLOBALS = [",
            "def gen():",
            "# ----------------------------------------------------------------------------- shared components\n"
            "# page group IMPR, application items (G_ALLOW_MCI, G_ALLOW_MOI, G_LETTER_*, G_PORT_CD, G_SUPP_TITLE_CD,\n"
            "# G_CHK_IMP_TYP, P_PRSNL_IMPR, P_LETTER_NBR), Application Setting HIJRI_DATE_FORMAT and 8 LOVs come from the\n"
            "# IMPR1110 export; G_SUPPORT_ENTRY_CALLER from the SUPPORT_ENTRY export (spec 13)\n"
            "LOVS = [(l['name'], l['call'], [tuple(c) for c in l['columns']], l['source']) for l in D['lovs']['new']]\n"
            "REUSED_LOVS = [l['name'] for l in D['lovs']['reused']]\n\n")
rep("-- File        : apex/IMPR1110/f345_impr1110.sql\n-- Generated by: Claude Code (scripts/gen_apex_impr1110.py, step 04 revision 2) from\n"
    "--               analysis/IMPR1110/IMPR1110_apex_page_spec.md (work/step03/page_design.json), %s, form IMPR1110",
    "-- File        : apex/IMPR1130/f345_impr1130.sql\n-- Generated by: Claude Code (scripts/gen_apex_impr1130.py, step 04) from\n"
    "--               analysis/IMPR1130/IMPR1130_apex_page_spec.md (work/IMPR1130/step03/page_design.json), %s, form IMPR1130")
rep("--               FOS + native dynamic actions, one-line calls into package IMPR1110 (version 011) and FORMS_APX (004, common helpers).",
    "--               FOS + native dynamic actions, one-line calls into package IMPR1130 (version 001) and FORMS_APX (004, common helpers).")
rep("""-- Contents    : component export INTO the application installed from f345: pages 1110 (main),
--               111001 (search), 111002 (mobile) + the shared components they need.
--               Functions F1, F2, F3, F5 open page 9001 SUPPORT_ENTRY (its own export apex/SUPPORT_ENTRY/).
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR1110/import_notes.md""",
    """-- Contents    : component export INTO the application installed from f345: pages 1130 (main) and
--               113001 (search) + 4 shared LOVs. Needs the IMPR1110 export (page group IMPR, application
--               items, LOVs, Application Setting HIJRI_DATE_FORMAT) and the SUPPORT_ENTRY export (page 9001,
--               G_SUPPORT_ENTRY_CALLER) imported first.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR1130/import_notes.md""")
sub_section("    # ---------------------------------------------------------------- shared components\n    nid('9000:pg:IMPR', 1)",
            "    for name, sql, cols, s in LOVS:",
            "    # ---------------------------------------------------------------- shared components (spec 13)\n"
            "    UNCERTAIN.add(lov_apx.UNCERTAIN)\n")
rep("        nid('9000:lov:' + name, 5)\n        b = [call('create_list_of_values', [\n            ('p_id', ref('9000:lov:' + name)), ('p_lov_name', q(name))] + lov_apx.lov_attributes(sql, q), 'Source: ' + s + ' / spec 6')]",
    "        nid('9130:lov:' + name, 5)\n        b = [call('create_list_of_values', [\n            ('p_id', ref('9130:lov:' + name)), ('p_lov_name', q(name))] + lov_apx.lov_attributes(sql, q), 'Source: IMPR1130 ' + s + ' / spec 6')]")
rep("            key = '9000:lovc:%s:%s' % (name, c)", "            key = '9130:lovc:%s:%s' % (name, c)")
rep("                ('p_id', ref(key)), ('p_lov_id', ref('9000:lov:' + name)), ('p_query_column_name', q(c)),",
    "                ('p_id', ref(key)), ('p_lov_id', ref('9130:lov:' + name)), ('p_query_column_name', q(c)),")
sub_section("    for name, vals, s in STATIC_LOVS:", "    # ---------------------------------------------------------------- page 1110\n", "")

# ---------------------------------------------------------------- page 1130
rep("    # ---------------------------------------------------------------- page 1110\n", "    # ---------------------------------------------------------------- page 1130\n")
rep("        ('p_group_id', ref('9000:pg:IMPR')), ('p_step_template', fid('PAGE_MAIN')), ('p_page_css_classes', q('zf')),",
    "        ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_step_template', fid('PAGE_MAIN')), ('p_page_css_classes', q('zf')),")
rep("        ('p_page_comment', src('IMPR1110.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),\n        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR1110.fmb - spec 2 / f345 standard 4'))",
    "        ('p_page_comment', src('IMPR1130.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),\n        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR1130.fmb - spec 2 / f345 standard 4'))")
rep("'<div><div class=\"cg-hero-k\">المستوردون</div><div class=\"cg-hero-t\">&P1110_HERO_TITLE.</div>'",
    "'<div><div class=\"cg-hero-k\">المستوردون</div><div class=\"cg-hero-t\">&P1130_HERO_TITLE.</div>'")
rep("'<div class=\"cg-hero-d\">إضافة وتعديل بيانات المستورد وبيانات النشاط والعنوان</div></div></div></div>')",
    "'<div class=\"cg-hero-d\">إضافة وتعديل بيانات المستورد ورقم المنشأة وبيانات النشاط والعنوان</div></div></div></div>')")
t = t.replace("'1110:plug:IMPORTERS_HERO'", "'1130:plug:IMPORTERS_HERO'").replace("'1110:plug:IMPORTERS'", "'1130:plug:IMPORTERS'")
rep("('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src('IMPR1110.TITLE (OLB) -> f345 hero / spec 3'))]))",
    "('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src('IMPR1130.TITLE (OLB) -> f345 hero / spec 3'))]))\n"
    "    nid('1130:btn:SUPPORT_ENTRY', 2)\n"
    "    A(call('create_page_button', [\n"
    "        ('p_id', ref('1130:btn:SUPPORT_ENTRY')), ('p_button_sequence', '10'), ('p_button_plug_id', ref('1130:plug:IMPORTERS_HERO')),\n"
    "        ('p_button_name', q('SUPPORT_ENTRY')), ('p_button_action', q('DEFINED_BY_DA')),\n"
    "        ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')), ('p_button_template_id', fid('BUTTON')),\n"
    "        ('p_button_image_alt', q('بيانات المساندة الفنية')), ('p_button_position', q('BODY')),\n"
    "        ('p_icon_css_classes', q('fa-file-text-o')), ('p_button_css_classes', q('cg-b-funcs')),\n"
    "        ('p_button_comment', src('IMPR1130.WHEN-NEW-FORM-INSTANCE OPEN_FORM(SUPPORT_ENTRY) - letter dialog on demand (D1) / spec 5'))]))")
rep("        ('p_plug_comment', src('IMPR1110.IMPORTERS (single record, WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD, key mode ROWID) / spec 3'))]))",
    "        ('p_plug_comment', src('IMPR1130.IMPORTERS (single record, WHERE PORT_CD = :PARAMETER.P_CURR_PORT_CD, key mode ROWID; delete by process KEY-DELREC) / spec 3'))]))")
t = t.replace("'1110:branch:STAY'", "'1130:branch:STAY'").replace("'1110:branch:QUERY'", "'1130:branch:QUERY'")
rep("        ('p_id', ref('1130:branch:STAY')), ('p_branch_name', q('IMPR1110 - stay in the form')),\n        ('p_branch_action', q('f?p=&APP_ID.:1110:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#')),",
    "        ('p_id', ref('1130:branch:STAY')), ('p_branch_name', q('IMPR1130 - stay in the form')),\n        ('p_branch_action', q('f?p=&APP_ID.:1130:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#')),")
rep("        ('p_branch_action', q('f?p=&APP_ID.:1110:&SESSION.::&DEBUG.:1110::')),", "        ('p_branch_action', q('f?p=&APP_ID.:1130:&SESSION.::&DEBUG.:1130::')),")
rep("        ('p_branch_comment', src('IMPR1110.IMPORTERS.WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY: clear cache 1110, P0_PAGE_PK kept / spec 12'))]))",
    "        ('p_branch_comment', src('IMPR1130.IMPORTERS.WHEN-NEW-ITEM-INSTANCE EXECUTE_QUERY: clear cache 1130, P0_PAGE_PK kept / spec 12'))]))")
rep("    for n, c in enumerate([c for c in D['computations'] if c['item'].startswith('P1110_')], 1):\n        key = '1110:comp:' + c['item']",
    "    for n, c in enumerate([c for c in D['computations'] if c['item'].startswith(PI)], 1):\n        key = '1130:comp:' + c['item']")
rep("        key = '1110:val:' + v['name']", "        key = '1130:val:' + v['name']")
rep("            + cond + [('p_associated_item', 'wwv_flow_api.id(%s)' % _ids['1110:item:' + v['item']]),",
    "            + cond + [('p_associated_item', 'wwv_flow_api.id(%s)' % _ids['1130:item:' + v['item']]),")
rep("                      ('p_validation_comment', src('IMPR1110.' + v['source'] + ' / spec 7'))]))",
    "                      ('p_validation_comment', src('IMPR1130.' + v['source'] + ' / spec 7'))]))")
rep("        key = '1110:proc:%s:%s' % (point, p['name'])\n        s = 'IMPR1110 %s / spec 8' % p['source']",
    "        key = '1130:proc:%s:%s' % (point, p['name'])\n        s = 'IMPR1130 %s / spec 8' % p['source']")
rep("    W(block('application/pages/page_01110', '\\n'.join(P)))", "    W(block('application/pages/page_01130', '\\n'.join(P)))")

# ---------------------------------------------------------------- page 113001 (search)
t = t.replace("'111001:", "'113001:").replace("P111001_SEARCH", "P113001_SEARCH")
rep("    # ---------------------------------------------------------------- page 111001 (search)", "    # ---------------------------------------------------------------- page 113001 (search)")
rep("        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', ref('9000:pg:IMPR')), ('p_page_css_classes', q('zf')),",
    "        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_page_css_classes', q('zf')),")
for a in ("IMPR1110 Enter-Query / Execute-Query of block IMPORTERS (TOOLBAR.RE_ENTER_QUERY) / spec 2, 3",
          "IMPR1110.IMPORTERS.PRE-QUERY criteria as one search text over all columns / spec 3",
          "IMPR1110 EXECUTE_QUERY of block IMPORTERS / spec 3", "IMPR1110 TOOLBAR.CLEAR_ALL for the search (user request 2026-11-23) / spec 3",
          "IMPR1110 EXECUTE_QUERY / spec 3", "IMPR1110 TOOLBAR.CLEAR_ALL (search criteria) / spec 3"):
    rep(a, a.replace('IMPR1110', 'IMPR1130'))
rep("    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('SEARCH KEY-ENTER')), ('p_event_sequence', '12'),",
    "    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('SEARCH KEY-ENTER')), ('p_event_sequence', '12'),")
rep("src('IMPR1110 KEY-EXEQRY (Enter in the search text; f345 AGR1100_SEARCH '", "src('IMPR1130 KEY-EXEQRY (Enter in the search text; f345 AGR1100_SEARCH '")
rep("        '   AND (NVL(:P1110_P_PRSNL_IMPR, 0) <> 1 OR i.impr_type_cd = 4)',", "        '   AND (NVL(:P1130_P_PRSNL_IMPR, 0) <> 1 OR i.impr_type_cd = 4)',")
rep("        ('p_plug_comment', src('IMPR1110.IMPORTERS block query + PRE-QUERY (PRSNL_IMPR; block ORDER BY dropped); one search text '",
    "        ('p_plug_comment', src('IMPR1130.IMPORTERS block query + PRE-QUERY (PRSNL_IMPR; block ORDER BY dropped); one search text '")
rep("            # ROW_ID is URL-safe ('+' / '/' -> '-' / '_'); IMPR1110.P0_PAGE_PK_CHECK translates it back (spec 3)",
    "            # ROW_ID is URL-safe ('+' / '/' -> '-' / '_'); IMPR1130.P0_PAGE_PK_CHECK translates it back (spec 3)")
rep("                    ('p_link_target', q('f?p=&APP_ID.:1110:&SESSION.::&DEBUG.:1110:P0_PAGE_PK:&ROW_ID.')),",
    "                    ('p_link_target', q('f?p=&APP_ID.:1130:&SESSION.::&DEBUG.:1130:P0_PAGE_PK:&ROW_ID.')),")
rep("        ('p_id', ref('113001:ig')), ('p_internal_uid', '111001000201'),", "        ('p_id', ref('113001:ig')), ('p_internal_uid', '113001000201'),")
rep("                                ('p_static_id', q('111001000202')),", "                                ('p_static_id', q('113001000202')),")
rep("        comment='Source: IMPR1110.IMPORTERS query criteria (ARBC_IMPR_NAME: PRE-QUERY IMPR_NAME_STD = STR.StrFormat(name, TRUE), '",
    "        comment='Source: IMPR1130.IMPORTERS query criteria (ARBC_IMPR_NAME: PRE-QUERY IMPR_NAME_STD = STR.StrFormat(name, TRUE), '")
rep("    UNCERTAIN.add('NATIVE_CLEAR action with p_affected_elements (page 111001 CLEAR; not in f345)')",
    "    UNCERTAIN.add('NATIVE_CLEAR action with p_affected_elements (page 113001 CLEAR; not in f345)')")
rep("    UNCERTAIN.add('button DA: p_triggering_button_id (page 111001 SEARCH)')", "    UNCERTAIN.add('button DA: p_triggering_button_id (as page 113001 SEARCH; IMPR1110 uses it)')")
rep("    UNCERTAIN.add('search IG 111001: p_lazy_loading true, p_show_total_row_count false, toolbar ACTIONS_MENU:RESET (search field removed)')",
    "    UNCERTAIN.add('search IG 113001: p_lazy_loading true, p_show_total_row_count false, toolbar ACTIONS_MENU:RESET (search field removed)')")
rep("    W(block('application/pages/page_111001', '\\n'.join(P)))", "    W(block('application/pages/page_113001', '\\n'.join(P)))")
sub_section("    # ---------------------------------------------------------------- page 111002 (mobile)", "    W('''prompt --application/end_environment", "")

# ---------------------------------------------------------------- checks against the other exports
rep("    ref_txt = open(REF, encoding='utf-8', errors='replace').read()",
    "    ref_txt = open(REF, encoding='utf-8', errors='replace').read()\n"
    "    others = '\\n'.join(open(f, encoding='utf-8', errors='replace').read() for f in OTHER_EXPORTS)")
rep("    if re.search(r'pkg_|IMPR1110_APX\\.', code, re.I): problems.append('page calls pkg_ / IMPR1110_APX')",
    "    if re.search(r'pkg_|IMPR1110|_APX\\.(?!.)', code, re.I): problems.append('page calls pkg_ / IMPR1110')")
rep("    for bad in ('ON_DEMAND', 'p_javascript_file_urls', 'AJAX_FUNCTION', 'impr1110.js'):",
    "    for bad in ('ON_DEMAND', 'p_javascript_file_urls', 'AJAX_FUNCTION', 'impr1130.js'):")
rep("    if set(defined) & ref_ids: problems.append('ids clash with f345')\n    missing = set(re.findall(r'wwv_flow_api\\.id\\((\\d+)\\)', text)) - set(defined) - ref_ids",
    "    if set(defined) & ref_ids: problems.append('ids clash with f345')\n"
    "    other_ids = set(re.findall(r'p_id=>wwv_flow_api\\.id\\((\\d+)\\)', others))\n"
    "    if set(defined) & other_ids: problems.append('ids clash with the IMPR1110 / SUPPORT_ENTRY / IMPR1120 exports')\n"
    "    for k, v in IMPR1110_IDS.items():\n"
    "        if v not in other_ids: problems.append('IMPR1110 id %s (%s) not in the IMPR1110 export' % (k, v))\n"
    "    missing = set(re.findall(r'wwv_flow_api\\.id\\((\\d+)\\)', text)) - set(defined) - ref_ids - other_ids")
rep("    ref_items = set(names_of(ref_txt, 'create_flow_item'))", "    ref_items = set(names_of(ref_txt, 'create_flow_item')) | set(names_of(others, 'create_flow_item'))")
rep("""    ref_lovs = set(re.findall(r"p_lov_name=>'([^']+)'", ref_txt))
    for n in re.findall(r"p_lov_name=>'([^']+)'", text):
        if n in ref_lovs: problems.append('LOV %s already in f345' % n)""",
    """    ref_lovs = set(re.findall(r"p_lov_name=>'([^']+)'", ref_txt))
    other_lovs = set(re.findall(r"p_lov_name=>'([^']+)'", others))
    for n in re.findall(r"p_lov_name=>'([^']+)'", text):
        if n in ref_lovs or n in other_lovs: problems.append('LOV %s already exists (f345 / other export)' % n)
    for n in REUSED_LOVS:
        if n not in other_lovs: problems.append('reused LOV %s not in the IMPR1110 export' % n)
    for n in set(re.findall(r"p_named_lov=>'([^']+)'", text)):
        if n not in other_lovs | set(re.findall(r"p_lov_name=>'([^']+)'", text)): problems.append('named LOV %s not defined' % n)
    if 'G_SUPPORT_ENTRY_CALLER' not in others: problems.append('SUPPORT_ENTRY export without G_SUPPORT_ENTRY_CALLER')""")
rep("""    for m in set(re.findall(r'IMPR1110\\.([A-Z_0-9]+)', code)):
        if m not in members: problems.append('IMPR1110.%s not in impr1110_spec.sql' % m)""",
    """    for m in set(re.findall(r'IMPR1130\\.([A-Z_0-9]+)', code)):
        if m not in members: problems.append('IMPR1130.%s not in impr1130_spec.sql' % m)
    for m in set(re.findall(r'SUPPORT_ENTRY\\.([A-Z_0-9]+)', code)):
        if m not in ('OPEN_DIALOG',): problems.append('SUPPORT_ENTRY.%s not part of the caller contract' % m)""")
rep("    path = os.path.join(ROOT, 'apex', 'IMPR1110', 'f%s_impr1110_import.sql' % vals['app_id'])",
    "    path = os.path.join(ROOT, 'apex', 'IMPR1130', 'f%s_impr1130_import.sql' % vals['app_id'])")
rep("    json.dump(sorted(UNCERTAIN), open(os.path.join(ROOT, 'work', 'step04_uncertain.json'), 'w'), indent=1)",
    "    json.dump(sorted(UNCERTAIN), open(os.path.join(ROOT, 'work', 'IMPR1130', 'step04', 'uncertain.json'), 'w'), indent=1)")

left = [l for l in t.split('\n') if re.search(r'1110|111001|111002', l) and 'IMPR1110_IDS' not in l and 'IMPR1110 export' not in l
        and 'IMPR1110 uses' not in l and 'IMPR1110/' not in l and 'gen_apex_impr1110' not in l and 'IMPR1110 ' not in l
        and 'pkg_|IMPR1110' not in l and 'IMPR1110.fmb module' not in l]
if left:
    raise SystemExit('IMPR1110 references left:\n' + '\n'.join(left))
open(OUT, 'w', encoding='utf-8').write(t)
print('written', OUT, len(t.splitlines()), 'lines')
