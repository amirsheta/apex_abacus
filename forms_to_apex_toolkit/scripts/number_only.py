# -*- coding: utf-8 -*-
"""
number_only.py - Number Field items accept only digits while the user types (user request 2026-11-24).

  CLASS   CSS class set on every Number Field item (p_tag_css_classes) and on every editable grid number
          column (Text / Number Field on NUMBER data: p_item_css_classes); the generators check both
  JS      the one-line Execute JavaScript Code action of the page DA "NUMBER ONLY" (Page Load):
          one delegated handler for every .number_only input of the page. On each input event (typing,
          paste, autofill) Arabic-Indic / Persian digits become 0-9 and any other character is removed.
          f345 has no class-based handler (FTEX.js pageItemOnlyNumber needs one call per item), so the DA is
          added to page 0 (global page) by scripts/build_full_app.py; the form pages have no copy.
"""
CLASS = 'number_only'
JS = ('$(document).off("input.numberOnly").on("input.numberOnly", ".number_only", function () { '
      'var v = this.value.replace(/[\\u0660-\\u0669\\u06F0-\\u06F9]/g, function (d) { var c = d.charCodeAt(0); '
      'return String(c - (c >= 1776 ? 1776 : 1632)); }).replace(/[^0-9]/g, ""); '
      'if (v !== this.value) { this.value = v; } });')
COMMENT = ('Source: Claude Code - items and grid columns with CSS class number_only accept only digits while typing '
           '(user request 2026-11-24, global page); f345 had no class-based handler (FTEX.js pageItemOnlyNumber is per item)')


def add_class(css):
    """css classes of an item plus number_only"""
    parts = (css or '').split()
    return ' '.join(parts + [CLASS] if CLASS not in parts else parts)


# ---- page 0 (user decision 2026-11-24): the handler is one DA on the f345 global page, so every page has it.
# The component exports cannot change page 0; scripts/build_full_app.py adds this DA to page 0 of the full
# application file. Fixed ids in f345 numbering (the IMPR "9000" range, kinds 08 = DA event, 09 = DA action).
PAGE0_EVENT_ID = '900008000010'
PAGE0_ACTION_ID = '900009000010'


def page0_dynamic_action():
    """wwv_flow_api calls of the page 0 DA "NUMBER ONLY" (inserted at the end of the page_00000 block)"""
    js = JS.replace("'", "''")
    return '\n'.join([
        'wwv_flow_api.create_page_da_event(',
        ' p_id=>wwv_flow_api.id(%s)' % PAGE0_EVENT_ID,
        ",p_name=>'NUMBER ONLY'",
        ',p_event_sequence=>8',
        ",p_bind_type=>'bind'",
        ",p_bind_event_type=>'ready'",
        ",p_da_event_comment=>'%s'" % COMMENT.replace("'", "''"),
        ');',
        'wwv_flow_api.create_page_da_action(',
        ' p_id=>wwv_flow_api.id(%s)' % PAGE0_ACTION_ID,
        ',p_event_id=>wwv_flow_api.id(%s)' % PAGE0_EVENT_ID,
        ",p_event_result=>'TRUE'",
        ',p_action_sequence=>10',
        ",p_execute_on_page_init=>'Y'",
        ",p_action=>'NATIVE_JAVASCRIPT_CODE'",
        ",p_attribute_01=>'%s'" % js,
        ');'])
