"""Generate the mechanical sections of the Forms inventory from frmf2xml output.
Usage: python3 gen_inv.py <xml> <manual_dir> <out_md>
Manual sections are read from <manual_dir>/s01.md, s02.md, s13.md, s14.md, s15.md and notes_*.md.
"""
import sys, re, html, collections, json, os, glob
import xml.etree.ElementTree as ET

NS = '{http://xmlns.oracle.com/Forms}'
xml_path, man_dir, out_path = sys.argv[1:4]
fm = ET.parse(xml_path).getroot().find(NS + 'FormModule')


def U(s):
    return html.unescape(html.unescape(s or '')).replace('\r', '')


def cell(v):
    v = '' if v is None else str(v)
    return v.replace('|', '\\|').replace('\n', ' ').strip() or '–'


def man(name):
    p = os.path.join(man_dir, name)
    return open(p, encoding='utf-8').read().rstrip() + '\n' if os.path.exists(p) else ''


TOK_RE = re.compile(r"'(?:[^']|'')*'|--[^\n]*|/\*.*?(?:\*/|\Z)", re.S)


def strip_comments(t):
    """Remove comments in one left-to-right pass so '--' inside strings and '/*' inside line comments are handled."""
    return TOK_RE.sub(lambda m: m.group(0) if m.group(0).startswith("'") else ' ', t)


def strip_code(t):
    """Remove comments and blank out string literals."""
    return TOK_RE.sub(lambda m: "''" if m.group(0).startswith("'") else ' ', t)


BUILTINS = """ABORT_QUERY ADD_GROUP_COLUMN ADD_GROUP_ROW ADD_LIST_ELEMENT ADD_PARAMETER BELL BLOCK_MENU BREAK CALL_FORM CALL_INPUT
CALL_LOV CANCEL_REPORT_OBJECT CHECKBOX_CHECKED CHECK_RECORD_UNIQUENESS CLEAR_BLOCK CLEAR_EOL CLEAR_FORM CLEAR_ITEM CLEAR_LIST
CLEAR_MESSAGE CLEAR_RECORD CLOSE_FORM COMMIT_FORM CONVERT_OTHER_VALUE COPY COPY_REGION COUNT_QUERY CREATE_GROUP
CREATE_GROUP_FROM_QUERY CREATE_PARAMETER_LIST CREATE_QUERIED_RECORD CREATE_RECORD CREATE_TIMER CUT_REGION DBMS_ERROR_CODE
DBMS_ERROR_TEXT DEFAULT_VALUE DELETE_GROUP DELETE_GROUP_ROW DELETE_LIST_ELEMENT DELETE_PARAMETER DELETE_RECORD DELETE_TIMER
DESTROY_PARAMETER_LIST DISPATCH_EVENT DISPLAY_ERROR DISPLAY_ITEM DOWN DO_KEY DUPLICATE_ITEM DUPLICATE_RECORD EDIT_TEXTITEM
ENTER ENTER_QUERY ERASE ERROR_CODE ERROR_TEXT ERROR_TYPE EXECUTE_QUERY EXECUTE_TRIGGER EXIT_FORM FETCH_RECORDS FIND_ALERT
FIND_BLOCK FIND_CANVAS FIND_COLUMN FIND_EDITOR FIND_FORM FIND_GROUP FIND_ITEM FIND_LOV FIND_MENU_ITEM FIND_RELATION
FIND_REPORT_OBJECT FIND_TAB_PAGE FIND_TIMER FIND_VA FIND_VIEW FIND_WINDOW FIRST_RECORD FORMS_DDL FORM_FAILURE FORM_FATAL
FORM_SUCCESS GENERATE_SEQUENCE_NUMBER GET_APPLICATION_PROPERTY GET_BLOCK_PROPERTY GET_CANVAS_PROPERTY GET_FORM_PROPERTY
GET_GROUP_CHAR_CELL GET_GROUP_DATE_CELL GET_GROUP_NUMBER_CELL GET_GROUP_ROW_COUNT GET_GROUP_SELECTION GET_ITEM_INSTANCE_PROPERTY
GET_ITEM_PROPERTY GET_LIST_ELEMENT_COUNT GET_LIST_ELEMENT_LABEL GET_LIST_ELEMENT_VALUE GET_LOV_PROPERTY GET_MESSAGE
GET_PARAMETER_LIST GET_RECORD_PROPERTY GET_RELATION_PROPERTY GET_TAB_PAGE_PROPERTY GET_VIEW_PROPERTY GET_WINDOW_PROPERTY
GO_BLOCK GO_FORM GO_ITEM GO_RECORD HIDE_VIEW HIDE_WINDOW HOST ID_NULL IMAGE_SCROLL INSERT_RECORD ISSUE_ROLLBACK
ISSUE_SAVEPOINT ITEM_ENABLED LAST_RECORD LIST_VALUES LOCK_RECORD MENU_CLEAR_FIELD MESSAGE MESSAGE_CODE MESSAGE_TEXT
MESSAGE_TYPE MOVE_WINDOW NAME_IN NEW_FORM NEXT_BLOCK NEXT_FORM NEXT_ITEM NEXT_KEY NEXT_RECORD NEXT_SET OPEN_FORM PASTE_REGION
PAUSE POPULATE_GROUP POPULATE_GROUP_WITH_QUERY POPULATE_LIST POST PREVIOUS_BLOCK PREVIOUS_FORM PREVIOUS_ITEM PREVIOUS_RECORD
PRINT QUERY_PARAMETER READ_IMAGE_FILE REDISPLAY REPLACE_MENU RESET_GROUP_SELECTION RESIZE_WINDOW RETRIEVE_LIST RUN_PRODUCT
RUN_REPORT_OBJECT SCROLL_DOWN SCROLL_UP SCROLL_VIEW SELECT_ALL SELECT_RECORDS SET_ALERT_BUTTON_PROPERTY SET_ALERT_PROPERTY
SET_APPLICATION_PROPERTY SET_BLOCK_PROPERTY SET_CANVAS_PROPERTY SET_CUSTOM_PROPERTY SET_FORM_PROPERTY SET_GROUP_SELECTION
SET_ITEM_INSTANCE_PROPERTY SET_ITEM_PROPERTY SET_LOV_COLUMN_PROPERTY SET_LOV_PROPERTY SET_MENU_ITEM_PROPERTY SET_RECORD_PROPERTY
SET_RELATION_PROPERTY SET_REPORT_OBJECT_PROPERTY SET_TAB_PAGE_PROPERTY SET_TIMER SET_VA_PROPERTY SET_VIEW_PROPERTY
SET_WINDOW_PROPERTY SHOW_ALERT SHOW_EDITOR SHOW_KEYS SHOW_LOV SHOW_MENU SHOW_VIEW SHOW_WINDOW SYNCHRONIZE TERMINATE
UP UPDATE_RECORD USER_EXIT VALIDATE WEB.SHOW_DOCUMENT WRITE_IMAGE_FILE""".split()
BUILTIN_RE = re.compile(r'(?<![\w.$:])(' + '|'.join(sorted(map(re.escape, BUILTINS), key=len, reverse=True)) + r')\b', re.I)
EXTRA_KW = {'TEXT_IO': r'\bTEXT_IO\.', 'COMMIT (DB)': r'(?<![\w_])COMMIT\s*;|STANDARD\.COMMIT', 'ROLLBACK (DB)': r'\bROLLBACK\b',
            'RAISE FORM_TRIGGER_FAILURE': r'FORM_TRIGGER_FAILURE', 'SELECT ... FOR UPDATE': r'FOR\s+UPDATE\b',
            'DB link (@)': r'\w@\w'}

