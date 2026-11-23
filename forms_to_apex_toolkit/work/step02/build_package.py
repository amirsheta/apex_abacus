"""
build_package.py - step 02 rev 2: build package LIB_APX_USR.IMPR1110 (f345 standard, CLAUDE.md §4c).

Source : rollback/IMPR1110/step02_rev1/impr1110_spec.sql + impr1110_body.sql  (converted trigger logic, record based)
Output : plsql/IMPR1110/impr1110_spec.sql, plsql/IMPR1110/impr1110_body.sql

What it does
 1. keeps the converted Forms logic (record based) as PRIVATE code, in its Forms order, with forward declarations;
    UI-recorder calls (ui / entrable / ui_focus / ...) become "NULL; -- APEX: ..." (rules: read_only_rules.md)
 2. drops the session-state adapter, the UI recorder, the old entry points and the Forms default INSERT / UPDATE
    (APEX native Form DML replaces them)
 3. adds the read-only / required / visible rule functions (read_only_rules.md)
 4. generates every APEX entry point with IN / IN OUT parameters = exactly the items its logic reads / writes
 6. names the parameters by the project rule (scripts/parameter_names.py, version 008): no I_ / IO_ / O_ prefix,
    page item P<page>_X -> P_X, application items unchanged; parameters qualified with the member name inside SQL
 5. writes the spec in the f345 §10 section order
Re-run after changing the rules or the entry table. Usage: python3 -I work/step02/build_package.py
"""
import re, json, collections, sys, os
sys.path.insert(0, 'scripts')
import parameter_names

SRC_SPEC = 'rollback/IMPR1110/step02_rev1/impr1110_spec.sql'
SRC_BODY = 'rollback/IMPR1110/step02_rev1/impr1110_body.sql'
OUT_SPEC = 'plsql/IMPR1110/impr1110_spec.sql'
OUT_BODY = 'plsql/IMPR1110/impr1110_body.sql'
DATE = '23-11-2026'
PAGE = 'P1110_'

spec_src = open(SRC_SPEC, encoding='utf-8').read()
body_src = open(SRC_BODY, encoding='utf-8').read()

# ------------------------------------------------------------------ parse source members
def parse_members(text):
    lines = text.split('\n')
    out, cur = [], None
    for i, l in enumerate(lines):
        d = re.match(r'^    (PROCEDURE|FUNCTION)\s+([A-Za-z0-9_$#]+)', l)
        if d and cur is None:
            # include the comment lines directly above
            j = i
            while j > 0 and re.match(r'^    --', lines[j - 1]):
                j -= 1
            cur = dict(kind=d.group(1), name=d.group(2).upper(), start=j, decl=i)
        if cur is not None:
            e = re.match(r'^    END\s+([A-Za-z0-9_$#]+)\s*;', l)
            if e and e.group(1).upper() == cur['name']:
                cur['end'] = i
                cur['text'] = '\n'.join(lines[cur['start']:i + 1])
                hdr = '\n'.join(lines[cur['decl']:i + 1])
                m = re.match(r'(?is)(\s*(?:PROCEDURE|FUNCTION)\s+\S+.*?)\s+(IS|AS)\b', hdr)
                cur['header'] = m.group(1).strip()
                out.append(cur)
                cur = None
    return out

members = parse_members(body_src)
by_name = collections.OrderedDict()
for m in members:
    by_name.setdefault(m['name'], []).append(m)

# record / context type text and field types (from the source spec)
def block_between(text, start_pat):
    m = re.search(start_pat + r'(.*?)\n\s*\);', text, re.S)
    return m.group(0)
t_record_txt = block_between(spec_src, r'(?s)\n\s*-- [^\n]*\n\s*TYPE T_RECORD IS RECORD \(')
t_context_txt = block_between(spec_src, r'(?s)\n\s*TYPE T_CONTEXT IS RECORD \(')
def fields(txt):
    f = collections.OrderedDict()
    for l in txt.split('\n'):
        m = re.match(r'\s*([a-z_0-9]+)\s+([A-Za-z0-9_.%()]+(?:\(\d+\))?)\s*,?\s*(--.*)?$', l)
        if m and m.group(1).upper() not in ('TYPE',):
            f[m.group(1).upper()] = m.group(2).rstrip(',')
    return f
REC = fields(t_record_txt)
CTX = fields(t_context_txt)
assert 'IMPR_NBR' in REC and 'CURR_PORT_CD' in CTX, 'record parse failed'

# ------------------------------------------------------------------ what is kept / dropped
DROP = {
    # UI recorder (replaced by the rule functions)
    'UI_RESET', 'UI', 'ENTRABLE', 'UI_FOCUS', 'UI_JSON', 'UI_COUNT', 'UI_ENTRY',
    'TYPE_ENTRABLE_QUERY', 'LOCK_KEY_ITEMS', 'CR_FIELDS_ENTRABLE',
    # Forms default DML -> APEX native Form DML
    'IMPORTERS_INSERT', 'IMPORTERS_UPDATE',
    # PRE-QUERY -> WHERE clause of the search page <page>01
    'IMPORTERS_PRE_QUERY',
}
REMOVED_CALLS = {'UI_RESET', 'UI', 'ENTRABLE', 'UI_FOCUS', 'TYPE_ENTRABLE_QUERY', 'LOCK_KEY_ITEMS', 'CR_FIELDS_ENTRABLE'}
# rev1 section markers: everything after these banners is adapter / old entry code
cut = body_src.find('SESSION-STATE ADAPTER (formerly package IMPR1110_APX')
cut_line = body_src[:cut].count('\n')
logic = [m for m in members if m['decl'] < cut_line and m['name'] not in DROP and m['name'] != 'PKG_VERSION']
logic_names = set(m['name'] for m in logic)

