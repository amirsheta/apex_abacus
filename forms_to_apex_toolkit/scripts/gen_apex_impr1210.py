# -*- coding: utf-8 -*-
"""
gen_apex_impr1210.py - step 04: APEX 21.2 component export of IMPR1210 (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c / 4d, docs/f345_reference_standard.md).
Cloned from scripts/gen_apex_impr1160.py (editable Form region, helpers, search page); the function events follow
scripts/gen_apex_impr1150.py, the Confirm action scripts/gen_apex_impr1125.py.

Design: analysis/IMPR1210/IMPR1210_apex_page_spec.md. The design data is in this file (ITEMS, HIDDEN, MESSAGES,
VALIDATIONS, PROCESSES, COMPUTATIONS, DAS, AUTH_SQL, SEARCH_SQL): change it here, re-run, and keep the spec in step.

Reads
  apex/Reference/f345.sql             template ids, existing ids / items / LOVs (checks)
  apex/*/f345_*.sql                   the other component exports (page group IMPR, LOV_IMPR, LOV_ALLOWED_EXPORT, id clashes)
  plsql/IMPR1210/impr1210_spec.sql    members of package IMPR1210 (checks)
Writes
  apex/IMPR1210/f345_impr1210.sql     component export, REVIEW BEFORE IMPORT (4 placeholders)
  apex/IMPR1210/f<app>_impr1210_import.sql  with --workspace-id --app-id --id-offset --schema
  work/IMPR1210/step04/uncertain.json parameters f345 does not show (import_notes.md)

Declarative: editable native Form region on AGNTS (key ROWID, i:u; a used / cancelled authorization is read only through
IMPR1210.AGNTS_IS_READ_ONLY), FOS + native actions (Confirm, Refresh, Set Focus, Submit), validations and processes =
one call into IMPR1210 / FORMS_APX. No JavaScript file, no AJAX callback. IDs are deterministic: re-running gives the
same file.

Usage (from forms_to_apex_toolkit):  python3 -I scripts/gen_apex_impr1210.py [--workspace-id=.. --app-id=.. --id-offset=.. --schema=..]
"""
import os, re, sys, json, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
import number_only      # Number Field items: CSS class number_only + one page-load handler on page 0
import functions_drawer # the FUNCS region is on page 0, never on a form page
import item_icons       # Post Text icon next to every entry item
import items_to_submit  # every page item a query / LOV / FOS call reads is in its Items to Submit
import client_condition  # an item in an item-type client-side condition has a default value (user rule 2026-11-26)
import lov_apx          # shared LOVs: function body returning SQL, code in LOV_APX (CLAUDE.md 4d)
import forms_apx_helpers
import parameter_names

REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')
PKG = os.path.join(ROOT, 'plsql', 'IMPR1210', 'impr1210_spec.sql')
OUT = os.path.join(ROOT, 'apex', 'IMPR1210', 'f345_impr1210.sql')
OTHER_EXPORTS = sorted(f for f in glob.glob(os.path.join(ROOT, 'apex', '*', 'f345_*.sql'))
                       if os.sep + 'IMPR1210' + os.sep not in f and os.sep + 'Reference' + os.sep not in f)
DATE, STAMP = '2026-11-25', '20261125000000'
FORM = 'IMPR1210'
PG, PG_SEARCH = 1210, 121001
PI = 'P1210_'
SHARED_BASE = 9210                 # IMPR1110 9000, IMPR1116 9116, ... IMPR1160 9160, IMPR1170 9170
IMPR1110_IDS = dict(PAGE_GROUP_IMPR='900001000010')   # created by the IMPR1110 export: reused
REUSED_LOVS = ['LOV_IMPR', 'LOV_ALLOWED_EXPORT']     # created by the IMPR1110 export: reused by name

F345 = dict(
    UI='11622010846008869795', PAGE_MAIN='11622270914969205733', REGION_HERO='11621859120066869682',
    REGION_FORM='11621909206693869707', REGION_GRID='11621913486616869708',
    LABEL_REQ='11621984380233869750', LABEL_OPT='11621983529556869749',
    BUTTON='11621986167597869752', P0_ACTIONS='73488102084440079322')
ITEM_OPTS = '#DEFAULT#:t-Form-fieldContainer--stretchInputs'
HIJRI_MASK = '&P1210_HIJRI_DATE_FORMAT.'
HIJRI_PLACEHOLDER = 'placeholder="%s"' % 'سنة-شهر-يوم'   # default HIJRI_DATE_FORMAT YYYY-MM-MI (as IMPR1110)

# ============================================================================= design data (spec sections 4-10)
RECORD = ':P0_PAGE_PK IS NOT NULL'   # a queried record (ATHRZTN_SEQ_NBR: Update Allowed = false)
# WHEN-NEW-RECORD-INSTANCE MAKE_BLOCK_FULL_OPERATION: a used / cancelled authorization cannot be changed
LOCKED = ('IMPR1210.AGNTS_IS_READ_ONLY(P_PORT_CD => :P1210_PORT_CD, '
          'P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR)')
# items of page 1210 in canvas order (rows by Y, then X): name, column, type, label, data type, newline, span, extra
ITEMS = [
    ('PORT_CD', 'PORT_CD', 'NATIVE_DISPLAY_ONLY', 'رمز الجمرك', 'NUMBER', True, 2,
     dict(send=True, src='AGNTS.PORT_CD (CGSO$CHAR_ARB Required, Insert / Update Allowed = false; WHEN-CREATE-RECORD '
                         ':= P_CURR_PORT_CD; LOV CGFK$AGNTS_PORT_CD / KEY-LISTVAL LOV_SD_PORTS / button PORT_CD2 unreachable)')),
    ('PORT_NAME', None, 'NATIVE_DISPLAY_ONLY', 'اسم الجمرك', None, False, 4,
     dict(src='AGNTS.PORT_NAME (non-database CGSO$CHAR_ARB_DO; WHEN-CREATE-RECORD / POST-QUERY)')),
    ('ATHRZTN_SEQ_NBR', 'ATHRZTN_SEQ_NBR', 'NATIVE_NUMBER_FIELD', 'مسلسل التفويض', 'NUMBER', False, 2,
     dict(maxlen=11, read_only=RECORD,
          src='AGNTS.ATHRZTN_SEQ_NBR (Update Allowed = false; hint "للإستعلام أدخل مسلسل التفويض - لإدخال تفويض جديد اترك '
              'الخانة بدون بيانات"; PRE-INSERT MAX + 1)')),
    ('ALLOW_EXPORT', 'ALLOW_EXPORT', 'NATIVE_SELECT_LIST', 'إستخدام التفويض', 'NUMBER', True, 2,
     dict(req=True, lov='LOV_ALLOWED_EXPORT', lov_null='NO', default='0', read_only=LOCKED,
          src='AGNTS.ALLOW_EXPORT (CGSO$POP_MD Required, default 0; CGDV$POPULATE_DYNAMIC_LISTS CG_REF_CODES ALLOWED EXPORT)')),
    ('IMPR_NBR', 'IMPR_NBR', 'NATIVE_POPUP_LOV', 'رقم المستورد', 'NUMBER', True, 2,
     dict(req=True, lov='LOV_IMPR', maxlen=11, read_only=LOCKED,
          src='AGNTS.IMPR_NBR (Required; KEY-LISTVAL / button IMP_LOV -> LOV form LOV_IMPR, PORT_CD = P_CURR_PORT_CD)')),
    ('IMPR_EXPR_TYPE', None, 'NATIVE_DISPLAY_ONLY', 'نشاط المستورد', None, False, 2,
     dict(lov='LOV_ALLOWED_EXPORT', src='AGNTS.IMPR_EXPR_TYPE (non-database CGSO$POP_DO, list ALLOWED EXPORT; '
                                        'CGFK$CHK_AGNTS_AG_IMP_FK / POST-QUERY)')),
    ('IMPR_NAME', None, 'NATIVE_DISPLAY_ONLY', 'اسم المستورد', None, True, 8,
     dict(src='AGNTS.IMPR_NAME (non-database; IMPR_NBR WHEN-VALIDATE-ITEM / POST-QUERY)')),
    ('IMPR_NBR_AG', 'IMPR_NBR_AGENT_ID', 'NATIVE_POPUP_LOV', 'رقم الشركة الوسيطة', 'NUMBER', True, 2,
     dict(req=True, lov='LOV_IMPR', maxlen=11, read_only=LOCKED,
          src='AGNTS.IMPR_NBR_AG (column IMPR_NBR_AGENT_ID, Required; KEY-LISTVAL / button AGNT_LOV -> LOV form LOV_IMPR)')),
    ('IMPR_EXPR_TYPE_AG', None, 'NATIVE_DISPLAY_ONLY', 'نشاط الشركة الوسيطة', None, False, 2,
     dict(lov='LOV_ALLOWED_EXPORT', src='AGNTS.IMPR_EXPR_TYPE_AG (non-database CGSO$POP_DO; CGFK$CHK_AGNTS_AG_IMP_AGENT_ID / '
                                        'POST-QUERY)')),
    ('IMPR_NAME_AG', None, 'NATIVE_DISPLAY_ONLY', 'اسم الشركة الوسيطة', None, True, 8,
     dict(src='AGNTS.IMPR_NAME_AG (non-database; IMPR_NBR_AG WHEN-VALIDATE-ITEM / POST-QUERY)')),
    ('ATHRZTN_NOTE', 'ATHRZTN_NOTE', 'NATIVE_TEXT_FIELD', 'ملاحظات', 'VARCHAR2', True, 8,
     dict(maxlen=51, read_only=LOCKED, src='AGNTS.ATHRZTN_NOTE (CGSO$CHAR_ARB, 51 characters)')),
    ('ATHRZTN_CRET_DT', 'ATHRZTN_CRET_DT', 'NATIVE_DISPLAY_ONLY', 'تاريخ التفويض', 'DATE', True, 2,
     dict(mask=HIJRI_MASK, src='AGNTS.ATHRZTN_CRET_DT (CGSO$HDATE_ARB_DO Hijri MI-MM-RRRR, never enterable; PRE-INSERT '
                               'current Hijri date; WHEN-VALIDATE-ITEM HIJDATE.VALID_HIJ_DATE dropped)')),
    ('UPDATE_STATUS', None, 'NATIVE_DISPLAY_ONLY', 'حالة التعديل', None, False, 6,
     dict(src='AGNTS.UPDATE_STATUS (non-database CGSO$CHAR_ARB_DO; WHEN-NEW-RECORD-INSTANCE message 8-30 / 8-80 / '
               '"يمكن التعديل")')),
    ('ATHRZTN_STA_CD', 'ATHRZTN_STA_CD', 'NATIVE_RADIOGROUP', 'وضع التفويض', 'NUMBER', True, 2,
     dict(req=True, static='STATIC2:ساري;1,غير ساري;2', default='1', read_only=LOCKED,
          src='AGNTS.ATHRZTN_STA_CD (CGSO$RADIO_MD Required, default 1, radio B_1 ساري = 1 / B_2 غير ساري = 2; PRE-INSERT '
              ':= 1; EXEC_FUNS; enterable as in Forms, inventory 15 #3)')),
    ('ATHRZTN_CNCLD_DT', 'ATHRZTN_CNCLD_DT', 'NATIVE_DISPLAY_ONLY', 'تاريخ الغاء التفويض', 'DATE', False, 2,
     dict(mask=HIJRI_MASK, src='AGNTS.ATHRZTN_CNCLD_DT (CGSO$HDATE_ARB_DO Hijri, never enterable; EXEC_FUNS CD1_STOPIMPRAUTH; '
                               'WHEN-VALIDATE-ITEM dropped)')),
]
# not displayed: name, column, data type, kind, mask, value protected, source
HIDDEN = [
    ('ROW_ID', 'ROWID', 'ROWID', 'NATIVE_HIDDEN', None, 'Y', 'AGNTS ROWID (Form region primary key, = P0_PAGE_PK)'),
    ('MODULE_ID', None, None, 'NATIVE_HIDDEN', None, 'Y', 'f345 Page Functions: P<page>_MODULE_ID'),
    ('HIJRI_DATE_FORMAT', None, None, 'NATIVE_HIDDEN', None, 'Y', 'FORMS_APX.HIJRI_DATE_FORMAT (format mask of the Hijri dates)'),
    ('HERO_TITLE', None, None, 'NATIVE_HIDDEN', None, 'Y', 'f345 hero title (FORMS_APX.HEADER_TITLE)'),
    ('CONFIRM_STOP', None, None, 'NATIVE_HIDDEN', None, 'Y',
     'PU EXEC_FUNS STR.DispArbMsg(9, 50, CONFIRM): text of the cancel confirmation (FORMS_APX.ARABIC_MESSAGE)'),
]
LOVS = []   # no new shared LOV: LOV_IMPR and LOV_ALLOWED_EXPORT come from the IMPR1110 export
MESSAGES = [  # AGNTS.ON-ERROR / CGTE$CHECK_CONSTRAINT_VIO texts
    ('AG_PK', 'هذا السجل مدخل سابقاً - أعد ادخال البيانات', 'CGTE$CHECK_CONSTRAINT_VIO (ORA-00001)'),
    ('AG_SDP_FK', 'رمز الجمرك غير صحيح - أعد إدخال رمز الجمرك', 'AGNTS.ON-ERROR (ORA-02291)'),
    ('AG_IMP_FK', 'بيانات المستورد غير صحيحة - أعد إدخال البيانات', 'AGNTS.ON-ERROR (ORA-02291)'),
    ('AG_IMP_AGENT_ID_FK', 'بيانات الشركة الوسيطة غير صحيحة - أعد إدخال البيانات', 'AGNTS.ON-ERROR (ORA-02291)')]
