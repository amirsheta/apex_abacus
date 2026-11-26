# -*- coding: utf-8 -*-
"""
client_condition.py - an item tested by an item-type client-side condition always has a value (user rule 2026-11-26).

A Dynamic Action client-side condition of an item type (Item = Value, Item != Value, Item in list, Item > Value ...)
compares the item value in the browser. When the item is empty the comparison never matches and, on a Change event,
an item that stays empty raises no event at all, so the actions the page relies on (e.g. Enable after Disable) do not
run. Therefore the item named by such a condition
  * event level  : create_page_da_event  p_triggering_condition_type (item = p_triggering_element)
  * action level : create_page_da_action p_client_condition_type     (item = p_client_condition_element)
must have a Default value (p_item_default). Not checked: JAVASCRIPT_EXPRESSION, and NULL / NOT_NULL, which test the
empty value itself (the "only when entered" guard of a WHEN-VALIDATE-ITEM).

fix(text)   -> export where a hidden Y / N flag item without default gets default 'N' when tested against 'Y'
               (and 'Y' when tested against 'N'); every other case is left for check().
check(text) -> list of problems (empty = OK).
"""
import re

NO_VALUE_NEEDED = {'JAVASCRIPT_EXPRESSION', 'NULL', 'NOT_NULL'}


def _blocks(text, api):
    return [c[:c.find('\n);')] for c in text.split('wwv_flow_api.%s(' % api)[1:]]


def _attr(block, name):
    m = re.search(r"\n[ ,]%s=>'((?:[^']|'')*)'" % name, block)
    return m.group(1).replace("''", "'") if m else None


def _conditions(text):
    """(item, condition type, expression, where) of every item-type client-side condition"""
    out = []
    for b in _blocks(text, 'create_page_da_event'):
        ct = _attr(b, 'p_triggering_condition_type')
        if ct and ct not in NO_VALUE_NEEDED and _attr(b, 'p_triggering_element_type') == 'ITEM':
            out.append((_attr(b, 'p_triggering_element'), ct, _attr(b, 'p_triggering_expression'),
                        'DA %s' % _attr(b, 'p_name')))
    for b in _blocks(text, 'create_page_da_action'):
        ct = _attr(b, 'p_client_condition_type')
        if ct and ct not in NO_VALUE_NEEDED and _attr(b, 'p_client_condition_element'):
            out.append((_attr(b, 'p_client_condition_element'), ct, _attr(b, 'p_client_condition_expression'),
                        'DA action %s' % re.search(r'p_id=>wwv_flow_api\.id\((\d+)\)', b).group(1)))
    return out


def _items(text):
    return {_attr(b, 'p_name'): b for b in _blocks(text, 'create_page_item')}


def _without_condition_item(text):
    """DA events with an item-type client-side condition (NULL / NOT_NULL included) but no condition Item"""
    for b in _blocks(text, 'create_page_da_event'):
        ct = _attr(b, 'p_triggering_condition_type')
        if ct and ct != 'JAVASCRIPT_EXPRESSION' and not _attr(b, 'p_condition_element'):
            yield b


def check(text):
    items = _items(text)
    problems = ['DA %s: client-side condition %s has no Item (p_condition_element)' % (_attr(b, 'p_name'),
                _attr(b, 'p_triggering_condition_type')) for b in _without_condition_item(text)]
    for item, ct, expr, where in _conditions(text):
        b = items.get(item)
        if b is not None and not _attr(b, 'p_item_default'):
            problems.append('%s: client-side condition %s %s on %s, which has no default value (DA does not fire '
                            'while it is empty)' % (where, ct, expr, item))
    return problems


def fix(text):
    # 1. the condition Item: the triggering item / column (real 20.2 / 21.2 exports: p_condition_element_type +
    #    p_condition_element before p_triggering_condition_type; without them the Item of the condition is empty
    #    in App Builder and the condition never matches)
    for b in list(_without_condition_item(text)):
        kind = _attr(b, 'p_triggering_element_type')
        if kind not in ('ITEM', 'COLUMN'):
            continue                                    # reported by check(): the generator must name the item
        new = re.sub(r"(\n,p_triggering_condition_type=>)",
                     "\n,p_condition_element_type=>'%s'\n,p_condition_element=>'%s'\\1"
                     % (kind, _attr(b, 'p_triggering_element')), b, count=1)
        if text.count(b + '\n);') != 1:
            raise SystemExit('client_condition.fix: DA block not unique (%s)' % _attr(b, 'p_name'))
        text = text.replace(b + '\n);', new + '\n);', 1)
    # 2. a default value for the tested item
    items = _items(text)
    for item, ct, expr, _ in _conditions(text):
        b = items.get(item)
        if b is None or _attr(b, 'p_item_default') or _attr(b, 'p_display_as') != 'NATIVE_HIDDEN' \
                or ct != 'EQUALS' or expr not in ('Y', 'N'):
            continue
        new = re.sub(r"(\n,p_item_plug_id=>[^\n]*)", r"\1\n,p_item_default=>'%s'" % ('N' if expr == 'Y' else 'Y'), b, count=1)
        if new == b or text.count(b + '\n);') != 1:
            raise SystemExit('client_condition.fix: cannot set default of %s' % item)
        text = text.replace(b + '\n);', new + '\n);', 1)
        items[item] = new
    return text