PU_NAMES = [p.get('Name') for p in fm.findall(NS + 'ProgramUnit')]
PU_RE = re.compile(r'(?<![\w.$:])(' + '|'.join(sorted(map(re.escape, PU_NAMES), key=len, reverse=True)) + r')\b', re.I)
DOT_RE = re.compile(r'(?<![:\w.$])([A-Za-z][\w$]*(?:\.[A-Za-z][\w$]*){1,2}|[A-Za-z]\w*\$\w+)\s*(?=\(|;)')
TABLE_ALIASES = {'ITIDT', 'ADD_CITY', 'IDT', 'I', 'STANDARD'}


def analyse(code):
    c = strip_code(code)
    b = sorted(set(m.upper() for m in BUILTIN_RE.findall(c)))
    for k, rx in EXTRA_KW.items():
        if re.search(rx, c, re.I):
            b.append(k)
    p = sorted(set(m.upper() for m in PU_RE.findall(c)))
    d = sorted(set(m.upper() for m in DOT_RE.findall(c)
                   if m.split('.')[0].upper() not in TABLE_ALIASES and not m.upper().startswith(('TEXT_IO.', 'WEB.'))
                   and m.upper() not in {x.upper() for x in PU_NAMES}))
    return b, p, d


def nlines(t):
    return len(t.splitlines()) if t else 0


def alines(t):
    """Active lines: non-blank lines left after removing comments."""
    return sum(1 for l in strip_comments(t or '').splitlines() if l.strip())


# ---------------------------------------------------------------- collect triggers
triggers = []  # dict(level, owner, name, elem)
for t in fm.findall(NS + 'Trigger'):
    triggers.append(dict(level='Form', owner='FORM', block='', e=t))
blocks = fm.findall(NS + 'Block')
for b in blocks:
    for t in b.findall(NS + 'Trigger'):
        triggers.append(dict(level='Block', owner=b.get('Name'), block=b.get('Name'), e=t))
    for it in b.findall(NS + 'Item'):
        for t in it.findall(NS + 'Trigger'):
            triggers.append(dict(level='Item', owner=b.get('Name') + '.' + it.get('Name'), block=b.get('Name'), e=t))
for tr in triggers:
    e = tr['e']
    tr['name'] = e.get('Name')
    tr['code'] = U(e.get('TriggerText'))
    tr['lines'] = nlines(tr['code'])
    tr['active'] = alines(tr['code'])
    tr['b'], tr['p'], tr['d'] = analyse(tr['code'])
pus = []
for p in fm.findall(NS + 'ProgramUnit'):
    code = U(p.get('ProgramUnitText'))
    b, c, d = analyse(code)
    c = [x for x in c if x != p.get('Name').upper()]
    pus.append(dict(name=p.get('Name'), type=p.get('ProgramUnitType'), code=code, lines=nlines(code), active=alines(code), b=b, p=c, d=d))
