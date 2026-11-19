import json, re, collections
units = json.load(open('work/step02/units.json', encoding='utf-8'))

# target per unit: (group, target, note)
FORM = {
    'PRE-FORM': ('DROPPED', 'PKG_VERSION / f345 globalization', 'NIB.PRE_FORM, version stamp :GLOBAL.current_ver (-> PKG_VERSION), date format (f345), help path'),
    'WHEN-NEW-FORM-INSTANCE': ('INITIALISATION', 'WHEN_NEW_FORM_INSTANCE', 'NIB startup, timers, window dropped; functions / broker / globals kept'),
    'ON-ERROR': ('DROPPED', 'f345 APP_ERROR_HANDLER', 'NIB.ON_ERROR'),
    'ON-MESSAGE': ('DROPPED', 'f345 APP_ERROR_HANDLER', 'NIB.ON_MESSAGE'),
    'KEY-F9': ('UI-ONLY', 'page 0 FUNCS + region FUNCS', 'side menu toggle; ADJ_FUNS part → ADJ_FUNS'),
    'KEY-CLRFRM': ('UI-ONLY', 'page 0 CLEAR', 'CGDV lists → shared LOVs; WHEN-CLEAR-BLOCK logic kept in IMPORTERS_WHEN_CLEAR_BLOCK'),
    'KEY-HELP': ('DROPPED', '-', 'MS-Help (CGHP$)'),
}
DROP_FORM_NIB = 'page 0 toolbar / APEX navigation (NIB key, timer, window handler)'
BLOCK = {
    'ON-ERROR': ('VALIDATION', 'IMPORTERS_ON_ERROR', 'constraint name → message (OFGTEL MISSING SOURCE); used by APP_ERROR_HANDLER text lookup'),
    'POST-QUERY': ('QUERY', 'IMPORTERS_POST_QUERY', 'split into private helpers (status, suspension, privileged, duty-diff, CR status, lookups); UI → WASL_CITY_IS_SHOWN / _IS_READ_ONLY'),
    'PRE-QUERY': ('QUERY', 'search page SQL', 'name criterion / IMPORTERS_WHERE / PRSNL_IMPR → WHERE clause of page <page>01 (no package member)'),
    'PRE-INSERT': ('PRE/POST DML', 'PRE_INSERT', 'split: required checks, register check, central number (CREATE_UNI_IMPR_NEBRAS), activity'),
    'POST-INSERT': ('PRE/POST DML', 'POST_INSERT', 'Make_Field_Entrable → saved-record lock rule'),
    'PRE-UPDATE': ('PRE/POST DML', 'PRE_UPDATE', 'split like PRE_INSERT; journaling on'),
    'POST-UPDATE': ('PRE/POST DML', 'POST_UPDATE', 'journaling off; Make_Field_Entrable → saved-record lock rule'),
    'PRE-DELETE': ('PRE/POST DML', 'PRE_DELETE', ''),
    'KEY-DELREC': ('PRE/POST DML', 'KEY_DELREC', 'delete IMPR_UPDTS + importer, no COMMIT (decision §15 #6); confirm = page 0 DELETE'),
    'PRE-RECORD': ('INITIALISATION', 'IMPORTERS_PRE_RECORD', ''),
    'WHEN-CLEAR-BLOCK': ('INITIALISATION', 'IMPORTERS_WHEN_CLEAR_BLOCK', 'globals'),
    'WHEN-CREATE-RECORD': ('INITIALISATION', 'IMPORTERS_WHEN_CREATE_RECORD', 'defaults; PRSNL_IMPR rule → _IS_READ_ONLY'),
    'WHEN-NEW-ITEM-INSTANCE': ('NAVIGATION', 'page submit with request (re-query)', 'EXEC_QUERY_NOW'),
    'WHEN-NEW-RECORD-INSTANCE': ('INITIALISATION', 'IMPORTERS_NEW_RECORD_INSTANCE', 'split per function code (F1..F5, SF6); type-19 rule kept without COMMIT (§15 #16); entrable → rules'),
    'KEY-HELP': ('DROPPED', '-', 'MS-Help'),
}
PU_KEEP = {'UPDATE_IMPORTER', 'UPDATE_BASIC_IMPORTER', 'RETURN_IMPR_ID', 'LOV_UPDATE_MOBLIE', 'IS_DIGIT',
           'INSERT_AUDIT_RECORD', 'GET_MAIN_CR_DATA', 'GET_CR_DATA', 'GET_BRANCH_CR_DATA', 'EXEC_FUNS',
           'CREATE_BRKR_IMPR_AUTH', 'CHK_PERSONAL', 'CHK_IMPR_DUPL', 'CHK_DUPL_IMP_BRKR', 'CHECK_IDNO', 'CHECK_BUS_ID',
           'BROKER_INT', 'ADJ_FUNS', 'VIEW_SAME_BUSID', 'CHK_BUS_ID_BRNCH', 'CGSF$CLRLU_IMPORTERS_IMP_BUS_I',
           'CGTE$CHECK_CONSTRAINT_VIO'}
