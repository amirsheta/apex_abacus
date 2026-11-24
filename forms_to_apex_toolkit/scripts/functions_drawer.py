# -*- coding: utf-8 -*-
"""
functions_drawer.py - the functions menu (الوظائف) as ONE side drawer for all pages (user request 2026-11-24).

f345 page 0 has the toolbar button FUNCS (DA "FUNCS OPEN": apex.theme.openRegion('FUNCS')) and the shared list
"Page Functions" (its links call apex.theme.closeRegion('FUNCS') and trigger the function event), but no FUNCS
region: until now every form page carried its own small Inline Dialog. Now the region is on page 0 (global
page), so every page gets the same menu, and its page CSS turns the Inline Dialog into a side drawer:
full height on the LEFT of the page (user request), slides in, with a search box, list rows as f345 styles them (.cg-funcs .t-MediaList).

  page0_dynamic_action()  the page 0 DA FUNCS SEARCH (one line of JavaScript: filter while typing)
  page0_region()   wwv_flow_api.create_page_plug of the page 0 region FUNCS (scripts/build_full_app.py adds it,
                   as the NUMBER ONLY DA; apex/Reference/f345.sql itself stays unchanged)
  CSS              the drawer rules (in the region header, so the region is self-contained)
Form pages must NOT have a region FUNCS any more (the generators check it).

Notes: the drawer selector uses :has() (as f345's own Popup LOV dialog CSS); it never sets display, so the
jQuery UI dialog still opens and closes itself. No icon per function (removed 2026-11-24: the copied list with an icon column failed at import); the rows
show the f345 list as it is. Rendered on the pages where the FUNCS button is shown (no
P<page>_REPORT item, not page 100000).
"""
PAGE0_REGION_ID = '900001000990'      # f345 numbering, the IMPR "9000" range, kind 01 = region
REGION_DIALOG = '11621894586660869699'   # f345 Inline Dialog region template
LIST_PAGE_FUNCTIONS = '73054485650159247603'   # f345 list "Page Functions"
LIST_TEMPLATE = '11621967896643869739'          # f345 list template Media List (f345 CSS .cg-funcs .t-MediaList)
CSS_CLASSES = 'cg-funcs cg-funcs-drawer'
D = 'html .ui-dialog:has(> .cg-funcs-drawer)'
CSS = ''.join([
    D, '{position:fixed!important;top:0!important;bottom:0!important;left:0!important;right:auto!important;direction:rtl;text-align:right;',
    'width:min(380px,92vw)!important;max-width:92vw!important;height:100vh!important;max-height:100vh!important;',
    'margin:0!important;border:0!important;border-radius:0 16px 16px 0!important;overflow:hidden!important;',
    'box-shadow:14px 0 40px rgba(0,36,71,.22)!important;animation:cg-funcs-in .22s ease-out}',
    D, ' .ui-dialog-titlebar{height:64px;box-sizing:border-box;padding:0 20px!important;display:flex;align-items:center;',
    'border-bottom:1px solid var(--app-border-soft,#e3ebf2)}',
    D, ' .ui-dialog-title{font-size:18px;font-weight:700;color:var(--app-navy,#0e2445)}',
    D, ' > .ui-dialog-content{position:absolute!important;top:64px;bottom:0;left:0;right:0;width:auto!important;',
    'height:auto!important;max-height:none!important;overflow-y:auto!important;padding:8px 14px 18px!important}',
    D, ' > .ui-dialog-content{padding-top:0!important}',
    D, ' .cg-funcs-searchbar{position:sticky;top:0;z-index:1;background:#fff;padding:12px 0 10px}',
    D, ' .cg-funcs-search{width:100%;box-sizing:border-box;min-height:42px;padding:0 14px;border:1.5px solid var(--app-border,#d5dee8);',
    'border-radius:12px;font:inherit;font-size:15px;direction:rtl;text-align:right;outline:0}',
    D, ' .cg-funcs-search:focus{border-color:var(--app-primary,#1370b4);box-shadow:0 0 0 3px rgba(19,112,180,.15)}',
    D, ' .cg-funcs-empty{margin:18px 4px;color:#6b7c8f;text-align:center}',
    D, ' .t-MediaList-itemWrap{padding:12px 10px}',
    D, ' .t-MediaList-title{font-size:15px}',
    D, ' .t-MediaList-iconWrap .t-Icon{width:32px;height:32px;line-height:32px;font-size:15px}',
    '@keyframes cg-funcs-in{from{transform:translateX(-100%)}to{transform:none}}',
    '@media (prefers-reduced-motion:reduce){', D, '{animation:none}}'])
# search box (header) and "no function" message (footer); every text of the drawer is Arabic
HEADER = ('<div class="cg-funcs-searchbar"><input type="search" class="cg-funcs-search" autocomplete="off" '
          'placeholder="ابحث عن وظيفة…" '
          'aria-label="البحث في الوظائف"></div>')