def strip_code(t):
    t = re.sub(r'--[^\n]*', '', t)
    return re.sub(r"'(?:[^']|'')*'", "''", t)

def transform(text):
    out = []
    n_removed = 0
    for l in text.split('\n'):
        m = re.match(r'^(\s*)(%s)\b\s*(\(.*\))?\s*;\s*(--.*)?$' % '|'.join(sorted(REMOVED_CALLS, key=len, reverse=True)), l, re.I)
        if m:
            out.append('%sNULL;  -- APEX (read_only_rules.md): %s%s;' % (m.group(1), m.group(2), m.group(3) or ''))
            n_removed += 1
        else:
            out.append(l)
    t = '\n'.join(out)
    left = re.findall(r'(?im)^(?!\s*--)[^\n]*\b(%s)\s*\(' % '|'.join(REMOVED_CALLS), strip_code(t))
    return t, n_removed, left

logic_text, removed_total, leftovers = [], 0, []
for m in logic:
    t, n, left = transform(m['text'])
    removed_total += n
    leftovers += [(m['name'], x) for x in left]
    logic_text.append((m, t))
if leftovers:
    sys.exit('UI calls not removed (multi-line?): %s' % leftovers[:10])

# INFO: messages go to APEX (no message list in the package)
INFO_NEW = '''    -- MESSAGE / STR.DispAlert(..., 'INFORMATION') that does not stop the trigger
    PROCEDURE INFO (p_text IN VARCHAR2)
    IS
    BEGIN
        FORMS_APX.MESSAGE(p_text);
    END INFO;'''
logic_text = [(m, INFO_NEW if m['name'] == 'INFO' else t) for m, t in logic_text]

# ------------------------------------------------------------------ call graph -> transitive field usage
def into_fields(c):
    """record fields filled by SELECT / FETCH / RETURNING ... INTO p_rec.a, p_rec.b"""
    out = set()
    for m in re.finditer(r'(?is)\bINTO\s+((?:p_rec\.\w+\s*,\s*)*p_rec\.\w+)', c):
        out |= set(f.upper() for f in re.findall(r'p_rec\.(\w+)', m.group(1)))
    return out
info = {}
for m, t in logic_text:
    c = strip_code(t)
    info[m['name']] = dict(
        read=set(f.upper() for f in re.findall(r'\bp_rec\.(\w+)', c, re.I)),
        write=set(f.upper() for f in re.findall(r'\bp_rec\.(\w+)\s*:=', c, re.I)) | into_fields(c),
        ctx=set(f.upper() for f in re.findall(r'\bp_ctx\.(\w+)', c, re.I)),
        ctxw=set(f.upper() for f in re.findall(r'\bp_ctx\.(\w+)\s*:=', c, re.I)),
        calls=set(x.upper() for x in re.findall(r'(?<![\w.$#])([A-Za-z][A-Za-z0-9_$#]*)\s*\(', c) if x.upper() in logic_names) |
              set(x.upper() for x in re.findall(r'(?<![\w.$#])([A-Za-z][A-Za-z0-9_$#]*)\s*;', c) if x.upper() in logic_names))
def closure(names):
    seen, stack = set(), list(names)
    r, w, cx, cw = set(), set(), set(), set()
    while stack:
        n = stack.pop()
        if n in seen or n not in info: continue
        seen.add(n)
        i = info[n]; r |= i['read']; w |= i['write']; cx |= i['ctx']; cw |= i['ctxw']
        stack += list(i['calls'])
    return r, w, cx, cw

# ------------------------------------------------------------------ parameter naming
CTX_ITEM = {'CURR_PORT_CD': 'P_CURR_PORT_CD', 'USER_ID': 'SSO_APP_USER', 'WS_ID': 'P_GLOBAL_V_WS_ID',
            'CLASS_CD': 'P_CLASS_CD', 'USER_TYPE': 'V_USR_TYPE', 'PRSNL_IMPR': PAGE + 'P_PRSNL_IMPR',
            'LETTER_NBR': PAGE + 'P_LETTER_NBR', 'CODE': PAGE + 'P_CODE', 'BRKR_PORT_CD': 'P_BRKR_PORT_CD',
            'LIC_TYPE': 'P_LIC_TYPE', 'BRKR_NBR': 'P_BRKR_NBR'}
CONTROL = {'ROW_ID', 'REC_STATUS', 'ACTIVITY_ENTR', 'BUS_ID_BRNCH_ENTR'}
def rec_type(f):
    return REC[f]
def ctx_type(f):
    return CTX[f]