SAVE = ":REQUEST IN ('CREATE', 'SAVE')"
CREATE = ":REQUEST = 'CREATE'"
KEYS = 'P_PORT_CD => :P1210_PORT_CD, P_IMPR_NBR => :P1210_IMPR_NBR, P_IMPR_NBR_AG => :P1210_IMPR_NBR_AG'
VALIDATIONS = [   # name, item, code, condition (PL/SQL expression), source
    ('ATHRZTN_SEQ_NBR VALIDATION', 'ATHRZTN_SEQ_NBR',
     'RETURN IMPR1210.ATHRZTN_SEQ_NBR_VALIDATION(P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR);',
     CREATE, 'AGNTS.ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM'),
    ('IMPR_NBR VALIDATION', 'IMPR_NBR', 'RETURN IMPR1210.IMPR_NBR_VALIDATION(%s);' % KEYS, SAVE,
     'AGNTS.IMPR_NBR.WHEN-VALIDATE-ITEM (+ PU CHECK_SUSPENSION)'),
    ('IMPR_NBR_AG VALIDATION', 'IMPR_NBR_AG', 'RETURN IMPR1210.IMPR_NBR_AG_VALIDATION(%s);' % KEYS, SAVE,
     'AGNTS.IMPR_NBR_AG.WHEN-VALIDATE-ITEM (+ PU CHECK_SUSPENSION)'),
]
POST_QUERY = ('IMPR1210.POST_QUERY(%s, P_PORT_NAME => :P1210_PORT_NAME, P_IMPR_NAME => :P1210_IMPR_NAME, '
              'P_IMPR_EXPR_TYPE => :P1210_IMPR_EXPR_TYPE, P_IMPR_NAME_AG => :P1210_IMPR_NAME_AG, '
              'P_IMPR_EXPR_TYPE_AG => :P1210_IMPR_EXPR_TYPE_AG);' % KEYS)
WCR = ('IMPR1210.WHEN_CREATE_RECORD(P_CURR_PORT_CD => :P_CURR_PORT_CD, P_PORT_CD => :P1210_PORT_CD, '
       'P_PORT_NAME => :P1210_PORT_NAME);')
WNRI = ('IMPR1210.WHEN_NEW_RECORD_INSTANCE(P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR, '
        'P_UPDATE_STATUS => :P1210_UPDATE_STATUS);')
USER = 'P_CURR_PORT_CD => :P_CURR_PORT_CD, SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID'
PRE_INSERT = ('IMPR1210.PRE_INSERT(P_PORT_CD => :P1210_PORT_CD, %s, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR, '
              'P_ATHRZTN_STA_CD => :P1210_ATHRZTN_STA_CD, P_ATHRZTN_CRET_DT => :P1210_ATHRZTN_CRET_DT);' % USER)
PRE_UPDATE = ('IMPR1210.PRE_UPDATE(P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR, %s);' % USER)
def exec_funs(code):
    return ("IMPR1210.EXEC_FUNS(P_FUNCTION_CODE => '%s', P_PORT_CD => :P1210_PORT_CD, "
            "P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR, %s);" % (code, USER))
INS = ":P0_PAGE_PK IS NULL AND :REQUEST = 'CREATE'"
UPD = ":P0_PAGE_PK IS NOT NULL AND :REQUEST = 'SAVE'"
FORM_DML = "'DML'"   # marker: Process form (NATIVE_FORM_DML)
# processes: point, seq, name, code, condition (PL/SQL expression | NEVER | None), source, success message
PROCESSES = [
    ('BEFORE_HEADER', 10, 'New', None, 'NEVER', 'f345 session setup copied from AGR1100 (condition Never) / standard 6', None),
    ('BEFORE_HEADER', 20, 'P0_PAGE_PK CHECK', 'IMPR1210.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK, P_CURR_PORT_CD => :P_CURR_PORT_CD);',
     None, 'f345 key (ROWID of AGNTS in the user\'s port, URL-safe from page 121001)', None),
    ('BEFORE_HEADER', 40, 'PARAMETERS',
     ":P1210_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1210_MODULE_ID, FORM_NAME => 'IMPR1210');", None,
     'f345 module id of the Page Functions list', None),
    ('BEFORE_HEADER', 70, 'P0_PAGE_PK', ':P1210_ROW_ID := :P0_PAGE_PK;', None, 'f345 (key = ROWID)', None),
    ('BEFORE_HEADER', 80, 'Initialize form', None, None, 'block AGNTS fetch', None),
    ('BEFORE_HEADER', 82, 'POST-QUERY', POST_QUERY, ':P1210_ROW_ID IS NOT NULL', 'AGNTS.POST-QUERY', None),
    ('BEFORE_HEADER', 84, 'WHEN-CREATE-RECORD', WCR, ':P1210_ROW_ID IS NULL',
     'AGNTS.WHEN-CREATE-RECORD (PORT_CD, PORT_NAME of a new record; after Initialize form, which would clear them)', None),
    ('BEFORE_HEADER', 86, 'WHEN-NEW-RECORD-INSTANCE', WNRI, None, 'AGNTS.WHEN-NEW-RECORD-INSTANCE (UPDATE_STATUS)', None),
    ('BEFORE_HEADER', 100, 'HEADER TITLE',
     "FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1210_MODULE_ID, P_HERO_TITLE => :P1210_HERO_TITLE, "
     "DEFAULT_TITLE => 'صيانة تفاويض الشركات الوسيطة');", None, 'f345 hero title (module title)', None),
    ('AFTER_SUBMIT', 5, 'EXECUTE-QUERY',
     ':P0_PAGE_PK := IMPR1210.PRE_QUERY(P_PORT_CD => :P1210_PORT_CD, P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR);',
     ":REQUEST = 'EXECUTE_QUERY'", 'AGNTS.PRE-QUERY + IMPR_NBR.WHEN-NEW-ITEM-INSTANCE (EXEC_QUERY_NOW -> EXECUTE_QUERY)', None),
    ('AFTER_SUBMIT', 10, 'PRE-INSERT', PRE_INSERT, INS, 'AGNTS.PRE-INSERT', None),
    ('AFTER_SUBMIT', 20, 'PRE-UPDATE', PRE_UPDATE, UPD, 'AGNTS.PRE-UPDATE (+ WHEN-NEW-RECORD-INSTANCE update rule)', None),
    ('AFTER_SUBMIT', 30, 'PRE-DELETE', 'IMPR1210.PRE_DELETE;', ":REQUEST = 'DELETE'",
     'FORM.KEY-DELREC (NIB) + WHEN-NEW-RECORD-INSTANCE: a queried authorization is never deletable', None),
    ('AFTER_SUBMIT', 40, 'Process form', FORM_DML, SAVE, 'block AGNTS DML (insert / update)', 'تم الحفظ بنجاح'),
    ('AFTER_SUBMIT', 50, 'CD1_STOPIMPRAUTH EXECUTE-FUNCTION', exec_funs('CD1_STOPIMPRAUTH'), ":REQUEST = 'CD1_STOPIMPRAUTH'",
     'PU EXECUTE_FUNCTION -> EXEC_FUNS(CD1_STOPIMPRAUTH) (no message in Forms)', None),
    ('AFTER_SUBMIT', 60, 'CD2_REUSEIMPRAUTH EXECUTE-FUNCTION', exec_funs('CD2_REUSEIMPRAUTH'), ":REQUEST = 'CD2_REUSEIMPRAUTH'",
     'PU EXECUTE_FUNCTION -> EXEC_FUNS(CD2_REUSEIMPRAUTH) (no message in Forms)', None),
    ('AFTER_SUBMIT', 80, 'P0_PAGE_PK AFTER INSERT', ':P0_PAGE_PK := :P1210_ROW_ID;', CREATE, 'f345', None),
]
COMPUTATIONS = [   # item, point, expression, source
    ('HIJRI_DATE_FORMAT', 'BEFORE_HEADER', 'FORMS_APX.HIJRI_DATE_FORMAT',
     'Hijri date format from one place: Application Setting HIJRI_DATE_FORMAT (Forms mask MI-MM-RRRR)'),
    ('CONFIRM_STOP', 'BEFORE_HEADER', 'FORMS_APX.ARABIC_MESSAGE(9, 50)',
     'PU EXEC_FUNS STR.DispArbMsg(9, 50, CONFIRM): text of the confirmation of CD1_STOPIMPRAUTH'),
]
def fos(code, submit, ret=()):
    return dict(action='FOS', code=code, submit=list(submit), ret=list(ret))