FOOTER = '<p class="cg-funcs-empty" hidden>لا توجد وظيفة بهذا الاسم</p>'
CLOSE_TEXT = 'إغلاق'
# page 0 DA "FUNCS SEARCH" (Page Load, ONE line of Execute JavaScript Code, CLAUDE.md 4c): filters the rows while
# typing (Arabic letters normalised: alef forms, ya / alef maqsura, ta marbuta / ha), shows the empty message,
# and on every open clears the search and sets the Arabic close label. ASCII only (\u escapes).
JS = ('$(document).off(".cgFuncs").on("input.cgFuncs", "#FUNCS .cg-funcs-search", function () { '
      'var n = function (s) { return (s || "").replace(/[\u0623\u0625\u0622]/g, "\u0627").replace(/\u0649/g, "\u064A")'
      '.replace(/\u0629/g, "\u0647").replace(/\\s+/g, " ").trim(); }, s = n(this.value), any = false; '
      '$("#FUNCS .t-MediaList-item").each(function () { var ok = !s || n($(this).text()).indexOf(s) > -1; '
      '$(this).toggle(ok); any = any || ok; }); $("#FUNCS .cg-funcs-empty").prop("hidden", any); })'
      '.on("dialogopen.cgFuncs", "#FUNCS", function () { $(this).dialog("option", "closeText", "\u0625\u063A\u0644\u0627\u0642"); '
      '$(this).find(".cg-funcs-search").val("").trigger("input").trigger("focus"); });')
PAGE0_EVENT_ID = '900008000020'
PAGE0_ACTION_ID = '900009000020'
CONDITION = ('select 1 from dual where :APP_PAGE_ID <> 100000 and not exists (select 1 from APEX_APPLICATION_PAGE_ITEMS I '
             "where I.APPLICATION_ID = :APP_ID and I.PAGE_ID = :APP_PAGE_ID and I.ITEM_NAME = 'P' || :APP_PAGE_ID || '_REPORT')")
COMMENT = ('Source: Claude Code - functions menu of every page as one side drawer (user request 2026-11-24); opened by '
           'the page 0 button FUNCS, list Page Functions; Forms TMPLT / LSIDE (KEY-F9)')

def q(s):
    """PL/SQL literal; non-ASCII text as unistr (as App Builder exports it)"""
    s = s.replace("'", "''")
    if all(ord(c) < 128 for c in s):
        return "'%s'" % s
    return "unistr('%s')" % ''.join(c if ord(c) < 128 and c != '\\' else '\\%04X' % ord(c) for c in s)


def page0_region():
    """wwv_flow_api call of the page 0 region FUNCS (inserted at the end of the page_00000 block)"""
    return '\n'.join([
        'wwv_flow_api.create_page_plug(',
        ' p_id=>wwv_flow_api.id(%s)' % PAGE0_REGION_ID,
        ",p_plug_name=>unistr('\\0627\\0644\\0648\\0638\\0627\\0626\\0641')",
        ",p_region_name=>'FUNCS'",
        ',p_region_css_classes=>%s' % q(CSS_CLASSES),
        ",p_region_template_options=>'#DEFAULT#:js-dialog-size480x320'",
        ',p_component_template_options=>%s' % q('#DEFAULT#:t-MediaList--showIcons'),
        ',p_plug_template=>wwv_flow_api.id(%s)' % REGION_DIALOG,
        ',p_plug_display_sequence=>990',
        ',p_plug_header=>%s' % q('<style>%s</style>%s' % (CSS, HEADER)),
        ',p_plug_footer=>%s' % q(FOOTER),
        ",p_plug_source_type=>'NATIVE_LIST'",
        ',p_list_id=>wwv_flow_api.id(%s)' % LIST_PAGE_FUNCTIONS,
        ',p_list_template_id=>wwv_flow_api.id(%s)' % LIST_TEMPLATE,
        ',p_plug_query_num_rows=>50',
        ",p_plug_display_condition_type=>'EXISTS'",
        ',p_plug_display_when_condition=>%s' % q(CONDITION),
        ',p_plug_comment=>%s' % q(COMMENT),
        ');'])


def check_form_page(text):
    """problems: a form page export must not carry its own FUNCS region any more"""
    return ['page has its own FUNCS region (it is on page 0 now: scripts/functions_drawer.py)'] \
        if "p_region_name=>'FUNCS'" in text else []


def page0_dynamic_action():
    """wwv_flow_api calls of the page 0 DA "FUNCS SEARCH" (inserted at the end of the page_00000 block)"""
    return '\n'.join([
        'wwv_flow_api.create_page_da_event(',
        ' p_id=>wwv_flow_api.id(%s)' % PAGE0_EVENT_ID,
        ",p_name=>'FUNCS SEARCH'",
        ',p_event_sequence=>9',
        ",p_bind_type=>'bind'",
        ",p_bind_event_type=>'ready'",
        ',p_da_event_comment=>%s' % q('Source: Claude Code - search box of the functions side drawer (region FUNCS), user request 2026-11-24'),
        ');',
        'wwv_flow_api.create_page_da_action(',
        ' p_id=>wwv_flow_api.id(%s)' % PAGE0_ACTION_ID,
        ',p_event_id=>wwv_flow_api.id(%s)' % PAGE0_EVENT_ID,
        ",p_event_result=>'TRUE'",
        ',p_action_sequence=>10',
        ",p_execute_on_page_init=>'Y'",
        ",p_action=>'NATIVE_JAVASCRIPT_CODE'",
        ',p_attribute_01=>%s' % q(JS),
        ');'])
