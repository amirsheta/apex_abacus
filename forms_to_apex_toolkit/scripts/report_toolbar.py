# -*- coding: utf-8 -*-
"""
report_toolbar.py - the page 0 toolbar on report pages (user request 2026-11-25; Forms_to_APEX standard 13-b,
DEC-017 / DEC-018): a page that has the item P<page>_REPORT shows only

    REPORT_PRINT (طباعة)  ·  CLEAR (مسح)  ·  BACK (رجوع)

f345 page 0 already hides FUNCS on report pages and shows SAVE / DELETE only with P0_PAGE_PK (a report page clears it).
This module changes the other three buttons of f345 page 0:

    CREATE       : P0_PAGE_PK is null AND the page has no P<page>_REPORT   (was: P0_PAGE_PK is null)
    SEARCH       : P0_PAGE_PK is null AND the page has no P<page>_REPORT   (was: P0_PAGE_PK is null)
    REPORT_SHOW  : Never (DEC-018: a report page has «طباعة» only; VIEW and PRINT open the same PDF)

Used by scripts/build_full_app.py on its copy of f345 (apex/Reference/f345.sql stays unchanged). A component-only
import does not carry page 0: make the same three changes by hand once (apex/IMPR2110/import_notes.md).
"""
import re

NOT_REPORT_PAGE = '\n'.join([
    ",p_button_condition=>wwv_flow_string.join(wwv_flow_t_varchar2(",
    "'-- not on a report page (item P<page>_REPORT): report pages show PRINT, CLEAR, BACK only (DEC-018, scripts/report_toolbar.py)',",
    "'if :P0_PAGE_PK is not null then',",
    "'    return false;',",
    "'end if;',",
    "'for r in (select 1',",
    "'            from APEX_APPLICATION_PAGE_ITEMS I',",
    "'           where I.APPLICATION_ID = :APP_ID',",
    "'             and I.PAGE_ID = :APP_PAGE_ID',",
    "'             and I.ITEM_NAME = ''P'' || :APP_PAGE_ID || ''_REPORT'') loop',",
    "'    return false;',",
    "'end loop;',",
    "'return true;'))",
    ",p_button_condition2=>'PLSQL'",
    ",p_button_condition_type=>'FUNCTION_BODY'"])
NEVER = ",p_button_condition_type=>'NEVER'"
CHANGES = {'CREATE': NOT_REPORT_PAGE, 'SEARCH': NOT_REPORT_PAGE, 'REPORT_SHOW': NEVER}
CONDITION = re.compile(r"\n,p_button_condition=>.*?\n,p_button_condition_type=>'[A-Z_]+'", re.S)


def patch_page0(ref):
    """f345 text with the three page 0 button conditions changed (exits on anything unexpected)"""
    p0 = ref.index('prompt --application/pages/page_00000\n')
    p0_end = ref.index('\nend;\n/\nprompt --', p0)
    page = ref[p0:p0_end]
    for name, new in CHANGES.items():
        blocks = [m for m in re.finditer(r"wwv_flow_api\.create_page_button\(\n.*?\n\);", page, re.S)
                  if "\n,p_button_name=>'%s'\n" % name in m.group(0)]
        if len(blocks) != 1:
            raise SystemExit('report_toolbar: page 0 button %s found %d times' % (name, len(blocks)))
        b = blocks[0].group(0)
        if len(CONDITION.findall(b)) != 1:
            raise SystemExit('report_toolbar: page 0 button %s has no single condition' % name)
        page = page.replace(b, CONDITION.sub(lambda m: '\n' + new, b), 1)
    return ref[:p0] + page + ref[p0_end:]


def check(full_text):
    """problems: the three conditions must be in the page 0 of a merged application file"""
    p0 = full_text.index('prompt --application/pages/page_00000\n')
    page = full_text[p0:full_text.index('\nend;\n/\nprompt --', p0)]
    out = []
    for name, new in CHANGES.items():
        b = [m.group(0) for m in re.finditer(r"wwv_flow_api\.create_page_button\(\n.*?\n\);", page, re.S)
             if "\n,p_button_name=>'%s'\n" % name in m.group(0)]
        if len(b) != 1 or new not in b[0]:
            out.append('page 0 button %s: report-page condition missing' % name)
    return out