MSG_REUSE = 'سيتم إسترجاع التفويض - هل ترغب في إستكمال الإسترجاع'
SHOWN = "$v('P1210_ATHRZTN_SEQ_NBR') !== '' && $v('P1210_ATHRZTN_STA_CD') === '%s'"
# dynamic actions: name, event, selection, client condition, fire on init, actions, source
DAS = [
    ('ATHRZTN_SEQ_NBR WHEN-VALIDATE-ITEM', 'change', ('ITEM', 'P1210_ATHRZTN_SEQ_NBR'), ('NOT_NULL', None), False,
     [fos('FORMS_APX.CHECK_ERROR(IMPR1210.ATHRZTN_SEQ_NBR_VALIDATION(P_PORT_CD => :P1210_PORT_CD, '
          'P_ATHRZTN_SEQ_NBR => :P1210_ATHRZTN_SEQ_NBR));', ['P1210_PORT_CD', 'P1210_ATHRZTN_SEQ_NBR']),
      dict(action='SUBMIT', request='EXECUTE_QUERY')],
     'AGNTS.ATHRZTN_SEQ_NBR.WHEN-VALIDATE-ITEM (message 9-40; :GLOBAL.EXEC_QUERY_NOW -> IMPR_NBR.WHEN-NEW-ITEM-INSTANCE '
     'EXECUTE_QUERY)'),
    ('IMPR_NBR WHEN-VALIDATE-ITEM', 'change', ('ITEM', 'P1210_IMPR_NBR'), ('NOT_NULL', None), False,
     [fos('IMPR1210.IMPR_NBR_WHEN_VALIDATE_ITEM(%s, P_IMPR_NAME => :P1210_IMPR_NAME, '
          'P_IMPR_EXPR_TYPE => :P1210_IMPR_EXPR_TYPE);' % KEYS,
          ['P1210_PORT_CD', 'P1210_IMPR_NBR', 'P1210_IMPR_NBR_AG'], ['P1210_IMPR_NAME', 'P1210_IMPR_EXPR_TYPE']),
      dict(action='NATIVE_REFRESH', region='1210:plug:LOV_AGNT_ATHR_IMPR'),
      dict(action='NATIVE_SET_FOCUS', items='P1210_IMPR_NBR_AG')],
     'AGNTS.IMPR_NBR.WHEN-VALIDATE-ITEM (name, CHECK_SUSPENSION, CALL_FORM LOV_AGNT_ATHR_IMPR -> grid of the importer\'s '
     'authorizations) + KEY-LISTVAL GO_ITEM; also after the Popup LOV LOV_IMPR'),
    ('IMPR_NBR_AG WHEN-VALIDATE-ITEM', 'change', ('ITEM', 'P1210_IMPR_NBR_AG'), ('NOT_NULL', None), False,
     [fos('IMPR1210.IMPR_NBR_AG_WHEN_VALIDATE_ITEM(%s, P_IMPR_NAME_AG => :P1210_IMPR_NAME_AG, '
          'P_IMPR_EXPR_TYPE_AG => :P1210_IMPR_EXPR_TYPE_AG);' % KEYS,
          ['P1210_PORT_CD', 'P1210_IMPR_NBR', 'P1210_IMPR_NBR_AG'], ['P1210_IMPR_NAME_AG', 'P1210_IMPR_EXPR_TYPE_AG']),
      dict(action='NATIVE_SET_FOCUS', items='P1210_ATHRZTN_NOTE')],
     "AGNTS.IMPR_NBR_AG.WHEN-VALIDATE-ITEM (name, CHECK_SUSPENSION, <> IMPR_NBR) + KEY-LISTVAL GO_ITEM('ATHRZTN_NOTE')"),
    ('CD1_STOPIMPRAUTH EXECUTE-FUNCTION', 'custom:CD1_STOPIMPRAUTH', ('DOCUMENT', None),
     ('JAVASCRIPT_EXPRESSION', SHOWN % '1'), False,
     [dict(action='NATIVE_CONFIRM', text='&P1210_CONFIRM_STOP.'),
      dict(action='SUBMIT', request='CD1_STOPIMPRAUTH')],
     'PU EXEC_FUNS(CD1_STOPIMPRAUTH): ATHRZTN_SEQ_NBR shown and status 1 -> STR.DispArbMsg(9, 50, CONFIRM) -> request '
     '(event of the f345 Page Functions list)'),
    ('CD2_REUSEIMPRAUTH EXECUTE-FUNCTION', 'custom:CD2_REUSEIMPRAUTH', ('DOCUMENT', None),
     ('JAVASCRIPT_EXPRESSION', SHOWN % '2'), False,
     [dict(action='NATIVE_CONFIRM', text=MSG_REUSE),
      dict(action='SUBMIT', request='CD2_REUSEIMPRAUTH')],
     'PU EXEC_FUNS(CD2_REUSEIMPRAUTH): ATHRZTN_SEQ_NBR shown and status 2 -> STR.DispALERT(... CONFIRM) -> request'),
]
# read-only grid of the importer's authorizations (LOV form LOV_AGNT_ATHR_IMPR, block AGNTS of that form)
AUTH_SQL = '\n'.join([
    '-- LOV form LOV_AGNT_ATHR_IMPR (CALL_FORM from IMPR_NBR.WHEN-VALIDATE-ITEM, parameters PORT_CD, IMPR_NBR): the',
    '-- authorizations of the importer in the port, ORDER BY IMPR_NBR, ATHRZTN_SEQ_NBR (block WHERE / ORDER BY clauses).',
    '-- No rows until an importer is chosen (Forms calls the form only for a typed importer with authorizations).',
    "SELECT TRANSLATE(ROWIDTOCHAR(a.ROWID), '+/', '-_') AS row_id,   -- URL-safe: a '+' in f?p arrives as a space",
    '       a.athrztn_seq_nbr, a.impr_nbr_agent_id, i.arbc_impr_name, ae.rv_meaning AS allow_export_name,',
    '       TO_CHAR(a.athrztn_cret_dt, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS athrztn_cret_dt,',
    "       DECODE(a.athrztn_sta_cd, 1, 'ساري', 2, 'غير ساري') AS athrztn_sta_name",
    '  FROM agnts a, importers i, cg_ref_codes ae',
    ' WHERE a.port_cd = :P1210_PORT_CD',
    '   AND a.impr_nbr = :P1210_IMPR_NBR',
    '   AND i.port_cd (+) = a.port_cd',
    '   AND i.impr_nbr (+) = a.impr_nbr_agent_id',
    "   AND ae.rv_domain (+) = 'ALLOWED EXPORT' AND ae.rv_low_value (+) = TO_CHAR(a.allow_export)",
    ' ORDER BY a.impr_nbr, a.athrztn_seq_nbr'])
AUTH_COLUMNS = [   # name, heading, data type, kind
    ('ROW_ID', None, 'VARCHAR2', 'pk'), ('ATHRZTN_SEQ_NBR', 'رقم التفويض', 'NUMBER', 'link'),
    ('IMPR_NBR_AGENT_ID', 'رمز الشركة الوسيطة', 'NUMBER', 'text'), ('ARBC_IMPR_NAME', 'وصف الشركة الوسيطة', 'VARCHAR2', 'text'),
    ('ALLOW_EXPORT_NAME', 'إستخدام التفويض', 'VARCHAR2', 'text'), ('ATHRZTN_CRET_DT', 'تاريخ انشاء التفويض', 'VARCHAR2', 'text'),
    ('ATHRZTN_STA_NAME', 'وضع التفويض', 'VARCHAR2', 'text')]
