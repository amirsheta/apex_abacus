# -*- coding: utf-8 -*-
"""
gen_apex_impr1160.py - step 04: APEX 21.2 component export of IMPR1160 (wwv_flow_api),
f345 reference standard (CLAUDE.md 4b / 4c / 4d, docs/f345_reference_standard.md).
Helpers (q, lit, nid, call, da, process, ig_region, selfcheck, ready_copy) follow scripts/gen_apex_impr1150.py;
the editable Form region, Popup LOVs, Text Messages and Form DML follow scripts/gen_apex_impr1140.py.

Design: analysis/IMPR1160/IMPR1160_apex_page_spec.md. The design data is in this file (ITEMS, HIDDEN, LOVS,
MESSAGES, VALIDATIONS, PROCESSES, COMPUTATIONS, DAS): change it here, re-run, and keep the spec in step.

Reads
  apex/Reference/f345.sql             template ids, existing ids / items / LOVs (checks)
  apex/*/f345_*.sql                   the other component exports (page group IMPR, LOV_REC_STATUS, id clashes)
  plsql/IMPR1160/impr1160_spec.sql    members of package IMPR1160 (checks)
Writes
  apex/IMPR1160/f345_impr1160.sql     component export, REVIEW BEFORE IMPORT (4 placeholders)
  apex/IMPR1160/f<app>_impr1160_import.sql  with --workspace-id --app-id --id-offset --schema
  work/IMPR1160/step04/uncertain.json parameters f345 does not show (import_notes.md)

Declarative: editable native Form region on IMPR_CAR_EXCEPTION (key ROWID, i:u:d; a queried record only lets STATUS
change), FOS + native actions, validations and processes = one call into IMPR1160 / FORMS_APX. No JavaScript file,
no AJAX callback. IDs are deterministic: re-running gives the same file.

Usage (from forms_to_apex_toolkit):  python3 -I scripts/gen_apex_impr1160.py [--workspace-id=.. --app-id=.. --id-offset=.. --schema=..]
"""
import os, re, sys, json, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
import number_only      # Number Field items: CSS class number_only + one page-load handler on page 0
import functions_drawer # the FUNCS region is on page 0, never on a form page
import item_icons       # Post Text icon next to every entry item
import items_to_submit  # every page item a query / LOV / FOS call reads is in its Items to Submit
import lov_apx          # shared LOVs: function body returning SQL, code in LOV_APX (CLAUDE.md 4d)
import forms_apx_helpers
import parameter_names

REF = os.path.join(ROOT, 'apex', 'Reference', 'f345.sql')
PKG = os.path.join(ROOT, 'plsql', 'IMPR1160', 'impr1160_spec.sql')
OUT = os.path.join(ROOT, 'apex', 'IMPR1160', 'f345_impr1160.sql')
OTHER_EXPORTS = sorted(f for f in glob.glob(os.path.join(ROOT, 'apex', '*', 'f345_*.sql'))
                       if os.sep + 'IMPR1160' + os.sep not in f and os.sep + 'Reference' + os.sep not in f)
DATE, STAMP = '2026-11-25', '20261125000000'
FORM = 'IMPR1160'
PG, PG_SEARCH = 1160, 116001
PI = 'P1160_'
SHARED_BASE = 9160                 # IMPR1110 9000, IMPR1116 9116, IMPR1120 9120, IMPR1125 9125, IMPR1130 9130, IMPR1140 9140, IMPR1150 9150
IMPR1110_IDS = dict(PAGE_GROUP_IMPR='900001000010')   # created by the IMPR1110 export: reused
REUSED_LOVS = ['LOV_REC_STATUS']                     # created by the IMPR1140 export: reused by name

F345 = dict(
    UI='11622010846008869795', PAGE_MAIN='11622270914969205733', REGION_HERO='11621859120066869682',
    REGION_FORM='11621909206693869707', REGION_GRID='11621913486616869708',
    LABEL_REQ='11621984380233869750', LABEL_OPT='11621983529556869749',
    BUTTON='11621986167597869752', P0_ACTIONS='73488102084440079322')
ITEM_OPTS = '#DEFAULT#:t-Form-fieldContainer--stretchInputs'
HIJRI_MASK = '&P1160_HIJRI_DATE_FORMAT.'
HIJRI_PLACEHOLDER = 'placeholder="%s"' % 'سنة-شهر-يوم'   # default HIJRI_DATE_FORMAT YYYY-MM-MI (as IMPR1110)