# ------------------------------------------------------------------ entry table
# Each entry: the converted logic it runs, in Forms firing order. Parameters are computed from
# what that logic (and everything it calls) reads / writes: I_ = read, IO_ = read and written.
ITEMS = collections.OrderedDict([
    # item: (POST-CHANGE call or None, WHEN-VALIDATE-ITEM call)    {F} = p_from_item, {A} / {S} = answers
    ('PORT_CD',         (None, 'PORT_CD_WHEN_VALIDATE_ITEM(r);')),
    ('HQ_IMPR_NBR',     ('HQ_IMPR_NBR_POST_CHANGE;', None)),
    ('IMPR_NBR',        (None, 'IMPR_NBR_WHEN_VALIDATE_ITEM(r);')),
    ('IMPR_TYPE_CD',    ('IMPR_TYPE_CD_POST_CHANGE(r);', 'IMPR_TYPE_CD_VALIDATE_ITEM(r, c);')),
    ('BUS_ID_EXPRD_DT', (None, 'BUS_ID_EXPRD_DT_VALIDATE_ITEM(r, {F});')),
    ('BUS_ID_TYPE_CD',  ('BUS_ID_TYPE_CD_POST_CHANGE(r);', None)),
    ('CITY_CODE_OF_ID', (None, 'CITY_CODE_OF_ID_VALIDATE_ITEM(r);')),
    ('BUS_ID',          ('BUS_ID_POST_CHANGE;', 'BUS_ID_WHEN_VALIDATE_ITEM(r, c, {A}, {S});')),
    ('BRNH_CITY_CD',    (None, 'BRNH_CITY_CD_VALIDATE_ITEM(r);')),
    ('BUS_ID_BRNCH',    ('BUS_ID_BRNCH_POST_CHANGE;', 'BUS_ID_BRNCH_VALIDATE_ITEM(r, c, {A});')),
    ('CTRY_CD',         (None, 'CTRY_CD_WHEN_VALIDATE_ITEM(r);')),
    ('IMPR_EXPR_TYPE',  ('IMPR_EXPR_TYPE_POST_CHANGE;', None)),
    ('ARBC_IMPR_NAME',  (None, 'ARBC_IMPR_NAME_VALIDATE_ITEM(r);')),
    ('ENG_IMPR_NAME',   (None, 'ENG_IMPR_NAME_VALIDATE_ITEM(r);')),
    ('BUS_ID_ISSUE_DT', (None, 'BUS_ID_ISSUE_DT_VALIDATE_ITEM(r, {F});')),
    ('IMPR_NBR_PARENT', (None, 'IMPR_NBR_PARENT_VALIDATE_ITEM(r);')),
    ('ADD_CTRY_CD',     (None, 'ADD_CTRY_CD_WHEN_VALIDATE_ITEM(r);')),
    ('CITY_CODE',       (None, 'CITY_CODE_WHEN_VALIDATE_ITEM(r);')),
    ('IMPR_TEL_NBR',    (None, 'IMPR_TEL_NBR_VALIDATE_ITEM(r);')),
    ('B_EMAIL',         ('B_EMAIL_POST_CHANGE(r, c);', 'B_EMAIL_WHEN_VALIDATE_ITEM(r, {F});')),
    ('EMAIL',           (None, 'EMAIL_WHEN_VALIDATE_ITEM(r, {F});')),
    ('B_MOBILE_NO',     ('B_MOBILE_NO_POST_CHANGE(r, c);', 'B_MOBILE_NO_WHEN_VALIDATE_ITEM(r, c);')),
    ('BANK_IBAN',       (None, 'BANK_IBAN_WHEN_VALIDATE_ITEM(r);')),
    ('B_ID_NBR',        ('B_ID_NBR_POST_CHANGE(r, c);', 'B_ID_NBR_WHEN_VALIDATE_ITEM(r);')),
    ('CTRY_CD_OF_ID',   (None, 'CTRY_CD_OF_ID_VALIDATE_ITEM(r);')),
])
ANSWER = 'NVL(I_%sANSWER, c_yes)' % PAGE
SUSPEND = 'NVL(I_%sSUSPEND_ANSWER, c_yes)' % PAGE

def short(name):
    if len(name) <= 30: return name
    for a, b in (('_WHEN_VALIDATE_ITEM', '_VALIDATE_ITEM'), ('_VALIDATE_ITEM', '_VALIDATE')):
        if name.endswith(a) and len(name[:-len(a)] + b) <= 30: return name[:-len(a)] + b
    sys.exit('name too long: ' + name)

entries = []
def add(section, name, kind, source, apex, stmts, rec_status=None, ret=None, extra=None,
        no_ctx_write=(), prefix=PAGE, text_function=False):
    entries.append(dict(section=section, name=short(name), kind=kind, source=source, apex=apex, stmts=stmts,
                        rec_status=rec_status, ret=ret, extra=extra or [], no_ctx_write=set(no_ctx_write),
                        prefix=prefix, text_function=text_function))

add('FORM LEVEL', 'WHEN_NEW_FORM_INSTANCE', 'P', 'IMPR1110.WHEN-NEW-FORM-INSTANCE (business part)',
    'Process "WHEN-NEW-FORM-INSTANCE" (Before Header, first page view)', ['WHEN_NEW_FORM_INSTANCE(r, c);'])
add('BLOCK IMPORTERS - query', 'POST_QUERY', 'P',
    'IMPORTERS.POST-QUERY, after the POST-CHANGE triggers Forms fires for the fetched items',
    'Process "POST-QUERY" (Before Header, after "Initialize form IMPORTERS"; :P0_PAGE_PK is not null)',
    ['IF r.hq_impr_nbr IS NOT NULL THEN HQ_IMPR_NBR_POST_CHANGE; END IF;',
     'IF r.impr_type_cd IS NOT NULL THEN IMPR_TYPE_CD_POST_CHANGE(r); END IF;',
     'IF r.bus_id_type_cd IS NOT NULL THEN BUS_ID_TYPE_CD_POST_CHANGE(r); END IF;',
     'IF r.bus_id IS NOT NULL THEN BUS_ID_POST_CHANGE; END IF;',
     'IF r.bus_id_brnch IS NOT NULL THEN BUS_ID_BRNCH_POST_CHANGE; END IF;',
     'IF r.impr_expr_type IS NOT NULL THEN IMPR_EXPR_TYPE_POST_CHANGE; END IF;',
     'IMPORTERS_POST_QUERY(r, c);'], rec_status='QUERY')