SEARCH_SQL = '\n'.join([
    '-- one search text over every shown column; no rows until a search is made (Forms opens in Enter-Query mode).',
    '-- Block WHERE clause: the authorizations of the user\'s port (P_CURR_PORT_CD). No ORDER BY in the block.',
    'SELECT x.*',
    "  FROM (SELECT TRANSLATE(ROWIDTOCHAR(a.ROWID), '+/', '-_') AS row_id,   -- URL-safe: a '+' in f?p arrives as a space",
    '               a.athrztn_seq_nbr, a.impr_nbr, i.arbc_impr_name AS impr_name,',
    '               a.impr_nbr_agent_id AS impr_nbr_ag, g.arbc_impr_name AS impr_name_ag,',
    '               ae.rv_meaning AS allow_export_name, a.athrztn_note,',
    '               TO_CHAR(a.athrztn_cret_dt, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS athrztn_cret_dt,',
    "               DECODE(a.athrztn_sta_cd, 1, 'ساري', 2, 'غير ساري') AS athrztn_sta_name,",
    '               TO_CHAR(a.athrztn_cncld_dt, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS athrztn_cncld_dt',
    '          FROM agnts a, importers i, importers g, cg_ref_codes ae',
    '         WHERE a.port_cd = :P_CURR_PORT_CD',
    '           AND i.port_cd (+) = a.port_cd AND i.impr_nbr (+) = a.impr_nbr',
    '           AND g.port_cd (+) = a.port_cd AND g.impr_nbr (+) = a.impr_nbr_agent_id',
    "           AND ae.rv_domain (+) = 'ALLOWED EXPORT' AND ae.rv_low_value (+) = TO_CHAR(a.allow_export)) x",
    ' WHERE :P121001_SEARCH IS NOT NULL',
    "   AND INSTR(UPPER(x.athrztn_seq_nbr || '|' || x.impr_nbr || '|' || x.impr_name || '|' || x.impr_nbr_ag || '|' ||",
    "                   x.impr_name_ag || '|' || x.allow_export_name || '|' || x.athrztn_note || '|' || x.athrztn_cret_dt || '|' ||",
    "                   x.athrztn_sta_name || '|' || x.athrztn_cncld_dt), UPPER(TRIM(:P121001_SEARCH))) > 0"])
SEARCH_COLUMNS = [   # name, heading, data type, kind
    ('ROW_ID', None, 'VARCHAR2', 'pk'), ('ATHRZTN_SEQ_NBR', 'مسلسل التفويض', 'NUMBER', 'link'),
    ('IMPR_NBR', 'رقم المستورد', 'NUMBER', 'text'), ('IMPR_NAME', 'اسم المستورد', 'VARCHAR2', 'text'),
    ('IMPR_NBR_AG', 'رقم الشركة الوسيطة', 'NUMBER', 'text'), ('IMPR_NAME_AG', 'اسم الشركة الوسيطة', 'VARCHAR2', 'text'),
    ('ALLOW_EXPORT_NAME', 'إستخدام التفويض', 'VARCHAR2', 'text'), ('ATHRZTN_NOTE', 'ملاحظات', 'VARCHAR2', 'text'),
    ('ATHRZTN_CRET_DT', 'تاريخ التفويض', 'VARCHAR2', 'text'), ('ATHRZTN_STA_NAME', 'وضع التفويض', 'VARCHAR2', 'text'),
    ('ATHRZTN_CNCLD_DT', 'تاريخ الغاء التفويض', 'VARCHAR2', 'text')]

# ============================================================================= helpers (as gen_apex_impr1130.py)
def q(s):
    """SQL literal; non-ASCII text -> unistr() as in a real APEX export."""
    if s is None:
        return 'null'
    s = str(s)
    if all(ord(ch) < 128 for ch in s):
        return "'" + s.replace("'", "''") + "'"
    out = []
    for ch in s:
        o = ord(ch)
        out.append('\\005C' if ch == '\\' else "''" if ch == "'" else ch if o < 128 else '\\%04X' % o)
    return "unistr('" + ''.join(out) + "')"

def lit(s):
    """long literal: lines joined with wwv_flow_string.join, pieces < 3000 chars"""
    if s is None:
        return 'null'
    if len(s) <= 3000 and '\n' not in s:
        return q(s)
    lines = []
    for line in s.split('\n'):
        parts = [line[i:i + 3000] for i in range(0, len(line), 3000)] or ['']
        lines.append('\n||'.join(q(p) for p in parts))
    return 'wwv_flow_string.join(wwv_flow_t_varchar2(\n' + ',\n'.join(lines) + '))'

_ids = {}
def nid(key, kind):
    """deterministic id <page or shared base><kind 2><seq 6>"""
    if key in _ids:
        return _ids[key]
    page = key.split(':')[0]
    base = int(page) if page.isdigit() and page != str(SHARED_BASE) else SHARED_BASE
    n = sum(1 for k in _ids if k.split(':')[0] == page and _ids[k][len(str(base)):len(str(base)) + 2] == '%02d' % kind) + 1
    _ids[key] = '%d%02d%06d' % (base, kind, n * 10)
    return _ids[key]
def ref(key):
    if key not in _ids:
        raise KeyError('undefined id ' + key)
    return 'wwv_flow_api.id(%s)' % _ids[key]
def fid(name):
    return 'wwv_flow_api.id(%s)' % F345[name]
def call(proc, params, comment=None):
    lines = ['-- ' + comment] if comment else []
    lines.append('wwv_flow_api.%s(' % proc)
    first = True
    for k, v in params:
        if v is None or v == 'null':
            continue
        lines.append('%s%s=>%s' % (' ' if first else ',', k, v))
        first = False
    lines.append(');')
    return '\n'.join(lines)
def block(title, body):
    return 'prompt --%s\nbegin\n%s\nend;\n/\n' % (title, body)
src = lambda s: q('Source: ' + s)
UNCERTAIN = set()

def page_item(page, plug_key, seq, it, form_region=False):
    """create_page_item: attributes as gen_apex_impr1140.page_item (+ Hijri text field and textarea of gen_apex_impr1110)
       it: name, kind, label, column, data_type, pk, req, lov, lov_null, default, mask, maxlen, read_only, hijri, send,
           value_protected, protect, span, newline, hidden_column, comment"""
    name, k = it['name'], it['kind']
    p = [('p_id', 'wwv_flow_api.id(%s)' % nid('%s:item:%s' % (page, name), 4)), ('p_name', q(name))]
    if form_region and it.get('column'):
        p.append(('p_source_data_type', q(it['data_type'])))
        if it.get('pk'):
            p.append(('p_is_primary_key', 'true'))
    if it.get('req'):
        p.append(('p_is_required', 'true'))
    p += [('p_item_sequence', str(seq)), ('p_item_plug_id', ref(plug_key))]
    if form_region and it.get('column'):
        p.append(('p_item_source_plug_id', ref(plug_key)))
    p += [('p_item_default', q(it.get('default'))), ('p_prompt', q(it.get('label'))), ('p_format_mask', q(it.get('mask')))]
    if form_region and it.get('column'):
        p += [('p_source', q(it['column'])), ('p_source_type', q('REGION_SOURCE_COLUMN'))]
    p.append(('p_display_as', q(k)))
    if it.get('lov'):
        p += [('p_named_lov', q(it['lov'])), ('p_lov_display_null', q(it.get('lov_null', 'YES')))]
        if it.get('lov_null', 'YES') == 'YES' and k == 'NATIVE_SELECT_LIST':
            p.append(('p_lov_null_text', q('-')))
    if it.get('static'):
        # Forms radio group: static values from the XML (RadioButton labels / values)
        p += [('p_lov', q(it['static'])), ('p_lov_display_null', q('NO'))]
        UNCERTAIN.add('NATIVE_RADIOGROUP with an inline STATIC2 LOV, p_attribute_01 (columns) / 02 (page action NONE) - '
                      'no radio group in f345 / f202604')
    if k in ('NATIVE_TEXT_FIELD', 'NATIVE_NUMBER_FIELD', 'NATIVE_POPUP_LOV', 'NATIVE_TEXTAREA'):
        p.append(('p_cSize', '30'))
    if it.get('maxlen') and k in ('NATIVE_TEXT_FIELD', 'NATIVE_NUMBER_FIELD', 'NATIVE_POPUP_LOV', 'NATIVE_TEXTAREA'):
        p.append(('p_cMaxlength', str(it['maxlen'])))
    if k == 'NATIVE_TEXTAREA':
        p.append(('p_cHeight', '3'))
    css = number_only.add_class(None) if k == 'NATIVE_NUMBER_FIELD' else ('hijri-date-default' if it.get('hijri') else None)
    if css:
        p.append(('p_tag_css_classes', q(css)))
    if item_icons.post_text(name, k):
        p.append(('p_post_element_text', q(item_icons.post_text(name, k))))
    if k != 'NATIVE_HIDDEN':
        p.append(('p_begin_on_new_line', q('YES' if it.get('newline', True) else 'NO')))
        if it.get('span'):
            p.append(('p_colspan', str(it['span'])))
        if it.get('hidden_column'):
            p.append(('p_grid_column_css_classes', q('u-hidden')))
    ro = it.get('read_only')
    if ro:
        p += [('p_read_only_when', q(ro)), ('p_read_only_when2', q('PLSQL')), ('p_read_only_when_type', q('EXPRESSION'))]
        UNCERTAIN.add('p_read_only_when2 => PLSQL with p_read_only_when_type => EXPRESSION (f345 shows the pattern only for p_display_when)')
    if k != 'NATIVE_HIDDEN':
        p += [('p_field_template', fid('LABEL_REQ' if it.get('req') else 'LABEL_OPT')), ('p_item_template_options', q(ITEM_OPTS))]
    if it.get('hijri'):
        p.append(('p_tag_attributes', q(HIJRI_PLACEHOLDER)))
    p.append(('p_is_persistent', q('N')))
    if it.get('protect'):
        p.append(('p_protection_level', q(it['protect'])))
    if k == 'NATIVE_TEXT_FIELD':
        p += [('p_attribute_01', q('N')), ('p_attribute_02', q('N')), ('p_attribute_04', q('TEXT')), ('p_attribute_05', q('BOTH'))]
    elif k == 'NATIVE_NUMBER_FIELD':
        p += [('p_attribute_03', q('right'))]
    elif k == 'NATIVE_SELECT_LIST':
        p += [('p_attribute_01', q('NONE')), ('p_attribute_02', q('N'))]
    elif k == 'NATIVE_POPUP_LOV':
        p += [('p_attribute_01', q('DIALOG')), ('p_attribute_02', q('FIRST_ROWSET')), ('p_attribute_03', q('N'))]
    elif k == 'NATIVE_RADIOGROUP':
        p += [('p_attribute_01', q('2')), ('p_attribute_02', q('NONE'))]
    elif k == 'NATIVE_TEXTAREA':
        p += [('p_attribute_01', q('Y')), ('p_attribute_02', q('N')), ('p_attribute_03', q('N')), ('p_attribute_04', q('BOTH'))]
    elif k == 'NATIVE_DISPLAY_ONLY':
        # p_attribute_01 = Send On Page Submit (N: server value set by processes / FOS; Y: PORT_CD read by FOS)
        p += [('p_attribute_01', q('Y' if it.get('send') else 'N')), ('p_attribute_02', q('LOV' if it.get('lov') else 'VALUE')),
              ('p_attribute_04', q('N')),
              ('p_attribute_05', q('PLAIN'))]
    elif k == 'NATIVE_HIDDEN':
        p += [('p_attribute_01', q(it.get('value_protected') or 'Y'))]
    p.append(('p_item_comment', q(it.get('comment'))))
    return call('create_page_item', p)