callers = collections.defaultdict(list)
for tr in triggers:
    for x in tr['p']:
        callers[x].append(f"{tr['owner']}.{tr['name']}" if tr['level'] != 'Form' else f"FORM.{tr['name']}")
for pu in pus:
    for x in pu['p']:
        callers[x].append('PU ' + pu['name'])

# ---------------------------------------------------------------- stats for manual sections
stats = dict(blocks=len(blocks), items=sum(len(b.findall(NS + 'Item')) for b in blocks), triggers=len(triggers),
             triggers_with_code=sum(1 for t in triggers if t['code'].strip()),
             trigger_lines=sum(t['lines'] for t in triggers), trigger_active=sum(t['active'] for t in triggers), pu=len(pus),
             pu_lines=sum(p['lines'] for p in pus), pu_active=sum(p['active'] for p in pus),
             by_level=collections.Counter(t['level'] for t in triggers),
             lov=len(fm.findall(NS + 'LOV')), rg=len(fm.findall(NS + 'RecordGroup')), canvases=len(fm.findall(NS + 'Canvas')),
             windows=len(fm.findall(NS + 'Window')), alerts=len(fm.findall(NS + 'Alert')),
             params=len(fm.findall(NS + 'ModuleParameter')), libs=len(fm.findall(NS + 'AttachedLibrary')),
             relations=len(list(fm.iter(NS + 'Relation'))), va=len(fm.findall(NS + 'VisualAttribute')))
json.dump({k: (dict(v) if isinstance(v, collections.Counter) else v) for k, v in stats.items()},
          open(os.path.join(man_dir, 'stats.json'), 'w'), indent=1)

# feature index: which trigger/PU uses risky features
feat = collections.defaultdict(list)
for src, code in [(f"{t['owner']}.{t['name']}", t['code']) for t in triggers] + [('PU ' + p['name'], p['code']) for p in pus]:
    c = strip_code(code)
    for k, rx in {'CALL_FORM': r'\bCALL_FORM\b', 'OPEN_FORM': r'\bOPEN_FORM\b', 'NEW_FORM': r'\bNEW_FORM\b',
                  'RUN_PRODUCT': r'RUN_PRODUCT', 'RUN_REPORT_OBJECT': r'RUN_REPORT_OBJECT', 'HOST': r'(?<![\w.])HOST\s*\(',
                  'TEXT_IO': r'TEXT_IO\.', 'CLIENT_': r'\bCLIENT_\w+', 'WEB.SHOW_DOCUMENT': r'WEB\.SHOW_DOCUMENT',
                  'CREATE_TIMER': r'CREATE_TIMER', 'FORMS_DDL': r'FORMS_DDL', 'COMMIT': r'(?<![\w_])COMMIT\s*;|STANDARD\.COMMIT',
                  'ROLLBACK': r'\bROLLBACK\b', 'CREATE_GROUP': r'CREATE_GROUP', 'POPULATE_GROUP': r'POPULATE_GROUP',
                  'FOR UPDATE': r'FOR\s+UPDATE', 'SET_ITEM_PROPERTY': r'SET_ITEM_PROPERTY',
                  'MAKE_FIELD_ENTRABLE': r'MAKE_FIELD_ENTRABLE', 'SET_BLOCK_PROPERTY': r'SET_BLOCK_PROPERTY',
                  'SET_WINDOW_PROPERTY': r'SET_WINDOW_PROPERTY', 'SET_APPLICATION_PROPERTY': r'SET_APPLICATION_PROPERTY',
                  'SET_MENU_ITEM_PROPERTY': r'SET_MENU_ITEM_PROPERTY', 'WIN_API': r'WIN_API_\w+|SEC_DLL\.',
                  'MCISERVICE': r'MCISERVICE', 'NEXT_RECORD/FIRST_RECORD loop': r'NEXT_RECORD|FIRST_RECORD|LAST_RECORD',
                  'SHOW_ALERT': r'SHOW_ALERT', 'DO_KEY': r'DO_KEY', 'EXECUTE_QUERY': r'EXECUTE_QUERY',
                  'SET_RECORD_PROPERTY': r'SET_RECORD_PROPERTY', 'SYNCHRONIZE': r'SYNCHRONIZE', 'EXIT_FORM': r'EXIT_FORM',
                  'GLOBAL write': r':GLOBAL\.\w+\s*:=|DEFAULT_VALUE|COPY\s*\(', 'USER/ROLE check': r'SC_USER_ROLES|SC_GROUP_ROLES|P_CLASS_CD|P_USER_TYPE|ADJ_FUNS|FUN_ITEMS'
                  }.items():
        n = len(re.findall(rx, c, re.I))
        if n:
            feat[k].append(f'{src} ({n})')
json.dump(feat, open(os.path.join(man_dir, 'features.json'), 'w'), indent=1, ensure_ascii=False)

