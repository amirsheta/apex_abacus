-- =============================================================================
-- IMPR2180 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (trace: analysis/IMPR2180/IMPR2180_apex_page_spec.md section 11)
-- Form    : IMPR2180.fmb (report parameter form of IMPR2180.rdf "تقرير ازدواجية مهنتي الإستيراد والتخليص الجمركي")
-- Author  : Claude Code
-- Date    : 2026-11-25
-- Version : 1.0 (package IMPR2180 version 001). Built from registry/IMPR2170_registry.sql.
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR2180';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR2180';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR2180', 'IMPR', 'IMPR', 202530, 2180, 2180, 'IMPR2180',
     'IMPR2180', 'LOW', 'DESIGN', NULL, NULL,
     'تقرير ازدواجية مهنتي الإستيراد والتخليص الجمركي - report page 2180 + ARD package IMPR2180_ARD (standard 13-b / 13-c); '
     || 'packages 001 not compiled; LOV_APX 006');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR2180', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN
    m('BLOCK', 'CONTROL', 'REGION', 'CONTROL (static, report parameters)', 2180, NULL, 'MAPPED', 'control block');
    m('BLOCK', 'TITLE', 'REGION', 'TITLE (hero)', 2180, 'IMPR2180.WHEN_NEW_FORM_INSTANCE', 'MAPPED', 'OLB title: module name, report no, port');
    m('BLOCK', 'TOOLBAR', 'REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, NULL, 'MAPPED', 'PRINT/VIEW -> REPORT_PRINT');
    m('BLOCK', 'ZATCA_LOGOS', 'REGION', 'TITLE (hero) / theme', 2180, NULL, 'MAPPED', 'OLB logos');
    m('ITEM', 'CONTROL.P_PORT_CD', 'ITEM', 'P2180_P_PORT_CD', 2180, 'IMPR2180.P_PORT_CD_VALIDATION', 'MAPPED', 'Popup LOV LOV_SD_PORTS, head office only');
    m('ITEM', 'CONTROL.P_LOV_PORT', 'ITEM', 'P2180_P_PORT_CD (Popup LOV button)', 2180, NULL, 'MAPPED', NULL);
    m('ITEM', 'CONTROL.P_PORT_NAME', 'ITEM', 'P2180_P_PORT_NAME', 2180, 'IMPR2180.P_PORT_CD_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('ITEM', 'CONTROL.P_LIC_TYPE', 'ITEM', 'P2180_P_LIC_TYPE', 2180, 'IMPR2180.P_LIC_TYPE_VALIDATION', 'MAPPED', 'Select List LOV_LIC_TYPE');
    m('ITEM', 'TITLE.SCREEN_NAME', 'ITEM', 'P2180_HERO_TITLE', 2180, NULL, 'MAPPED', 'FORMS_APX.HEADER_TITLE');
    m('ITEM', 'TITLE.REPORT_NO', 'ITEM', 'P2180_REPORT_NO', 2180, 'IMPR2180.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.P_CURR_PORT_NAME', 'ITEM', 'P2180_P_CURR_PORT_NAME', 2180, 'IMPR2180.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.USER_NAME', NULL, NULL, NULL, NULL, 'DROPPED', 'f345 shell shows the user');
    m('ITEM', 'TITLE.SYSTEM_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('ITEM', 'TITLE.SYSTEM_G_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('TRIGGER', 'P_PORT_CD.KEY-LISTVAL', 'ITEM', 'P2180_P_PORT_CD (Popup LOV)', 2180, NULL, 'MAPPED', 'REP_LOV_SD_PORTS');
    m('TRIGGER', 'P_PORT_CD.WHEN-VALIDATE-ITEM', 'DA', 'P_PORT_CD WHEN-VALIDATE-ITEM', 2180, 'IMPR2180.P_PORT_CD_WHEN_VALIDATE_ITEM', 'MAPPED', 'Clear + FOS; message 1-120');
    m('TRIGGER', 'P_LOV_PORT.WHEN-BUTTON-PRESSED', 'ITEM', 'P2180_P_PORT_CD (Popup LOV)', 2180, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TITLE.SYSTEM_G_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TOOLBAR.PRINT.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2180, 'IMPR2180.PRINT_CHECK_VAL', 'MAPPED', 'طباعة');
    m('TRIGGER', 'TOOLBAR.VIEW.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2180, 'IMPR2180.PRINT_CHECK_VAL', 'MAPPED', 'عرض = same PDF; REPORT_SHOW Never (DEC-018)');
    m('TRIGGER', 'TOOLBAR.CLEAR.WHEN-BUTTON-PRESSED', 'BUTTON', 'CLEAR (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'TOOLBAR.LOV.WHEN-BUTTON-PRESSED', 'ITEM', 'Popup LOV button', 2180, NULL, 'MAPPED', 'DO_KEY(LIST_VALUES)');
    m('TRIGGER', 'TOOLBAR.EXIT.WHEN-BUTTON-PRESSED', 'BUTTON', 'BACK (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'WHEN-NEW-FORM-INSTANCE', 'PROCESS', 'WHEN-NEW-FORM-INSTANCE', 2180, 'IMPR2180.WHEN_NEW_FORM_INSTANCE', 'MAPPED', 'VISIBLE -> P_PORT_CD_IS_VISIBLE');
    m('TRIGGER', 'PRE-FORM', NULL, NULL, NULL, NULL, 'DROPPED', 'window title / icon / date format');
    m('TRIGGER', 'WHEN-WINDOW-ACTIVATED', NULL, NULL, NULL, NULL, 'DROPPED', 'window state');
    m('TRIGGER', 'KEY-PRINT', 'DA', 'REPORT_PRINT', 2180, 'IMPR2180.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut (CLAUDE.md 5)');
    m('TRIGGER', 'KEY-F4', 'DA', 'REPORT_PRINT', 2180, 'IMPR2180.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut');
    m('TRIGGER', 'KEY-F5', 'DA', 'REPORT_PRINT', 2180, 'IMPR2180.PRINT_CHECK_VAL', 'MAPPED', 'CHECK_VALUE; no keyboard shortcut');
    m('PROGRAM_UNIT', 'PRINT_CHECK_VAL', 'PACKAGE', 'IMPR2180.PRINT_CHECK_VAL', 2180, 'IMPR2180.PRINT_CHECK_VAL', 'MAPPED', 'no count check (V_COUNT := 1)');
    m('PROGRAM_UNIT', 'CHECK_VALUE', 'PACKAGE', 'IMPR2180.PRINT_CHECK_VAL', 2180, 'IMPR2180.PRINT_CHECK_VAL', 'MAPPED', 'VIEW = PRINT (DEC-018); same code');
    m('PROGRAM_UNIT', 'LOAD_LIST', 'LOV', 'LOV_LIC_TYPE', 2180, NULL, 'MAPPED', 'LOV_APX.REFERENCE_CODES(LIC_TYPE, excluded 3)');
    m('PROGRAM_UNIT', 'PORTS', NULL, NULL, NULL, NULL, 'DROPPED', 'not called; list item PORT does not exist');
    m('PROGRAM_UNIT', 'LOAD_ZATCA_LOGOS', 'REGION', 'TITLE (hero)', 2180, NULL, 'MAPPED', 'OLB');
    m('RECORD_GROUP', 'GROUP_TYPE', 'LOV', 'LOV_LIC_TYPE', 2180, NULL, 'MAPPED', 'run-time record group of LOAD_LIST');
    m('REPORT', 'IMPR2180.rdf', 'PACKAGE', 'IMPR2180_ARD.ARD_IMPR2180', 2180, 'IMPR2180.PRINT_IMPR2180_ARD', 'MAPPED', 'ardpdf link');
    m('ALERT', 'CFG_* / USR_* / CG$ASK_COMMIT', NULL, NULL, NULL, NULL, 'DROPPED', 'not used by this form');
END;
/

COMMIT;
