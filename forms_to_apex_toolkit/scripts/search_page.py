# -*- coding: utf-8 -*-
"""
search_page.py - a search page <main page>01 (name <FORM>_SEARCH) shows every row when the dialog opens and the
search text only narrows them (user requests 2026-11-26).

The search IG SQL has no WHERE :P<page>01_SEARCH IS NOT NULL gate; the text filter is optional
(:P<page>01_SEARCH IS NULL OR INSTR(...)). The search text keeps its session state (Per Session): without a reset the
next opening of the dialog would show only the rows of the old text, and page 0 opens the dialog with
apex_page.get_url(p_page => <page>01) without clearing the cache (f345 P0_SEARCH_URL, not changed: f345 shared
component). So every search page gets the Before Header process
  CLEAR SEARCH  -  Clear Session State, Clear Cache for Current Page (NATIVE_SESSION_STATE / CLEAR_CACHE_CURRENT_PAGE,
                   the same call as the f345 login page 9999 "Clear Page(s) Cache")
which empties P<page>01_SEARCH each time the dialog is rendered. An IG refresh (AJAX) does not render the page, so
the text typed for a search is kept while the user pages through the result.

fix(text)   -> export with the process added to every <FORM>_SEARCH page block that has none (idempotent).
check(text) -> list of problems (empty = OK): a search page without the process, with the IS NOT NULL gate, or
               without the optional filter :P<page>01_SEARCH IS NULL OR.
"""
import re

NAME = 'CLEAR SEARCH'
_PAGE = re.compile(r"(prompt --application/pages/page_(\d+)\nbegin\n)(.*?)(\nend;\n/\n)", re.S)


def _is_search(body):
    m = re.search(r"wwv_flow_api\.create_page\(.*?\n,p_name=>'([^']+)'", body, re.S)
    return bool(m) and m.group(1).upper().endswith('_SEARCH')


def _process(page):
    return '\n'.join([
        'wwv_flow_api.create_page_process(',
        ' p_id=>wwv_flow_api.id(%s07999990)' % page,
        ',p_process_sequence=>10',
        ",p_process_point=>'BEFORE_HEADER'",
        ",p_process_type=>'NATIVE_SESSION_STATE'",
        ",p_process_name=>'%s'" % NAME,
        ",p_attribute_01=>'CLEAR_CACHE_CURRENT_PAGE'",
        ",p_error_display_location=>'INLINE_IN_NOTIFICATION'",
        ",p_process_comment=>'Source: Forms Enter-Query (empty criteria on entry); clears P%s_SEARCH on every opening of "
        "the dialog, so it shows every row (user requests 2026-11-26, "
        "scripts/search_page.py)'" % page,
        ');'])


def fix(text):
    def add(m):
        head, page, body, tail = m.groups()
        if not _is_search(body) or "p_process_name=>'%s'" % NAME in body:
            return m.group(0)
        return head + body + '\n' + _process(page) + tail
    return _PAGE.sub(add, text)


def check(text):
    problems = []
    for m in _PAGE.finditer(text):
        page, body = m.group(2), m.group(3)
        if not _is_search(body):
            continue
        if "p_process_name=>'%s'" % NAME not in body:
            problems.append('search page %s without process %s (search_page.fix)' % (page, NAME))
        if ':P%s_SEARCH IS NOT NULL' % page in body:
            problems.append('search page %s: IG SQL with :P%s_SEARCH IS NOT NULL (no rows on opening)' % (page, page))
        if ':P%s_SEARCH IS NULL OR' % page not in body:
            problems.append('search page %s: search text filter not optional (:P%s_SEARCH IS NULL OR ...)' % (page, page))
    return problems