# ---------------------------------------------------------------- write markdown
o = []
w = o.append
w(man('s00_title.md'))
w('## 1. Summary\n')
w(man('s01.md'))
w('## 2. Module header\n')
w('| Property | Value |\n|---|---|')
mh = fm.attrib
coord = fm.find(NS + 'Coordinate')
for k, v in [('Form name', mh.get('Name')), ('Title', mh.get('Title')),
             ('First navigation block', mh.get('FirstNavigationBlockName')), ('Console window', mh.get('ConsoleWindow')),
             ('Menu module (MenuModule)', mh.get('MenuModule')), ('Initial menu', mh.get('InitializeMenu') or '(empty)'),
             ('Validation unit', mh.get('ValidationUnit')),
             ('Interaction mode', mh.get('InteractionMode') or 'not in XML → Forms default (Blocking)'),
             ('Language direction', mh.get('LanguageDirection')), ('Runtime compatibility', mh.get('RuntimeComp')),
             ('Coordinate system', f"{coord.get('CoordinateSystem')} / unit {coord.get('RealUnit')} / char cell "
                                   f"{coord.get('CharacterCellWidth')}x{coord.get('CharacterCellHeight')}" if coord is not None else '–')]:
    w(f'| {k} | {cell(v)} |')
w('\nModule comment (decoded, verbatim):\n\n```text\n' + U(mh.get('Comment')) + '\n```\n')
w(man('s02.md'))

# ---- 3 blocks
w('## 3. Blocks\n')
w('> Properties absent from the XML are Forms defaults **or inherited from the object library** '
  '(`ParentModule`/`ParentName`); such values are shown as `default/OLB` (OLB properties: `forms/COMMON/olb/CIC_OLB_OLB.xml`).\n')
w('| Block | Base table / Query data source | DML target | Type | Records displayed | Records buffered | WHERE clause | ORDER BY | '
  'Insert | Update | Delete | Query | Canvas(es) | Subclassed from |\n|' + '---|' * 14)
item_canvas = {}
for b in blocks:
    canv = sorted(set(i.get('CanvasName') for i in b.findall(NS + 'Item') if i.get('CanvasName')))
    src = b.get('QueryDataSourceName')
    typ = 'base-table' if src else 'control (non-DB)'
    d = lambda k: b.get(k) if b.get(k) is not None else 'default/OLB'
    w(f"| {b.get('Name')} | {cell(src)} | {cell(b.get('DMLDataName') or (src and 'same as query source (default)'))} | {typ} | "
      f"{cell(b.get('RecordsDisplayCount') or 'default/OLB')} | {cell(b.get('RecordsBufferedCount') or 'default/OLB')} | "
      f"{cell(U(b.get('WhereClause')))} | {cell(U(b.get('OrderByClause')))} | {d('InsertAllowed')} | {d('UpdateAllowed')} | "
      f"{d('DeleteAllowed')} | {d('QueryAllowed')} | {cell(', '.join(canv))} | "
      f"{cell(b.get('ParentFilename', '') + ':' + b.get('ParentName', '') if b.get('ParentName') else '')} |")
w('')
for b in blocks:
    if b.get('Comment') and not b.get('Comment').startswith('CG$IGNORE'):
        w(f"Block `{b.get('Name')}` comment (decoded):\n\n```text\n{U(b.get('Comment'))}\n```\n")
w(man('notes_blocks.md'))

# ---- 4 items
w('## 4. Items\n')
w('> Legend: `–` = attribute not present in the XML (Forms default or inherited from the OLB property class named in '
  '"Subclass"). ItemType `–` therefore normally means *Text Item* unless the OLB class says otherwise (e.g. `CGSO$LOV_BUT` = button, '
  '`*_DO` = display-only text item).\n')
for b in blocks:
    items = b.findall(NS + 'Item')
    w(f"### 4.{blocks.index(b) + 1} Block `{b.get('Name')}` ({len(items)} items)\n")
    w('| # | Item | Item type | Subclass (OLB) | Data type | Max len | Column name | DB item | Required | LOV | Default value | '
      'Format mask | Canvas / tab page | Visible | Insert / Update / Query allowed | Prompt / label | Copy-value-from / calc | List values / hint |')
    w('|' + '---|' * 18)
    for n, it in enumerate(items, 1):
        g = it.get
        lists = '; '.join(f"{le.get('Value')}={le.get('Name')}" for le in it.findall(NS + 'ListItemElement'))
        if g('CheckedValue') or g('UncheckedValue'):
            lists = (lists + f" checked={g('CheckedValue')} unchecked={g('UncheckedValue')}").strip()
        extra = lists or g('Hint') or ''
        iuq = '/'.join(x if x else '·' for x in (g('InsertAllowed'), g('UpdateAllowed'), g('QueryAllowed')))
        canvas = (g('CanvasName') or '') + (('/' + g('TabPageName')) if g('TabPageName') else '')
        calc = g('CopyValueFromItem') or g('Formula') or g('CalculateMode') or ''
        w(f"| {n} | {g('Name')} | {cell(g('ItemType'))} | {cell(g('ParentName'))} | {cell(g('DataType'))} | {cell(g('MaximumLength'))} | "
          f"{cell(g('ColumnName'))} | {cell(g('DatabaseItem'))} | {cell(g('Required'))} | {cell(g('LovName'))} | "
          f"{cell(U(g('InitializeValue')))} | {cell(g('FormatMask'))} | {cell(canvas)} | {cell(g('Visible'))} | {iuq if iuq != '·/·/·' else '–'} | "
          f"{cell(U(g('Prompt') or g('Label')))} | {cell(calc)} | {cell(U(extra))} |")
    w('')
w(man('notes_items.md'))