def da(page, n, name, event, selection, condition, init, actions, source):
    ek = '%s:da:%s' % (page, name)
    nid(ek, 8)
    prm = [('p_id', ref(ek)), ('p_name', q(name)), ('p_event_sequence', str(n * 10))]
    if selection and selection[0] == 'ITEM':
        prm += [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q(selection[1]))]
    elif selection and selection[0] == 'DOCUMENT':
        prm += [('p_triggering_element_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_element', q('document'))]
    if condition:
        prm.append(('p_triggering_condition_type', q(condition[0])))
        if condition[1]:
            prm.append(('p_triggering_expression', q(condition[1])))
        UNCERTAIN.add('DA client-side condition p_triggering_condition_type / p_triggering_expression (not in f345)')
    if event.startswith('custom:'):
        prm += [('p_bind_type', q('bind')), ('p_bind_event_type', q('custom')), ('p_bind_event_type_custom', q(event[7:]))]
    else:
        prm += [('p_bind_type', q('bind')), ('p_bind_event_type', q(event))]
    prm.append(('p_da_event_comment', src('%s.%s / spec 10' % (FORM, source))))
    out = [call('create_page_da_event', prm)]
    seq = {'TRUE': 0, 'FALSE': 0}
    for a in actions:
        res = a.get('result', 'TRUE')
        seq[res] += 10
        ak = '%s:daa:%s:%s:%d' % (page, name, res, seq[res])
        nid(ak, 9)
        base = [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q(res)),
                ('p_action_sequence', str(seq[res])), ('p_execute_on_page_init', q('Y' if init else 'N'))]
        act = a['action']
        if act == 'FOS':
            base += [('p_action', q('PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE')), ('p_attribute_01', lit(a['code'])),
                     ('p_attribute_02', q(','.join(a['submit']) or None)), ('p_attribute_03', q(','.join(a['ret']) or None)),
                     ('p_attribute_05', q('#SQLERRM#')), ('p_attribute_15', q('suppressChangeEvent:escape-message')),
                     ('p_wait_for_result', q('Y'))]
        elif act == 'SUBMIT':
            base += [('p_action', q('NATIVE_SUBMIT_PAGE')), ('p_attribute_01', q(a['request'])), ('p_attribute_02', q('Y'))]
            UNCERTAIN.add('NATIVE_SUBMIT_PAGE attributes 01 / 02 (not in f345)')
        elif act in ('NATIVE_HIDE', 'NATIVE_SHOW', 'NATIVE_SET_FOCUS'):
            base += [('p_action', q(act)), ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q(a['items']))]
            if act == 'NATIVE_HIDE':
                base.append(('p_attribute_01', q('N')))
            UNCERTAIN.add('NATIVE_SHOW / NATIVE_HIDE / NATIVE_SET_FOCUS with p_affected_elements items (f345 hides a region only)')
        elif act == 'NATIVE_CONFIRM':
            base += [('p_action', q('NATIVE_CONFIRM')), ('p_attribute_01', q(a['text']))]
            UNCERTAIN.add('NATIVE_CONFIRM with the text in p_attribute_01 (as page 1125); &P1210_CONFIRM_STOP. substitution in it')
        elif act == 'NATIVE_REFRESH':
            base += [('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')),
                     ('p_affected_region_id', ref(a['region']))]
        elif act == 'NATIVE_ALERT':
            base += [('p_action', q('NATIVE_ALERT')), ('p_attribute_01', q(a['text']))]
            UNCERTAIN.add('NATIVE_ALERT with the text in p_attribute_01 (as page 1140; not in f345)')
        else:
            raise ValueError(act)
        out.append(call('create_page_da_action', base))
    return '\n'.join(out)

def process(key, seq, point, name, code, cond, s, ptype='NATIVE_PLSQL', extra=None, region=None, success=None):
    nid(key, 7)
    prm = [('p_id', ref(key)), ('p_process_sequence', str(seq)), ('p_process_point', q(point))]
    if region:
        prm.append(('p_region_id', ref(region)))
    prm += [('p_process_type', q(ptype)), ('p_process_name', q(name)),
            ('p_process_sql_clob', lit(code) if code else None), ('p_process_clob_language', q('PLSQL') if code else None)]
    prm += (extra or [])
    prm.append(('p_error_display_location', q('INLINE_IN_NOTIFICATION')))
    if cond == 'NEVER':
        prm.append(('p_process_when_type', q('NEVER')))
    elif cond:
        prm += [('p_process_when', q(cond)), ('p_process_when_type', q('EXPRESSION')), ('p_process_when2', q('PLSQL'))]
    if success:
        prm.append(('p_process_success_message', q(success)))
    prm.append(('p_process_comment', src(s)))
    return call('create_page_process', prm)