# ============================================================================= design data (spec sections 4-10)
RECORD = ':P0_PAGE_PK IS NOT NULL'   # a queried record: every item except STATUS is read only (Update Allowed = false)
# items of page 1160 in canvas order (rows by Y, then X): name, column, type, label, data type, newline, span, extra
ITEMS = [
    ('PORT_CD', 'PORT_CD', 'NATIVE_DISPLAY_ONLY', 'رقم المنفذ', 'NUMBER', True, 2,
     dict(send=True, src='IMPR_CAR_EXCEPTION.PORT_CD (CGSO$CHAR_ARB_DO, Required, never enterable; WHEN-NEW-FORM-INSTANCE '
                         ':= P_CURR_PORT_CD; LOV CGFK$IMPR_CAR_EXCEPTION_PORT_C / button PORT_CD2 dropped)')),
    ('PORT_NAME', None, 'NATIVE_DISPLAY_ONLY', None, None, False, 6,
     dict(src='IMPR_CAR_EXCEPTION.PORT_NAME (non-database; WHEN-NEW-FORM-INSTANCE / POST-QUERY)')),
    ('EXCPT_ISN', 'IMPR_CAR_EXPTN_ISN', 'NATIVE_DISPLAY_ONLY', 'مسلسل الإستثناء', 'NUMBER', True, 2,
     dict(src='IMPR_CAR_EXCEPTION.EXCPT_ISN (column IMPR_CAR_EXPTN_ISN, CGSO$NUMBER_ARB_WT_DO; PRE-INSERT sequence)')),
    ('IMPR_NBR', 'IMPR_NBR', 'NATIVE_POPUP_LOV', 'رقم المستورد', 'NUMBER', False, 2,
     dict(req=True, lov='LOV_IMPR_P', maxlen=11, read_only=RECORD,
          src='IMPR_CAR_EXCEPTION.IMPR_NBR (CGSO$NUMBER_MD Required, Update Allowed = false; KEY-LISTVAL / IMPR_BUT -> '
              'CALL_IMPR_LOV: LOV form LOV_IMPR_P)')),
    ('IMPR_NAME', None, 'NATIVE_DISPLAY_ONLY', None, None, False, 6,
     dict(src='IMPR_CAR_EXCEPTION.IMPR_NAME (non-database; IMPR_NBR KEY-NEXT-ITEM / POST-QUERY)')),
    ('DCLTN_TYPE', 'DCLTN_TYPE', 'NATIVE_SELECT_LIST', 'نوع البيان', 'NUMBER', True, 2,
     dict(req=True, lov='LOV_DCL_STA_FLAG', lov_null='NO', default='1', read_only=RECORD,
          src='IMPR_CAR_EXCEPTION.DCLTN_TYPE (List Item, Required, default 1, Update Allowed = false; '
              'CGDV$POPULATE_DYNAMIC_LISTS CG_REF_CODES DCL_STA_FLAG)')),
    ('DCLTN_NBR', None, 'NATIVE_POPUP_LOV', 'رقم البيان', None, False, 2,
     dict(lov='LOV_IMPR_DCLTN', maxlen=20, read_only=RECORD,
          src='IMPR_CAR_EXCEPTION.DCLTN_NBR (non-database, enterable on a new record (WHEN-NEW-FORM-INSTANCE); '
              'KEY-LISTVAL / DCLTN_LOV -> CALL_IMPR_DCLTN_LOV: LOV form LOV_IMPR_DCLTN)')),
    ('DCLTN_DT', None, 'NATIVE_TEXT_FIELD', 'تاريخ البيان', None, False, 2,
     dict(maxlen=10, hijri=True, read_only=RECORD,
          src='IMPR_CAR_EXCEPTION.DCLTN_DT (non-database Hijri date MI-MM-RRRR, enterable on a new record; '
              'DCLTN_NBR POST-CHANGE / POST-QUERY; KEY-NEXT-ITEM and WHEN-VALIDATE-ITEM are NULL;)')),
    ('AWARD_NBR', 'EXPTN_AWARD_NBR', 'NATIVE_TEXT_FIELD', 'رقم المراسلة', 'VARCHAR2', True, 2,
     dict(maxlen=20, read_only=RECORD, src='IMPR_CAR_EXCEPTION.AWARD_NBR (column EXPTN_AWARD_NBR, Update Allowed = false)')),
    ('AWARD_DATE', 'EXPTN_AWARD_DATE', 'NATIVE_TEXT_FIELD', 'تاريخ المراسلة', 'DATE', False, 2,
     dict(maxlen=10, hijri=True, mask=HIJRI_MASK, read_only=RECORD,
          src='IMPR_CAR_EXCEPTION.AWARD_DATE (column EXPTN_AWARD_DATE, CGSO$HDATE_ARB Hijri MI-MM-RRRR; KEY-F4 / KEY-LISTVAL '
              'Hijri picker -> hijri-date-default)')),
    ('NO_OF_CARS', 'NO_OF_CARS', 'NATIVE_NUMBER_FIELD', 'عدد السيارات المستثناة', 'NUMBER', False, 2,
     dict(maxlen=4, read_only=RECORD,
          src='IMPR_CAR_EXCEPTION.NO_OF_CARS (Insert Allowed = true, Update Allowed = false (CGSO$CHAR_ARB_DO); DCLTN_NBR POST-CHANGE)')),
    ('STATUS', 'STATUS', 'NATIVE_SELECT_LIST', 'حالة السجل', 'NUMBER', True, 2,
     dict(lov='LOV_REC_STATUS', src='IMPR_CAR_EXCEPTION.STATUS (List Item 1 / 0, CG_REF_CODES REC_STATUS; PRE-QUERY / POST-QUERY '
                                    'SET_ITEM_PROPERTY UPDATE_ALLOWED TRUE: the one item a queried record can change)')),
    ('AWARD_REMARKS', 'EXPTN_AWARD_REMARKS', 'NATIVE_TEXTAREA', 'ملاحظات', 'VARCHAR2', True, 8,
     dict(maxlen=100, read_only=RECORD, src='IMPR_CAR_EXCEPTION.AWARD_REMARKS (column EXPTN_AWARD_REMARKS, multi-line, Update Allowed = false)')),
]
# not displayed: name, column, data type, kind, mask, value protected, source
HIDDEN = [
    ('ROW_ID', 'ROWID', 'ROWID', 'NATIVE_HIDDEN', None, 'Y', 'IMPR_CAR_EXCEPTION ROWID (Form region primary key, = P0_PAGE_PK)'),
    ('ENTRY_DT', 'ENTRY_DT', 'DATE', 'NATIVE_DISPLAY_ONLY', 'YYYY/MM/DD HH24:MI:SS', None,
     'IMPR_CAR_EXCEPTION.ENTRY_DT (CGSO$DATETIME, not displayed; PRE-INSERT SYSDATE)'),
    ('EXPTN_START_DT', 'EXPTN_START_DT', 'DATE', 'NATIVE_DISPLAY_ONLY', HIJRI_MASK, None,
     'IMPR_CAR_EXCEPTION.EXPTN_START_DT (Hijri, not displayed; WHEN-NEW-FORM-INSTANCE current Hijri date)'),
    ('EXPTN_END_DT', 'EXPTN_END_DT', 'DATE', 'NATIVE_DISPLAY_ONLY', HIJRI_MASK, None,
     'IMPR_CAR_EXCEPTION.EXPTN_END_DT (Hijri, not displayed, never set by the form)'),
    ('DCLTN_ISN', 'DCLTN_ISN', 'NUMBER', 'NATIVE_HIDDEN', None, 'N',
     'IMPR_CAR_EXCEPTION.DCLTN_ISN (not displayed; DCLTN_NBR POST-CHANGE, PRE-INSERT)'),
    ('STATS_ISN', 'STATS_ISN', 'NUMBER', 'NATIVE_HIDDEN', None, 'N',
     'IMPR_CAR_EXCEPTION.STATS_ISN (not displayed; DCLTN_NBR POST-CHANGE, PRE-INSERT)'),
    ('MODULE_ID', None, None, 'NATIVE_HIDDEN', None, 'Y', 'f345 Page Functions: P<page>_MODULE_ID'),
    ('HIJRI_DATE_FORMAT', None, None, 'NATIVE_HIDDEN', None, 'Y', 'FORMS_APX.HIJRI_DATE_FORMAT (format mask of the Hijri dates)'),
    ('HERO_TITLE', None, None, 'NATIVE_HIDDEN', None, 'Y', 'f345 hero title (FORMS_APX.HEADER_TITLE)'),
]
LOVS = [   # name, LOV_APX call, Popup LOV columns, source
    ('LOV_DCL_STA_FLAG', lov_apx.call('REFERENCE_CODES', P_DOMAIN='DCL_STA_FLAG'), None,
     'IMPR_CAR_EXCEPTION.DCLTN_TYPE list (CGDV$POPULATE_DYNAMIC_LISTS, CG_REF_CODES domain DCL_STA_FLAG; XML values 1, 2, 3)'),
    ('LOV_IMPR_P', lov_apx.call('IMPORTERS', P_PORT_ITEM='P_CURR_PORT_CD', P_IMPR_TYPE_CD='4', P_BUS_ID_TYPE_CD='5'),
     [('D', 'رقم مستورد', 'NUMBER'), ('ARBC_IMPR_NAME', 'اسم المستورد', 'VARCHAR2'), ('BUS_ID', 'رقم إستدلالي', 'VARCHAR2'),
      ('BUS_ID_BRNCH', 'فرع', 'VARCHAR2'), ('IMPR_TEL_NBR', 'تليفون', 'VARCHAR2')],
     'PU CALL_IMPR_LOV -> LOV form LOV_IMPR_P (PORT_CD = P_CURR_PORT_CD, IMPR_TYPE_CD 4, BUS_ID_TYPE_CD 5)'),
    ('LOV_IMPR_DCLTN', lov_apx.call('LOV_IMPR_DCLTN', P_DCLTN_TYPE_ITEM='P1160_DCLTN_TYPE', P_IMPR_NBR_ITEM='P1160_IMPR_NBR'),
     [('D', 'رقم البيان', 'VARCHAR2'), ('DCLTN_DT', 'تاريخ البيان', 'VARCHAR2')],
     'PU CALL_IMPR_DCLTN_LOV -> LOV form LOV_IMPR_DCLTN (declarations / statistical declarations of the importer)'),
]
MESSAGES = [  # ON-ERROR / CGTE$CHECK_CONSTRAINT_VIO texts (Des$Form_errors.MSGGETTEXT defaults with the Arabic label)
    ('ICE_PK', 'Row exists already with same رقم المنفذ,مسلسل الإستثناء', 'CGTE$CHECK_CONSTRAINT_VIO (ORA-00001)'),
    ('ICE_SD_FK', 'This رقم المنفذ does not exist', 'IMPR_CAR_EXCEPTION.ON-ERROR (ORA-02291)'),
    ('ICE_SDP_FK', 'This رقم المنفذ does not exist', 'IMPR_CAR_EXCEPTION.ON-ERROR (ORA-02291)'),
    ('ICE_IMP_FK', 'This رقم المستورد does not exist', 'IMPR_CAR_EXCEPTION.ON-ERROR (ORA-02291)'),
    ('ICE_DCLTN_FK', 'This رقم المنفذ does not exist', 'IMPR_CAR_EXCEPTION.ON-ERROR (ORA-02291; label as in Forms)')]