add('BLOCK IMPORTERS - record', 'WHEN_CREATE_RECORD', 'P', 'IMPORTERS.WHEN-CREATE-RECORD',
    'Process "WHEN-CREATE-RECORD" (Before Header, :P0_PAGE_PK is null)', ['IMPORTERS_WHEN_CREATE_RECORD(r, c);'], rec_status='NEW')
add('BLOCK IMPORTERS - record', 'WHEN_NEW_RECORD_INSTANCE', 'P',
    'IMPORTERS.PRE-RECORD + WHEN-NEW-RECORD-INSTANCE (function modes F1..F5, SF6; type-19 rule without COMMIT)',
    'Process "WHEN-NEW-RECORD-INSTANCE" (Before Header, after POST-QUERY / WHEN-CREATE-RECORD); '
    'FOS after a function (Confirm with NEW_RECORD_CONFIRM_TEXT first)',
    ['IMPORTERS_PRE_RECORD(r, c);', 'IMPORTERS_NEW_RECORD_INSTANCE(r, c, %s);' % ANSWER],
    no_ctx_write=['CODE'])
add('BLOCK IMPORTERS - record', 'NEW_RECORD_CONFIRM_TEXT', 'F',
    'IMPORTERS.WHEN-NEW-RECORD-INSTANCE, question of IMPR1110F1 / IMPR1110F5 ("سيتم تعديل الإسم إلى ...")',
    'FOS returns P1110_CONFIRM_TEXT; native Confirm when it is not null', [], ret='NEW_RECORD_CONFIRM_TEXT(r, c)')
add('BLOCK IMPORTERS - record', 'WHEN_CLEAR_BLOCK', 'P', 'IMPORTERS.WHEN-CLEAR-BLOCK',
    'Process "WHEN-CLEAR-BLOCK" (request CLEAR of the page 0 toolbar)', ['IMPORTERS_WHEN_CLEAR_BLOCK;'])

for it, (pc, wvi) in ITEMS.items():
    seq_v = [x for x in (pc, wvi) if x]
    val = [s.replace('{F}', 'FALSE').replace('{A}', 'c_yes').replace('{S}', 'c_yes') for s in seq_v]
    da = [s.replace('{F}', 'TRUE').replace('{A}', ANSWER).replace('{S}', SUSPEND) for s in seq_v]
    trig = ' + '.join(t for t, x in (('POST-CHANGE', pc), ('WHEN-VALIDATE-ITEM', wvi)) if x)
    add('ITEM ' + it, it + '_VALIDATION', 'F', 'IMPORTERS.%s.%s' % (it, trig),
        'Validation "%s VALIDATION" (request CREATE / SAVE): returns the error text' % it,
        val, text_function=True)
    add('ITEM ' + it, it + '_WHEN_VALIDATE_ITEM', 'P', 'IMPORTERS.%s.%s' % (it, trig),
        'DA "%s WHEN-VALIDATE-ITEM" (Change): FOS, Items to Submit = the IN items, Items to Return = the IN OUT / OUT items' % it, da)

for name, it, src, call in [
        ('IMPR_TYPE_CD_NEW_ITEM_INSTANCE', 'IMPR_TYPE_CD', 'WHEN-NEW-ITEM-INSTANCE', 'IMPR_TYPE_CD_NEW_ITEM_INSTANCE(r);'),
        ('IMPR_TYPE_CD_LOV_RETURN', 'IMPR_TYPE_CD', 'KEY-LISTVAL (values the LOV returns)', 'IMPR_TYPE_CD_LOV_RETURN(r);'),
        ('CITY_CODE_OF_ID_WHEN_NEW_ITEM', 'CITY_CODE_OF_ID', 'WHEN-NEW-ITEM-INSTANCE', 'CITY_CODE_OF_ID_WHEN_NEW_ITEM(r);'),
        ('BUS_ID_WHEN_NEW_ITEM_INSTANCE', 'BUS_ID', 'WHEN-NEW-ITEM-INSTANCE', 'BUS_ID_WHEN_NEW_ITEM_INSTANCE(r);'),
        ('BUS_ID_BRNCH_NEW_ITEM_INSTANCE', 'BUS_ID_BRNCH', 'WHEN-NEW-ITEM-INSTANCE', 'BUS_ID_BRNCH_NEW_ITEM_INSTANCE(r);'),
        ('COMM_RGSTRTN_TYPE_LIST_CHANGED', 'COMM_RGSTRTN_TYPE', 'WHEN-LIST-CHANGED', 'COMM_RGSTRTN_TYPE_LIST_CHANGED(r);'),
        ('ARBC_IMPR_NAME_KEY_NEXT_ITEM', 'ARBC_IMPR_NAME', 'KEY-NEXT-ITEM', 'ARBC_IMPR_NAME_KEY_NEXT_ITEM(r);'),
        ('BANK_IBAN_NEW_ITEM_INSTANCE', 'BANK_IBAN', 'WHEN-NEW-ITEM-INSTANCE', 'BANK_IBAN_NEW_ITEM_INSTANCE(r);')]:
    add('ITEM ' + it, name, 'P', 'IMPORTERS.%s.%s' % (it, src),
        'DA "%s %s": FOS, Items to Return = the IN OUT / OUT items' % (it, src.split(' ')[0]), [call])
add('ITEM BUS_ID', 'BUS_ID_SUSPENDED_CONFIRM_TEXT', 'F',
    'IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM, question "يوجد مستورد ... موقوف له نفس الرقم الإستدلالي"',
    'FOS before "BUS_ID WHEN-VALIDATE-ITEM": returns P1110_CONFIRM_TEXT; Confirm sets P1110_SUSPEND_ANSWER',
    ['v_importer := BUS_ID_SUSPENDED_IMPORTER(r);'],
    ret="""CASE WHEN v_importer <> 0 THEN 'يوجد مستورد' || v_importer || ' موقوف له نفس الرقم الإستدلالي" هل تريد تعديل الرقم الاستدلالي بالرغم من ذلك ؟' END""")