# ---- 5 relations
w('## 5. Relations (master–detail)\n')
# frmf2xml nests each <Relation> inside its master <Block>, so search the whole tree and take the master from the parent.
rels = [(b, r) for b in fm.iter(NS + 'Block') for r in b.findall(NS + 'Relation')]
if rels:
    w('| Relation | Master block | Detail block | Join condition | Delete behaviour | Deferred / Auto-query | Prevent masterless operations | Subclassed from |'
      '\n|---|---|---|---|---|---|---|---|')
    for b, r in rels:
        w(f"| {r.get('Name')} | {cell(r.get('MasterBlock') or b.get('Name'))} | {cell(r.get('DetailBlock'))} | {cell(U(r.get('JoinCondition')))} | "
          f"{cell(r.get('DeleteRecordBehavior') or 'not in XML → Forms default (Non-Isolated)')} | "
          f"{cell(r.get('Deferred') or 'default (false)')}/{cell(r.get('AutoQuery') or 'default (false)')} | "
          f"{cell(r.get('PreventMasterlessOperations') or 'default (false)')} | {cell(r.get('ParentName'))} |")
    w('')
else:
    base = [b.get('Name') for b in blocks if b.get('QueryDataSourceName')]
    w(f"**None.** The XML contains 0 `<Relation>` elements. Base-table blocks: {', '.join('`%s`' % n for n in base) or 'none'}; "
      f"the other {len(blocks) - len(base)} are control blocks.\n")

# ---- 6 triggers
w('## 6. Triggers\n')
w(man('notes_triggers.md'))
w('### 6.0 Trigger index\n')
w('| # | Level | Owner | Trigger | Lines (total / active) | Exec. hierarchy | Source | Program units called |\n|---|---|---|---|---|---|---|---|')
# inherited trigger code from the object library XML (forms/COMMON/olb/<OLB>_OLB.xml), by block / item / trigger name
olb_trig = {}
for cand in glob.glob(os.path.join(os.path.dirname(os.path.abspath(xml_path)), '..', 'COMMON', 'olb', '*_OLB.xml')):
    if 'OLD' in os.path.basename(cand).upper():
        continue
    oroot = ET.parse(cand).getroot()
    for ob in oroot.iter(NS + 'Block'):
        for ot in ob.findall(NS + 'Trigger'):
            olb_trig.setdefault((ob.get('Name'), ot.get('Name')), ot)
        for oi in ob.findall(NS + 'Item'):
            for ot in oi.findall(NS + 'Trigger'):
                olb_trig.setdefault((ob.get('Name') + '.' + oi.get('Name'), ot.get('Name')), ot)
    for ot in oroot.iter(NS + 'Trigger'):
        olb_trig.setdefault(('*', ot.get('Name')), ot)


def olb_source(t):
    e = t['e']
    owner = t['owner']
    key = (e.get('ParentName') if owner == 'FORM' else owner, t['name']) if owner != 'FORM' else ('*', e.get('ParentName') or t['name'])
    ot = olb_trig.get(key)
    code = U(ot.get('TriggerText')) if ot is not None else ''
    if not code.strip():
        return None
    first = next((x.strip() for x in code.split('\n') if x.strip() and not x.strip().startswith('--')), '')
    return 'OLB code (%d lines): `%s`' % (len(code.split('\n')), first[:60].replace('|', '\\|'))


for n, t in enumerate(triggers, 1):
    e = t['e']
    inherited = olb_source(t) if not t['code'].strip() else None
    src = 'XML' if t['code'].strip() else (inherited or ('MISSING SOURCE (OLB ' + (e.get('ParentName') or e.get('ParentFilename') or 'parent') + ')'
                                            if e.get('ParentModule') or e.get('SubclassSubObject') else 'EMPTY (no text in XML)'))
    t['src'] = src
    w(f"| {n} | {t['level']} | {t['owner']} | {t['name']} | {t['lines']} / {t['active']} | {cell(e.get('ExecuteHierarchy') or 'default (Override)')} | "
      f"{src} | {cell(', '.join(t['p']))} |")
w('')
sec = {'Form': '6.1 Form-level triggers', 'Block': '6.2 Block-level triggers', 'Item': '6.3 Item-level triggers'}
for lvl in ('Form', 'Block', 'Item'):
    w(f'### {sec[lvl]}\n')
    for t in [x for x in triggers if x['level'] == lvl]:
        if not t['code'].strip():
            continue
        e = t['e']
        w(f"#### {t['owner']} · {t['name']}\n")
        w(f"- Level: {lvl} · Owner: `{t['owner']}` · Execution hierarchy: {e.get('ExecuteHierarchy') or 'default (Override)'}"
          f"{' · Fire in query: ' + e.get('FireInQuery') if e.get('FireInQuery') else ''}"
          f"{' · Subclassed from ' + e.get('ParentFilename', '') + ':' + (e.get('ParentName') or '') if e.get('ParentModule') else ''}")
        w(f"- Lines: {t['lines']} total / {t['active']} active (non-blank, non-comment)")
        w(f"- Built-ins: {', '.join(t['b']) or '–'}")
        w(f"- Program units (form): {', '.join(t['p']) or '–'}")
        w(f"- Library / DB package calls: {', '.join(t['d']) or '–'}\n")
        w('```plsql\n' + t['code'].rstrip() + '\n```\n')
    empt = [x for x in triggers if x['level'] == lvl and not x['code'].strip()]
    if empt:
        grp = collections.Counter((x['block'], x['name'], x['src']) for x in empt)
        w(f'Triggers of this level without code in the XML ({len(empt)}):\n')
        w('| Block | Trigger | Count | Source status | Owners |\n|---|---|---|---|---|')
        for (bk, nm, s), c in grp.items():
            owners = [x['owner'] for x in empt if (x['block'], x['name'], x['src']) == (bk, nm, s)]
            ow = ', '.join(owners) if len(owners) <= 6 else f"{owners[0]} … {owners[-1]}"
            w(f'| {bk or "FORM"} | {nm} | {c} | {s} | {ow} |')
        w('')

