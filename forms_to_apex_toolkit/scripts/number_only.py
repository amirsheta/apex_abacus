# -*- coding: utf-8 -*-
"""
number_only.py - Number Field items accept only digits while the user types (user request 2026-11-24).

  CLASS   CSS class set on every Number Field item (p_tag_css_classes) and on every editable grid number
          column (Text / Number Field on NUMBER data: p_item_css_classes); the generators check both
  JS      the one-line Execute JavaScript Code action of the page DA "NUMBER ONLY" (Page Load):
          one delegated handler for every .number_only input of the page. On each input event (typing,
          paste, autofill) Arabic-Indic / Persian digits become 0-9 and any other character is removed.
          f345 has no class-based handler (FTEX.js pageItemOnlyNumber needs one call per item); when one
          is added to page 0 or FTEX.js, drop the DA from the form pages.
"""
CLASS = 'number_only'
JS = ('$(document).off("input.numberOnly").on("input.numberOnly", ".number_only", function () { '
      'var v = this.value.replace(/[\\u0660-\\u0669\\u06F0-\\u06F9]/g, function (d) { var c = d.charCodeAt(0); '
      'return String(c - (c >= 1776 ? 1776 : 1632)); }).replace(/[^0-9]/g, ""); '
      'if (v !== this.value) { this.value = v; } });')
COMMENT = ('Number Field items (CSS class number_only) accept only digits while typing (user request 2026-11-24); '
           'f345 has no class-based handler (FTEX.js pageItemOnlyNumber is per item)')


def add_class(css):
    """css classes of an item plus number_only"""
    parts = (css or '').split()
    return ' '.join(parts + [CLASS] if CLASS not in parts else parts)