def ig_region(page, rk, sql, items_submit, cols, uid, empty_msg, search, comment, name, static_id, seq, link=None):
    """read-only Interactive Grid (search grid 115001 / documents grid IMPORTER_DOCS)"""
    out = []
    nid(rk, 1)
    out.append(call('create_page_plug', [
        ('p_id', ref(rk)), ('p_plug_name', q(name)), ('p_region_name', q(static_id)),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', str(seq)), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(sql)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q(items_submit)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src(comment))]))
    filt = [('p_enable_filter', 'true'), ('p_filter_operators', q('C:S:CASE_INSENSITIVE:REGEXP')), ('p_filter_is_required', 'false'),
            ('p_filter_text_case', q('MIXED')), ('p_filter_lov_type', q('NONE')), ('p_use_as_row_header', 'false'),
            ('p_enable_sort_group', 'true'), ('p_enable_control_break', 'true'), ('p_enable_hide', 'true'),
            ('p_is_primary_key', 'false'), ('p_duplicate_value', 'true'), ('p_include_in_export', 'true')]
    for i, (c, h, dt, kind) in enumerate(cols):
        key = '%s:col:%s' % (rk, c)
        nid(key, 2)
        prm = [('p_id', ref(key)), ('p_name', q(c)), ('p_source_type', q('DB_COLUMN')), ('p_source_expression', q(c)),
               ('p_data_type', q(dt)), ('p_is_query_only', 'false')]
        if kind == 'pk':
            prm += [('p_item_type', q('NATIVE_HIDDEN')), ('p_display_sequence', str((i + 1) * 10)), ('p_attribute_01', q('N')),
                    ('p_use_as_row_header', 'false'), ('p_enable_sort_group', 'false'), ('p_is_primary_key', 'true'),
                    ('p_duplicate_value', 'true'), ('p_include_in_export', 'false')]
        elif kind == 'hidden':
            prm += [('p_item_type', q('NATIVE_HIDDEN')), ('p_display_sequence', str((i + 1) * 10)), ('p_attribute_01', q('N')),
                    ('p_use_as_row_header', 'false'), ('p_enable_sort_group', 'false'), ('p_is_primary_key', 'false'),
                    ('p_duplicate_value', 'true'), ('p_include_in_export', 'false')]
        elif kind == 'link':
            prm += [('p_item_type', q('NATIVE_LINK')), ('p_heading', q(h)), ('p_heading_alignment', q('CENTER')),
                    ('p_display_sequence', str((i + 1) * 10)), ('p_value_alignment', q('CENTER')),
                    ('p_link_target', q(link)), ('p_link_text', q('&%s.' % c)), ('p_link_attributes', q('target="_top"'))] + filt
        else:
            prm += [('p_item_type', q('NATIVE_DISPLAY_ONLY')), ('p_heading', q(h)), ('p_heading_alignment', q('CENTER')),
                    ('p_display_sequence', str((i + 1) * 10)), ('p_value_alignment', q('CENTER')),
                    ('p_attribute_02', q('VALUE')), ('p_attribute_05', q('PLAIN'))] + filt
        out.append(call('create_region_column', prm))
    gk, rpk, vk = rk + ':ig', rk + ':igr', rk + ':igv'
    nid(gk, 3); nid(rpk, 3); nid(vk, 3)
    out.append(call('create_interactive_grid', [
        ('p_id', ref(gk)), ('p_internal_uid', uid), ('p_is_editable', 'false'), ('p_lazy_loading', 'true' if search else 'false'),
        ('p_requires_filter', 'false'), ('p_select_first_row', 'true'), ('p_fixed_row_height', 'true'), ('p_pagination_type', q('SET')),
        ('p_show_total_row_count', 'false' if search else 'true'), ('p_no_data_found_message', q(empty_msg)),
        ('p_show_toolbar', 'true'),
        ('p_toolbar_buttons', q('ACTIONS_MENU:RESET' if search else 'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET')),
        ('p_enable_save_public_report', 'false'), ('p_enable_subscriptions', 'true'), ('p_enable_flashback', 'true'),
        ('p_define_chart_view', 'true'), ('p_enable_download', 'true'), ('p_download_formats', q('CSV:HTML:XLSX:PDF')),
        ('p_enable_mail_download', 'true'), ('p_fixed_header', q('PAGE')), ('p_show_icon_view', 'false'), ('p_show_detail_view', 'false')]))
    out.append(call('create_ig_report', [('p_id', ref(rpk)), ('p_interactive_grid_id', ref(gk)), ('p_static_id', q(uid[:-1] + '2')),
                                         ('p_type', q('PRIMARY')), ('p_default_view', q('GRID')),
                                         ('p_show_row_number', 'false'), ('p_settings_area_expanded', 'true')]))
    out.append(call('create_ig_report_view', [('p_id', ref(vk)), ('p_report_id', ref(rpk)), ('p_view_type', q('GRID')),
                                              ('p_stretch_columns', 'true'), ('p_srv_exclude_null_values', 'false'),
                                              ('p_srv_only_display_columns', 'true'), ('p_edit_mode', 'false')]))
    for i, (c, h, dt, kind) in enumerate(cols):
        key = '%s:igc:%s' % (rk, c)
        nid(key, 3)
        out.append(call('create_ig_report_column', [('p_id', ref(key)), ('p_view_id', ref(vk)), ('p_display_seq', str((i + 1) * 10)),
                                                    ('p_column_id', ref('%s:col:%s' % (rk, c))),
                                                    ('p_is_visible', 'false' if kind in ('pk', 'hidden') else 'true'),
                                                    ('p_is_frozen', 'false')]))
    return out

# ============================================================================= generation
def gen():
    out = []
    W = out.append
    W('''-- =============================================================================
-- REVIEW BEFORE IMPORT
-- File        : apex/IMPR1210/f345_impr1210.sql
-- Generated by: Claude Code (scripts/gen_apex_impr1210.py, step 04) from
--               analysis/IMPR1210/IMPR1210_apex_page_spec.md, %s, form IMPR1210 (صيانة تفاويض الشركات الوسيطة)
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / 4c / 4d, docs/f345_reference_standard.md 3-9: editable native Form region on
--               AGNTS (key ROWID, i:u; a used / cancelled authorization is read only), Popup LOVs from the IMPR1110
--               export, FOS + native dynamic actions, one-line calls into package IMPR1210 (version 001) and
--               FORMS_APX (004). No JavaScript file, no AJAX callback process.
-- Contents    : component export INTO the application installed from f345: pages 1210 (main) and
--               121001 (search) + 4 Text Messages. Needs the IMPR1110 export (page group IMPR, Application Setting
--               HIJRI_DATE_FORMAT, LOVs LOV_IMPR and LOV_ALLOWED_EXPORT) imported first.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR1210/import_notes.md
-- WARNING     : generated wwv_flow_api code is not an officially supported way to build APEX
--               applications. Import into a DEV workspace first, back up the application,
--               review every page in Page Designer.
-- Status      : NOT IMPORTED.
-- =============================================================================
prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
begin
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2021.10.15'
,p_release=>'21.2.0'
,p_default_workspace_id=>__WORKSPACE_ID__
,p_default_application_id=>__APP_ID__
,p_default_id_offset=>__ID_OFFSET__
,p_default_owner=>'__SCHEMA_NAME__'
);
end;
/
''' % DATE)
    # ---------------------------------------------------------------- shared LOVs and Text Messages (spec 6, 11)
    if LOVS:
        UNCERTAIN.add(lov_apx.UNCERTAIN)
    for name, sql, cols, s in LOVS:
        key = '%d:lov:%s' % (SHARED_BASE, name)
        nid(key, 5)
        b = [call('create_list_of_values', [('p_id', ref(key)), ('p_lov_name', q(name))] + lov_apx.lov_attributes(sql, q),
                  'Source: IMPR1210 ' + s + ' / spec 6')]
        for i, (c, h, dt, visible) in enumerate(lov_apx.column_definitions(cols)):
            ck = '%d:lovc:%s:%s' % (SHARED_BASE, name, c)
            nid(ck, 6)
            b.append(call('create_list_of_values_cols', [
                ('p_id', ref(ck)), ('p_lov_id', ref(key)), ('p_query_column_name', q(c)),
                ('p_heading', q(h)), ('p_display_sequence', str((i + 1) * 10)), ('p_data_type', q(dt))]
                + lov_apx.column_attributes(visible)))
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), '\n'.join(b)))
    for name, text, s in MESSAGES:
        key = '%d:msg:%s' % (SHARED_BASE, name)
        nid(key, 3)
        W(block('application/shared_components/globalization/messages/' + name.lower(),
                call('create_message', [('p_id', ref(key)), ('p_name', q(name)),
                                        ('p_message_language', q('ar-sa')), ('p_message_text', q(text))],
                     'Source: IMPR1210.%s (constraint %s) / spec 11' % (s, name))))
    UNCERTAIN.add('wwv_flow_api.create_message (Text Message; f345 has none; IMPR1110 / IMPR1120 / IMPR1140 use it) - p_message_language ar-sa')

    # ---------------------------------------------------------------- page 1210
    P = []
    A = P.append
    R = '1210:plug:AGNTS'
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG)
    A(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM)), ('p_alias', q(FORM)),
        ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('Y')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_step_template', fid('PAGE_MAIN')),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1210.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR1210.fmb - spec 2 / f345 standard 4'))
    hero = ('<div class="cg-hero-row"><div class="cg-hero-top"><span class="cg-hero-ic fa fa-handshake-o" aria-hidden="true"></span>'
            '<div><div class="cg-hero-k">المستوردون</div><div class="cg-hero-t">&P1210_HERO_TITLE.</div>'
            '<div class="cg-hero-d">تفاويض المستوردين للشركات الوسيطة في المنفذ</div></div></div></div>')
    nid('1210:plug:HERO', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1210:plug:HERO')), ('p_plug_name', q('الهيدر')), ('p_region_name', q('AGNTS_HERO')),
        ('p_region_css_classes', q('cg-hero')), ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '5'), ('p_plug_source', q(hero)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src('IMPR1210.TITLE (OLB) -> f345 hero / spec 3'))]))
    nid(R, 1)
    A(call('create_page_plug', [
        ('p_id', ref(R)), ('p_plug_name', q('تفاويض الشركات الوسيطة')), ('p_region_name', q('AGNTS')),
        ('p_region_css_classes', q('zatca-forms cg-form cg-card')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_FORM')), ('p_plug_display_sequence', '10'), ('p_query_type', q('TABLE')),
        ('p_query_table', q('AGNTS')), ('p_include_rowid_column', 'true'), ('p_is_editable', 'true'),
        ('p_edit_operations', q('i:u')), ('p_plug_source_type', q('NATIVE_FORM')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1210.AGNTS (single record, WHERE PORT_CD = P_CURR_PORT_CD; insert; update unless '
                               'WHEN-NEW-RECORD-INSTANCE MAKE_BLOCK_FULL_OPERATION forbids it; never delete; key mode ROWID) / spec 3'))]))
    UNCERTAIN.add('ROWID primary key of the Form region: p_include_rowid_column, item source ROWID / p_source_data_type ROWID (as IMPR1110 / IMPR1140)')
    UNCERTAIN.add('NATIVE_FORM region p_edit_operations => i:u (IMPR1140 uses i:u:d)')
    # button IMP_NEW (Designer action item CGSO$WINDOW_1_IMP_NEW, OPEN_FORM('IMP_NEW'))
    nid('1210:btn:IMP_NEW', 2)
    A(call('create_page_button', [
        ('p_id', ref('1210:btn:IMP_NEW')), ('p_button_sequence', '10'), ('p_button_plug_id', ref(R)),
        ('p_button_name', q('IMP_NEW')), ('p_button_action', q('REDIRECT_URL')),
        ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')), ('p_button_template_id', fid('BUTTON')),
        ('p_button_image_alt', q('إضافة وتعديل بيانات مستورد')), ('p_button_position', q('BODY')),
        ('p_button_redirect_url', q('f?p=&APP_ID.:1130:&SESSION.::&DEBUG.:::')), ('p_button_execute_validations', q('N')),
        ('p_icon_css_classes', q('fa-user-plus')), ('p_button_css_classes', q('cg-b-new')),
        ('p_button_comment', src('IMPR1210.CGNV$CGSO$WINDOW_1_1.CGSO$WINDOW_1_IMP_NEW.WHEN-BUTTON-PRESSED -> '
                                 'CGNV$AI_CGSO$WINDOW_1_IMP_NEW OPEN_FORM(IMP_NEW): page 1130 IMPR1130 assumed (inventory 15 #5) / spec 5'))]))
    UNCERTAIN.add('button IMP_NEW: p_button_action REDIRECT_URL with p_button_redirect_url (as the f345 page 0 CLEAR button), '
                  'position BODY in the Form region')
    # read-only grid of the importer's authorizations (LOV form LOV_AGNT_ATHR_IMPR)
    P.extend(ig_region(PG, '1210:plug:LOV_AGNT_ATHR_IMPR', AUTH_SQL, 'P1210_PORT_CD,P1210_IMPR_NBR', AUTH_COLUMNS,
                       '121000000101', 'لا توجد تفاويض لهذا المستورد', False,
                       'IMPR1210.AGNTS.IMPR_NBR.WHEN-VALIDATE-ITEM CALL_FORM LOV_AGNT_ATHR_IMPR (PORT_CD, IMPR_NBR): the '
                       'authorizations the importer already has; a row opens that authorization (inventory 15 #4) / spec 3',
                       'تفاويض المستورد', 'LOV_AGNT_ATHR_IMPR', 30,
                       link='f?p=&APP_ID.:1210:&SESSION.::&DEBUG.:1210:P0_PAGE_PK:&ROW_ID.'))
    UNCERTAIN.add('read-only IG LOV_AGNT_ATHR_IMPR on page 1210 with a link column (as the search grid)')
    nid('1210:branch:STAY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1210:branch:STAY')), ('p_branch_name', q('IMPR1210 - stay in the form')),
        ('p_branch_action', q('f?p=&APP_ID.:1210:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '20'),
        ('p_branch_comment', src('Forms stays on the record after COMMIT, after the functions and after EXECUTE_QUERY (P0_PAGE_PK kept or set by '
                                 'EXECUTE-QUERY) / spec 12'))]))
    # items (spec 4)
    seq = 0
    for name, col, kind, label, dt, newline, span, x in ITEMS:
        seq += 10
        it = dict(name=PI + name, kind=kind, label=label, newline=newline, span=span, column=col, data_type=dt,
                  comment='Source: %s.%s' % (FORM, x['src']), **{k: v for k, v in x.items() if k != 'src'})
        A(page_item(PG, R, seq, it, form_region=True))
    seq = 1000
    for name, col, dt, kind, mask, vp, s in HIDDEN:
        seq += 10
        it = dict(name=PI + name, kind=kind, column=col, data_type=dt, mask=mask, value_protected=vp,
                  pk=(name == 'ROW_ID'), hidden_column=(kind != 'NATIVE_HIDDEN'),
                  protect='S' if name == 'MODULE_ID' else None, comment='Source: %s - %s' % (FORM, s))
        A(page_item(PG, R, seq, it, form_region=True))
    UNCERTAIN.add('DATE columns as Display Only items with a Hijri format mask (&P1210_HIJRI_DATE_FORMAT.) set by PRE_INSERT (as IMPR1160 ENTRY_DT)')
    UNCERTAIN.add('p_item_default with a static value on the Select List ALLOW_EXPORT (0) and the radio group ATHRZTN_STA_CD (1)')
    # computations (spec 9)
    for n, (item, point, expr, s) in enumerate(COMPUTATIONS, 1):
        key = '1210:comp:' + item
        nid(key, 5)
        A(call('create_page_computation', [
            ('p_id', ref(key)), ('p_computation_sequence', str(n * 10)), ('p_computation_item', q(PI + item)),
            ('p_computation_point', q(point)), ('p_computation_type', q('EXPRESSION')), ('p_computation_language', q('PLSQL')),
            ('p_computation', lit(expr)), ('p_computation_comment', src('IMPR1210 ' + s + ' / spec 9'))]))
    # validations (spec 7)
    for n, (name, item, code, cond, s) in enumerate(VALIDATIONS, 1):
        key = '1210:val:' + name
        nid(key, 6)
        A(call('create_page_validation', [
            ('p_id', ref(key)), ('p_validation_name', q(name)), ('p_validation_sequence', str(n * 10)),
            ('p_validation', lit(code)), ('p_validation2', q('PLSQL')), ('p_validation_type', q('FUNC_BODY_RETURNING_ERR_TEXT')),
            ('p_validation_condition', q(cond)), ('p_validation_condition2', q('PLSQL')), ('p_validation_condition_type', q('EXPRESSION')),
            ('p_associated_item', 'wwv_flow_api.id(%s)' % _ids['1210:item:' + PI + item]),
            ('p_error_display_location', q('INLINE_WITH_FIELD_AND_NOTIFICATION')),
            ('p_validation_comment', src('IMPR1210.' + s + ' / spec 7'))]))
    # processes (spec 8, f345 standard 6)
    AGR_NEW = 'NULL;  -- f345 session setup (SSO_APP_USER, P_CURR_PORT_CD, V_USR_TYPE ...) is done by the application; disabled as in AGR1100'
    form_dml = lambda msg: [('p_attribute_01', q('REGION_SOURCE')), ('p_attribute_05', q('Y')), ('p_attribute_06', q('Y')),
                            ('p_attribute_08', q('Y'))]
    for point, seq, name, code, cond, s, msg in PROCESSES:
        key = '1210:proc:%s:%s' % (point, name)
        if name == 'New':
            A(process(key, seq, point, 'New', AGR_NEW, 'NEVER', s))
        elif name == 'Initialize form':
            A(process(key, seq, point, name, None, None, 'IMPR1210 ' + s + ' / spec 8', ptype='NATIVE_FORM_INIT', region=R))
        elif code == FORM_DML:
            A(process(key, seq, point, name, None, cond, 'IMPR1210 ' + s + ' / spec 8', ptype='NATIVE_FORM_DML',
                      extra=form_dml(msg), region=R, success=msg))
        else:
            A(process(key, seq, point, name, code, cond, 'IMPR1210 ' + s + ' / spec 8', success=msg))
    # dynamic actions (spec 10)
    for n, d in enumerate(DAS, 1):
        A(da(PG, n, *d))
    W(block('application/pages/page_01210', '\n'.join(P)))

    # ---------------------------------------------------------------- page 121001 (search)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_SEARCH)
    A(call('create_page', [
        ('p_id', str(PG_SEARCH)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM + '_SEARCH')), ('p_alias', q(FORM + '-SEARCH')),
        ('p_page_mode', q('MODAL')), ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_height', q('800')),
        ('p_dialog_width', q('1800')), ('p_protection_level', q('C')), ('p_first_item', q('AUTO_FIRST_ITEM')),
        ('p_page_comment', src('IMPR1210 Enter-Query / Execute-Query of block AGNTS (KEY-ENTQRY, KEY-EXEQRY) / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: f345 search page <page>01 (page 0 SEARCH)'))
    nid('121001:plug:CRIT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('121001:plug:CRIT')), ('p_plug_name', q('بحث')), ('p_region_name', q('AGNTS_SEARCH_CRITERIA')),
        ('p_region_css_classes', q('zatca-forms cg-form')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_HERO')), ('p_plug_display_sequence', '10'), ('p_attribute_01', q('N')),
        ('p_attribute_02', q('TEXT')), ('p_attribute_03', q('Y')),
        ('p_plug_comment', src('IMPR1210.AGNTS query criteria as one search text over all columns / spec 3'))]))
    P.extend(ig_region(PG_SEARCH, '121001:plug:IG', SEARCH_SQL, 'P121001_SEARCH', SEARCH_COLUMNS,
                       '121001000201', 'لا توجد نتائج - أدخل نص البحث ثم اضغط بحث', True,
                       'IMPR1210.AGNTS block query (WHERE PORT_CD = P_CURR_PORT_CD) with the POST-QUERY names; one search '
                       'text over all columns, no query until a search / spec 3', 'تفاويض الشركات الوسيطة', 'AGNTS_SEARCH', 20,
                       link='f?p=&APP_ID.:1210:&SESSION.::&DEBUG.:1210:P0_PAGE_PK:&ROW_ID.'))
    UNCERTAIN.add('search IG 121001: p_lazy_loading true, p_show_total_row_count false, toolbar ACTIONS_MENU:RESET (search field removed)')
    A(page_item(PG_SEARCH, '121001:plug:CRIT', 10, dict(
        name='P121001_SEARCH', kind='NATIVE_TEXT_FIELD', label='بحث في كل الأعمدة', maxlen=200, span=6,
        comment='Source: IMPR1210.AGNTS query criteria (QBE of ATHRZTN_SEQ_NBR, IMPR_NBR, IMPR_NBR_AG ...) as one text over all columns')))
    for b, seq, label, icon, css, s in [('SEARCH', 20, 'بحث', 'fa-search', 'cg-b-search', 'EXECUTE_QUERY of block AGNTS'),
                                        ('CLEAR', 30, 'مسح البحث', 'fa-eraser', 'cg-b-clear', 'TOOLBAR.CLEAR_ALL for the search')]:
        nid('121001:btn:' + b, 2)
        A(call('create_page_button', [
            ('p_id', ref('121001:btn:' + b)), ('p_button_sequence', str(seq)), ('p_button_plug_id', ref('121001:plug:CRIT')),
            ('p_button_name', q(b)), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
            ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q(label)), ('p_button_position', q('BODY')),
            ('p_icon_css_classes', q(icon)), ('p_button_css_classes', q(css)), ('p_button_comment', src('IMPR1210 %s / spec 3' % s))]))
    refresh = [('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('121001:plug:IG'))]
    for ek, name, seq, trig, extra, acts, s in [
            ('121001:da:SEARCH', 'SEARCH', 10, [('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('121001:btn:SEARCH'))],
             [('p_bind_type', q('bind')), ('p_bind_event_type', q('click'))], [refresh], 'IMPR1210 EXECUTE_QUERY / spec 3'),
            ('121001:da:SEARCH KEY-ENTER', 'SEARCH KEY-ENTER', 12,
             [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q('P121001_SEARCH')),
              ('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_expression', q('this.browserEvent.which === 13'))],
             [('p_bind_type', q('bind')), ('p_bind_event_type', q('keyup'))], [refresh],
             'IMPR1210 KEY-EXEQRY (Enter in the search text; f345 AGR1100_SEARCH keyup pattern) / spec 3'),
            ('121001:da:CLEAR', 'CLEAR WHEN-BUTTON-PRESSED', 15,
             [('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('121001:btn:CLEAR'))],
             [('p_bind_type', q('bind')), ('p_bind_event_type', q('click'))],
             [[('p_action', q('NATIVE_CLEAR')), ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q('P121001_SEARCH'))], refresh],
             'IMPR1210 TOOLBAR.CLEAR_ALL (search criteria) / spec 3')]:
        nid(ek, 8)
        A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q(name)), ('p_event_sequence', str(seq))] + trig + extra
               + [('p_da_event_comment', src(s))]))
        for i, a in enumerate(acts, 1):
            nid('%s:%d' % (ek, i * 10), 9)
            A(call('create_page_da_action', [('p_id', ref('%s:%d' % (ek, i * 10))), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                             ('p_action_sequence', str(i * 10)), ('p_execute_on_page_init', q('N'))] + a))
    UNCERTAIN.add('button DA: p_triggering_button_id (as page 113001 SEARCH; IMPR1110 uses it)')
    UNCERTAIN.add('DA client-side condition JAVASCRIPT_EXPRESSION this.browserEvent.which === 13 (Enter key; not in f345)')
    UNCERTAIN.add('NATIVE_CLEAR action with p_affected_elements (page 121001 CLEAR; not in f345)')
    ek, ak = '121001:da:Hide', '121001:daa:Hide:10'
    nid(ek, 8); nid(ak, 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('Hide')), ('p_event_sequence', '20'),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('ready')),
                                    ('p_da_event_comment', src('f345 AGR1100_SEARCH "Hide" (page 0 toolbar not used in a dialog)'))]))
    A(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('Y')), ('p_action', q('NATIVE_HIDE')),
                                     ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', fid('P0_ACTIONS'))]))
    W(block('application/pages/page_121001', '\n'.join(P)))
    W('''prompt --application/end_environment
begin
wwv_flow_api.component_end;
end;
/
set verify on feedback on define on
prompt  ...done
''')
    text = client_condition.fix(items_to_submit.fix('\n'.join(out)))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    return text