# ---- 7 LOVs
w('## 7. LOVs & Record Groups\n')
rgs = {r.get('Name'): r for r in fm.findall(NS + 'RecordGroup')}
lov_users = collections.defaultdict(list)
for b in blocks:
    for it in b.findall(NS + 'Item'):
        if it.get('LovName'):
            lov_users[it.get('LovName')].append(b.get('Name') + '.' + it.get('Name'))
w('| LOV | Title | Record group | Return items (column → item) | Attached to items | Validate from list | Auto-display |\n|---|---|---|---|---|---|---|')
for lv in fm.findall(NS + 'LOV'):
    maps = '; '.join(f"{m.get('Name')} → {m.get('ReturnItem') or '(not returned)'}" for m in lv.findall(NS + 'LOVColumnMapping'))
    w(f"| {lv.get('Name')} | {cell(lv.get('Title'))} | {lv.get('RecordGroupName')} | {cell(maps)} | {cell(', '.join(lov_users[lv.get('Name')]))} | "
      f"not in XML (item property `ValidateFromList` absent → default/OLB) | {cell(lv.get('AutoDisplay') or 'default/OLB')} |")
w('\n### 7.1 Record groups\n')
used = {lv.get('RecordGroupName') for lv in fm.findall(NS + 'LOV')}
for name, r in rgs.items():
    cols = ', '.join(f"{c.get('Name')} {c.get('ColumnDataType') or ''}({c.get('MaximumLength') or ''})" for c in r.findall(NS + 'RecordGroupColumn'))
    w(f"#### {name}\n- Type: {r.get('RecordGroupType') or 'Query'} · Attached to LOV: {'yes' if name in used else 'NO'}"
      f"{' · Comment: ' + r.get('Comment') if r.get('Comment') else ''}\n- Columns: {cols or '–'}")
    if r.get('RecordGroupQuery'):
        w('\n```sql\n' + U(r.get('RecordGroupQuery')).rstrip() + '\n```\n')
    rows = r.findall(NS + 'RecordGroupColumnRow') + [x for c in r.findall(NS + 'RecordGroupColumn') for x in c]
    if rows:
        w('- Static values: ' + '; '.join(cell(json.dumps(x.attrib, ensure_ascii=False)) for x in rows) + '\n')
    w('')
w(man('notes_lov.md'))

# ---- 8 canvases
w('## 8. Canvases & Windows\n')
w('| Canvas | Type | Window | Size (W×H) | Viewport | Tab pages | Items shown | Subclassed from |\n|---|---|---|---|---|---|---|---|')
for cv in fm.findall(NS + 'Canvas'):
    its = [b.get('Name') + '.' + i.get('Name') for b in blocks for i in b.findall(NS + 'Item') if i.get('CanvasName') == cv.get('Name')]
    tabs = ', '.join(tp.get('Name') for tp in cv.findall(NS + 'TabPage')) or '–'
    w(f"| {cv.get('Name')} | {cv.get('CanvasType') or 'Content (default) / OLB'} | {cell(cv.get('WindowName') or 'default/OLB')} | "
      f"{cell((cv.get('Width') or '?') + '×' + (cv.get('Height') or '?') if cv.get('Width') else '')} | "
      f"{cell((cv.get('ViewportWidth') or '') + '×' + (cv.get('ViewportHeight') or '') if cv.get('ViewportHeight') else '')} | {tabs} | "
      f"{len(its)}: {cell(', '.join(i.split('.', 1)[1] for i in its))} | {cell(cv.get('ParentFilename', '') + ':' + cv.get('ParentName', ''))} |")
w('\n| Window | Modal | Title | Size | Subclassed from |\n|---|---|---|---|---|')
for wd in fm.findall(NS + 'Window'):
    w(f"| {wd.get('Name')} | {cell(wd.get('Modal') or 'default/OLB')} | {cell(wd.get('Title'))} | "
      f"{cell((wd.get('Width') or '') + '×' + (wd.get('Height') or '') if wd.get('Width') else 'default/OLB')} | "
      f"{cell(wd.get('ParentFilename', '') + ':' + wd.get('ParentName', ''))} |")
w('\nGraphics objects on canvases (boilerplate, from XML):\n\n| Canvas | Name | Type | Subclassed from |\n|---|---|---|---|')
for cv in fm.iter(NS + 'Canvas'):
    for g in cv.iter(NS + 'Graphics'):
        w(f"| {cv.get('Name')} | {g.get('Name')} | {cell(g.get('GraphicsType') or 'not in XML (OLB sub-object)')} | {cell(((g.get('ParentFilename') or '') + ':' + g.get('ParentName')) if g.get('ParentName') else '')} |")