CREATE = ":REQUEST = 'CREATE'"
VALIDATIONS = [   # name, item, code, condition (PL/SQL expression), source
    ('IMPR_NBR VALIDATION', 'IMPR_NBR',
     'RETURN IMPR1160.IMPR_NBR_VALIDATION(P_PORT_CD => :P1160_PORT_CD, P_IMPR_NBR => :P1160_IMPR_NBR);', CREATE,
     'IMPR_CAR_EXCEPTION.IMPR_NBR.WHEN-VALIDATE-ITEM + KEY-NEXT-ITEM (suspension check)'),
    ('AWARD_NBR VALIDATION', 'AWARD_NBR', 'RETURN IMPR1160.AWARD_NBR_VALIDATION(P_AWARD_NBR => :P1160_AWARD_NBR);', CREATE,
     'IMPR_CAR_EXCEPTION.AWARD_NBR.WHEN-VALIDATE-ITEM'),
    ('AWARD_DATE VALIDATION', 'AWARD_DATE', 'RETURN FORMS_APX.HIJRI_DATE_ERROR(:P1160_AWARD_DATE);', CREATE,
     'IMPR_CAR_EXCEPTION.AWARD_DATE.WHEN-VALIDATE-ITEM (HIJDATE.VALID_HIJ_DATE)'),
    ('NO_OF_CARS VALIDATION', 'NO_OF_CARS', 'RETURN IMPR1160.NO_OF_CARS_VALIDATION(P_NO_OF_CARS => :P1160_NO_OF_CARS);', CREATE,
     'IMPR_CAR_EXCEPTION.NO_OF_CARS.WHEN-VALIDATE-ITEM'),
]
POST_QUERY = ('IMPR1160.POST_QUERY(P_IMPR_NBR => :P1160_IMPR_NBR, P_DCLTN_TYPE => :P1160_DCLTN_TYPE, '
              'P_DCLTN_ISN => :P1160_DCLTN_ISN, P_STATS_ISN => :P1160_STATS_ISN, P_CURR_PORT_CD => :P_CURR_PORT_CD, '
              'P_IMPR_NAME => :P1160_IMPR_NAME, P_PORT_NAME => :P1160_PORT_NAME, P_DCLTN_NBR => :P1160_DCLTN_NBR, '
              'P_DCLTN_DT => :P1160_DCLTN_DT);')