add('BLOCK IMPORTERS - DML', 'PRE_INSERT', 'P', 'IMPORTERS.PRE-INSERT',
    'Process "PRE-INSERT" (request CREATE / SAVE, :P0_PAGE_PK is null), before "Process form IMPORTERS"; '
    'Confirm of brokers (class 1, type 3) sets P1110_ANSWER', ['IMPORTERS_PRE_INSERT(r, c, %s);' % ANSWER], rec_status='INSERT')
add('BLOCK IMPORTERS - DML', 'POST_INSERT', 'P', 'IMPORTERS.POST-INSERT',
    'Process "POST-INSERT", after "Process form IMPORTERS"', ['IMPORTERS_POST_INSERT(r, c);'], rec_status='INSERT')
add('BLOCK IMPORTERS - DML', 'PRE_UPDATE', 'P', 'IMPORTERS.PRE-UPDATE',
    'Process "PRE-UPDATE" (request SAVE, :P0_PAGE_PK is not null), before "Process form IMPORTERS"',
    ['IMPORTERS_PRE_UPDATE(r, c);'], rec_status='CHANGED')
add('BLOCK IMPORTERS - DML', 'POST_UPDATE', 'P', 'IMPORTERS.POST-UPDATE',
    'Process "POST-UPDATE", after "Process form IMPORTERS"', ['IMPORTERS_POST_UPDATE(r);'], rec_status='CHANGED')
add('BLOCK IMPORTERS - DML', 'KEY_DELREC', 'P', 'IMPORTERS.KEY-DELREC (+ PRE-DELETE); the question is the page 0 DELETE confirm',
    'Process "KEY-DELREC" (request DELETE) instead of the native delete', ['IMPORTERS_KEY_DELREC(r, c);'])

add('FUNCTIONS', 'ADJ_FUNS', 'F', 'PU ADJ_FUNS (TMPLT.ENABLE_FUN / DISABLE_FUN)',
    'Computation P1110_ADJ_FUNS (comma list of the enabled functions, filter of the f345 Page Functions list)',
    ['g_fun_cd.DELETE;', 'g_fun_on.DELETE;', 'ADJ_FUNS(r, c);'], ret='PRIVATE_ENABLED_FUNCTIONS')
add('FUNCTIONS', 'EXEC_FUNS', 'P', 'PU EXEC_FUNS (TMPLT EXECUTE_FUNCTION)',
    'DA of each entry of the Page Functions list (FOS); then WHEN_NEW_RECORD_INSTANCE',
    ['EXEC_FUNS(r, c, I_FUNCTION_CODE);'], extra=[('I_FUNCTION_CODE', 'IN', 'VARCHAR2')])
add('FUNCTIONS', 'UPDATE_IMPORTER_CONFIRM_TEXT', 'F', 'PU UPDATE_IMPORTER_MSG (question of function IMPR_MCI_SERVICE)',
    'FOS returns P1110_CONFIRM_TEXT; native Confirm', [], ret='UPDATE_IMPORTER_MSG(r)')
add('FUNCTIONS', 'UPDATE_IMPORTER', 'P', 'PU UPDATE_IMPORTER (function IMPR_MCI_SERVICE, ALLOW_MCI / ALLOW_MOI)',
    'DA "IMPR_MCI_SERVICE" after the Confirm (FOS)',
    ["IF %s = c_yes AND (GET_GLOBAL('ALLOW_MCI') = '1' OR GET_GLOBAL('ALLOW_MOI') = '1') THEN" % ANSWER,
     '    UPDATE_IMPORTER(r);', 'END IF;'])
add('FUNCTIONS', 'LOV_UPDATE_MOBLIE', 'P', 'PU LOV_UPDATE_MOBLIE, part after CALL_FORM(LOV_UPDATE_IMPR_MOBILE)',
    'DA "Dialog Closed" of page 111002 (FOS)', ['LOV_UPDATE_MOBLIE(r);'])
add('PAGE 111002 (LOV_UPDATE_IMPR_MOBILE)', 'CENTRAL_MOBILE', 'N', 'PU LOV_UPDATE_MOBLIE, part before CALL_FORM (P_CENTRAL_MOBILE)',
    'Computation P111002_CENTRAL_MOBILE (Before Header)', [], ret='CENTRAL_MOBILE(r, c)', prefix='P111002_')

# ------------------------------------------------------------------ generate entries
DATE_MASK = {'BUS_ID_EXPRD_DT': 'HIJRI_DATE_FORMAT', 'BUS_ID_ISSUE_DT': 'HIJRI_DATE_FORMAT', 'LST_TRAN_DT': 'c_date_time_mask'}
def ptype(t):
    return re.sub(r'\(\d+\)', '', t)          # no length in a parameter type
LOGIC_CALL = re.compile(r'(?<![\w.$#])([A-Za-z][A-Za-z0-9_$#]*)\s*[(;]')
def pname(mode, item):
    n = '%s_%s' % (mode, item)
    if len(n) > 30: sys.exit('parameter name too long: ' + n)
    return n