# ============================================================================= checks
def names_of(text, api):
    out = []
    for chunk in text.split('wwv_flow_api.%s(' % api)[1:]:
        m = re.search(r"\n[ ,]p_name=>'([^']+)'", chunk[:chunk.find('\n);')])
        if m: out.append(m.group(1))
    return out

def selfcheck(text):
    problems = items_to_submit.check(text) + client_condition.check(text) + item_icons.check(text) + lov_apx.check(text) + functions_drawer.check_form_page(text)
    ref_txt = open(REF, encoding='utf-8', errors='replace').read()
    others = '\n'.join(open(f, encoding='utf-8', errors='replace').read() for f in OTHER_EXPORTS)
    pkg_txt = re.sub(r'--[^\n]*', '', open(PKG, encoding='utf-8').read())
    if 'wwv_flow_imp' in text: problems.append('wwv_flow_imp found')
    allowed = {'__WORKSPACE_ID__', '__APP_ID__', '__SCHEMA_NAME__', '__ID_OFFSET__'}
    ph = set(re.findall(r'__[A-Z_]+__', text))
    if ph - allowed: problems.append('unexpected placeholders %s' % sorted(ph - allowed))
    if re.search(r'password|pwd', text, re.I): problems.append('password text found')
    code = '\n'.join(l for l in text.splitlines() if not l.startswith('--') and not re.match(r'^[ ,]p_\w*comment=>', l))
    if re.search(r'\bAI_[A-Z]', code): problems.append('AI_ item name found')
    if re.search(r'pkg_|IMPR1110\.', code, re.I): problems.append('page calls pkg_ / IMPR1110')
    fx = forms_apx_helpers.forms_apx_members(ROOT)
    for name in set(re.findall(r'FORMS_APX\.([A-Z0-9_$]+)', code)):
        if name not in fx: problems.append('FORMS_APX.%s not in forms_apx.sql' % name)
    for m in re.finditer(r'FORMS_APX\.([A-Z0-9_$]+)\(([^()]*(?:\([^()]*\)[^()]*)*)\)', code):
        name, args = m.groups()
        given = set(re.findall(r'(?<![.\w])([A-Z0-9_$]+)\s*=>', re.sub(r'\([^()]*\)', '()', args)))
        if name in fx and given and not given <= fx[name]:
            problems.append('call FORMS_APX.%s: unknown parameters %s' % (name, sorted(given - fx[name])))
    for bad in ('ON_DEMAND', 'p_javascript_file_urls', 'AJAX_FUNCTION', 'NATIVE_JAVASCRIPT_CODE'):
        if bad in code: problems.append('not allowed: ' + bad)
    defined = re.findall(r'[ ,]p_id=>wwv_flow_api\.id\((\d+)\)', text)
    if len(defined) != len(set(defined)): problems.append('duplicate p_id')
    ref_ids = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', ref_txt))
    if set(defined) & ref_ids: problems.append('ids clash with f345')
    other_ids = set(re.findall(r'p_id=>wwv_flow_api\.id\((\d+)\)', others))
    if set(defined) & other_ids: problems.append('ids clash with the other component exports: %s' % sorted(set(defined) & other_ids)[:5])
    for k, v in IMPR1110_IDS.items():
        if v not in other_ids: problems.append('IMPR1110 id %s (%s) not in the IMPR1110 export' % (k, v))
    missing = set(re.findall(r'wwv_flow_api\.id\((\d+)\)', text)) - set(defined) - ref_ids - other_ids
    if missing: problems.append('ids used but defined nowhere: %s' % sorted(missing))
    for k, v in F345.items():
        if v not in ref_ids: problems.append('f345 id %s (%s) not in f345.sql' % (k, v))
    ref_items = set(names_of(ref_txt, 'create_flow_item')) | set(names_of(others, 'create_flow_item'))
    for n in ('SSO_APP_USER', 'P_CURR_PORT_CD', 'P_GLOBAL_V_WS_ID'):
        if n not in ref_items: problems.append('application item %s not in f345' % n)
    lovs_here = set(re.findall(r"p_lov_name=>'([^']+)'", text))
    other_lovs = set(re.findall(r"p_lov_name=>'([^']+)'", ref_txt + others))
    for n in lovs_here & other_lovs: problems.append('LOV %s already exists (f345 / other export)' % n)
    for n in set(re.findall(r"p_named_lov=>'([^']+)'", text)):
        if n not in lovs_here | other_lovs: problems.append('named LOV %s not defined' % n)
    members = set(m.upper() for m in re.findall(r'(?m)^\s*(?:PROCEDURE|FUNCTION)\s+(\w+)', pkg_txt))
    for m in set(re.findall(r'IMPR1210\.([A-Z_0-9]+)', code)):
        if m not in members: problems.append('IMPR1210.%s not in impr1210_spec.sql' % m)
    for name in re.findall(r"p_(?:name|process_name|validation_name)=>'([^']*)'", text):
        if '.' in name and ' ' not in name and not name.startswith('P'): problems.append('dot in component name ' + name)
    page_items = set(names_of(text, 'create_page_item'))
    app_items = ref_items | {'APP_USER', 'REQUEST', 'APP_ID'}
    for b in set(re.findall(r"(?<![\w$&])[:](P\d+_\w+|P_\w+|G_\w+|SSO_APP_USER|V_USR_TYPE|P0_PAGE_PK)\b", code)):
        if b not in page_items | app_items and not b.startswith('P0_'): problems.append('bind :%s has no item' % b)
    for b in set(re.findall(r"p_attribute_0[23]=>'([^']+)'", code)):
        for i in b.split(','):
            if re.match(r'P\d+_', i) and i not in page_items: problems.append('FOS item %s missing' % i)
    if text.count('\nbegin\n') != text.count('\nend;\n/'): problems.append('begin/end not balanced')
    if "p_name=>'NUMBER ONLY'" in text: problems.append('NUMBER ONLY DA on a form page (it belongs to page 0)')
    for c in text.split('wwv_flow_api.create_page_item(')[1:]:
        c = c[:c.find('\n);')]
        if "p_display_as=>'NATIVE_NUMBER_FIELD'" in c and number_only.CLASS not in c:
            problems.append('number field without class %s' % number_only.CLASS)
    # page items named after the Forms items; the package: parameter names, qualified parameters inside SQL
    spec_raw = open(PKG, encoding='utf-8').read()
    body_raw = open(PKG.replace('_spec.sql', '_body.sql'), encoding='utf-8').read()
    for p in parameter_names.unqualified_in_sql(spec_raw, body_raw):
        problems.append('package body: parameter not qualified inside SQL: %s' % (p,))
    for p in parameter_names.private_functions_in_sql(spec_raw, body_raw):
        problems.append('package body: private function inside SQL: %s' % (p,))
    if re.search(r'\b[IO]{1,2}_[A-Z]\w*\s+(IN|OUT)\b', spec_raw): problems.append('I_ / IO_ / O_ parameter in the spec')
    for name in re.findall(r'(?m)^\s*(?:PROCEDURE|FUNCTION)\s+(\w+)', spec_raw + body_raw):
        if len(name.encode()) > 30: problems.append('identifier longer than 30 bytes: ' + name)
    problems += ['package: FORMS_APX helper copy %s' % (x,) for x in forms_apx_helpers.leftovers(body_raw)]
    problems += ['package: %s' % (x,) for x in forms_apx_helpers.unknown_calls(body_raw, ROOT)]
    counts = {k: len(re.findall(r'wwv_flow_api\.%s\(' % k, text)) for k in [
        'create_page', 'create_page_plug', 'create_page_item', 'create_page_button', 'create_page_validation',
        'create_page_process', 'create_page_da_event', 'create_page_da_action', 'create_page_computation', 'create_page_branch',
        'create_region_column', 'create_interactive_grid', 'create_ig_report_column', 'create_list_of_values', 'create_flow_item']}
    counts['FOS actions'] = text.count("p_action=>'PLUGIN_COM.FOS.EXECUTE_PLSQL_CODE'")
    return problems, counts, sorted(ph)

