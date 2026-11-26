-- =============================================================================
-- IMPR2420 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (trace: analysis/IMPR2420/IMPR2420_apex_page_spec.md section 11)
-- Form    : IMPR2420.fmb (report parameter form of IMPR2420.rdf "تقرير أخطاء المستوردين")
-- Author  : Claude Code
-- Date    : 2026-11-26
-- Version : 1.0 (package IMPR2420 version 001). Built from registry/IMPR2180_registry.sql.
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR2420';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR2420';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR2420', 'IMPR', 'IMPR', 202530, 2420, 2420, 'IMPR2420',
     'IMPR2420', 'LOW', 'DESIGN', NULL, NULL,
     'تقرير أخطاء المستوردين - report page 2420 + ARD package IMPR2420_ARD (standard 13-b / 13-c); '
     || 'package 001 not compiled');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR2420', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN
    m('BLOCK', 'CALLING_PARAMETERS', 'REGION', 'CALLING_PARAMETERS (static, report parameters)', 2420, NULL, 'MAPPED', 'control block');
    m('BLOCK', 'TITLE', 'REGION', 'TITLE (hero)', 2420, 'IMPR2420.WHEN_NEW_FORM_INSTANCE', 'MAPPED', 'OLB title: module name, report no, port');
    m('BLOCK', 'TOOLBAR', 'REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, NULL, 'MAPPED', 'PRINT/VIEW -> REPORT_PRINT');
    m('BLOCK', 'ZATCA_LOGOS', 'REGION', 'TITLE (hero) / theme', 2420, NULL, 'MAPPED', 'OLB logos');
    m('ITEM', 'CALLING_PARAMETERS.P_TYPE', 'ITEM', 'P2420_P_TYPE', 2420, 'IMPR2420.PRINT_CHECK_VAL', 'MAPPED', 'static Select List, default 3');
    m('ITEM', 'TITLE.SCREEN_NAME', 'ITEM', 'P2420_HERO_TITLE', 2420, NULL, 'MAPPED', 'FORMS_APX.HEADER_TITLE');
    m('ITEM', 'TITLE.REPORT_NO', 'ITEM', 'P2420_REPORT_NO', 2420, 'IMPR2420.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.P_CURR_PORT_NAME', 'ITEM', 'P2420_P_CURR_PORT_NAME', 2420, 'IMPR2420.WHEN_NEW_FORM_INSTANCE', 'MAPPED', 'Forms SELECT commented out; hero only (SUGGESTION)');
    m('ITEM', 'TITLE.USER_NAME', NULL, NULL, NULL, NULL, 'DROPPED', 'f345 shell shows the user');
    m('ITEM', 'TITLE.SYSTEM_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('ITEM', 'TITLE.SYSTEM_G_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('TRIGGER', 'TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TITLE.SYSTEM_G_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TOOLBAR.PRINT.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2420, 'IMPR2420.PRINT_CHECK_VAL', 'MAPPED', 'طباعة');
    m('TRIGGER', 'TOOLBAR.VIEW.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2420, 'IMPR2420.PRINT_CHECK_VAL', 'MAPPED', 'عرض = same PDF; REPORT_SHOW Never (DEC-018)');
    m('TRIGGER', 'TOOLBAR.CLEAR.WHEN-BUTTON-PRESSED', 'BUTTON', 'CLEAR (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'TOOLBAR.LOV.WHEN-BUTTON-PRESSED', NULL, NULL, NULL, NULL, 'DROPPED', 'DO_KEY(LIST_VALUES); the form has no LOV');
    m('TRIGGER', 'TOOLBAR.EXIT.WHEN-BUTTON-PRESSED', 'BUTTON', 'BACK (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'WHEN-NEW-FORM-INSTANCE', 'PROCESS', 'WHEN-NEW-FORM-INSTANCE', 2420, 'IMPR2420.WHEN_NEW_FORM_INSTANCE', 'MAPPED', 'REPORT_NO; GLOBAL.CHPT_* not needed');
    m('TRIGGER', 'PRE-FORM', NULL, NULL, NULL, NULL, 'DROPPED', 'window title / icon / date format');
    m('TRIGGER', 'WHEN-WINDOW-ACTIVATED', NULL, NULL, NULL, NULL, 'DROPPED', 'window state');
    m('TRIGGER', 'KEY-PRINT', 'DA', 'REPORT_PRINT', 2420, 'IMPR2420.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut (CLAUDE.md 5)');
    m('TRIGGER', 'KEY-F4', 'DA', 'REPORT_PRINT', 2420, 'IMPR2420.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut');
    m('TRIGGER', 'KEY-F5', 'DA', 'REPORT_PRINT', 2420, 'IMPR2420.PRINT_CHECK_VAL', 'MAPPED', 'CHECK_VAL; no keyboard shortcut');
    m('PROGRAM_UNIT', 'PRINT_CHECK_VAL', 'PACKAGE', 'IMPR2420.PRINT_CHECK_VAL', 2420, 'IMPR2420.PRINT_CHECK_VAL', 'MAPPED', 'no count check (V_COUNT := 1)');
    m('PROGRAM_UNIT', 'CHECK_VAL', 'PACKAGE', 'IMPR2420.PRINT_CHECK_VAL', 2420, 'IMPR2420.PRINT_CHECK_VAL', 'MAPPED', 'VIEW = PRINT (DEC-018); P_TYPE := 3 rule kept');
    m('PROGRAM_UNIT', 'P_ORDER', NULL, NULL, NULL, NULL, 'DROPPED', 'body commented out (NULL); V_ORDER never set');
    m('PROGRAM_UNIT', 'CGDV$POPULATE_DYNAMIC_LISTS', NULL, NULL, NULL, NULL, 'DROPPED', 'body commented out (NULL), not called');
    m('PROGRAM_UNIT', 'LOAD_ZATCA_LOGOS', 'REGION', 'TITLE (hero)', 2420, NULL, 'MAPPED', 'OLB');
    m('REPORT', 'IMPR2420.rdf', 'PACKAGE', 'IMPR2420_ARD.ARD_IMPR2420', 2420, 'IMPR2420.PRINT_IMPR2420_ARD', 'MAPPED', 'ardpdf link');
    m('ALERT', 'CFG_* / USR_* / CG$ASK_COMMIT', NULL, NULL, NULL, NULL, 'DROPPED', 'not used by this form');
END;
/

COMMIT;