def gen_entry(e):
    calls = [x.upper() for s in e['stmts'] + [e['ret'] or ''] for x in LOGIC_CALL.findall(s)]
    calls = [x for x in calls if x in logic_names]
    r, w, cx, cw = closure(calls)
    r |= w
    returns_only = e['kind'] in ('F', 'N')          # functions return a value, never write items back
    pre, post, params = [], [], []
    P = e['prefix']
    for f in REC:
        if f in r and f not in CONTROL:
            io = f in w and not returns_only
            p = pname('IO' if io else 'I', P + f)
            if f in DATE_MASK:          # APEX items are text: convert with the Forms mask (step 03 §4)
                params.append((p, 'IN OUT' if io else 'IN', 'VARCHAR2'))
                pre.append('r.%s := TO_DATE(%s, %s);' % (f.lower(), p, DATE_MASK[f]))
                if io: post.append('%s := TO_CHAR(r.%s, %s);' % (p, f.lower(), DATE_MASK[f]))
                continue
            params.append((p, 'IN OUT' if io else 'IN', ptype(REC[f])))
            pre.append('r.%s := %s;' % (f.lower(), p))
            if io: post.append('%s := r.%s;' % (p, f.lower()))
    if 'ROW_ID' in r or 'REC_STATUS' in r:
        params.append((pname('I', P + 'ROW_ID'), 'IN', 'VARCHAR2'))
        pre.append('r.row_id := I_%sROW_ID;' % P)
    if 'REC_STATUS' in r:
        pre.append("r.rec_status := %s;" % ("'%s'" % e['rec_status'] if e['rec_status']
                   else "CASE WHEN r.row_id IS NULL THEN 'NEW' ELSE 'QUERY' END"))
    if 'ACTIVITY_ENTR' in r:
        if 'BUS_ID' not in r or 'ACTIVITY' not in r: sys.exit('ACTIVITY_ENTR needs BUS_ID / ACTIVITY: ' + e['name'])
        pre.append("r.activity_entr := CASE WHEN ACTIVITY_IS_READ_ONLY(r.bus_id, r.activity) THEN 'N' ELSE 'Y' END;")
    if 'BUS_ID_BRNCH_ENTR' in r:
        cx = cx | {'CODE'}
        pre.append("r.bus_id_brnch_entr := CASE WHEN BUS_ID_BRNCH_IS_READ_ONLY(r.impr_nbr, I_%sP_CODE, r.impr_type_cd,\n"
                   "                                    r.bus_id_type_cd, r.comm_rgstrtn_type) THEN 'N' ELSE 'Y' END;" % PAGE)
    ctx_pre = []
    for f in CTX:
        if f in cx:
            io = f in cw and not returns_only and f not in e['no_ctx_write']
            p = pname('IO' if io else 'I', CTX_ITEM[f])
            params.append((p, 'IN OUT' if io else 'IN', ptype(CTX[f])))
            ctx_pre.append('c.%s := %s;' % (f.lower(), p))
            if io: post.append('%s := c.%s;' % (p, f.lower()))
    pre = ctx_pre + pre          # context first: the derived control fields may use I_P1110_P_CODE
    txt = ' '.join(e['stmts'])
    for a in ('ANSWER', 'SUSPEND_ANSWER'):
        if 'I_%s%s' % (PAGE, a) in txt or (e['ret'] and 'I_%s%s' % (PAGE, a) in e['ret']):
            params.append(('I_%s%s' % (PAGE, a), 'IN', 'PLS_INTEGER DEFAULT NULL'))
    params += e['extra']
    width = max([len(p) for p, _, _ in params] + [1])
    sig = (',\n').join('%-*s %-6s %s' % (width, p, m, t) for p, m, t in params)
    kw = 'PROCEDURE' if e['kind'] == 'P' else 'FUNCTION'
    pad = ' ' * (len('    %s %s (' % (kw, e['name'])))
    head = '%s %s' % (kw, e['name'])
    if params:
        head += ' (' + sig.replace('\n', '\n' + pad) + ')'
    if e['kind'] != 'P':
        head += '\n        RETURN %s' % ('NUMBER' if e['kind'] == 'N' else 'VARCHAR2')
    cmt = '    -- Source: %s\n    -- APEX  : %s\n' % (e['source'], e['apex'])
    code = ' '.join(e['stmts'] + pre + [e['ret'] or ''] + (['r.row_id'] if e['text_function'] else []))
    decl = [d for d, k in (('        r T_RECORD;', r'\br\b'), ('        c T_CONTEXT;', r'\bc\b')) if re.search(k, code)]
    if 'v_importer' in txt: decl.append('        v_importer NUMBER;')
    body = ['        ' + x.replace('\n', '\n        ') for x in pre] + ['        ' + s for s in e['stmts']]
    if e['text_function']:
        body += ['        RETURN NULL;', '    EXCEPTION', '        WHEN OTHERS THEN',
                 "            RETURN PRIVATE_ERROR_TEXT(SQLCODE, SQLERRM, CASE WHEN r.row_id IS NULL THEN 'I' ELSE 'U' END);"]
    elif e['ret']:
        body += ['        RETURN %s;' % e['ret']]
    else:
        body += ['        ' + x for x in post]
    impl = '%s    %s\n    IS\n%s\n    BEGIN\n%s\n    END %s;' % (cmt, head, '\n'.join(decl), '\n'.join(body), e['name'])
    e['params'] = params
    return cmt + '    ' + head + ';', impl
gen = [(e, gen_entry(e)) for e in entries]
VAL_ITEMS = list(ITEMS)

# ------------------------------------------------------------------ hand-written members
RULES = open('work/step02/rules.sql', encoding='utf-8').read()
HELPERS = open('work/step02/helpers.sql', encoding='utf-8').read()
def split_members(sql):
    ms = parse_members(sql)
    return [(m, m['text']) for m in ms]
