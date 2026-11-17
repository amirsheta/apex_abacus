-- =============================================================================
-- IMPR1110 - migration registry rows (scripts/create_migration_registry.sql)
-- app_id 2000 is a PLACEHOLDER - replace with the real IMPR application id.
-- Re-runnable: deletes the form's rows first.
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR1110';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR1110';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR1110', 'IMPR', 'IMPORTERS', 2000, 1110, 1119, 'IMPR1110',
     'PKG_IMPR1110', 'COMPLEX', 'DESIGN', NULL, NULL,
     'إضافة وتعديل بيانات مستورد - package written (not compiled), page spec ready, app_id placeholder');

-- helper to keep the inserts short
DECLARE
    PROCEDURE m (p_type VARCHAR2, p_name VARCHAR2, p_comp VARCHAR2, p_comp_name VARCHAR2,
                 p_member VARCHAR2, p_status VARCHAR2 DEFAULT 'MAPPED', p_notes VARCHAR2 DEFAULT NULL)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR1110', p_type, p_name, p_comp, p_comp_name,
                CASE WHEN p_comp IN ('LOV','TEXT_MESSAGE','APP_ITEM','AUTH_SCHEME') THEN NULL ELSE 1110 END,
                p_member, p_status, p_notes);
    END m;
BEGIN
    -- blocks
    m('BLOCK', 'IMPORTERS', 'REGION', 'IMPORTERS', NULL, 'MAPPED', 'plus IR IMPORTERS_QRY');
    m('BLOCK', 'TITLE',     'REGION', NULL, NULL, 'DROPPED', 'page title / nav bar');
    m('BLOCK', 'EDI_MSG',   'REGION', NULL, NULL, 'DROPPED', 'EDI ticker not migrated');
    m('BLOCK', 'LSIDE',     'REGION', NULL, NULL, 'DROPPED', 'APEX navigation menu');
    m('BLOCK', 'TOOLBAR',   'BUTTON', 'SAVE/CREATE/DELETE/QUERY/CLEAR/EXIT', NULL, 'MAPPED');
    m('CANVAS','CG$PAGE_1', 'PAGE',   'IMPR1110', NULL);

    -- form-level / block-level triggers
    m('TRIGGER', 'WHEN-NEW-FORM-INSTANCE',       'PROCESS', 'IMPR1110.WHEN-NEW-FORM-INSTANCE', 'PKG_IMPR1110.PAGE_WNFI');
    m('TRIGGER', 'IMPORTERS.WHEN-CREATE-RECORD', 'PROCESS', 'IMPORTERS.POST-QUERY / WHEN-CREATE-RECORD', 'PKG_IMPR1110.IMPORTERS_WCR');
    m('TRIGGER', 'IMPORTERS.POST-QUERY',         'PROCESS', 'IMPORTERS.POST-QUERY / WHEN-CREATE-RECORD', 'PKG_IMPR1110.IMPORTERS_POST_QRY');
    m('TRIGGER', 'IMPORTERS.PRE-QUERY',          'REGION',  'IMPORTERS_QRY', 'PKG_IMPR1110.IMPR_NAME_STD_QRY');
    m('TRIGGER', 'IMPORTERS.WHEN-NEW-RECORD-INSTANCE', 'DYNAMIC_ACTION', 'IMPORTERS.UI_STATE', 'PKG_IMPR1110.UI_STATE_JSON');
    m('TRIGGER', 'IMPORTERS.PRE-INSERT',         'PROCESS', 'IMPORTERS.PRE/ON/POST-INSERT', 'PKG_IMPR1110.IMPORTERS_PRE_INS');
    m('TRIGGER', 'IMPORTERS.POST-INSERT',        'PROCESS', 'IMPORTERS.PRE/ON/POST-INSERT', 'PKG_IMPR1110.IMPORTERS_POST_INS');
    m('TRIGGER', 'IMPORTERS.PRE-UPDATE',         'PROCESS', 'IMPORTERS.PRE/ON/POST-UPDATE', 'PKG_IMPR1110.IMPORTERS_PRE_UPD');
    m('TRIGGER', 'IMPORTERS.POST-UPDATE',        'PROCESS', 'IMPORTERS.PRE/ON/POST-UPDATE', 'PKG_IMPR1110.IMPORTERS_POST_UPD');
    m('TRIGGER', 'IMPORTERS.PRE-DELETE',         'PROCESS', 'IMPORTERS.KEY-DELREC', 'PKG_IMPR1110.IMPORTERS_PRE_DEL');
    m('TRIGGER', 'IMPORTERS.KEY-DELREC',         'PROCESS', 'IMPORTERS.KEY-DELREC', 'PKG_IMPR1110.IMPORTERS_DEL', 'MAPPED', 'delete policy open question');
    m('TRIGGER', 'IMPORTERS.ON-ERROR',           'TEXT_MESSAGE', 'IMP_PK/IMP_BUSID_UK/IMP_*_FK', 'PKG_FORMS_COMPAT.APEX_ERROR_HANDLER');
    m('TRIGGER', 'ON-ERROR',                     'TEXT_MESSAGE', 'error handling function', 'PKG_FORMS_COMPAT.APEX_ERROR_HANDLER');
    m('TRIGGER', 'IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED', 'DYNAMIC_ACTION',
      'IMPORTERS.COMM_RGSTRTN_TYPE.WHEN-LIST-CHANGED', 'PKG_IMPR1110.COMM_RGSTRTN_WLC');
    m('TRIGGER', 'WHEN-TIMER-EXPIRED', 'PAGE', NULL, NULL, 'DROPPED', 'EDI timer');
    m('TRIGGER', 'KEY-* navigation',   'PAGE', NULL, NULL, 'DROPPED', 'browser navigation');

    -- item validations (WHEN-VALIDATE-ITEM -> validation + DA)
    FOR r IN (SELECT COLUMN_VALUE it FROM TABLE(sys.odcivarchar2list(
                'IMPR_NBR','IMPR_TYPE_CD','BUS_ID_EXPRD_DT','CITY_CODE_OF_ID','BUS_ID',
                'BRNH_CITY_CD','BUS_ID_BRNCH','CTRY_CD','ARBC_IMPR_NAME','ENG_IMPR_NAME',
                'BUS_ID_ISSUE_DT','IMPR_NBR_PARENT','ADD_CTRY_CD','CITY_CODE','IMPR_TEL_NBR',
                'B_EMAIL','B_MOBILE_NO','BANK_IBAN','B_ID_NBR'))) LOOP
        m('TRIGGER', 'IMPORTERS.' || r.it || '.WHEN-VALIDATE-ITEM', 'VALIDATION',
          'IMPORTERS.' || r.it || '.WHEN-VALIDATE-ITEM',
          SUBSTR('PKG_IMPR1110.' || r.it || '_WVI', 1, 70));
    END LOOP;

    -- program units
    m('PROGRAM_UNIT', 'CHECK_IDNO',            'VALIDATION', NULL, 'PKG_IMPR1110.CHECK_IDNO');
    m('PROGRAM_UNIT', 'IS_DIGIT',              'VALIDATION', NULL, 'PKG_IMPR1110.IS_DIGIT');
    m('PROGRAM_UNIT', 'CHK_IMPR_DUPL',         'VALIDATION', NULL, 'PKG_IMPR1110.CHK_IMPR_DUPL');
    m('PROGRAM_UNIT', 'CHK_DUPL_IMP_BRKR',     'VALIDATION', NULL, 'PKG_IMPR1110.CHK_DUPL_IMP_BRKR');
    m('PROGRAM_UNIT', 'CHK_PERSONAL',          'VALIDATION', NULL, 'PKG_IMPR1110.CHK_PERSONAL');
    m('PROGRAM_UNIT', 'INSERT_AUDIT_RECORD',   'PROCESS',    NULL, 'PKG_IMPR1110.INSERT_AUDIT_RECORD');
    m('PROGRAM_UNIT', 'UPDATE_BASIC_IMPORTER', 'PROCESS',    NULL, 'PKG_IMPR1110.UPDATE_BASIC_IMPORTER', 'MAPPED', 'COMMIT removed');
    m('PROGRAM_UNIT', 'ADJ_FUNS',              'AUTH_SCHEME',NULL, 'PKG_IMPR1110.FUN_ALLOWED');
    m('PROGRAM_UNIT', 'EXEC_FUNS',             'BUTTON',     'IMPR1110F1/F3', 'PKG_IMPR1110.F1_COMM_NAME / F3_SET_TYPE_19');
    m('PROGRAM_UNIT', 'GET_CR_DATA',           'BUTTON',     'IMPR_MCI_SERVICE', NULL, 'MANUAL', 'MCI web service');
    m('PROGRAM_UNIT', 'GET_MAIN_CR_DATA',      'BUTTON',     'IMPR_MCI_SERVICE', NULL, 'MANUAL');
    m('PROGRAM_UNIT', 'GET_BRANCH_CR_DATA',    'BUTTON',     'IMPR_MCI_SERVICE', NULL, 'MANUAL');
    m('PROGRAM_UNIT', 'CREATE_BRKR_IMPR_AUTH', 'BUTTON',     'CREATE_BRKR_IMPR_AUTH', NULL, 'MANUAL');
    m('PROGRAM_UNIT', 'BROKER_INT',            'BUTTON',     NULL, NULL, 'MANUAL');
    m('PROGRAM_UNIT', 'LOV_UPDATE_MOBLIE',     'BUTTON',     'IMPR1110_MOB', NULL, 'TODO', 'target page unknown');
    m('PROGRAM_UNIT', 'VIEW_SAME_BUSID',       'BUTTON',     NULL, NULL, 'TODO');
    m('PROGRAM_UNIT', 'RETURN_IMPR_ID',        'PROCESS',    NULL, NULL, 'TODO');
    m('PROGRAM_UNIT', 'UPDATE_IMPORTER',       'PROCESS',    NULL, NULL, 'TODO');
    m('PROGRAM_UNIT', 'EDI_MSG_LOV/FOR_EDI_MSG/TURN_MSG', 'PAGE', NULL, NULL, 'DROPPED');
    m('PROGRAM_UNIT', 'CHECK_TIMEOUT/MOUSE_CLICK/TOGGEL_WND/PRINT_REPORT', 'PAGE', NULL, NULL, 'DROPPED');

    -- LOVs
    m('LOV', 'CGFK$IMPORTERS_PORT_CD',         'LOV', 'LOV_SD_PORTS',   NULL);
    m('LOV', 'CGFK$IMPORTERS_IMPR_TYPE_CD',    'LOV', 'LOV_IMPR_TYPE',  NULL, 'MAPPED', '+ LOV_BUS_ID_TYPE');
    m('LOV', 'CGFK$IMPORTERS_CTRY_CD',         'LOV', 'LOV_COUNTRIES',  NULL);
    m('LOV', 'CGFK$IMPORTERS_ADD_CTRY_CD',     'LOV', 'LOV_CITIES_IMP', NULL);
    m('LOV', 'CGFK$IMPORTERS_CITY_CODE_OF_ID', 'LOV', 'LOV_CITIES',     NULL);
    m('LOV', 'CGFK$IMPORTERS_HQ_IMPR_NBR',     'LOV', NULL, NULL, 'DROPPED', 'display only');
    m('LOV', 'CGDV$IMPORTERS_CREATION_FLAG',   'LOV', NULL, NULL, 'DROPPED', 'hidden item');
    m('LOV', 'CGDV$IMPORTERS_CUSTOMS_ENTERED', 'LOV', NULL, NULL, 'DROPPED', 'hidden item');

    -- parameters / globals
    m('PARAMETER', 'P_CURR_PORT_CD', 'APP_ITEM', 'AI_P_CURR_PORT_CD', NULL);
    m('PARAMETER', 'P_USER_ID',      'APP_ITEM', 'AI_P_USER_ID',      NULL);
    m('PARAMETER', 'P_WS_ID',        'APP_ITEM', 'AI_P_WS_ID',        NULL);
    m('PARAMETER', 'P_CLASS_CD',     'APP_ITEM', 'AI_P_CLASS_CD',     NULL);
    m('PARAMETER', 'P_USER_TYPE',    'APP_ITEM', 'AI_P_USER_TYPE',    NULL);
    m('PARAMETER', 'PRSNL_IMPR',     'ITEM',     'P1110_PRSNL_IMPR',  NULL);
    m('PARAMETER', 'LETTER_NBR',     'ITEM',     'P1110_LETTER_NBR',  NULL);
    m('PARAMETER', 'CODE',           'BUTTON',   'REQUEST',           NULL);
    FOR g IN (SELECT COLUMN_VALUE gn FROM TABLE(sys.odcivarchar2list(
                'ALLOW_MCI','ALLOW_MOI','CHK_DUP_BUSID','CHK_IMP_TYP','FLAGUPDATE','FUNS_IMP',
                'IMPR_NAME_B','IMPR_NBR_B','LETTER_DT','LETTER_NBR','OLD_IMPR_TYPE_CD',
                'OLD_PORT_CD','PORT_CD','SUPP_TITLE_CD'))) LOOP
        m('GLOBAL', g.gn, 'APP_ITEM', 'AI_' || g.gn, 'PKG_FORMS_COMPAT.GET_GLOBAL');
    END LOOP;
END;
/
COMMIT;