PRE_INSERT = ('IMPR1160.PRE_INSERT(P_DCLTN_TYPE => :P1160_DCLTN_TYPE, P_DCLTN_NBR => :P1160_DCLTN_NBR, '
              'P_DCLTN_DT => :P1160_DCLTN_DT, P_IMPR_NBR => :P1160_IMPR_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD, '
              'P_EXCPT_ISN => :P1160_EXCPT_ISN, P_ENTRY_DT => :P1160_ENTRY_DT, P_DCLTN_ISN => :P1160_DCLTN_ISN, '
              'P_STATS_ISN => :P1160_STATS_ISN);')
WNFI = ('IMPR1160.WHEN_NEW_FORM_INSTANCE(P_CURR_PORT_CD => :P_CURR_PORT_CD, P_PORT_CD => :P1160_PORT_CD, '
        'P_PORT_NAME => :P1160_PORT_NAME, P_EXPTN_START_DT => :P1160_EXPTN_START_DT);')
INS = ":P0_PAGE_PK IS NULL AND :REQUEST = 'CREATE'"
UPD = ":P0_PAGE_PK IS NOT NULL AND :REQUEST = 'SAVE'"
FORM_DML = "'DML'"   # marker: Process form (NATIVE_FORM_DML)
# processes: point, seq, name, code, condition (PL/SQL expression | NEVER | None), source, success message
PROCESSES = [
    ('BEFORE_HEADER', 10, 'New', None, 'NEVER', 'f345 session setup copied from AGR1100 (condition Never) / standard 6', None),
    ('BEFORE_HEADER', 20, 'P0_PAGE_PK CHECK', 'IMPR1160.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK);', None,
     'f345 key (ROWID of IMPR_CAR_EXCEPTION, URL-safe from page 116001)', None),
    ('BEFORE_HEADER', 40, 'PARAMETERS',
     ":P1160_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1160_MODULE_ID, FORM_NAME => 'IMPR1160');", None,
     'f345 module id of the Page Functions list', None),
    ('BEFORE_HEADER', 70, 'P0_PAGE_PK', ':P1160_ROW_ID := :P0_PAGE_PK;', None, 'f345 (key = ROWID)', None),
    ('BEFORE_HEADER', 80, 'Initialize form', None, None, 'block IMPR_CAR_EXCEPTION fetch', None),
    ('BEFORE_HEADER', 82, 'POST-QUERY', POST_QUERY, ':P1160_ROW_ID IS NOT NULL', 'IMPR_CAR_EXCEPTION.POST-QUERY', None),
    ('BEFORE_HEADER', 84, 'WHEN-NEW-FORM-INSTANCE', WNFI, ':P1160_ROW_ID IS NULL',
     'FORM.WHEN-NEW-FORM-INSTANCE (defaults of the new record: PORT_CD, PORT_NAME, EXPTN_START_DT; after Initialize form, '
     'which would clear them)', None),
    ('BEFORE_HEADER', 100, 'HEADER TITLE',
     "FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1160_MODULE_ID, P_HERO_TITLE => :P1160_HERO_TITLE, "
     "DEFAULT_TITLE => 'استثناء المستوردين الافراد للسيارات');", None, 'f345 hero title (OLB block TITLE)', None),
    ('AFTER_SUBMIT', 10, 'PRE-INSERT', PRE_INSERT, INS, 'IMPR_CAR_EXCEPTION.PRE-INSERT (+ CGUI$GET_UNIQUE_ID_MODIFIED)', None),
    ('AFTER_SUBMIT', 20, 'PRE-UPDATE', 'IMPR1160.PRE_UPDATE(P_PORT_CD => :P1160_PORT_CD, P_EXCPT_ISN => :P1160_EXCPT_ISN);', UPD,
     'IMPR_CAR_EXCEPTION.PRE-UPDATE', None),
    ('AFTER_SUBMIT', 40, 'Process form', FORM_DML, ":REQUEST IN ('CREATE', 'SAVE')", 'block IMPR_CAR_EXCEPTION DML', 'تم الحفظ بنجاح'),
    ('AFTER_SUBMIT', 41, 'Process form - DELETE', FORM_DML, ":REQUEST = 'DELETE'",
     'block IMPR_CAR_EXCEPTION DML (delete: NIB.KEY_DELREC after PRE-QUERY MAKE_BLOCK_FULL_OPERATION)', 'تم الحذف بنجاح'),
    ('AFTER_SUBMIT', 80, 'P0_PAGE_PK AFTER INSERT', ':P0_PAGE_PK := :P1160_ROW_ID;', CREATE, 'f345', None),
    ('AFTER_SUBMIT', 85, 'P0_PAGE_PK AFTER DELETE', ':P0_PAGE_PK := NULL;', ":REQUEST = 'DELETE'", 'f345', None),
]
COMPUTATIONS = [   # item, point, expression, source
    ('HIJRI_DATE_FORMAT', 'BEFORE_HEADER', 'FORMS_APX.HIJRI_DATE_FORMAT',
     'Hijri date format from one place: Application Setting HIJRI_DATE_FORMAT (Forms mask MI-MM-RRRR)'),
]
def fos(code, submit, ret=()):
    return dict(action='FOS', code=code, submit=list(submit), ret=list(ret))