rule_members = split_members(RULES)
helper_members = split_members(HELPERS)
public_handwritten = [m for m, _ in rule_members + helper_members if not m['name'].startswith('PRIVATE_')]

def spec_decl(m):
    cm = '\n'.join(l for l in m['text'].split('\n')[:m['decl'] - m['start']])
    return (cm + '\n' if cm else '') + '    ' + m['header'] + ';'

# ------------------------------------------------------------------ assemble the spec
vb = re.search(r'(?s)(   V_PKG_VERSION .*?\|\| V_MODIFIED_BY;\n)', spec_src).group(1)
vb = re.sub(r"'VERSION NO\. IS:' \|\| '\d+'", "'VERSION NO. IS:' || '010'", vb, count=1)
vb = re.sub(r"V_LAST_MODIFY_DT    VARCHAR2 \(10\) := '[^']*'", "V_LAST_MODIFY_DT    VARCHAR2 (10) := '%s'" % DATE, vb)
grants = spec_src[spec_src.index('\n-- -----------------------------------------------------------------------------\n-- Synonym and grants'):]
def banner(t):
    return '\n    -- =========================================================================\n    -- %s\n    -- =========================================================================\n' % t
sections = collections.OrderedDict()
for e, (sd, _) in gen:
    sections.setdefault(e['section'], []).append(sd)
for m in public_handwritten:
    sec = re.search(r'-- Section: (.+)', m['text'])
    sections.setdefault(sec.group(1).strip() if sec else 'f345 HELPERS', []).append(spec_decl(m))
xml = open('forms/IMPR/IMPR1110_fmb.xml', encoding='utf-8', errors='replace').read()
blk = xml.index('<Block Name="IMPORTERS"')
FORMS_ITEM_ORDER = re.findall(r'<Item Name="([^"]+)"', xml[blk:xml.index('</Block>', blk)])
item_sections = sorted((s for s in sections if s.startswith('ITEM ')), key=lambda s: FORMS_ITEM_ORDER.index(s[5:]))
order = ['f345 HELPERS', 'FORM LEVEL', 'BLOCK IMPORTERS - query', 'BLOCK IMPORTERS - record'] + item_sections + \
        ['BLOCK IMPORTERS - DML', 'FUNCTIONS', 'PAGE 111002 (LOV_UPDATE_IMPR_MOBILE)']
order += [s for s in sections if s not in order]
spec = ['-- =============================================================================',
        '-- Package     : IMPR1110  (form IMPR1110.fmb "إضافة وتعديل بيانات مستورد")',
        '-- Owner       : LIB_APX_USR (public synonym IMPR1110; EXECUTE granted to LIB_USR, SECURITY_DEFAULT, SECURITY_PROD, CUSTOMS)',
        '-- Version     : 010 (%s: 006 = step 02 revision 2 + step 03 changes (DATE items as text, ROWID page key);' % DATE,
        '--               007 = parameter names by scripts/parameter_names.py; 008 = no doubled P_P_ (P_CODE => :P1110_P_CODE),',
        '--               APP_P_PRSNL_IMPR / APP_P_LETTER_NBR in PARAMETERS_ENTRY. No logic change. 007: rollback/IMPR1110/step04_v007/;',
        "--               009 = P0_PAGE_PK_CHECK restores the URL-safe ROWID of page 111001 ('-' / '_' -> '+' / '/'; a '+'",
        '--               in f?p arrived as a space: checksum error). 008: rollback/IMPR1110/step04_v008/;',
        '--               010 = Hijri date format from one place: HIJRI_DATE_FORMAT reads the Application Setting',
        '--               HIJRI_DATE_FORMAT (default YYYY-MM-MI, was the constant MI-MM-YYYY). 009: rollback/IMPR1110/step04_v009/)',
        '-- Author      : Claude Code',
        '-- Status      : NOT COMPILED.',
        '-- Layout      : VERSION -> f345 HELPERS -> FORM LEVEL -> BLOCK IMPORTERS (query, record, items in Forms',
        '--               navigation order with their read-only / required rules, DML) -> FUNCTIONS -> page 111002.',
        '--               Every member here is called by APEX with named binds. Parameter names have no I_ / IO_ / O_',
        '--               prefix (the mode is IN / IN OUT / OUT); a page item P<page>_X is passed as P_X',
        '--               (P_BUS_ID => :P1110_BUS_ID, P_PAGE_PK => :P0_PAGE_PK, P_MOBILE_NO => :P111002_MOBILE_NO),',
        '--               application items keep their name (P_CURR_PORT_CD => :P_CURR_PORT_CD). Inside SQL a parameter',
        '--               is qualified with its member name. The converted Forms logic is private in the body.',
        '-- Generated   : by work/step02/build_package.py (re-run after a change; do not edit by hand)',
        '-- =============================================================================',
        'SET DEFINE OFF', '', 'CREATE OR REPLACE PACKAGE LIB_APX_USR.IMPR1110 AS', vb,
        '    c_yes CONSTANT PLS_INTEGER := 1;   -- confirm answers (ALERT_BUTTON1 / ALERT_BUTTON2)',
        '    c_no  CONSTANT PLS_INTEGER := 2;']
for s in order:
    if s not in sections: continue
    spec.append(banner(s))
    spec.append('\n\n'.join(sections[s]))
spec += ['', 'END IMPR1110;', '/', 'SHOW ERRORS', grants.rstrip('\n'), '']
spec_text = '\n'.join(spec)

