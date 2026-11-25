-- =============================================================================
-- IMPR2140 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (trace: analysis/IMPR2140/IMPR2140_apex_page_spec.md section 11)
-- Form    : IMPR2140.fmb (report parameter form of the letters IMPR2141 / IMPR2142 / IMPR2143 "خطاب للمستورد")
-- Author  : Claude Code
-- Date    : 2026-11-25
-- Version : 1.0 (package IMPR2140 version 001). Built from registry/IMPR2130_registry.sql.
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR2140';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR2140';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR2140', 'IMPR', 'IMPR', 202530, 2140, 2140, 'IMPR2140',
     'IMPR2140', 'SIMPLE', 'DESIGN', NULL, NULL,
     'خطاب للمستورد - report page 2140 + ARD letter packages IMPR2141_ARD / IMPR2142_ARD / IMPR2143_ARD (standard 13-b / 13-c); packages 001 not compiled');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR2140', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN
    m('BLOCK', 'CALLING_PARAMETERS', 'REGION', 'CALLING_PARAMETERS (static, report parameters)', 2140, NULL, 'MAPPED', 'control block');
    m('BLOCK', 'TITLE', 'REGION', 'TITLE (hero)', 2140, 'IMPR2140.WHEN_NEW_FORM_INSTANCE', 'MAPPED', 'OLB title: module name, report no, port');
    m('BLOCK', 'TOOLBAR', 'REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, NULL, 'MAPPED', 'VIEW/PRINT -> REPORT_PRINT');
    m('BLOCK', 'ZATCA_LOGOS', 'REGION', 'TITLE (hero) / theme', 2140, NULL, 'MAPPED', 'OLB logos');
    m('ITEM', 'CALLING_PARAMETERS.P_PORT_CD', 'ITEM', 'P2140_P_PORT_CD', 2140, 'IMPR2140.P_PORT_CD_VALIDATION', 'MAPPED', 'Popup LOV LOV_SD_PORTS; port 99 only');
    m('ITEM', 'CALLING_PARAMETERS.P_PORT_NAME', 'ITEM', 'P2140_P_PORT_NAME', 2140, 'IMPR2140.P_PORT_CD_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.P_LOV_PORT', 'ITEM', 'P2140_P_PORT_CD (Popup LOV button)', 2140, NULL, 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.LETTER_DIRCTION', 'ITEM', 'P2140_LETTER_DIRCTION', 2140, 'IMPR2140.LETTER_DIRCTION_VALIDATION', 'MAPPED', 'Select List STATIC2 1/2/3, default 1');
    m('ITEM', 'CALLING_PARAMETERS.IMPR_NO', 'ITEM', 'P2140_IMPR_NO', 2140, 'IMPR2140.IMPR_NO_VALIDATION', 'MAPPED', 'Popup LOV LOV_IMPR2140_REP_IMPR, required');
    m('ITEM', 'CALLING_PARAMETERS.SECT_LOV', 'ITEM', 'P2140_IMPR_NO (Popup LOV button)', 2140, NULL, 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.IMPR_NAME', 'ITEM', 'P2140_IMPR_NAME', 2140, 'IMPR2140.IMPR_NO_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.BUS_ID', NULL, NULL, NULL, NULL, 'DROPPED', 'hidden, not used');
    m('ITEM', 'CALLING_PARAMETERS.FROM_PORT_CD', NULL, NULL, NULL, NULL, 'DROPPED', 'hidden, not used');
    m('ITEM', 'TITLE.SCREEN_NAME', 'ITEM', 'P2140_HERO_TITLE', 2140, NULL, 'MAPPED', 'FORMS_APX.HEADER_TITLE');
    m('ITEM', 'TITLE.REPORT_NO', 'ITEM', 'P2140_REPORT_NO', 2140, 'IMPR2140.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.P_CURR_PORT_NAME', 'ITEM', 'P2140_P_CURR_PORT_NAME', 2140, 'IMPR2140.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.USER_NAME', NULL, NULL, NULL, NULL, 'DROPPED', 'f345 shell shows the user');
    m('ITEM', 'TITLE.SYSTEM_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('ITEM', 'TITLE.SYSTEM_G_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('TRIGGER', 'P_PORT_CD.WHEN-VALIDATE-ITEM', 'DA', 'P_PORT_CD WHEN-VALIDATE-ITEM', 2140, 'IMPR2140.P_PORT_CD_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('TRIGGER', 'P_PORT_CD.KEY-LISTVAL', 'ITEM', 'P2140_P_PORT_CD (Popup LOV)', 2140, NULL, 'MAPPED', 'CALL_FORM REP_LOV_SD_PORTS');
    m('TRIGGER', 'P_LOV_PORT.WHEN-BUTTON-PRESSED', 'ITEM', 'P2140_P_PORT_CD (Popup LOV)', 2140, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'IMPR_NO.KEY-LISTVAL', 'ITEM', 'P2140_IMPR_NO (Popup LOV)', 2140, NULL, 'MAPPED', 'CALL_FORM REP_LOV_IMPR');
    m('TRIGGER', 'IMPR_NO.WHEN-VALIDATE-ITEM', 'DA', 'IMPR_NO WHEN-VALIDATE-ITEM', 2140, 'IMPR2140.IMPR_NO_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('TRIGGER', 'SECT_LOV.WHEN-BUTTON-PRESSED', 'ITEM', 'P2140_IMPR_NO (Popup LOV)', 2140, NULL, 'MAPPED', 'CALL_FORM REP_LOV_IMPR');
    m('TRIGGER', 'TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TITLE.SYSTEM_G_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TOOLBAR.VIEW.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2140, 'IMPR2140.PRINT_CHECK_VAL', 'MAPPED', 'same PDF as PRINT; REPORT_SHOW Never (DEC-018)');
    m('TRIGGER', 'TOOLBAR.PRINT.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2140, 'IMPR2140.PRINT_CHECK_VAL', 'MAPPED', NULL);
    m('TRIGGER', 'TOOLBAR.CLEAR.WHEN-BUTTON-PRESSED', 'BUTTON', 'CLEAR (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'TOOLBAR.LOV.WHEN-BUTTON-PRESSED', 'ITEM', 'Popup LOV buttons', 2140, NULL, 'MAPPED', 'DO_KEY(LIST_VALUES)');
    m('TRIGGER', 'TOOLBAR.EXIT.WHEN-BUTTON-PRESSED', 'BUTTON', 'BACK (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'WHEN-NEW-FORM-INSTANCE', 'PROCESS', 'WHEN-NEW-FORM-INSTANCE', 2140, 'IMPR2140.WHEN_NEW_FORM_INSTANCE', 'MAPPED', '+ item condition P_PORT_CD_IS_VISIBLE');
    m('TRIGGER', 'PRE-FORM', NULL, NULL, NULL, NULL, 'DROPPED', 'window title / icon / date format');
    m('TRIGGER', 'WHEN-WINDOW-ACTIVATED', NULL, NULL, NULL, NULL, 'DROPPED', 'window state');
    m('TRIGGER', 'KEY-CLRBLK', 'BUTTON', 'CLEAR (page 0)', 0, NULL, 'MAPPED', 'clears IMPR_NO, IMPR_NAME, P_PORT_CD, P_PORT_NAME');
    m('TRIGGER', 'KEY-F5', 'DA', 'REPORT_PRINT', 2140, 'IMPR2140.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut (CLAUDE.md 5)');
    m('TRIGGER', 'KEY-PRINT', 'DA', 'REPORT_PRINT', 2140, 'IMPR2140.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut');
    m('TRIGGER', 'KEY-F4', 'DA', 'REPORT_PRINT', 2140, 'IMPR2140.PRINT_CHECK_VAL', 'MAPPED', 'no keyboard shortcut');
    m('PROGRAM_UNIT', 'CHECK_VAL', 'PACKAGE', 'IMPR2140.PRINT_CHECK_VAL', 2140, 'IMPR2140.PRINT_CHECK_VAL', 'MAPPED', 'VIEW = PRINT (DEC-018); letter 2 count of CHECK_VAL not used (user decision 2026-11-25)');
    m('PROGRAM_UNIT', 'PRINT_CHECK_VAL', 'PACKAGE', 'IMPR2140.PRINT_CHECK_VAL', 2140, 'IMPR2140.PRINT_CHECK_VAL', 'MAPPED', 'counts kept as in Forms -> private letter_count');
    m('PROGRAM_UNIT', 'LOAD_ZATCA_LOGOS', 'REGION', 'TITLE (hero)', 2140, NULL, 'MAPPED', 'OLB');
    m('REPORT', 'IMPR2141.rdf', 'PACKAGE', 'IMPR2141_ARD.ARD_IMPR2141', 2140, 'IMPR2140.PRINT_IMPR2141_ARD', 'MAPPED', 'LETTER_DIRCTION 1; params P_CURR_PORT_CD, IMPR_NO');
    m('REPORT', 'IMPR2142.rdf', 'PACKAGE', 'IMPR2142_ARD.ARD_IMPR2142', 2140, 'IMPR2140.PRINT_IMPR2142_ARD', 'MAPPED', 'LETTER_DIRCTION 2; params P_CURR_PORT_CD, IMPR_NO');
    m('REPORT', 'IMPR2143.rdf', 'PACKAGE', 'IMPR2143_ARD.ARD_IMPR2143', 2140, 'IMPR2140.PRINT_IMPR2143_ARD', 'MAPPED', 'LETTER_DIRCTION 3 (else); params P_CURR_PORT_CD, IMPR_NO');
    m('CALLED_FORM', 'REP_LOV_SD_PORTS', 'LOV', 'LOV_SD_PORTS (IMPR1110)', 2140, NULL, 'MAPPED', NULL);
    m('CALLED_FORM', 'REP_LOV_IMPR', 'LOV', 'LOV_IMPR2140_REP_IMPR (LOV_APX.IMPORTERS)', 2140, NULL, 'MAPPED', NULL);
    m('EXTERNAL', 'ARD_LOGO.IMG', 'PACKAGE', 'IMPR2141_ARD / IMPR2142_ARD / IMPR2143_ARD', NULL, NULL, 'TODO', 'source not in this repository (Forms_to_APEX 04_Database/Packages/Shared/ARD_LOGO.sql)');
END;
/

COMMIT;
