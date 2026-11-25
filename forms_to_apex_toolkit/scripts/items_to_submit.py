# -*- coding: utf-8 -*-
"""
items_to_submit.py - every page item a component reads must be in its "Items to Submit" (user rule 2026-11-25).

A page item used in
  * a region query (IG / report / chart, p_plug_source)            -> region   p_ajax_items_to_submit
  * the LOV query of a Popup LOV / Select List item                -> item     p_ajax_items_to_submit
    (shared LOV body: LOV_APX.<F>(P_X_ITEM => 'P<page>_<ITEM>'))
  * the PL/SQL of a FOS action (PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE)  -> action   p_attribute_02
must be listed there, so the server always works with the value on the screen. Application items (P_CURR_PORT_CD,
SSO_APP_USER ...) and P0_ items are session state and cannot be submitted; they are not checked.

check(text) -> list of problems for one component export (empty = OK).
"""
import re

PAGE_ITEM = r'P[1-9]\d*_[A-Z0-9_$#]+'


def _unq(s):
    m = re.fullmatch(r"unistr\('(.*)'\)", s, re.S)
    if m:
        return re.sub(r'\\([0-9A-F]{4})', lambda x: chr(int(x.group(1), 16)), m.group(1)).replace("''", "'")
    return s[1:-1].replace("''", "'") if s.startswith("'") else s


def _plain(value):
    """text of a q() / lit() literal"""
    return '\n'.join(_unq(v) for v in re.findall(r"(?:unistr\('(?:[^']|'')*'\)|'(?:[^']|'')*')", value))


def _attr(block, name):
    m = re.search(r"\n[ ,]%s=>(.*?)(?=\n[ ,]p_\w+=>|\Z)" % name, block, re.S)
    return _plain(m.group(1)) if m else ''


def _binds(code):
    code = re.sub(r'--[^\n]*', '', code)
    return set(re.findall(r'(?<![\w$#]):(%s)\b' % PAGE_ITEM, code))


def _submitted(value):
    return set(i.strip() for i in value.split(',') if i.strip())


def _blocks(text, api):
    return [c[:c.find('\n);')] for c in text.split('wwv_flow_api.%s(' % api)[1:]]


def check(text):
    problems = []
    lovs = {}
    for b in _blocks(text, 'create_list_of_values'):
        lovs[_attr(b, 'p_lov_name')] = set(re.findall(r"=>\s*'(%s)'" % PAGE_ITEM, _attr(b, 'p_lov_query'))) \
            | _binds(_attr(b, 'p_lov_query'))
    for b in _blocks(text, 'create_page_plug'):
        need = _binds(_attr(b, 'p_plug_source')) if _attr(b, 'p_query_type') == 'SQL' or 'NATIVE_IG' in b else set()
        miss = need - _submitted(_attr(b, 'p_ajax_items_to_submit'))
        if miss:
            problems.append('region %s: items to submit miss %s' % (_attr(b, 'p_region_name') or _attr(b, 'p_plug_name'), sorted(miss)))
    for b in _blocks(text, 'create_page_item'):
        lov = _attr(b, 'p_named_lov')
        need = (lovs.get(lov, set()) | _binds(_attr(b, 'p_lov'))) - {_attr(b, 'p_name')}
        miss = need - _submitted(_attr(b, 'p_ajax_items_to_submit'))
        if miss:
            problems.append('item %s (LOV %s): items to submit miss %s' % (_attr(b, 'p_name'), lov, sorted(miss)))
    for b in _blocks(text, 'create_page_da_action'):
        if "p_action=>'PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE'" not in b:
            continue
        miss = _binds(_attr(b, 'p_attribute_01')) - _submitted(_attr(b, 'p_attribute_02'))
        if miss:
            problems.append('FOS action %s: items to submit miss %s' % (re.search(r'p_id=>wwv_flow_api\.id\((\d+)\)', b).group(1), sorted(miss)))
    return problems


def _set_attr(block, name, items):
    value = "'%s'" % ','.join(items)
    if re.search(r"\n[ ,]%s=>" % name, block):
        return re.sub(r"(\n[ ,]%s=>)'[^']*'" % name, lambda m: m.group(1) + value, block, count=1)
    return block + "\n,%s=>%s" % (name, value)


def _ordered(current, need):
    have = [i.strip() for i in current.split(',') if i.strip()]
    return have + sorted(need - set(have))


def fix(text):
    """the export with every missing page item added to Items to Submit (regions, LOV items, FOS actions)"""
    lovs = {}
    for b in _blocks(text, 'create_list_of_values'):
        lovs[_attr(b, 'p_lov_name')] = set(re.findall(r"=>\s*'(%s)'" % PAGE_ITEM, _attr(b, 'p_lov_query'))) \
            | _binds(_attr(b, 'p_lov_query'))

    def patch(api, needed, attr):
        nonlocal text
        for b in _blocks(text, api):
            need = needed(b)
            if need and need - _submitted(_attr(b, attr)):
                new = _set_attr(b, attr, _ordered(_attr(b, attr), need))
                if text.count(b + '\n);') != 1:
                    raise SystemExit('items_to_submit.fix: block not unique')
                text = text.replace(b + '\n);', new + '\n);', 1)

    patch('create_page_plug', lambda b: _binds(_attr(b, 'p_plug_source'))
          if _attr(b, 'p_query_type') == 'SQL' or 'NATIVE_IG' in b else set(), 'p_ajax_items_to_submit')
    patch('create_page_item', lambda b: (lovs.get(_attr(b, 'p_named_lov'), set()) | _binds(_attr(b, 'p_lov')))
          - {_attr(b, 'p_name')}, 'p_ajax_items_to_submit')
    patch('create_page_da_action', lambda b: _binds(_attr(b, 'p_attribute_01'))
          if "p_action=>'PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE'" in b else set(), 'p_attribute_02')
    return text