# dynamic actions: name, event, selection, client condition, fire on init, actions, source
DAS = [
    ('IMPR_NBR KEY-NEXT-ITEM', 'change', ('ITEM', 'P1160_IMPR_NBR'), ('NOT_NULL', None), False,
     [fos('IMPR1160.IMPR_NBR_KEY_NEXT_ITEM(P_PORT_CD => :P1160_PORT_CD, P_IMPR_NBR => :P1160_IMPR_NBR, '
          'P_IMPR_NAME => :P1160_IMPR_NAME);', ['P1160_PORT_CD', 'P1160_IMPR_NBR'], ['P1160_IMPR_NAME']),
      dict(action='NATIVE_SET_FOCUS', items='P1160_DCLTN_TYPE')],
     'IMPR_CAR_EXCEPTION.IMPR_NBR.KEY-NEXT-ITEM (name of the importer, suspension check, go_item DCLTN_TYPE); '
     'also after the Popup LOV LOV_IMPR_P (CALL_IMPR_LOV)'),
    ('DCLTN_NBR POST-CHANGE', 'change', ('ITEM', 'P1160_DCLTN_NBR'), ('NOT_NULL', None), False,
     [fos('IMPR1160.DCLTN_NBR_POST_CHANGE(P_DCLTN_TYPE => :P1160_DCLTN_TYPE, P_DCLTN_NBR => :P1160_DCLTN_NBR, '
          'P_IMPR_NBR => :P1160_IMPR_NBR, P_CURR_PORT_CD => :P_CURR_PORT_CD, P_DCLTN_ISN => :P1160_DCLTN_ISN, '
          'P_STATS_ISN => :P1160_STATS_ISN, P_DCLTN_DT => :P1160_DCLTN_DT, P_NO_OF_CARS => :P1160_NO_OF_CARS);',
          ['P1160_DCLTN_TYPE', 'P1160_DCLTN_NBR', 'P1160_IMPR_NBR'],
          ['P1160_DCLTN_ISN', 'P1160_STATS_ISN', 'P1160_DCLTN_DT', 'P1160_NO_OF_CARS']),
      dict(action='NATIVE_SET_FOCUS', items='P1160_AWARD_NBR')],
     'IMPR_CAR_EXCEPTION.DCLTN_NBR.POST-CHANGE (+ CALL_IMPR_DCLTN_LOV GO_ITEM AWARD_NBR)'),
    ('AWARD_NBR WHEN-VALIDATE-ITEM', 'change', ('ITEM', 'P1160_AWARD_NBR'), ('NOT_NULL', None), False,
     [fos('FORMS_APX.CHECK_ERROR(IMPR1160.AWARD_NBR_VALIDATION(P_AWARD_NBR => :P1160_AWARD_NBR));', ['P1160_AWARD_NBR'])],
     'IMPR_CAR_EXCEPTION.AWARD_NBR.WHEN-VALIDATE-ITEM'),
    ('AWARD_DATE WHEN-VALIDATE-ITEM', 'change', ('ITEM', 'P1160_AWARD_DATE'), ('NOT_NULL', None), False,
     [fos('FORMS_APX.CHECK_ERROR(FORMS_APX.HIJRI_DATE_ERROR(:P1160_AWARD_DATE));', ['P1160_AWARD_DATE'])],
     'IMPR_CAR_EXCEPTION.AWARD_DATE.WHEN-VALIDATE-ITEM (HIJDATE.VALID_HIJ_DATE)'),
    ('NO_OF_CARS WHEN-VALIDATE-ITEM', 'change', ('ITEM', 'P1160_NO_OF_CARS'), ('NOT_NULL', None), False,
     [fos('FORMS_APX.CHECK_ERROR(IMPR1160.NO_OF_CARS_VALIDATION(P_NO_OF_CARS => :P1160_NO_OF_CARS));', ['P1160_NO_OF_CARS'])],
     'IMPR_CAR_EXCEPTION.NO_OF_CARS.WHEN-VALIDATE-ITEM'),
]
SEARCH_SQL = '\n'.join([
    '-- one search text over every shown column; no rows until a search is made (Forms opens in Enter-Query mode).',
    '-- The block has no WHERE clause: the exceptions of every port are listed (inventory 15 #3). No ORDER BY (as IMPR1140).',
    'SELECT x.*',
    "  FROM (SELECT TRANSLATE(ROWIDTOCHAR(e.ROWID), '+/', '-_') AS row_id,   -- URL-safe: a '+' in f?p arrives as a space",
    '               e.port_cd, e.impr_car_exptn_isn AS excpt_isn, e.impr_nbr, i.arbc_impr_name AS impr_name,',
    '               dt.rv_meaning AS dcltn_type_name,',
    '               CASE e.dcltn_type',
    '                    WHEN 1 THEN (SELECT TO_CHAR(d.dcltn_nbr) FROM declarations d',
    '                                  WHERE d.dcltn_isn = e.dcltn_isn AND d.port_cd = e.port_cd AND d.impr_nbr = e.impr_nbr)',
    '                    WHEN 2 THEN (SELECT TO_CHAR(s.stats_nbr) FROM stats_dcltns s',
    '                                  WHERE s.stats_isn = e.stats_isn AND s.port_cd = e.port_cd AND s.impr_expr_nbr = e.impr_nbr)',
    '               END AS dcltn_nbr,',
    '               e.exptn_award_nbr AS award_nbr,',
    '               TO_CHAR(e.exptn_award_date, (SELECT FORMS_APX.HIJRI_DATE_FORMAT FROM dual)) AS award_date,',
    '               e.no_of_cars, st.rv_meaning AS status_name',
    '          FROM impr_car_exception e, importers i, cg_ref_codes dt, cg_ref_codes st',
    '         WHERE i.port_cd (+) = e.port_cd',
    '           AND i.impr_nbr (+) = e.impr_nbr',
    "           AND dt.rv_domain (+) = 'DCL_STA_FLAG' AND dt.rv_low_value (+) = TO_CHAR(e.dcltn_type)",
    "           AND st.rv_domain (+) = 'REC_STATUS'   AND st.rv_low_value (+) = TO_CHAR(e.status)) x",
    ' WHERE :P116001_SEARCH IS NOT NULL',
    "   AND INSTR(UPPER(x.port_cd || '|' || x.excpt_isn || '|' || x.impr_nbr || '|' || x.impr_name || '|' ||",
    "                   x.dcltn_type_name || '|' || x.dcltn_nbr || '|' || x.award_nbr || '|' || x.award_date || '|' ||",
    "                   x.no_of_cars || '|' || x.status_name), UPPER(TRIM(:P116001_SEARCH))) > 0"])