PU_DROP = {
    'CHECK_TIMEOUT': 'session timeout → APEX (§15 #9)', 'MOUSE_CLICK': 'LSIDE menu', 'TOGGEL_WND': 'window (Windows API)',
    'PRINT_REPORT': 'not called by active code', 'TERMINATE_FUN': 'function menu', 'CHECK_EDI_MSG_LOV': 'EDI ticker (§15 #9)',
    'CHECK_EDI_MSG_TIMER': 'EDI ticker', 'CHECK_EDI_ROLE_ID': 'EDI ticker', 'EDI_MSG_LOV': 'EDI ticker', 'FOR_EDI_MSG': 'EDI ticker',
    'RETURN_MSG': 'EDI ticker', 'TURN_MSG': 'EDI ticker', 'WHEN_TIMER_EXPIRED_MSG': 'EDI ticker',
    'CG$WHEN_NEW_FORM_INSTANCE': 'calls CGDV$POPULATE_DYNAMIC_LISTS only', 'CGDV$POPULATE_DYNAMIC_LISTS': 'list items → shared LOVs on CG_REF_CODES',
    'CG$IMPR1110_PROD_CENTRL_GLOBAL': 'IMPORTERS_WHERE variable → search page SQL', 'DEV_VERSIONS': 'version stamp',
    'CALL_LOV_COUNTRIES': 'LOV form → popup LOV', 'CALL_LOV_COUN_GULF': 'LOV form → popup LOV',
    'EXECUTE_FUNCTION': 'TMPLT dispatcher → f345 Page Functions list; report branch (REP.RUN_PRODUCT) open (§14 #5)',
}
rows = []
for u in units:
    o, n = u['owner'], u['name']
    if u['kind'] == 'PU':
        if n in PU_KEEP:
            g, t, note = ('PROGRAM UNIT', n, 'same name as in Forms')
        elif n.startswith('CGFK$'):
            g, t, note = ('QUERY', n, 'Designer FK lookup / check, same name; used by validations')
        else:
            g, t, note = ('DROPPED', '-', PU_DROP.get(n, 'TODO classify'))
    elif o == 'FORM':
        g, t, note = FORM.get(n, ('DROPPED', DROP_FORM_NIB, 'one-line NIB.* delegation'))
    elif o.split('.')[0] in ('TITLE', 'TOOLBAR', 'LSIDE', 'EDI_MSG'):
        g, t, note = ('DROPPED', 'f345 page template / page 0 toolbar', 'OLB screen frame')
    elif o == 'IMPORTERS':
        g, t, note = BLOCK.get(n, ('TODO', '?', ''))
    else:
        item = o.split('.', 1)[1]
        if n == 'KEY-LISTVAL' and u['active'] <= 32:
            g, t, note = ('DROPPED', '-', 'generic Designer KEY-LISTVAL (no LOV on this item)')
        elif n == 'KEY-LISTVAL':
            g, t, note = ('UI-ONLY', 'Popup LOV on P1110_%s' % item, 'LOV form call → popup LOV; returned globals → LOV return columns')
        elif n == 'WHEN-BUTTON-PRESSED':
            g, t, note = ('DROPPED', 'popup LOV button', 'DO_KEY(LIST_VALUES)')
        elif n == 'KEY-F4':
            g, t, note = ('DROPPED', 'date picker', 'Hijri calendar (INTRFACE.Disp_Date_Con)')
        elif n == 'WHEN-VALIDATE-ITEM':
            g, t, note = ('VALIDATION', '%s_VALIDATION / %s_WHEN_VALIDATE_ITEM' % (item, item), 'error text function + procedure for derived values; entrable → rules')
        elif n == 'POST-CHANGE':
            g, t, note = ('VALIDATION', '%s_POST_CHANGE' % item, 'runs before WHEN-VALIDATE-ITEM')
        elif n == 'WHEN-NEW-ITEM-INSTANCE':
            g, t, note = ('NAVIGATION', 'DA %s WHEN-NEW-ITEM-INSTANCE' % item, 'messages / defaults on focus; required flags → _IS_REQUIRED')
        elif n == 'KEY-NEXT-ITEM':
            g, t, note = ('NAVIGATION', 'native Set Focus', 'net effect GO_ITEM')
        elif n == 'WHEN-LIST-CHANGED':
            g, t, note = ('UI-ONLY', '%s_LIST_CHANGED' % item, 'clears BUS_ID_BRNCH; entrable / required → rules')
        else:
            g, t, note = ('TODO', '?', '')
    rows.append((u['kind'], o, n, u['active'], g, t, note))

c = collections.Counter(r[4] for r in rows)
al = collections.Counter()
for r in rows:
    al[r[4]] += r[3]
out = ['# IMPR1110 — classification of all units with code (step 02 rev 2)', '',
       'Generated from `work/step02/units.json` by the step-02 classifier; groups as in prompt 02 step 2.', '',
       '| Group | Units | Active lines |', '|---|---|---|']
for k in sorted(c):
    out.append('| %s | %d | %d |' % (k, c[k], al[k]))
out += ['', '| # | Kind | Owner | Trigger / unit | Active lines | Group | Target (package member / APEX) | Note |', '|---|---|---|---|---|---|---|---|']
for i, r in enumerate(rows, 1):
    out.append('| %d | %s | %s | %s | %d | %s | %s | %s |' % ((i,) + r))
open('work/step02/classification.md', 'w', encoding='utf-8').write('\n'.join(out) + '\n')
print(dict(c)); print('TODO:', [(r[1], r[2]) for r in rows if r[4] == 'TODO' or 'TODO classify' in r[6]])