w('')
w(man('notes_canvas.md'))

# ---- 9 program units
w('## 9. Program Units\n')
w('| # | Name | Type | Lines (total / active) | Called by | Uses built-ins | Calls (form PUs) | Library / DB calls |\n|---|---|---|---|---|---|---|---|')
for n, p in enumerate(pus, 1):
    cb = callers.get(p['name'].upper(), [])
    w(f"| {n} | {p['name']} | {p['type']} | {p['lines']} / {p['active']} | {cell(', '.join(sorted(set(cb))) or 'not referenced in XML code')} | "
      f"{cell(', '.join(p['b']))} | {cell(', '.join(p['p']))} | {cell(', '.join(p['d']))} |")
w('')
for p in pus:
    w(f"### PU {p['name']} ({p['type']}, {p['lines']} lines)\n")
    w('```plsql\n' + p['code'].rstrip() + '\n```\n')

# ---- 10 external deps
w('## 10. External Dependencies\n')
w('### 10.1 Attached libraries\n\n| Library | Location | Source |\n|---|---|---|')
for l in fm.findall(NS + 'AttachedLibrary'):
    w(f"| {l.get('Name')} | {l.get('LibraryLocation')} | {l.get('LibrarySource')} |")
w('')
allcode = [(f"{t['owner']}.{t['name']}", t['code']) for t in triggers] + [('PU ' + p['name'], p['code']) for p in pus]
dotted = collections.defaultdict(set)
for src, code in allcode:
    for d in analyse(code)[2]:
        dotted[d].add(src)
w('### 10.2 Package-qualified calls found in the code (library or database — classification in 10.3)\n')
w('| Call | Count of callers | Callers |\n|---|---|---|')
for d in sorted(dotted):
    s = sorted(dotted[d])
    w(f"| {d} | {len(s)} | {cell(', '.join(s) if len(s) <= 8 else ', '.join(s[:8]) + f' … (+{len(s) - 8})')} |")
w('')
w(man('s10.md'))
cf = []
for src, code in allcode:
    for m in re.finditer(r'\b(CALL_FORM|OPEN_FORM|NEW_FORM)\s*\(([^;]*?)\)\s*;', strip_comments(code), re.I | re.S):
        cf.append((src, m.group(1).upper(), re.sub(r'\s+', ' ', m.group(2))))
w('### 10.4 Called forms\n\n| Caller | Built-in | Arguments (verbatim) | ADD_PARAMETER calls in the same unit (name, type, value) |\n|---|---|---|---|')
srccode = dict(allcode)
for src, b, a in cf:
    prm = re.findall(r"ADD_PARAMETER\s*\(\s*\w+\s*,\s*'([^']+)'\s*,\s*(\w+)\s*,\s*([^;]*?)\)\s*;", strip_comments(srccode[src]), re.I | re.S)
    ps = '; '.join(f"{n} {t} = {re.sub(chr(92) + 's+', ' ', v)}" for n, t, v in dict(((x[0].upper(), x) for x in prm)).values())
    w(f'| {src} | {b} | `{cell(a)}` | {cell(ps)} |')
w('')
tabs = collections.defaultdict(set)
NOT_TAB = re.compile(r'^(V_|P_|L_|RET$|X$|THE$|REC_|MSG_COUNT$|STRING_RESULT$|BUS_ID_COUNT$|IMPR_SEQ$)', re.I)
for src, code in allcode:
    c = strip_code(code)
    for m in re.finditer(r'\bFROM\s+(.*?)(?=\bWHERE\b|\bGROUP\b|\bORDER\b|\bCONNECT\b|\bUNION\b|;|\)|\bINTO\b|$)', c, re.I | re.S):
        for part in m.group(1).split(','):
            tok = part.strip().split()
            if tok and re.match(r'^[A-Za-z][\w$#.]*$', tok[0]) and not NOT_TAB.match(tok[0]):
                tabs[tok[0].upper()].add(src + ' (SELECT)')
    for kw, rx in (('INSERT', r'\bINSERT\s+INTO\s+([A-Za-z][\w$#.]*)'), ('UPDATE', r'(?<![\w_])UPDATE\s+([A-Za-z][\w$#.]*)\s+SET\b'),
                   ('DELETE', r'\bDELETE\s+(?:FROM\s+)?([A-Za-z][\w$#.]*)')):
        for m in re.finditer(rx, c, re.I):
            if not NOT_TAB.match(m.group(1)):
                tabs[m.group(1).upper()].add(f'{src} ({kw})')
w(f'### 10.5 Database tables / views referenced in SQL ({len(tabs)})\n')
w('Extracted from active (non-comment) code. Record-group queries are listed in section 7.\n')
w('| Object | DML used | Referenced in |\n|---|---|---|')
for tname in sorted(tabs):
    kinds = sorted({x.rsplit('(', 1)[1].rstrip(')') for x in tabs[tname]})
    srcs = sorted({x.rsplit(' (', 1)[0] for x in tabs[tname]})
    w(f"| {tname} | {', '.join(kinds)} | {cell(', '.join(srcs) if len(srcs) <= 8 else ', '.join(srcs[:8]) + f' … (+{len(srcs) - 8})')} |")