SEARCH_COLUMNS = [   # name, heading, data type, kind
    ('ROW_ID', None, 'VARCHAR2', 'pk'), ('EXCPT_ISN', 'مسلسل الإستثناء', 'NUMBER', 'link'), ('PORT_CD', 'رقم المنفذ', 'NUMBER', 'text'),
    ('IMPR_NBR', 'رقم المستورد', 'NUMBER', 'text'), ('IMPR_NAME', 'اسم المستورد', 'VARCHAR2', 'text'),
    ('DCLTN_TYPE_NAME', 'نوع البيان', 'VARCHAR2', 'text'), ('DCLTN_NBR', 'رقم البيان', 'VARCHAR2', 'text'),
    ('AWARD_NBR', 'رقم المراسلة', 'VARCHAR2', 'text'), ('AWARD_DATE', 'تاريخ المراسلة', 'VARCHAR2', 'text'),
    ('NO_OF_CARS', 'عدد السيارات المستثناة', 'NUMBER', 'text'), ('STATUS_NAME', 'حالة السجل', 'VARCHAR2', 'text')]

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
    elif k == 'NATIVE_TEXTAREA':
        p += [('p_attribute_01', q('Y')), ('p_attribute_02', q('N')), ('p_attribute_03', q('N')), ('p_attribute_04', q('BOTH'))]
    elif k == 'NATIVE_DISPLAY_ONLY':
        # p_attribute_01 = Send On Page Submit (N: server value set by processes / FOS; Y: PORT_CD read by FOS)
        p += [('p_attribute_01', q('Y' if it.get('send') else 'N')), ('p_attribute_02', q('VALUE')), ('p_attribute_04', q('N')),
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
-- File        : apex/IMPR1160/f345_impr1160.sql
-- Generated by: Claude Code (scripts/gen_apex_impr1160.py, step 04) from
--               analysis/IMPR1160/IMPR1160_apex_page_spec.md, %s, form IMPR1160 (IMPR1160_ND_CNTRL)
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / 4c / 4d, docs/f345_reference_standard.md 3-9: editable native Form region on
--               IMPR_CAR_EXCEPTION (key ROWID, i:u:d; a queried record only lets STATUS change), Popup LOVs from
--               LOV_APX (004), FOS + native dynamic actions, one-line calls into package IMPR1160 (version 001) and
--               FORMS_APX (004). No JavaScript file, no AJAX callback process.
-- Contents    : component export INTO the application installed from f345: pages 1160 (main) and
--               116001 (search) + 3 shared LOVs + 5 Text Messages. Needs the IMPR1110 export (page group IMPR,
--               Application Setting HIJRI_DATE_FORMAT) and the IMPR1140 export (LOV_REC_STATUS) imported first.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR1160/import_notes.md
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
    UNCERTAIN.add(lov_apx.UNCERTAIN)
    for name, sql, cols, s in LOVS:
        key = '%d:lov:%s' % (SHARED_BASE, name)
        nid(key, 5)
        b = [call('create_list_of_values', [('p_id', ref(key)), ('p_lov_name', q(name))] + lov_apx.lov_attributes(sql, q),
                  'Source: IMPR1160 ' + s + ' / spec 6')]
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
                     'Source: IMPR1160.%s (constraint %s) / spec 11' % (s, name))))
    UNCERTAIN.add('wwv_flow_api.create_message (Text Message; f345 has none; IMPR1110 / IMPR1120 / IMPR1140 use it) - p_message_language ar-sa')

    # ---------------------------------------------------------------- page 1160
    P = []
    A = P.append
    R = '1160:plug:IMPR_CAR_EXCEPTION'
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG)
    A(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM)), ('p_alias', q(FORM)),
        ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('Y')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_step_template', fid('PAGE_MAIN')),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1160.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR1160.fmb - spec 2 / f345 standard 4'))
    hero = ('<div class="cg-hero-row"><div class="cg-hero-top"><span class="cg-hero-ic fa fa-car" aria-hidden="true"></span>'
            '<div><div class="cg-hero-k">المستوردون</div><div class="cg-hero-t">&P1160_HERO_TITLE.</div>'
            '<div class="cg-hero-d">استثناء عدد من سيارات بيان المستورد الفرد بموجب مراسلة</div></div></div></div>')
    nid('1160:plug:HERO', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1160:plug:HERO')), ('p_plug_name', q('الهيدر')), ('p_region_name', q('IMPR_CAR_EXCEPTION_HERO')),
        ('p_region_css_classes', q('cg-hero')), ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '5'), ('p_plug_source', q(hero)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src('IMPR1160.TITLE (OLB) -> f345 hero / spec 3'))]))
    nid(R, 1)
    A(call('create_page_plug', [
        ('p_id', ref(R)), ('p_plug_name', q('استثناء المستوردين الافراد للسيارات')), ('p_region_name', q('IMPR_CAR_EXCEPTION')),
        ('p_region_css_classes', q('zatca-forms cg-form cg-card')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_FORM')), ('p_plug_display_sequence', '10'), ('p_query_type', q('TABLE')),
        ('p_query_table', q('IMPR_CAR_EXCEPTION')), ('p_include_rowid_column', 'true'), ('p_is_editable', 'true'),
        ('p_edit_operations', q('i:u:d')), ('p_plug_source_type', q('NATIVE_FORM')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1160.IMPR_CAR_EXCEPTION (single record; insert; PRE-QUERY MAKE_BLOCK_FULL_OPERATION(TRUE, TRUE, '
                               'TRUE): update (STATUS only) and delete of a queried record; key mode ROWID) / spec 3'))]))
    UNCERTAIN.add('ROWID primary key of the Form region: p_include_rowid_column, item source ROWID / p_source_data_type ROWID (as IMPR1110 / IMPR1140)')
    UNCERTAIN.add('NATIVE_FORM region p_edit_operations => i:u:d (as IMPR1140)')
    nid('1160:branch:STAY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1160:branch:STAY')), ('p_branch_name', q('IMPR1160 - stay in the form')),
        ('p_branch_action', q('f?p=&APP_ID.:1160:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '20'),
        ('p_branch_comment', src('Forms stays on the record after COMMIT (P0_PAGE_PK kept; after DELETE a new record) / spec 12'))]))
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
    UNCERTAIN.add('not displayed DATE columns as Display Only items with p_grid_column_css_classes u-hidden and a format mask (as IMPR1110 LST_TRAN_DT)')
    UNCERTAIN.add('p_item_default with a static value on the Select List DCLTN_TYPE (1; IMPR1110 / IMPR1140 use p_item_default)')
    # computations (spec 9)
    for n, (item, point, expr, s) in enumerate(COMPUTATIONS, 1):
        key = '1160:comp:' + item
        nid(key, 5)
        A(call('create_page_computation', [
            ('p_id', ref(key)), ('p_computation_sequence', str(n * 10)), ('p_computation_item', q(PI + item)),
            ('p_computation_point', q(point)), ('p_computation_type', q('EXPRESSION')), ('p_computation_language', q('PLSQL')),
            ('p_computation', lit(expr)), ('p_computation_comment', src('IMPR1160 ' + s + ' / spec 9'))]))
    # validations (spec 7)
    for n, (name, item, code, cond, s) in enumerate(VALIDATIONS, 1):
        key = '1160:val:' + name
        nid(key, 6)
        A(call('create_page_validation', [
            ('p_id', ref(key)), ('p_validation_name', q(name)), ('p_validation_sequence', str(n * 10)),
            ('p_validation', lit(code)), ('p_validation2', q('PLSQL')), ('p_validation_type', q('FUNC_BODY_RETURNING_ERR_TEXT')),
            ('p_validation_condition', q(cond)), ('p_validation_condition2', q('PLSQL')), ('p_validation_condition_type', q('EXPRESSION')),
            ('p_associated_item', 'wwv_flow_api.id(%s)' % _ids['1160:item:' + PI + item]),
            ('p_error_display_location', q('INLINE_WITH_FIELD_AND_NOTIFICATION')),
            ('p_validation_comment', src('IMPR1160.' + s + ' / spec 7'))]))
    # processes (spec 8, f345 standard 6)
    AGR_NEW = 'NULL;  -- f345 session setup (SSO_APP_USER, P_CURR_PORT_CD, V_USR_TYPE ...) is done by the application; disabled as in AGR1100'
    form_dml = lambda msg: [('p_attribute_01', q('REGION_SOURCE')), ('p_attribute_05', q('Y')), ('p_attribute_06', q('Y')),
                            ('p_attribute_08', q('Y'))]
    for point, seq, name, code, cond, s, msg in PROCESSES:
        key = '1160:proc:%s:%s' % (point, name)
        if name == 'New':
            A(process(key, seq, point, 'New', AGR_NEW, 'NEVER', s))
        elif name == 'Initialize form':
            A(process(key, seq, point, name, None, None, 'IMPR1160 ' + s + ' / spec 8', ptype='NATIVE_FORM_INIT', region=R))
        elif code == FORM_DML:
            A(process(key, seq, point, name, None, cond, 'IMPR1160 ' + s + ' / spec 8', ptype='NATIVE_FORM_DML',
                      extra=form_dml(msg), region=R, success=msg))
        else:
            A(process(key, seq, point, name, code, cond, 'IMPR1160 ' + s + ' / spec 8', success=msg))
    UNCERTAIN.add('Process form - DELETE: a second NATIVE_FORM_DML process on request DELETE (f345 standard 6, as IMPR1140)')
    # dynamic actions (spec 10)
    for n, d in enumerate(DAS, 1):
        A(da(PG, n, *d))
    W(block('application/pages/page_01160', '\n'.join(P)))

    # ---------------------------------------------------------------- page 116001 (search)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_SEARCH)
    A(call('create_page', [
        ('p_id', str(PG_SEARCH)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM + '_SEARCH')), ('p_alias', q(FORM + '-SEARCH')),
        ('p_page_mode', q('MODAL')), ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_height', q('800')),
        ('p_dialog_width', q('1800')), ('p_protection_level', q('C')), ('p_first_item', q('AUTO_FIRST_ITEM')),
        ('p_page_comment', src('IMPR1160 Enter-Query / Execute-Query of block IMPR_CAR_EXCEPTION (KEY-ENTQRY, KEY-EXEQRY) / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: f345 search page <page>01 (page 0 SEARCH)'))
    nid('116001:plug:CRIT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('116001:plug:CRIT')), ('p_plug_name', q('بحث')), ('p_region_name', q('IMPR_CAR_EXCEPTION_SEARCH_CRITERIA')),
        ('p_region_css_classes', q('zatca-forms cg-form')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_HERO')), ('p_plug_display_sequence', '10'), ('p_attribute_01', q('N')),
        ('p_attribute_02', q('TEXT')), ('p_attribute_03', q('Y')),
        ('p_plug_comment', src('IMPR1160.IMPR_CAR_EXCEPTION query criteria as one search text over all columns / spec 3'))]))
    P.extend(ig_region(PG_SEARCH, '116001:plug:IG', SEARCH_SQL, 'P116001_SEARCH', SEARCH_COLUMNS,
                       '116001000201', 'لا توجد نتائج - أدخل نص البحث ثم اضغط بحث', True,
                       'IMPR1160.IMPR_CAR_EXCEPTION block query (no WHERE clause: all ports) with the POST-QUERY names; one search '
                       'text over all columns, no query until a search / spec 3', 'استثناءات السيارات', 'IMPR_CAR_EXCEPTION_SEARCH', 20,
                       link='f?p=&APP_ID.:1160:&SESSION.::&DEBUG.:1160:P0_PAGE_PK:&ROW_ID.'))
    UNCERTAIN.add('search IG 116001: p_lazy_loading true, p_show_total_row_count false, toolbar ACTIONS_MENU:RESET (search field removed)')
    A(page_item(PG_SEARCH, '116001:plug:CRIT', 10, dict(
        name='P116001_SEARCH', kind='NATIVE_TEXT_FIELD', label='بحث في كل الأعمدة', maxlen=200, span=6,
        comment='Source: IMPR1160.IMPR_CAR_EXCEPTION query criteria (QBE of PORT_CD, EXCPT_ISN, IMPR_NBR ...) as one text over all columns')))
    for b, seq, label, icon, css, s in [('SEARCH', 20, 'بحث', 'fa-search', 'cg-b-search', 'EXECUTE_QUERY of block IMPR_CAR_EXCEPTION'),
                                        ('CLEAR', 30, 'مسح البحث', 'fa-eraser', 'cg-b-clear', 'TOOLBAR.CLEAR_ALL for the search')]:
        nid('116001:btn:' + b, 2)
        A(call('create_page_button', [
            ('p_id', ref('116001:btn:' + b)), ('p_button_sequence', str(seq)), ('p_button_plug_id', ref('116001:plug:CRIT')),
            ('p_button_name', q(b)), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
            ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q(label)), ('p_button_position', q('BODY')),
            ('p_icon_css_classes', q(icon)), ('p_button_css_classes', q(css)), ('p_button_comment', src('IMPR1160 %s / spec 3' % s))]))
    refresh = [('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('116001:plug:IG'))]
    for ek, name, seq, trig, extra, acts, s in [
            ('116001:da:SEARCH', 'SEARCH', 10, [('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('116001:btn:SEARCH'))],
             [('p_bind_type', q('bind')), ('p_bind_event_type', q('click'))], [refresh], 'IMPR1160 EXECUTE_QUERY / spec 3'),
            ('116001:da:SEARCH KEY-ENTER', 'SEARCH KEY-ENTER', 12,
             [('p_triggering_element_type', q('ITEM')), ('p_triggering_element', q('P116001_SEARCH')),
              ('p_triggering_condition_type', q('JAVASCRIPT_EXPRESSION')), ('p_triggering_expression', q('this.browserEvent.which === 13'))],
             [('p_bind_type', q('bind')), ('p_bind_event_type', q('keyup'))], [refresh],
             'IMPR1160 KEY-EXEQRY (Enter in the search text; f345 AGR1100_SEARCH keyup pattern) / spec 3'),
            ('116001:da:CLEAR', 'CLEAR WHEN-BUTTON-PRESSED', 15,
             [('p_triggering_element_type', q('BUTTON')), ('p_triggering_button_id', ref('116001:btn:CLEAR'))],
             [('p_bind_type', q('bind')), ('p_bind_event_type', q('click'))],
             [[('p_action', q('NATIVE_CLEAR')), ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q('P116001_SEARCH'))], refresh],
             'IMPR1160 TOOLBAR.CLEAR_ALL (search criteria) / spec 3')]:
        nid(ek, 8)
        A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q(name)), ('p_event_sequence', str(seq))] + trig + extra
               + [('p_da_event_comment', src(s))]))
        for i, a in enumerate(acts, 1):
            nid('%s:%d' % (ek, i * 10), 9)
            A(call('create_page_da_action', [('p_id', ref('%s:%d' % (ek, i * 10))), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                             ('p_action_sequence', str(i * 10)), ('p_execute_on_page_init', q('N'))] + a))
    UNCERTAIN.add('button DA: p_triggering_button_id (as page 113001 SEARCH; IMPR1110 uses it)')
    UNCERTAIN.add('DA client-side condition JAVASCRIPT_EXPRESSION this.browserEvent.which === 13 (Enter key; not in f345)')
    UNCERTAIN.add('NATIVE_CLEAR action with p_affected_elements (page 116001 CLEAR; not in f345)')
    ek, ak = '116001:da:Hide', '116001:daa:Hide:10'
    nid(ek, 8); nid(ak, 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('Hide')), ('p_event_sequence', '20'),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('ready')),
                                    ('p_da_event_comment', src('f345 AGR1100_SEARCH "Hide" (page 0 toolbar not used in a dialog)'))]))
    A(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('Y')), ('p_action', q('NATIVE_HIDE')),
                                     ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', fid('P0_ACTIONS'))]))
    W(block('application/pages/page_116001', '\n'.join(P)))
    W('''prompt --application/end_environment
begin
wwv_flow_api.component_end;
end;
/
set verify on feedback on define on
prompt  ...done
''')
    text = items_to_submit.fix('\n'.join(out))
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
    problems = items_to_submit.check(text) + item_icons.check(text) + lov_apx.check(text) + functions_drawer.check_form_page(text)
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
    for m in set(re.findall(r'IMPR1160\.([A-Z_0-9]+)', code)):
        if m not in members: problems.append('IMPR1160.%s not in impr1160_spec.sql' % m)
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
    path = os.path.join(ROOT, 'apex', 'IMPR1160', 'f%s_impr1160_import.sql' % vals['app_id'])
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
    os.makedirs(os.path.join(ROOT, 'work', 'IMPR1160', 'step04'), exist_ok=True)
    json.dump(sorted(UNCERTAIN), open(os.path.join(ROOT, 'work', 'IMPR1160', 'step04', 'uncertain.json'), 'w'), indent=1)
    print('problems:', probs or 'none')
    if probs:
        sys.exit(1)
    if len(sys.argv) > 1:
        ready_copy(t, sys.argv[1:])
