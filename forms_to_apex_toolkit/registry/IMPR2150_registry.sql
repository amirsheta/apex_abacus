-- =============================================================================
-- IMPR2150 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (trace: analysis/IMPR2150/IMPR2150_apex_page_spec.md section 11)
-- Form    : IMPR2150.fmb (report parameter form of IMPR2150.rdf "استثناءات المستوردين")
-- Author  : Claude Code
-- Date    : 2026-11-25
-- Version : 1.0 (package IMPR2150 version 001). Built from registry/IMPR2140_registry.sql.
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR2150';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR2150';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR2150', 'IMPR', 'IMPR', 202530, 2150, 2150, 'IMPR2150',
     'IMPR2150', 'SIMPLE', 'DESIGN', NULL, NULL,
     'استثناءات المستوردين - report page 2150 + ARD package IMPR2150_ARD (standard 13-b / 13-c); packages 001 not compiled');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR2150', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN
    m('BLOCK', 'CALLING_PARAMETERS', 'REGION', 'CALLING_PARAMETERS (static, report parameters)', 2150, NULL, 'MAPPED', 'control block');
    m('BLOCK', 'TITLE', 'REGION', 'TITLE (hero)', 2150, 'IMPR2150.WHEN_NEW_FORM_INSTANCE', 'MAPPED', 'OLB title: module name, report no, port');
    m('BLOCK', 'TOOLBAR', 'REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, NULL, 'MAPPED', 'VIEW/PRINT -> REPORT_PRINT');
    m('BLOCK', 'ZATCA_LOGOS', 'REGION', 'TITLE (hero) / theme', 2150, NULL, 'MAPPED', 'OLB logos');
    m('ITEM', 'CALLING_PARAMETERS.HQ_IMPR_NBR', 'ITEM', 'P2150_HQ_IMPR_NBR', 2150, 'IMPR2150.HQ_IMPR_NBR_VALIDATION', 'MAPPED', 'Popup LOV LOV_IMPORT_HQ_NBR, optional');
    m('ITEM', 'CALLING_PARAMETERS.HQ_IMPR_NBR2', 'ITEM', 'P2150_HQ_IMPR_NBR (Popup LOV button)', 2150, NULL, 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.L_SI_ARBC_IMPR_NAME', 'ITEM', 'P2150_L_SI_ARBC_IMPR_NAME', 2150, 'IMPR2150.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.BUS_ID_TYPE_CD', 'ITEM', 'P2150_BUS_ID_TYPE_CD', 2150, 'IMPR2150.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', 'display only (not read by any code)');
    m('ITEM', 'CALLING_PARAMETERS.BUS_ID_TYPE_NAME', 'ITEM', 'P2150_BUS_ID_TYPE_NAME', 2150, 'IMPR2150.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.BUS_ID', 'ITEM', 'P2150_BUS_ID', 2150, 'IMPR2150.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.BUS_ID_BRNCH', 'ITEM', 'P2150_BUS_ID_BRNCH', 2150, 'IMPR2150.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', 'count reads it again from SINGLE_IMPORTERS');
    m('ITEM', 'CALLING_PARAMETERS.REC_STATUS', 'ITEM', 'P2150_REC_STATUS', 2150, 'IMPR2150.REC_STATUS_VALIDATION', 'MAPPED', 'Select List STATIC2 1/0, default 1');
    m('ITEM', 'CALLING_PARAMETERS.RULE_TYPE', 'ITEM', 'P2150_RULE_TYPE', 2150, 'IMPR2150.RULE_TYPE_VALIDATION', 'MAPPED', 'Select List LOV_RULE_TYPE (IMPR1140), default 1');
    m('ITEM', 'CALLING_PARAMETERS.ITEM318', 'ITEM', 'P2150_RULE_TYPE (Select List)', 2150, NULL, 'MAPPED', 'LOV button');
    m('ITEM', 'CALLING_PARAMETERS.RULE_NAME', 'ITEM', 'P2150_RULE_TYPE (shown meaning)', 2150, NULL, 'MAPPED', 'the select list shows RV_MEANING');
    m('ITEM', 'CALLING_PARAMETERS.FROM_PORT_CD', NULL, NULL, NULL, NULL, 'DROPPED', 'hidden, not used');
    m('ITEM', 'TITLE.SCREEN_NAME', 'ITEM', 'P2150_HERO_TITLE', 2150, NULL, 'MAPPED', 'FORMS_APX.HEADER_TITLE');
    m('ITEM', 'TITLE.REPORT_NO', 'ITEM', 'P2150_REPORT_NO', 2150, 'IMPR2150.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.P_CURR_PORT_NAME', 'ITEM', 'P2150_P_CURR_PORT_NAME', 2150, 'IMPR2150.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.USER_NAME', NULL, NULL, NULL, NULL, 'DROPPED', 'f345 shell shows the user');
    m('ITEM', 'TITLE.SYSTEM_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('ITEM', 'TITLE.SYSTEM_G_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('TRIGGER', 'HQ_IMPR_NBR.KEY-LISTVAL', 'ITEM', 'P2150_HQ_IMPR_NBR (Popup LOV)', 2150, NULL, 'MAPPED', 'PU SINGLE_IMP_LOV');
    m('TRIGGER', 'HQ_IMPR_NBR.WHEN-VALIDATE-ITEM', 'DA', 'HQ_IMPR_NBR WHEN-VALIDATE-ITEM', 2150, 'IMPR2150.HQ_IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', 'Clear + FOS');
    m('TRIGGER', 'HQ_IMPR_NBR2.WHEN-BUTTON-PRESSED', 'ITEM', 'P2150_HQ_IMPR_NBR (Popup LOV)', 2150, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'BUS_ID_BRNCH.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'code commented out (NULL;)');
    m('TRIGGER', 'ITEM318.WHEN-BUTTON-PRESSED', 'ITEM', 'P2150_RULE_TYPE (Select List)', 2150, NULL, 'MAPPED', 'LOV319');
    m('TRIGGER', 'TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TITLE.SYSTEM_G_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TOOLBAR.VIEW.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2150, 'IMPR2150.PRINT_CHECK_VAL', 'MAPPED', 'same PDF as PRINT; REPORT_SHOW Never (DEC-018)');
    m('TRIGGER', 'TOOLBAR.PRINT.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2150, 'IMPR2150.PRINT_CHECK_VAL', 'MAPPED', NULL);
    m('TRIGGER', 'TOOLBAR.CLEAR.WHEN-BUTTON-PRESSED', 'BUTTON', 'CLEAR (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'TOOLBAR.LOV.WHEN-BUTTON-PRESSED', 'ITEM', 'Popup LOV button', 2150, NULL, 'MAPPED', 'DO_KEY(LIST_VALUES)');
    m('TRIGGER', 'TOOLBAR.EXIT.WHEN-BUTTON-PRESSED', 'BUTTON', 'BACK (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'WHEN-NEW-FORM-INSTANCE', 'PROCESS', 'WHEN-NEW-FORM-INSTANCE', 2150, 'IMPR2150.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('TRIGGER', 'PRE-FORM', NULL, NULL, NULL, NULL, 'DROPPED', 'window title / icon / date format');
    m('TRIGGER', 'WHEN-WINDOW-ACTIVATED', NULL, NULL, NULL, NULL, 'DROPPED', 'window state');
    m('TRIGGER', 'KEY-CLRBLK', 'BUTTON', 'CLEAR (page 0)', 0, NULL, 'MAPPED', 'NULL in Forms');
    m('TRIGGER', 'KEY-F5', 'DA', 'REPORT_PRINT', 2150, 'IMPR2150.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut (CLAUDE.md 5)');
    m('TRIGGER', 'KEY-PRINT', 'DA', 'REPORT_PRINT', 2150, 'IMPR2150.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut');
    m('TRIGGER', 'KEY-F4', 'DA', 'REPORT_PRINT', 2150, 'IMPR2150.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut');
    m('PROGRAM_UNIT', 'CHECK_VAL', 'PACKAGE', 'IMPR2150.PRINT_CHECK_VAL', 2150, 'IMPR2150.PRINT_CHECK_VAL', 'MAPPED', 'VIEW = PRINT (DEC-018); same code');
    m('PROGRAM_UNIT', 'PRINT_CHECK_VAL', 'PACKAGE', 'IMPR2150.PRINT_CHECK_VAL', 2150, 'IMPR2150.PRINT_CHECK_VAL', 'MAPPED', 'count kept as in Forms -> private rules_count (SUGGESTION: precedence)');
    m('PROGRAM_UNIT', 'SINGLE_IMP_LOV', 'LOV', 'LOV_IMPORT_HQ_NBR', 2150, NULL, 'MAPPED', 'LOV form -> Popup LOV (LOV_APX.SINGLE_IMPORTERS)');
    m('PROGRAM_UNIT', 'LOAD_ZATCA_LOGOS', 'REGION', 'TITLE (hero)', 2150, NULL, 'MAPPED', 'OLB');
    m('LOV', 'LOV319', 'LOV', 'LOV_RULE_TYPE (IMPR1140)', 2150, NULL, 'MAPPED', 'CG_REF_CODES RULE_TYPE');
    m('RECORD_GROUP', 'LOV319', 'LOV', 'LOV_RULE_TYPE (IMPR1140)', 2150, NULL, 'MAPPED', 'LOV_APX.REFERENCE_CODES');
    m('REPORT', 'IMPR2150.rdf', 'PACKAGE', 'IMPR2150_ARD.ARD_IMPR2150', 2150, 'IMPR2150.PRINT_IMPR2150_ARD', 'MAPPED', 'params P_CURR_PORT_CD, P_HQ_IMPR_NBR, P_REC_STATUS, P_RULE_TYPE, P_MODULE_NAME, P_REPORT_NO');
    m('CALLED_FORM', 'LOV_IMPORT_HQ_NBR', 'LOV', 'LOV_IMPORT_HQ_NBR (LOV_APX.SINGLE_IMPORTERS)', 2150, NULL, 'MAPPED', NULL);
    m('EXTERNAL', 'ARD_LOGO.IMG', 'PACKAGE', 'IMPR2150_ARD', NULL, NULL, 'TODO', 'source not in this repository (Forms_to_APEX 04_Database/Packages/Shared/ARD_LOGO.sql)');
END;
/

COMMIT;