w('')
w(man('s10b.md'))

# ---- 11 alerts
w('## 11. Alerts\n')
alert_use = collections.defaultdict(list)
for src, code in allcode:
    for a in fm.findall(NS + 'Alert'):
        if re.search(r"['\"]" + re.escape(a.get('Name')) + r"['\"]", code, re.I):
            alert_use[a.get('Name')].append(src)
# object library next to the form sources (forms/COMMON/olb/<OLB>_OLB.xml): resolves inherited alerts
olb_alerts = {}
for cand in glob.glob(os.path.join(os.path.dirname(os.path.abspath(xml_path)), '..', 'COMMON', 'olb', '*_OLB.xml')):
    if 'OLD' in os.path.basename(cand).upper():
        continue
    for oa in ET.parse(cand).getroot().iter(NS + 'Alert'):
        olb_alerts.setdefault((os.path.basename(cand).upper().replace('_OLB.XML', ''), oa.get('Name')), oa)
w('| Alert | Style | Title | Message | Buttons | Where used (by literal name) | Source |\n|---|---|---|---|---|---|---|')
for a in fm.findall(NS + 'Alert'):
    own = a.get
    lib = olb_alerts.get(((a.get('ParentModule') or '').upper(), a.get('ParentName') or a.get('Name')))
    g = (lambda k, own=own, lib=lib: own(k) or (lib.get(k) if lib is not None else None))
    w(f"| {g('Name')} | {cell(g('AlertStyle') or 'MISSING SOURCE')} | {cell(U(g('Title')) or ('–' if lib is not None else 'MISSING SOURCE'))} | {cell(U(g('AlertMessage')) or ('(set at runtime)' if lib is not None else 'MISSING SOURCE'))} | "
      f"{cell('/'.join(U(x) for x in (g('Button1Label'), g('Button2Label'), g('Button3Label')) if x) or 'MISSING SOURCE')} | "
      f"{cell(', '.join(alert_use[g('Name')]) or 'not referenced by literal name')} | {g('ParentFilename')}:{g('ParentName')}{' (resolved from the OLB XML)' if lib is not None else ''} |")
w('')
w(man('notes_alerts.md'))

# ---- 12 params & globals
w('## 12. Parameters & Globals\n')
w('| Parameter | Data type | Default | Subclassed from | Where used |\n|---|---|---|---|---|')
for p in fm.findall(NS + 'ModuleParameter'):
    nm = p.get('Name')
    users = sorted({src for src, code in allcode if re.search(r':PARAMETER\.' + re.escape(nm) + r'\b', code, re.I)})
    w(f"| {nm} | {cell(p.get('ParameterDataType') or 'default (CHAR) / OLB')} | {cell(U(p.get('ParameterInitializeValue')) if p.get('ParameterInitializeValue') is not None else 'default/OLB')} | "
      f"{cell(p.get('ParentName'))} | {cell(', '.join(users) if len(users) <= 10 else ', '.join(users[:10]) + f' … (+{len(users) - 10})') or 'not referenced'} |")
w('')
gl = collections.defaultdict(lambda: [set(), set()])
for src, code in allcode:
    c = strip_comments(code)
    for m in re.finditer(r':GLOBAL\.([\w$#]+)(\s*:=)?', c, re.I):
        gl[m.group(1).upper()][1 if m.group(2) else 0].add(src)
    for m in re.finditer(r"(DEFAULT_VALUE|COPY)\s*\([^;]*?'GLOBAL\.([\w$#]+)'", c, re.I | re.S):
        gl[m.group(2).upper()][1].add(src + ' (' + m.group(1).upper() + ')')
    for m in re.finditer(r"(NAME_IN|ERASE)\s*\(\s*'GLOBAL\.([\w$#]+)'", c, re.I):
        gl[m.group(2).upper()][0 if m.group(1).upper() == 'NAME_IN' else 1].add(src + ' (' + m.group(1).upper() + ')')
w(f'### 12.1 :GLOBAL variables ({len(gl)})\n\n| Global | Read in | Written in |\n|---|---|---|')
short = lambda s: ', '.join(sorted(s)) if len(s) <= 6 else ', '.join(sorted(s)[:6]) + f' … (+{len(s) - 6})'
for g in sorted(gl):
    w(f'| {g} | {cell(short(gl[g][0]))} | {cell(short(gl[g][1]))} |')
sy = collections.defaultdict(set)
for src, code in allcode:
    for m in re.finditer(r':SYSTEM\.([\w$]+)', strip_comments(code), re.I):
        sy[m.group(1).upper()].add(src)
w(f'\n### 12.2 :SYSTEM variables ({len(sy)})\n\n| Variable | Used in |\n|---|---|')
for s in sorted(sy):
    w(f'| {s} | {cell(short(sy[s]))} |')
w('')
w(man('notes_params.md'))

w('## 13. Menu & Security\n')
w(man('s13.md'))
w('## 14. Risk Assessment\n')
w(man('s14.md'))
w('## 15. Open Questions / Missing Sources\n')
w(man('s15.md'))
open(out_path, 'w', encoding='utf-8').write('\n'.join(o))
print('written', out_path, sum(1 for _ in open(out_path)), 'lines')
print(json.dumps({k: (dict(v) if isinstance(v, collections.Counter) else v) for k, v in stats.items()}))
