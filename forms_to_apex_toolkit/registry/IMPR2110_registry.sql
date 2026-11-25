-- =============================================================================
-- IMPR2110 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (trace: analysis/IMPR2110/IMPR2110_apex_page_spec.md section 11)
-- Form    : IMPR2110.fmb (report parameter form of IMPR2110.rdf)
-- Author  : Claude Code
-- Date    : 2026-11-25
-- Version : 1.0 (package IMPR2110 version 001)
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR2110';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR2110';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR2110', 'IMPR', 'IMPR', 202530, 2110, 2110, 'IMPR2110',
     'IMPR2110', 'SIMPLE', 'DESIGN', NULL, NULL,
     'طباعة بيانات المستوردين - report page 2110 + ARD report package IMPR2110_ARD (standard 13-b / 13-c); packages IMPR2110 002, IMPR2110_ARD 001 not compiled');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR2110', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN
    m('BLOCK', 'CALLING_PARAMETERS', 'REGION', 'CALLING_PARAMETERS (static, report parameters)', 2110, NULL, 'MAPPED', 'control block');
    m('BLOCK', 'CTR_BLK', 'REGION', 'CTR_BLK (read-only IG, LICE_NO split)', 2110, NULL, 'MAPPED', 'control block, 5 records');
    m('BLOCK', 'TITLE', 'REGION', 'TITLE (hero)', 2110, 'IMPR2110.WHEN_NEW_FORM_INSTANCE', 'MAPPED', 'OLB title: module name, report no, port');
    m('BLOCK', 'TOOLBAR', 'REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, NULL, 'MAPPED', 'VIEW/PRINT -> REPORT_SHOW/REPORT_PRINT');
    m('BLOCK', 'ZATCA_LOGOS', 'REGION', 'TITLE (hero) / theme', 2110, NULL, 'MAPPED', 'OLB logos');
    m('ITEM', 'CALLING_PARAMETERS.P_PORT_CD', 'ITEM', 'P2110_P_PORT_CD', 2110, 'IMPR2110.P_PORT_CD_VALIDATION', 'MAPPED', 'Popup LOV LOV_SD_PORTS; port 99 only');
    m('ITEM', 'CALLING_PARAMETERS.P_PORT_NAME', 'ITEM', 'P2110_P_PORT_NAME', 2110, 'IMPR2110.P_PORT_CD_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.LICE_NO', 'ITEM', 'P2110_LICE_NO', 2110, 'IMPR2110.LICE_NO_VALIDATION', 'MAPPED', 'comma list');
    m('ITEM', 'CALLING_PARAMETERS.SECT_LOV', 'ITEM', 'P2110_SECT_LOV', 2110, 'IMPR2110.SECT_LOV_WHEN_BUTTON_PRESSED', 'MAPPED', 'button -> Popup LOV LOV_REP_IMPR');
    m('ITEM', 'CALLING_PARAMETERS.P_LOV_PORT', 'ITEM', 'P2110_P_PORT_CD (Popup LOV button)', 2110, NULL, 'MAPPED', NULL);
    m('ITEM', 'CTR_BLK.P_AGR_NBR', 'COLUMN', 'CTR_BLK.P_AGR_NBR', 2110, NULL, 'MAPPED', NULL);
    m('ITEM', 'CTR_BLK.P_AGR_DESC', 'COLUMN', 'CTR_BLK.P_AGR_DESC', 2110, NULL, 'MAPPED', NULL);
    m('ITEM', 'TITLE.SCREEN_NAME', 'ITEM', 'P2110_HERO_TITLE', 2110, NULL, 'MAPPED', 'FORMS_APX.HEADER_TITLE');
    m('ITEM', 'TITLE.REPORT_NO', 'ITEM', 'P2110_REPORT_NO', 2110, 'IMPR2110.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.P_CURR_PORT_NAME', 'ITEM', 'P2110_P_CURR_PORT_NAME', 2110, 'IMPR2110.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.USER_NAME', NULL, NULL, NULL, NULL, 'DROPPED', 'f345 shell shows the user');
    m('ITEM', 'TITLE.SYSTEM_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('ITEM', 'TITLE.SYSTEM_G_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('TRIGGER', 'P_PORT_CD.WHEN-VALIDATE-ITEM', 'DA', 'P_PORT_CD WHEN-VALIDATE-ITEM', 2110, 'IMPR2110.P_PORT_CD_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('TRIGGER', 'P_PORT_CD.KEY-LISTVAL', 'ITEM', 'P2110_P_PORT_CD (Popup LOV)', 2110, NULL, 'MAPPED', 'CALL_FORM REP_LOV_SD_PORTS');
    m('TRIGGER', 'P_LOV_PORT.WHEN-BUTTON-PRESSED', 'ITEM', 'P2110_P_PORT_CD (Popup LOV)', 2110, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'LICE_NO.KEY-LISTVAL', 'DA', 'SECT_LOV WHEN-BUTTON-PRESSED', 2110, 'IMPR2110.SECT_LOV_WHEN_BUTTON_PRESSED', 'MAPPED', 'CALL_FORM REP_LOV_IMPR');
    m('TRIGGER', 'LICE_NO.WHEN-VALIDATE-ITEM', 'DA', 'LICE_NO WHEN-VALIDATE-ITEM', 2110, 'IMPR2110.LICE_NO_VALIDATION', 'MAPPED', 'name -> CTR_BLK column');
    m('TRIGGER', 'SECT_LOV.WHEN-BUTTON-PRESSED', 'DA', 'SECT_LOV WHEN-BUTTON-PRESSED', 2110, 'IMPR2110.SECT_LOV_WHEN_BUTTON_PRESSED', 'MAPPED', NULL);
    m('TRIGGER', 'CTR_BLK.WHEN-NEW-BLOCK-INSTANCE', 'REGION', 'CTR_BLK (grid SQL)', 2110, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TITLE.SYSTEM_G_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TOOLBAR.VIEW.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2110, 'IMPR2110.PRINT_CHECK_VAL', 'MAPPED', 'same PDF as PRINT; REPORT_SHOW Never (DEC-018)');
    m('TRIGGER', 'TOOLBAR.PRINT.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2110, 'IMPR2110.PRINT_CHECK_VAL', 'MAPPED', NULL);
    m('TRIGGER', 'TOOLBAR.CLEAR.WHEN-BUTTON-PRESSED', 'BUTTON', 'CLEAR (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'TOOLBAR.LOV.WHEN-BUTTON-PRESSED', 'ITEM', 'Popup LOV buttons', 2110, NULL, 'MAPPED', 'DO_KEY(LIST_VALUES)');
    m('TRIGGER', 'TOOLBAR.EXIT.WHEN-BUTTON-PRESSED', 'BUTTON', 'BACK (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'WHEN-NEW-FORM-INSTANCE', 'PROCESS', 'WHEN-NEW-FORM-INSTANCE', 2110, 'IMPR2110.WHEN_NEW_FORM_INSTANCE', 'MAPPED', '+ item condition P_PORT_CD_IS_VISIBLE');
    m('TRIGGER', 'PRE-FORM', NULL, NULL, NULL, NULL, 'DROPPED', 'window title / icon / date format');
    m('TRIGGER', 'WHEN-WINDOW-ACTIVATED', NULL, NULL, NULL, NULL, 'DROPPED', 'window state');
    m('TRIGGER', 'KEY-F5', 'DA', 'REPORT_PRINT', 2110, 'IMPR2110.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut (CLAUDE.md 5)');
    m('TRIGGER', 'KEY-PRINT', 'DA', 'REPORT_PRINT', 2110, 'IMPR2110.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut');
    m('TRIGGER', 'KEY-F4', 'DA', 'REPORT_PRINT', 2110, 'IMPR2110.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut');
    m('PROGRAM_UNIT', 'CHECK_VAL', 'PACKAGE', 'IMPR2110.PRINT_CHECK_VAL', 2110, 'IMPR2110.PRINT_CHECK_VAL', 'MAPPED', 'same code as PRINT_CHECK_VAL');
    m('PROGRAM_UNIT', 'PRINT_CHECK_VAL', 'PACKAGE', 'IMPR2110.PRINT_CHECK_VAL', 2110, 'IMPR2110.PRINT_CHECK_VAL', 'MAPPED', NULL);
    m('PROGRAM_UNIT', 'P_ORDER', NULL, NULL, NULL, NULL, 'DROPPED', 'body commented out');
    m('PROGRAM_UNIT', 'CGDV$POPULATE_DYNAMIC_LISTS', NULL, NULL, NULL, NULL, 'DROPPED', 'item P_LICE_TYPE does not exist; call commented out');
    m('PROGRAM_UNIT', 'LOAD_ZATCA_LOGOS', 'REGION', 'TITLE (hero)', 2110, NULL, 'MAPPED', 'OLB');
    m('REPORT', 'IMPR2110.rdf', 'PACKAGE', 'IMPR2110_ARD.ARD_IMPR2110', 2110, 'IMPR2110.PRINT_IMPR2110_ARD', 'MAPPED', 'ARD report; filter = importer list of the page (user decision 2026-11-25, spec 12.1)');
    m('REPORT', 'IMPR2110.rdf formulas V_NAME, CF_impr_id_type, v_name2, C_CODE, V_PORT_NAME_SEC1', 'PACKAGE', 'IMPR2110_ARD.<name>Formula', NULL, 'IMPR2110_ARD', 'MAPPED', 'same code');
    m('CALLED_FORM', 'REP_LOV_SD_PORTS', 'LOV', 'LOV_SD_PORTS (IMPR1110)', 2110, NULL, 'MAPPED', NULL);
    m('CALLED_FORM', 'REP_LOV_IMPR', 'LOV', 'LOV_REP_IMPR (LOV_APX.IMPORTERS)', 2110, NULL, 'MAPPED', NULL);
    m('EXTERNAL', 'ARD_LOGO.IMG', 'PACKAGE', 'IMPR2110_ARD.ARD_IMPR2110', NULL, 'IMPR2110_ARD.ARD_IMPR2110', 'TODO', 'source not in this repository (Forms_to_APEX 04_Database/Packages/Shared/ARD_LOGO.sql)');
END;
/

COMMIT;
