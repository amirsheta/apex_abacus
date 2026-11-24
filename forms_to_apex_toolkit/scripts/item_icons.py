# -*- coding: utf-8 -*-
"""
item_icons.py - an icon next to every entry item, chosen from the item name (user request 2026-11-24).

Convention of the real APEX 21.2 instance export (Forms_to_APEX/05_APEX/Application_Exports/Reference/f202604.sql,
189 items): Post Text  <span class="cg-ic fa fa-<icon>" aria-hidden="true"></span>  on Text Field, Number Field,
Popup LOV and Textarea items (not on Yes/No, Checkbox, Password, Display Only, Hidden); the f345 theme CSS styles
html .cg-ic (46px rounded icon box beside the field). The name rules below follow the icons that export uses
(_DT fa-calendar, PORT fa-building-o, EMAIL fa-at, _NBR fa-hashtag ...).

  post_text(name, display_as)   the Post Text of an item, or None
  check(text)                   problems of one export file (every eligible item has the icon)
"""
import re

KINDS = {'NATIVE_TEXT_FIELD': 'fa-font', 'NATIVE_NUMBER_FIELD': 'fa-hashtag', 'NATIVE_POPUP_LOV': 'fa-list',
         'NATIVE_TEXTAREA': 'fa-sticky-note-o'}      # item types with an icon -> icon when no name rule matches
# (icon, words of the item name without P<page>_): the first rule with a matching word wins
RULES = [
    ('fa-search', ['SEARCH']),
    ('fa-at', ['EMAIL']),
    ('fa-mobile', ['MOBILE']),
    ('fa-fax', ['FAX', 'TELEX']),
    ('fa-phone', ['TEL', 'PHONE']),
    ('fa-envelope-o', ['ZIP']),
    ('fa-inbox', ['POB']),
    ('fa-home', ['ADDRESS', 'ADDRS']),
    ('fa-credit-card', ['IBAN']),
    ('fa-calendar-times-o', ['EXPRD_DT', 'END_DT', 'EXPIRY_DT']),
    ('fa-calendar-check-o', ['STRT_DT', 'START_DT', 'CLRNC_DT']),
    ('fa-calendar', ['DT', 'DATE']),
    ('fa-building-o', ['PORT', 'BANK', 'SUPP_TITLE']),
    ('fa-globe', ['CTRY']),
    ('fa-map-marker', ['CITY']),
    ('fa-file-text-o', ['LETTER', 'DCLTN']),
    ('fa-id-card', ['BUS_ID', 'B_ID', 'ID_NBR']),
    ('fa-user', ['IMPR_NBR', 'HQ_IMPR', 'BRKR', 'AGENT']),
    ('fa-tag', ['NAME', 'NM']),
    ('fa-sticky-note-o', ['NOTE', 'NOTES', 'ACTIVITY', 'RSN', 'REASON', 'DESC']),
    ('fa-list-ol', ['CNT', 'COUNT']),
    ('fa-list', ['TYPE', 'STATUS', 'FLAG']),
    ('fa-hashtag', ['NBR', 'NO', 'CD', 'SEQ', 'ID', 'NUM']),
]


def icon(name, display_as):
    if display_as not in KINDS:
        return None
    words = '_' + re.sub(r'^P\d+_', '', name.upper()) + '_'
    for ic, keys in RULES:
        if any('_%s_' % k in words for k in keys):
            return ic
    return KINDS[display_as]


def post_text(name, display_as):
    ic = icon(name, display_as)
    return '<span class="cg-ic fa %s" aria-hidden="true"></span>' % ic if ic else None


def check(text):
    problems = []
    for b in re.findall(r'wwv_flow_api\.create_page_item\((.*?)\n\);', text, re.S):
        name = re.search(r"p_name=>'(\w+)'", b).group(1)
        kind = re.search(r"p_display_as=>'(\w+)'", b).group(1)
        want = post_text(name, kind)
        if want and want not in b:
            problems.append('%s: without the item icon %s (scripts/item_icons.py)' % (name, want))
    return problems