# ------------------------------------------------------------------ assemble the body
logic_fwd = ['    ' + m['header'] + ';' for m, _ in logic_text]
body = ['-- =============================================================================',
        '-- Package body: IMPR1110 (version 010, %s) - see the spec header. NOT COMPILED.' % DATE,
        '-- Layout      : 1 private types and declarations, 2 forward declarations, 3 private helpers and the',
        '--               converted Forms logic (record based, Forms order, UI calls replaced by "NULL; -- APEX ..."),',
        '--               4 read-only / required rules, 5 f345 helpers, 6 APEX entry points (spec order), 7 version.',
        '-- Generated   : by work/step02/build_package.py from rollback/IMPR1110/step02_rev1/ (do not edit by hand)',
        '-- =============================================================================',
        'SET DEFINE OFF', '', 'CREATE OR REPLACE PACKAGE BODY LIB_APX_USR.IMPR1110', 'AS',
        banner('1 PRIVATE TYPES AND DECLARATIONS').rstrip('\n'),
        t_record_txt.strip('\n'), '', t_context_txt.strip('\n'), '',
        "    c_hijri_date_format CONSTANT VARCHAR2(30) := 'YYYY-MM-MI';   -- default of the Application Setting HIJRI_DATE_FORMAT (f345 Hijri picker); day kept in the minutes (Feb 30 is no DATE); Forms used MI-MM-YYYY",
        "    c_date_time_mask CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';   -- Forms PLSQL_DATE_FORMAT (PRE-FORM), LST_TRAN_DT",
        '    c_err        CONSTANT PLS_INTEGER   := -20001;',
        "    c_hero_title CONSTANT VARCHAR2(200) := 'إضافة وتعديل بيانات مستورد';",
        '    TYPE t_vc_tab IS TABLE OF VARCHAR2(4000) INDEX BY PLS_INTEGER;',
        '    g_fun_cd     t_vc_tab;     -- function codes switched by ADJ_FUNS (TMPLT.ENABLE_FUN / DISABLE_FUN)',
        '    g_fun_on     t_vc_tab;     -- Y / N',
        "    c_functions  CONSTANT VARCHAR2(400) := 'IMPR1110F1,IMPR1110F2,IMPR1110F3,IMPR1110F4,IMPR1110F5,IMPR1110SF6,'",
        "                                        || 'IMPR_CAR_AGENT,IMPR_MCI_SERVICE,CREATE_BRKR_IMPR_AUTH,IMPR1115_GZT,IMPR1110_MOB';",
        banner('2 FORWARD DECLARATIONS (private converted logic)').rstrip('\n')] + logic_fwd + [
        banner('3 PRIVATE HELPERS AND CONVERTED FORMS LOGIC (Forms order)').rstrip('\n')]
for m, t in logic_text:
    body += [t, '']
body += [banner('4 READ-ONLY / REQUIRED / VISIBLE RULES (work/step02/read_only_rules.md)').rstrip('\n')] + [t + '\n' for m, t in rule_members]
body += [banner('5 f345 HELPERS AND SMALL ENTRY POINTS').rstrip('\n')] + [t + '\n' for m, t in helper_members]
body += [banner('6 APEX ENTRY POINTS (generated: IN / IN OUT parameters = items the logic reads / writes)').rstrip('\n')]
for s in order:
    for e, (_, impl) in gen:
        if e['section'] == s:
            body += [impl, '']
body += [banner('7 PACKAGE VERSION   (SELECT IMPR1110.PKG_VERSION FROM dual;)').rstrip('\n'),
         '    FUNCTION PKG_VERSION', '       RETURN VARCHAR2', '    IS', '    BEGIN', '       RETURN V_INFO;', '    END PKG_VERSION;', '',
         'END IMPR1110;', '/', 'SHOW ERRORS', '']
body_text = '\n'.join(body)
# ---- parameter names (scripts/parameter_names.py): rename, then qualify inside SQL
RENAMES = parameter_names.mapping_from_spec(spec_text)
# {member: {new name: original name}}: build_spec.py derives each bind from the original name
json.dump(parameter_names.binds_by_member(spec_text), open('work/step02/parameter_binds.json', 'w'), indent=1, sort_keys=True)
spec_text = parameter_names.rename_package(spec_text, RENAMES)
body_text = parameter_names.rename_package(body_text, RENAMES)
body_text, n_qualified = parameter_names.qualify_sql(spec_text, body_text)
left = parameter_names.unqualified_in_sql(spec_text, body_text)
if left:
    sys.exit('parameters not qualified inside SQL: %s' % left[:5])
private_sql = parameter_names.private_functions_in_sql(spec_text, body_text)
if private_sql:
    sys.exit('private functions called inside SQL (ORA-00904): %s' % private_sql[:5])
json.dump(RENAMES, open('work/step02/parameter_renames.json', 'w'), indent=1, sort_keys=True)
open(OUT_SPEC, 'w', encoding='utf-8', newline='\n').write(spec_text)
open(OUT_BODY, 'w', encoding='utf-8', newline='\n').write(body_text)

stats = dict(logic_members=len(logic_text), ui_calls_replaced=removed_total, entries=len(gen),
             rules=len(rule_members), helpers=len(helper_members), renamed_parameters=len(RENAMES), qualified_in_sql=n_qualified,
             spec_lines=sum(x.count('\n') + 1 for x in spec), body_lines=sum(x.count('\n') + 1 for x in body))
json.dump(stats, open('work/step02/build_stats.json', 'w'), indent=1)
print(stats)
json.dump([dict(section=e['section'], name=e['name'], kind=e['kind'], source=e['source'], apex=e['apex'],
                params=[(RENAMES.get(p, p), m) for p, m, _ in e['params']]) for e, _ in gen],
          open('work/step02/entries.json', 'w', encoding='utf-8'), indent=0, ensure_ascii=False)
