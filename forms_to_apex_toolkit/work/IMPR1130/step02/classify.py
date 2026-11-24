"""Classification of every IMPR1130 code unit (step 02): converted member, APEX component, or dropped + reason.

Input : work/IMPR1130/units_both.json (compare_impr1110.py), plsql/IMPR1130/impr1130_spec.sql (members must exist)
Output: work/IMPR1130/step02/classification.md
Usage : python3 -I work/IMPR1130/step02/classify.py
"""
import json, re, sys, collections

units = json.load(open('work/IMPR1130/units_both.json', encoding='utf-8'))
u30, u10 = units['1130'], units['1110']
spec = open('plsql/IMPR1130/impr1130_spec.sql', encoding='utf-8').read()
public = set(re.findall(r'^\s{4}(?:PROCEDURE|FUNCTION)\s+([A-Z0-9_$#]+)', spec, re.M))

C = 'CONVERTED'
M = {
    'FORM.WHEN-NEW-FORM-INSTANCE': (C, 'WHEN_NEW_FORM_INSTANCE', 'settings ALLOW_MCI / ALLOW_MOI, country 100 defaults; SUPPORT_ENTRY -> page 9001 DAs; rest = f345 frame'),
    'IMPORTERS.WHEN-CREATE-RECORD': (C, 'WHEN_CREATE_RECORD', 'port, personal importer type 4; entrable calls -> rules'),
    'IMPORTERS.WHEN-NEW-RECORD-INSTANCE': ('RULES', 'READ_ONLY_FLAGS', 'only Make_Field_Entrable / REQUIRED / GO_ITEM (declarations -> names read-only)'),
    'IMPORTERS.PRE-RECORD': (C, 'PRE_RECORD', 'parent importer name, message 9-150'),
    'IMPORTERS.PRE-QUERY': ('APEX', 'search page 113001 SQL', 'PRSNL_IMPR filter, :GLOBAL query-by-number -> request EXECUTE_QUERY; DEFAULT_WHERE / StrFormat search -> search page'),
    'IMPORTERS.POST-QUERY': (C, 'POST_QUERY', 'suspension, Ministry status, FK lookups; entrable part -> rules'),
    'IMPORTERS.PRE-INSERT': (C, 'PRE_INSERT', 'required checks, CHK_IMPR_DUPL, journaling, activity, CREATE_UNI_IMPR_NEBRAS, CGFK$CLR_FK_ON_INS'),
    'IMPORTERS.POST-INSERT': (C, 'POST_INSERT', 'audit row, journaling off'),
    'IMPORTERS.PRE-UPDATE': (C, 'PRE_UPDATE', 'IMPR_NAME_STD, audit row, HQ number, activity, trims'),
    'IMPORTERS.PRE-DELETE': (C, 'KEY_DELREC', 'activity 5 + the same delete check'),
    'IMPORTERS.KEY-DELREC': (C, 'KEY_DELREC', 'child deletes, delete check, delete (no COMMIT); question = page 0 DELETE confirm'),
    'IMPORTERS.ON-ERROR': (C, 'importers_on_error (private)', 'constraint messages incl. the 32 delete constraints (FRM-40510)'),
    'IMPORTERS.WHEN-NEW-ITEM-INSTANCE': ('APEX', 'request EXECUTE_QUERY / page reload', 'EXECUTE_QUERY after :GLOBAL.EXEC_QUERY_NOW'),
    'IMPORTERS.KEY-HELP': ('DROPPED', '-', 'Designer MS-Help (CGHP$CALL_MS_HELP)'),
    'IMPORTERS.PORT_CD.WHEN-VALIDATE-ITEM': (C, 'PORT_CD_VALIDATION / PORT_CD_WHEN_VALIDATE_ITEM', 'port lookup (PORT_CD read-only in APEX)'),
    'IMPORTERS.IMPR_NBR.WHEN-VALIDATE-ITEM': (C, 'IMPR_NBR_VALIDATION + IMPORTER_ROW_ID', 'query by number -> request EXECUTE_QUERY'),
    'IMPORTERS.IMPR_TYPE_CD.WHEN-VALIDATE-ITEM': (C, 'IMPR_TYPE_CD_VALIDATION / IMPR_TYPE_CD_VALIDATE_ITEM', 'type table, sequences, identity type, names'),
    'IMPORTERS.IMPR_TYPE_CD.WHEN-NEW-ITEM-INSTANCE': ('APEX', 'page reload', 'EXECUTE_QUERY after :GLOBAL.EXEC_QUERY_NOW'),
    'IMPORTERS.IMPR_TYPE_CD.KEY-NEXT-ITEM': ('APEX', 'DA Set Focus', 'next item COMM_RGSTRTN_TYPE (identity type 2) / BUS_ID_EXPRD_DT'),
    'IMPORTERS.IMPR_TYPE_CD.KEY-LISTVAL': ('APEX', 'Popup LOV LOV_IMPR_TYPE + IMPR_TYPE_CD_VALIDATE_ITEM', 'CALL_FORM LOV_Impr_Type returns type / identity type / names'),
    'IMPORTERS.IMPR_TYPE_CD2.WHEN-BUTTON-PRESSED': ('APEX', 'Popup LOV button', 'GO_ITEM + DO_KEY(LIST_VALUES)'),
    'IMPORTERS.BUS_ID_EXPRD_DT.WHEN-VALIDATE-ITEM': (C, 'BUS_ID_EXPRD_DT_VALIDATION', 'Hijri date check'),
    'IMPORTERS.BUS_ID_EXPRD_DT.WHEN-NEW-ITEM-INSTANCE': ('APEX', 'page reload', 'EXECUTE_QUERY after :GLOBAL.EXEC_QUERY_NOW'),
    'IMPORTERS.BUS_ID_EXPRD_DT.KEY-LISTVAL': ('APEX', 'date picker', 'INTRFACE.Disp_Calendar'),
    'IMPORTERS.BUS_ID_EXPRD_DT.KEY-F4': ('APEX', 'date picker', 'INTRFACE.Disp_Date_Con'),
    'IMPORTERS.BUS_ID_TYPE_CD.WHEN-VALIDATE-ITEM': (C, 'BUS_ID_TYPE_CD_VALIDATION / BUS_ID_TYPE_CD_VALIDATE_ITEM', 'message 9-170'),
    'IMPORTERS.BUS_ID_TYPE_CD.KEY-LISTVAL': ('APEX', 'Popup LOV LOV_IMPR_TYPE_BUS_ID + BUS_ID_TYPE_CD_VALIDATE_ITEM', 'CALL_FORM LOV_Impr_Type with IMPR_TYPE_CD'),
    'IMPORTERS.BUTT.WHEN-BUTTON-PRESSED': ('APEX', 'Popup LOV button', 'LOV button of BUS_ID_TYPE_CD'),
    'IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED': (C, 'COMM_RGSTRTN_TYPE_LIST_CHANGED', 'branch cleared for type 1; enabling -> rules'),
    'IMPORTERS.CTRY_CD.WHEN-VALIDATE-ITEM': (C, 'CTRY_CD_VALIDATION / CTRY_CD_WHEN_VALIDATE_ITEM', 'Gulf rule, country lookup'),
    'IMPORTERS.CTRY_CD.KEY-LISTVAL': ('APEX', 'Popup LOV LOV_COUNTRIES / LOV_COUNTRIES_GULF', 'CALL_LOV_COUNTRIES / CALL_LOV_COUN_GULF by type'),
    'IMPORTERS.CTRY_CD2.WHEN-BUTTON-PRESSED': ('APEX', 'Popup LOV button', 'GO_ITEM + DO_KEY'),
    'IMPORTERS.CITY_CODE_OF_ID.WHEN-VALIDATE-ITEM': (C, 'CITY_CODE_OF_ID_CONFIRM_TEXT / _VALIDATION / _VALIDATE_ITEM', 'country of the city, full number (9-120 Confirm), 9-130, lookups'),
    'IMPORTERS.CITY_CODE_OF_ID.WHEN-NEW-ITEM-INSTANCE': (C, 'CITY_CODE_OF_ID_VALIDATE_ITEM (ctry_cd_of_id_value)', 'CTRY_CD_OF_ID default'),
    'IMPORTERS.CITY_CODE_OF_ID.KEY-LISTVAL': ('APEX', 'Popup LOV LOV_CITIES_IMP_ID', 'CALL_FORM LOV_CITIES (Saudi cities)'),
    'IMPORTERS.CITY_CODE_OF_ID2.WHEN-BUTTON-PRESSED': ('APEX', 'Popup LOV button', 'GO_ITEM + DO_KEY'),
    'IMPORTERS.CTRY_CD_OF_ID.WHEN-VALIDATE-ITEM': (C, 'CITY_CODE_OF_ID_VALIDATE_ITEM', 'CGSF$CLRLU (hidden item, set by the city)'),
    'IMPORTERS.NATIONAL_NBR.WHEN-VALIDATE-ITEM': (C, 'NATIONAL_NBR_VALIDATION / NATIONAL_NBR_VALIDATE_ITEM', 'starts with 7; Ministry of Commerce web service'),
    'IMPORTERS.BUS_ID.WHEN-VALIDATE-ITEM': (C, 'BUS_ID_VALIDATION / BUS_ID_WHEN_VALIDATE_ITEM', 'formats, full number, duplicates, register'),
    'IMPORTERS.BUS_ID_BRNCH.WHEN-VALIDATE-ITEM': (C, 'BUS_ID_BRNCH_VALIDATION / BUS_ID_BRNCH_VALIDATE_ITEM', 'CHK_IMPR_DUPL, 1-220, register, 9-190 / 9-210'),
    'IMPORTERS.BUS_ID_BRNCH.KEY-NEXT-ITEM': (C, 'BUS_ID_BRNCH_VALIDATE_ITEM', 'CHK_IMPR_DUPL on a new record (also in the validation)'),
    'IMPORTERS.ARBC_IMPR_NAME.KEY-NEXT-ITEM': ('DROPPED', '-', 'temporary ADD_CTRY_CD / CITY_CODE values only for FIRST_RECORD navigation, restored at once: no net effect'),
    'IMPORTERS.ENG_IMPR_NAME.WHEN-VALIDATE-ITEM': (C, 'ENG_IMPR_NAME_VALIDATION / ENG_IMPR_NAME_VALIDATE_ITEM', 'RemoveRepeat, English letters'),
    'IMPORTERS.BUS_ID_ISSUE_DT.WHEN-VALIDATE-ITEM': (C, 'BUS_ID_ISSUE_DT_VALIDATION', 'Hijri date check'),
    'IMPORTERS.BUS_ID_ISSUE_DT.KEY-LISTVAL': ('APEX', 'date picker', 'INTRFACE.Disp_Calendar'),
    'IMPORTERS.BUS_ID_ISSUE_DT.KEY-F4': ('APEX', 'date picker', 'INTRFACE.Disp_Date_Con'),
    'IMPORTERS.IMPR_NBR_PARENT.WHEN-VALIDATE-ITEM': (C, 'IMPR_NBR_PARENT_VALIDATE_ITEM', 'parent name, message 9-160'),
    'IMPORTERS.IMPR_NBR_PARENT.KEY-LISTVAL': ('APEX', 'Popup LOV LOV_IMPR + IMPR_NBR_PARENT_VALIDATE_ITEM', 'CALL_FORM LOV_IMPR'),
    'IMPORTERS.IMPR_NBR_PARENT2.WHEN-BUTTON-PRESSED': ('APEX', 'Popup LOV button', 'LOV button'),
    'IMPORTERS.ADD_CTRY_CD.WHEN-VALIDATE-ITEM': (C, 'ADD_CTRY_CD_WHEN_VALIDATE_ITEM', 'country name (LOV return), city lookup warning'),
    'IMPORTERS.ADD_CTRY_CD.KEY-LISTVAL': ('APEX', 'Popup LOV LOV_COUNTRIES + ADD_CTRY_CD_WHEN_VALIDATE_ITEM', 'CALL_FORM LOV_COUNTRIES'),
    'IMPORTERS.ADD_CTRY_CD2.WHEN-BUTTON-PRESSED': ('APEX', 'Popup LOV button', 'GO_ITEM + DO_KEY'),
    'IMPORTERS.CITY_CODE.WHEN-VALIDATE-ITEM': (C, 'CITY_CODE_VALIDATION / CITY_CODE_WHEN_VALIDATE_ITEM', 'required, 18-282, lookup warning'),
    'IMPORTERS.CITY_CODE.KEY-LISTVAL': ('APEX', 'Popup LOV LOV_CITIES + CITY_CODE_WHEN_VALIDATE_ITEM', 'CALL_FORM LOV_CITIES by ADD_CTRY_CD'),
    'IMPORTERS.CITY_CODE2.WHEN-BUTTON-PRESSED': ('APEX', 'Popup LOV button', 'LOV button'),
    'IMPORTERS.IMPR_TEL_NBR.WHEN-VALIDATE-ITEM': (C, 'IMPR_TEL_NBR_VALIDATION', 'required, 10 digits'),
    'IMPORTERS.EMAIL.WHEN-VALIDATE-ITEM': (C, 'EMAIL_VALIDATION', "'@' check (DA only, as Forms: only when the user leaves the item)"),
    'IMPORTERS.MOBILE_NO.WHEN-VALIDATE-ITEM': (C, 'MOBILE_NO_VALIDATION', 'required, digits, 9 digits starting with 5'),
    'IMPORTERS.PORT_CD.KEY-LISTVAL': ('APEX', 'not needed', 'PORT_CD is always P_CURR_PORT_CD (read-only)'),
    'IMPORTERS.PORT_CD2.WHEN-BUTTON-PRESSED': ('APEX', 'not needed', 'LOV button of the read-only PORT_CD'),
    'IMPORTERS.CREATION_FLAG2.WHEN-BUTTON-PRESSED': ('DROPPED', '-', 'LOV button of a non-displayed item'),
    'IMPORTERS.CUSTOMS_ENTERED2.WHEN-BUTTON-PRESSED': ('DROPPED', '-', 'LOV button of a non-displayed item'),
    'PU.ADJ_FUNS': (C, 'ADJ_FUNS', 'IMPR_MCI_SERVICE enabled / disabled'),
    'PU.EXEC_FUNS': (C, 'EXEC_FUNS', 'function IMPR_MCI_SERVICE'),
    'PU.UPDATE_IMPORTER': (C, 'UPDATE_IMPORTER_CONFIRM_TEXT + update_importer (private, via EXEC_FUNS)', 'Confirm, UPDATE_IMPORTERS_NAMES, re-query; COMMITs removed'),
    'PU.INSERT_AUDIT_RECORD': (C, 'insert_audit_record (private)', 'IMPR_UPDTS row, 9-140'),
    'PU.CHK_IMPR_DUPL': (C, 'chk_impr_dupl (private)', 'duplicate BUS_ID / branch'),
    'PU.GET_MAIN_CR_DATA': (C, 'NATIONAL_NBR_VALIDATE_ITEM', 'MCISERVICE.getMainCRInfoCall'),
    'PU.GET_BRANCH_CR_DATA': (C, 'NATIONAL_NBR_VALIDATE_ITEM', 'MCISERVICE.getBranchCRInfoCall'),
    'PU.GET_CR_DATA': (C, 'get_cr_data (private)', 'parse of the web-service answer (loop instead of 16 SELECT INSTR FROM DUAL)'),
    'PU.CGRI$CHK_IMPORTERS': (C, 'CGRI$CHK_IMPORTERS (private, generated)', '36 dependent-table checks'),
    'PU.CGTE$CHECK_CONSTRAINT_VIO': (C, 'importers_on_error (private)', 'constraint messages'),
    'PU.CGSF$CLRLU_IMPORTERS_IMP_BUS_I': (C, 'city_code_of_id_logic / PRE_INSERT (private)', 'clear the city-of-ID lookups'),
    'PU.CGFK$CHK_IMPORTERS_IMP_ADD_CIT': (C, 'address_city_lookup (private)', 'FK lookup'),
    'PU.CGFK$CHK_IMPORTERS_IMP_BUS_ID_': (C, 'city_code_of_id_logic (private)', 'FK lookup'),
    'PU.CGFK$CHK_IMPORTERS_IMP_CTRY_FK': (C, 'ctry_cd_logic (private)', 'FK lookup'),
    'PU.CGFK$CHK_IMPORTERS_IMP_ITIDT_F': (C, 'impr_type_cd_logic (private)', 'FK lookup'),
    'PU.CGFK$CHK_IMPORTERS_IMP_SDP_FK': (C, 'port_cd_logic (private)', 'FK lookup'),
    'PU.CGFK$QRY_IMPORTERS_IMP_ADD_CIT': (C, 'POST_QUERY', 'FK lookup on query'),
    'PU.CGFK$QRY_IMPORTERS_IMP_BUS_ID_': (C, 'POST_QUERY', 'FK lookup on query'),
    'PU.CGFK$QRY_IMPORTERS_IMP_CTRY_FK': (C, 'POST_QUERY', 'FK lookup on query'),
    'PU.CGFK$QRY_IMPORTERS_IMP_ITIDT_F': (C, 'POST_QUERY', 'FK lookup on query'),
    'PU.CGFK$QRY_IMPORTERS_IMP_SDP_FK': (C, 'POST_QUERY', 'FK lookup on query'),
    'PU.CGFK$CHK_IMPORTERS_IMP_MB_FK': ('DROPPED', '-', 'not called by any active code'),
    'PU.CALL_LOV_COUNTRIES': ('APEX', 'Popup LOV LOV_COUNTRIES + CTRY_CD_WHEN_VALIDATE_ITEM', 'CALL_FORM LOV_COUNTRIES'),
    'PU.CALL_LOV_COUN_GULF': ('APEX', 'Popup LOV LOV_COUNTRIES_GULF + CTRY_CD_WHEN_VALIDATE_ITEM', 'CALL_FORM LOV_COUNTRIES_GULF'),
    'PU.CG$WHEN_NEW_FORM_INSTANCE': ('APEX', 'shared LOVs', 'CGDV$POPULATE_DYNAMIC_LISTS'),
    'PU.CGDV$POPULATE_DYNAMIC_LISTS': ('APEX', 'shared LOVs LOV_COMM_RGSTRTN_TYPE / LOV_ALLOWED_EXPORT (REFERENCE_CODES)', 'list items from CG_REF_CODES'),
    'PU.CG$IMPR1130_PROD_CENTRL_GLOBAL': ('DROPPED', '-', 'IMPORTERS_WHERE variable of PRE-QUERY (search page SQL)'),
    'PU.DEV_VERSIONS': ('DROPPED', '-', 'developer comment (version 8) -> PKG_VERSION'),
    'PU.EXECUTE_FUNCTION': ('APEX', 'f345 Page Functions list (page 0 FUNCS)', 'TMPLT function runner (CALL_FORM / RUN_PRODUCT by SC_SYSTEM_OBJECTS)'),
}
FRAME = ('FORM.KEY-', 'FORM.ON-', 'FORM.WHEN-MOUSE', 'FORM.WHEN-TIMER', 'FORM.WHEN-WINDOW', 'TOOLBAR.', 'TITLE.', 'LSIDE.', 'EDI_MSG.')
FRAME_PU = {'PU.CHECK_EDI_MSG_LOV', 'PU.CHECK_EDI_MSG_TIMER', 'PU.CHECK_EDI_ROLE_ID', 'PU.CHECK_TIMEOUT', 'PU.EDI_MSG_LOV',
            'PU.FOR_EDI_MSG', 'PU.MOUSE_CLICK', 'PU.PRINT_REPORT', 'PU.RETURN_MSG', 'PU.TERMINATE_FUN', 'PU.TOGGEL_WND',
            'PU.TURN_MSG', 'PU.WHEN_TIMER_EXPIRED_MSG'}

