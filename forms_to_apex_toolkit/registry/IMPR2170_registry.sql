-- =============================================================================
-- IMPR2170 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (trace: analysis/IMPR2170/IMPR2170_apex_page_spec.md section 11)
-- Form    : IMPR2170.fmb (report parameter form of IMPR2170.rdf "تقرير حالة مستورد")
-- Author  : Claude Code
-- Date    : 2026-11-25
-- Version : 1.0 (package IMPR2170 version 001). Built from registry/IMPR2150_registry.sql.
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR2170';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR2170';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR2170', 'IMPR', 'IMPR', 202530, 2170, 2170, 'IMPR2170',
     'IMPR2170', 'MEDIUM', 'DESIGN', NULL, NULL,
     'تقرير حالة مستورد - report page 2170 + ARD package IMPR2170_ARD (standard 13-b / 13-c); packages 001 not compiled; '
     || 'open item: SHOW_USER / IMPR2170n.rep missing');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR2170', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN
    m('BLOCK', 'CALLING_PARAMETERS', 'REGION', 'CALLING_PARAMETERS (static, report parameters)', 2170, NULL, 'MAPPED', 'control block');
    m('BLOCK', 'TITLE', 'REGION', 'TITLE (hero)', 2170, 'IMPR2170.WHEN_NEW_FORM_INSTANCE', 'MAPPED', 'OLB title: module name, report no, port');
    m('BLOCK', 'TOOLBAR', 'REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, NULL, 'MAPPED', 'ITEM303/ITEM304 -> REPORT_PRINT');
    m('BLOCK', 'ZATCA_LOGOS', 'REGION', 'TITLE (hero) / theme', 2170, NULL, 'MAPPED', 'OLB logos');
    m('ITEM', 'CALLING_PARAMETERS.SELECT1', 'ITEM', 'P2170_SELECT1', 2170, 'IMPR2170.SELECT1_VALIDATION', 'MAPPED', 'radio group 1/2, default 1, head office only');
    m('ITEM', 'CALLING_PARAMETERS.P_PORT_CD', 'ITEM', 'P2170_P_PORT_CD', 2170, 'IMPR2170.P_PORT_CD_VALIDATION', 'MAPPED', 'Popup LOV LOV_SD_PORTS, head office only');
    m('ITEM', 'CALLING_PARAMETERS.P_LOV_PORT', 'ITEM', 'P2170_P_PORT_CD (Popup LOV button)', 2170, NULL, 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.P_PORT_NAME', 'ITEM', 'P2170_P_PORT_NAME', 2170, 'IMPR2170.P_PORT_CD_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.IMPR_NBR', 'ITEM', 'P2170_IMPR_NBR', 2170, 'IMPR2170.IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', 'Popup LOV LOV_IMPR2170_LOV_IMPR_NBR');
    m('ITEM', 'CALLING_PARAMETERS.LOV_IMPR', 'ITEM', 'P2170_IMPR_NBR (Popup LOV button)', 2170, NULL, 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.IMPR_NAME', 'ITEM', 'P2170_IMPR_NAME', 2170, 'IMPR2170.IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.HQ_IMPR_NBR', 'ITEM', 'P2170_HQ_IMPR_NBR', 2170, 'IMPR2170.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', 'Popup LOV LOV_IMPORT_HQ_NBR (IMPR2150), head office only');
    m('ITEM', 'CALLING_PARAMETERS.HQ_LOV_IMPR', 'ITEM', 'P2170_HQ_IMPR_NBR (Popup LOV button)', 2170, NULL, 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.HQ_IMPR_NAME', 'ITEM', 'P2170_HQ_IMPR_NAME', 2170, 'IMPR2170.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('ITEM', 'TITLE.SCREEN_NAME', 'ITEM', 'P2170_HERO_TITLE', 2170, NULL, 'MAPPED', 'FORMS_APX.HEADER_TITLE');
    m('ITEM', 'TITLE.REPORT_NO', 'ITEM', 'P2170_REPORT_NO', 2170, 'IMPR2170.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.P_CURR_PORT_NAME', 'ITEM', 'P2170_P_CURR_PORT_NAME', 2170, 'IMPR2170.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.SHOW_USER', NULL, NULL, NULL, NULL, 'TODO', 'TODO: MISSING SOURCE IMPR2170n.rep (check box not converted)');
    m('ITEM', 'TITLE.USER_NAME', NULL, NULL, NULL, NULL, 'DROPPED', 'f345 shell shows the user');
    m('ITEM', 'TITLE.SYSTEM_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('ITEM', 'TITLE.SYSTEM_G_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('TRIGGER', 'SELECT1.WHEN-RADIO-CHANGED', 'DA', 'SELECT1 WHEN-RADIO-CHANGED', 2170, NULL, 'MAPPED', 'PU ENB_DISP_FLDS: Clear / Enable / Disable');
    m('TRIGGER', 'CALLING_PARAMETERS.WHEN-NEW-RECORD-INSTANCE', 'DA', 'SELECT1 WHEN-RADIO-CHANGED (page load)', 2170, NULL, 'MAPPED', 'PU ENB_DISP_FLDS');
    m('TRIGGER', 'P_PORT_CD.KEY-LISTVAL', 'ITEM', 'P2170_P_PORT_CD (Popup LOV)', 2170, NULL, 'MAPPED', 'REP_LOV_SD_PORTS');
    m('TRIGGER', 'P_PORT_CD.WHEN-VALIDATE-ITEM', 'DA', 'P_PORT_CD WHEN-VALIDATE-ITEM', 2170, 'IMPR2170.P_PORT_CD_WHEN_VALIDATE_ITEM', 'MAPPED', 'Clear + FOS');
    m('TRIGGER', 'P_LOV_PORT.WHEN-BUTTON-PRESSED', 'ITEM', 'P2170_P_PORT_CD (Popup LOV)', 2170, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'IMPR_NBR.KEY-LISTVAL', 'ITEM', 'P2170_IMPR_NBR (Popup LOV)', 2170, NULL, 'MAPPED', 'PU CHECK_LIST_VAL');
    m('TRIGGER', 'IMPR_NBR.WHEN-VALIDATE-ITEM', 'DA', 'IMPR_NBR WHEN-VALIDATE-ITEM', 2170, 'IMPR2170.IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', 'Clear + FOS');
    m('TRIGGER', 'LOV_IMPR.WHEN-BUTTON-PRESSED', 'ITEM', 'P2170_IMPR_NBR (Popup LOV)', 2170, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'IMPR_NAME.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'empty trigger');
    m('TRIGGER', 'IMPR_NAME.KEY-LISTVAL', NULL, NULL, NULL, NULL, 'DROPPED', 'empty trigger');
    m('TRIGGER', 'HQ_IMPR_NBR.KEY-LISTVAL', 'ITEM', 'P2170_HQ_IMPR_NBR (Popup LOV)', 2170, NULL, 'MAPPED', 'PU CHECK_LIST_VAL');
    m('TRIGGER', 'HQ_IMPR_NBR.WHEN-VALIDATE-ITEM', 'DA', 'HQ_IMPR_NBR WHEN-VALIDATE-ITEM', 2170, 'IMPR2170.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', 'Clear + FOS');
    m('TRIGGER', 'HQ_LOV_IMPR.WHEN-BUTTON-PRESSED', 'ITEM', 'P2170_HQ_IMPR_NBR (Popup LOV)', 2170, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'HQ_IMPR_NAME.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'empty trigger');
    m('TRIGGER', 'HQ_IMPR_NAME.KEY-LISTVAL', NULL, NULL, NULL, NULL, 'DROPPED', 'empty trigger');
    m('TRIGGER', 'TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TITLE.SYSTEM_G_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TOOLBAR.ITEM303.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2170, 'IMPR2170.PRINT_CHECK_VAL', 'MAPPED', 'طباعة');
    m('TRIGGER', 'TOOLBAR.ITEM304.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2170, 'IMPR2170.PRINT_CHECK_VAL', 'MAPPED', 'عرض = same PDF; REPORT_SHOW Never (DEC-018)');
    m('TRIGGER', 'TOOLBAR.ITEM305.WHEN-BUTTON-PRESSED', 'BUTTON', 'CLEAR (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'TOOLBAR.ITEM306.WHEN-BUTTON-PRESSED', 'ITEM', 'Popup LOV button', 2170, NULL, 'MAPPED', 'DO_KEY(LIST_VALUES)');
    m('TRIGGER', 'TOOLBAR.ITEM307.WHEN-BUTTON-PRESSED', 'BUTTON', 'BACK (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'TOOLBAR.ITEM303/304/305/306/307.KEY-NEXT-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'button navigation');
    m('TRIGGER', 'WHEN-NEW-FORM-INSTANCE', 'PROCESS', 'WHEN-NEW-FORM-INSTANCE', 2170, 'IMPR2170.WHEN_NEW_FORM_INSTANCE', 'MAPPED', 'SELECT1 := 1 -> item default');
    m('TRIGGER', 'PRE-FORM', NULL, NULL, NULL, NULL, 'DROPPED', 'window title / icon / date format');
    m('TRIGGER', 'WHEN-WINDOW-ACTIVATED', NULL, NULL, NULL, NULL, 'DROPPED', 'window state');
    m('TRIGGER', 'KEY-PRINT', NULL, NULL, NULL, NULL, 'DROPPED', 'NULL in Forms');
    m('TRIGGER', 'KEY-F4', 'DA', 'REPORT_PRINT', 2170, 'IMPR2170.PRINT_CHECK_VAL', 'MAPPED', 'CHECK_VAL; no keyboard shortcut (CLAUDE.md 5)');
    m('TRIGGER', 'KEY-F5', 'DA', 'REPORT_PRINT', 2170, 'IMPR2170.PRINT_CHECK_VAL', 'MAPPED', 'PRINT_CHECK_VAL; no keyboard shortcut');
    m('PROGRAM_UNIT', 'CHECK_VAL', 'PACKAGE', 'IMPR2170.PRINT_CHECK_VAL', 2170, 'IMPR2170.PRINT_CHECK_VAL', 'MAPPED', 'VIEW = PRINT (DEC-018); same code');
    m('PROGRAM_UNIT', 'PRINT_CHECK_VAL', 'PACKAGE', 'IMPR2170.PRINT_CHECK_VAL', 2170, 'IMPR2170.PRINT_CHECK_VAL', 'MAPPED', 'port required for SELECT1 = 1 (SUGGESTION)');
    m('PROGRAM_UNIT', 'COUNT_SUSP1', 'PACKAGE', 'IMPR2170.COUNT_SUSP1 (private)', 2170, 'IMPR2170.PRINT_CHECK_VAL', 'MAPPED', 'kept as in Forms; date format MI (SUGGESTION)');
    m('PROGRAM_UNIT', 'COUNT_SUSP1_OLD', NULL, NULL, NULL, NULL, 'DROPPED', 'not called');
    m('PROGRAM_UNIT', 'ENB_DISP_FLDS', 'DA', 'SELECT1 WHEN-RADIO-CHANGED + item conditions', 2170, 'IMPR2170.P_PORT_CD_IS_VISIBLE', 'MAPPED', NULL);
    m('PROGRAM_UNIT', 'CHECK_LIST_VAL', 'LOV', 'LOV_IMPR2170_LOV_IMPR_NBR / LOV_IMPORT_HQ_NBR', 2170, NULL, 'MAPPED', 'LOV form LOV_IMPR_NBR -> Popup LOVs');
    m('PROGRAM_UNIT', 'GET_HQ_IMPR_NAME', 'PACKAGE', 'IMPR2170.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM', 2170, 'IMPR2170.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', 'name to HQ_IMPR_NAME (SUGGESTION)');
    m('PROGRAM_UNIT', 'LOAD_ZATCA_LOGOS', 'REGION', 'TITLE (hero)', 2170, NULL, 'MAPPED', 'OLB');
    m('REPORT', 'IMPR2170.rdf', 'PACKAGE', 'IMPR2170_ARD.ARD_IMPR2170', 2170, 'IMPR2170.PRINT_IMPR2170_ARD', 'MAPPED', 'ardpdf link');
    m('REPORT', 'IMPR2170n.rep', NULL, NULL, NULL, NULL, 'TODO', 'TODO: MISSING SOURCE (SHOW_USER = 1)');
    m('ALERT', 'CFG_* / USR_* / CG$ASK_COMMIT', NULL, NULL, NULL, NULL, 'DROPPED', 'not used by this form');
END;
/

COMMIT;