def ready_copy(text, args):
    vals = {}
    for a in args:
        k, _, v = a.lstrip('-').partition('=')
        vals[k.replace('-', '_').lower()] = v.strip()
    need = ['workspace_id', 'app_id', 'id_offset', 'schema']
    missing = [k for k in need if not vals.get(k)]
    if missing: sys.exit('missing: ' + ', '.join('--%s=' % m.replace('_', '-') for m in missing))
    for k in ('workspace_id', 'app_id', 'id_offset'):
        if not re.fullmatch(r'-?\d+', vals[k]): sys.exit('--%s must be a number' % k.replace('_', '-'))
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_$#]{0,29}', vals['schema']): sys.exit('--schema is not a valid schema name')
    out = (text.replace('__WORKSPACE_ID__', vals['workspace_id']).replace('__APP_ID__', vals['app_id'])
               .replace('__ID_OFFSET__', vals['id_offset']).replace('__SCHEMA_NAME__', vals['schema'].upper()))
    path = os.path.join(ROOT, 'apex', 'IMPR1210', 'f%s_impr1210_import.sql' % vals['app_id'])
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(out)
    print('import-ready copy:', path)

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    t = gen()
    probs, counts, ph = selfcheck(t)
    print('written', OUT, len(t.splitlines()), 'lines')
    for k, v in counts.items():
        print('  %-32s %d' % (k, v))
    print('placeholders:', ', '.join(ph))
    print('uncertain parameters (import_notes.md):')
    for u in sorted(UNCERTAIN):
        print('  -', u)
    os.makedirs(os.path.join(ROOT, 'work', 'IMPR1210', 'step04'), exist_ok=True)
    json.dump(sorted(UNCERTAIN), open(os.path.join(ROOT, 'work', 'IMPR1210', 'step04', 'uncertain.json'), 'w'), indent=1)
    print('problems:', probs or 'none')
    if probs:
        sys.exit(1)
    if len(sys.argv) > 1:
        ready_copy(t, sys.argv[1:])