rows = []
for k in sorted(x for x, v in u30.items() if v.strip()):
    same = 'yes' if u10.get(k, '').strip() == u30[k].strip() else ('new' if not u10.get(k, '').strip() else 'changed')
    if k in M:
        grp, target, note = M[k]
    elif k == 'FORM.PRE-FORM':
        grp, target, note = 'DROPPED', 'f345 globalization', 'NIB.PRE_FORM, date-format ALTER SESSION, help path'
    elif k.startswith(FRAME) or k in FRAME_PU:
        grp, target, note = 'DROPPED', 'f345 frame', 'screen frame: NIB / TMPLT / toolbar / timers / windows (replaced by f345 page template, page 0 toolbar, FUNCS)'
    elif k.endswith('.KEY-LISTVAL'):
        grp, target, note = 'DROPPED', '-', 'Designer "may the LOV be shown" check of an item without an LOV call (APEX: no LOV, or the LOV of the item)'
    else:
        sys.exit('not classified: ' + k)
    for name in re.findall(r'\b([A-Z][A-Z0-9_$#]{3,})\b', target):
        if grp in (C, 'RULES') and '(private' not in target and name not in public and name not in ('POST_QUERY',):
            sys.exit('member not in spec: %s (%s)' % (name, k))
    rows.append((k, same, grp, target, note))

cnt = collections.Counter(r[2] for r in rows)
with open('work/IMPR1130/step02/classification.md', 'w', encoding='utf-8') as o:
    o.write('# IMPR1130 - classification of the code units (step 02)\n\n')
    o.write('Generated by `work/IMPR1130/step02/classify.py`. %d units with code: %s. Column *IMPR1110* = the Forms code '
            'is identical in IMPR1110 (yes), differs (changed) or exists only in IMPR1130 (new).\n\n'
            % (len(rows), ', '.join('%s %d' % kv for kv in sorted(cnt.items()))))
    o.write('| Unit | IMPR1110 | Group | Target | Note |\n|---|---|---|---|---|\n')
    for r in rows:
        o.write('| `%s` | %s | %s | %s | %s |\n' % r)
print(dict(cnt), len(rows))
