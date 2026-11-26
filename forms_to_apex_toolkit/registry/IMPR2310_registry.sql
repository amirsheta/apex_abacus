-- =============================================================================
-- IMPR2310 - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (trace: analysis/IMPR2310/IMPR2310_apex_page_spec.md section 11)
-- Form    : IMPR2310.fmb (report parameter form of IMPR2310.rdf "بيانات المستوردين المعدلة / المضافة")
-- Author  : Claude Code
-- Date    : 2026-11-26
-- Version : 1.0 (package IMPR2310 version 001). Built from registry/IMPR2170_registry.sql.
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'IMPR2310';
DELETE FROM mig_form_registry WHERE form_name = 'IMPR2310';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('IMPR2310', 'IMPR', 'IMPR', 202530, 2310, 2310, 'IMPR2310',
     'IMPR2310', 'MEDIUM', 'DESIGN', NULL, NULL,
     'بيانات المستوردين المعدلة / المضافة - report page 2310 + ARD package IMPR2310_ARD (standard 13-b / 13-c); '
     || 'packages 001 not compiled; open items: count without port vs report per port, LTR_NBR / SUPP_SRCE_CD LOV');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('IMPR2310', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN
    m('BLOCK', 'CALLING_PARAMETERS', 'REGION', 'CALLING_PARAMETERS (static, report parameters)', 2310, NULL, 'MAPPED', 'control block');
    m('BLOCK', 'TITLE', 'REGION', 'TITLE (hero)', 2310, 'IMPR2310.WHEN_NEW_FORM_INSTANCE', 'MAPPED', 'OLB title: module name, report no, port');
    m('BLOCK', 'TOOLBAR', 'REGION', 'P0_ACTIONS (page 0 toolbar, f345)', 0, NULL, 'MAPPED', 'ITEM303/ITEM304 -> REPORT_PRINT');
    m('BLOCK', 'ZATCA_LOGOS', 'REGION', 'TITLE (hero) / theme', 2310, NULL, 'MAPPED', 'OLB logos');
    m('ITEM', 'CALLING_PARAMETERS.SELECT1', 'ITEM', 'P2310_SELECT1', 2310, 'IMPR2310.SELECT1_VALIDATION', 'MAPPED', 'radio group 1/2, default 2 (WHEN-NEW-FORM-INSTANCE)');
    m('ITEM', 'CALLING_PARAMETERS.REPORT', 'ITEM', 'P2310_REPORT', 2310, 'IMPR2310.REPORT_VALIDATION', 'MAPPED', 'radio group 0/1, default 0; also the report-page flag');
    m('ITEM', 'CALLING_PARAMETERS.P_PORT_CD', 'ITEM', 'P2310_P_PORT_CD', 2310, 'IMPR2310.P_PORT_CD_VALIDATION', 'MAPPED', 'Popup LOV LOV_SD_PORTS, head office only');
    m('ITEM', 'CALLING_PARAMETERS.P_LOV_PORT', 'ITEM', 'P2310_P_PORT_CD (Popup LOV button)', 2310, NULL, 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.P_PORT_NAME', 'ITEM', 'P2310_P_PORT_NAME', 2310, 'IMPR2310.P_PORT_CD_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.LTR_NBR', 'ITEM', 'P2310_LTR_NBR', 2310, NULL, 'MAPPED', 'text 60');
    m('ITEM', 'CALLING_PARAMETERS.LTR_DATE', 'ITEM', 'P2310_LTR_DATE', 2310, 'FORMS_APX.HIJRI_DATE_ERROR', 'MAPPED', 'Hijri date, hijri-date-default');
    m('ITEM', 'CALLING_PARAMETERS.SUPP_SRCE_CD', 'ITEM', 'P2310_SUPP_SRCE_CD', 2310, NULL, 'MAPPED', 'number (port of the letter)');
    m('ITEM', 'CALLING_PARAMETERS.START_DT', 'ITEM', 'P2310_START_DT', 2310, 'FORMS_APX.HIJRI_DATE_ERROR', 'MAPPED', 'Hijri date, hijri-date-default');
    m('ITEM', 'CALLING_PARAMETERS.END_DT', 'ITEM', 'P2310_END_DT', 2310, 'FORMS_APX.HIJRI_DATE_ERROR', 'MAPPED', 'Hijri date, hijri-date-default');
    m('ITEM', 'CALLING_PARAMETERS.IMPR_NBR', 'ITEM', 'P2310_IMPR_NBR', 2310, 'IMPR2310.IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', 'Popup LOV LOV_IMPR2310_LOV_IMPR');
    m('ITEM', 'CALLING_PARAMETERS.LOV_IMPR', 'ITEM', 'P2310_IMPR_NBR (Popup LOV button)', 2310, NULL, 'MAPPED', NULL);
    m('ITEM', 'CALLING_PARAMETERS.IMPR_NAME', 'ITEM', 'P2310_IMPR_NAME', 2310, 'IMPR2310.IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', NULL);
    m('ITEM', 'TITLE.SCREEN_NAME', 'ITEM', 'P2310_HERO_TITLE', 2310, NULL, 'MAPPED', 'FORMS_APX.HEADER_TITLE');
    m('ITEM', 'TITLE.REPORT_NO', 'ITEM', 'P2310_REPORT_NO', 2310, 'IMPR2310.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.P_CURR_PORT_NAME', 'ITEM', 'P2310_P_CURR_PORT_NAME', 2310, 'IMPR2310.WHEN_NEW_FORM_INSTANCE', 'MAPPED', NULL);
    m('ITEM', 'TITLE.USER_NAME', NULL, NULL, NULL, NULL, 'DROPPED', 'f345 shell shows the user');
    m('ITEM', 'TITLE.SYSTEM_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('ITEM', 'TITLE.SYSTEM_G_DATE', NULL, NULL, NULL, NULL, 'DROPPED', 'display item; WHEN-VALIDATE-ITEM never fires');
    m('TRIGGER', 'SELECT1.WHEN-RADIO-CHANGED', 'DA', 'SELECT1 WHEN-RADIO-CHANGED', 2310, NULL, 'MAPPED', 'Clear / Enable / Disable, also on page load');
    m('TRIGGER', 'P_PORT_CD.KEY-LISTVAL', 'ITEM', 'P2310_P_PORT_CD (Popup LOV)', 2310, NULL, 'MAPPED', 'REP_LOV_SD_PORTS');
    m('TRIGGER', 'P_PORT_CD.WHEN-VALIDATE-ITEM', 'DA', 'P_PORT_CD WHEN-VALIDATE-ITEM', 2310, 'IMPR2310.P_PORT_CD_WHEN_VALIDATE_ITEM', 'MAPPED', 'Clear + FOS');
    m('TRIGGER', 'P_LOV_PORT.WHEN-BUTTON-PRESSED', 'ITEM', 'P2310_P_PORT_CD (Popup LOV)', 2310, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'LTR_NBR.KEY-LISTVAL', NULL, NULL, NULL, NULL, 'DROPPED', 'PU CHECK_LIST_VAL = importer LOV writing IMPR_NBR (spec 12 item 3)');
    m('TRIGGER', 'SUPP_SRCE_CD.KEY-LISTVAL', NULL, NULL, NULL, NULL, 'DROPPED', 'PU CHECK_LIST_VAL = importer LOV writing IMPR_NBR (spec 12 item 3)');
    m('TRIGGER', 'LTR_DATE.WHEN-VALIDATE-ITEM', 'DA', 'LTR_DATE WHEN-VALIDATE-ITEM', 2310, 'FORMS_APX.HIJRI_DATE_ERROR', 'MAPPED', 'OLB date check');
    m('TRIGGER', 'LTR_DATE.KEY-LISTVAL', 'ITEM', 'P2310_LTR_DATE (Hijri picker)', 2310, NULL, 'MAPPED', 'OLB calendar');
    m('TRIGGER', 'START_DT.WHEN-VALIDATE-ITEM', 'DA', 'START_DT WHEN-VALIDATE-ITEM', 2310, 'FORMS_APX.HIJRI_DATE_ERROR', 'MAPPED', 'OLB date check');
    m('TRIGGER', 'START_DT.KEY-LISTVAL', 'ITEM', 'P2310_START_DT (Hijri picker)', 2310, NULL, 'MAPPED', 'OLB calendar');
    m('TRIGGER', 'END_DT.WHEN-VALIDATE-ITEM', 'DA', 'END_DT WHEN-VALIDATE-ITEM', 2310, 'FORMS_APX.HIJRI_DATE_ERROR', 'MAPPED', 'OLB date check');
    m('TRIGGER', 'END_DT.KEY-LISTVAL', 'ITEM', 'P2310_END_DT (Hijri picker)', 2310, NULL, 'MAPPED', 'OLB calendar');
    m('TRIGGER', 'IMPR_NBR.KEY-LISTVAL', 'ITEM', 'P2310_IMPR_NBR (Popup LOV)', 2310, NULL, 'MAPPED', 'PU CHECK_LIST_VAL');
    m('TRIGGER', 'IMPR_NBR.WHEN-VALIDATE-ITEM', 'DA', 'IMPR_NBR WHEN-VALIDATE-ITEM', 2310, 'IMPR2310.IMPR_NBR_WHEN_VALIDATE_ITEM', 'MAPPED', 'Clear + FOS');
    m('TRIGGER', 'LOV_IMPR.WHEN-BUTTON-PRESSED', 'ITEM', 'P2310_IMPR_NBR (Popup LOV)', 2310, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'IMPR_NAME.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'OLB trigger without code');
    m('TRIGGER', 'IMPR_NAME.KEY-LISTVAL', NULL, NULL, NULL, NULL, 'DROPPED', 'OLB trigger without code');
    m('TRIGGER', 'TITLE.SYSTEM_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TITLE.SYSTEM_G_DATE.WHEN-VALIDATE-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'display item');
    m('TRIGGER', 'TOOLBAR.ITEM303.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2310, 'IMPR2310.PRINT_CHECK_VAL', 'MAPPED', 'طباعة');
    m('TRIGGER', 'TOOLBAR.ITEM304.WHEN-BUTTON-PRESSED', 'DA', 'REPORT_PRINT', 2310, 'IMPR2310.PRINT_CHECK_VAL', 'MAPPED', 'عرض = same PDF; REPORT_SHOW Never (DEC-018)');
    m('TRIGGER', 'TOOLBAR.ITEM305.WHEN-BUTTON-PRESSED', 'BUTTON', 'CLEAR (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'TOOLBAR.ITEM306.WHEN-BUTTON-PRESSED', 'ITEM', 'Popup LOV button', 2310, NULL, 'MAPPED', 'DO_KEY(LIST_VALUES)');
    m('TRIGGER', 'TOOLBAR.ITEM307.WHEN-BUTTON-PRESSED', 'BUTTON', 'BACK (page 0)', 0, NULL, 'MAPPED', NULL);
    m('TRIGGER', 'TOOLBAR.ITEM303/304/305/306/307.KEY-NEXT-ITEM', NULL, NULL, NULL, NULL, 'DROPPED', 'button navigation');
    m('TRIGGER', 'WHEN-NEW-FORM-INSTANCE', 'PROCESS', 'WHEN-NEW-FORM-INSTANCE', 2310, 'IMPR2310.WHEN_NEW_FORM_INSTANCE', 'MAPPED', 'SELECT1 := 2 -> default; ENABLED -> DA on load; VISIBLE -> P_PORT_CD_IS_VISIBLE');
    m('TRIGGER', 'PRE-FORM', NULL, NULL, NULL, NULL, 'DROPPED', 'window title / icon / date format (f345 shell)');
    m('TRIGGER', 'WHEN-WINDOW-ACTIVATED', NULL, NULL, NULL, NULL, 'DROPPED', 'window state');
    m('TRIGGER', 'KEY-PRINT', NULL, NULL, NULL, NULL, 'DROPPED', 'NULL in Forms');
    m('TRIGGER', 'KEY-F4', 'DA', 'REPORT_PRINT', 2310, 'IMPR2310.PRINT_CHECK_VAL', 'MAPPED', 'CHECK_VAL; no shortcuts in APEX');
    m('TRIGGER', 'KEY-F5', 'DA', 'REPORT_PRINT', 2310, 'IMPR2310.PRINT_CHECK_VAL', 'MAPPED', 'PRINT_CHECK_VAL; no shortcuts in APEX');
    m('PROGRAM_UNIT', 'CHECK_VAL', 'DA', 'REPORT_PRINT', 2310, 'IMPR2310.PRINT_CHECK_VAL', 'MAPPED', 'same code as PRINT_CHECK_VAL except DESTYPE');
    m('PROGRAM_UNIT', 'PRINT_CHECK_VAL', 'DA', 'REPORT_PRINT', 2310, 'IMPR2310.PRINT_CHECK_VAL', 'MAPPED', 'count kept as in Forms (private journal_count)');
    m('PROGRAM_UNIT', 'CHECK_LIST_VAL', 'LOV', 'LOV_IMPR2310_LOV_IMPR', 2310, NULL, 'MAPPED', 'LOV form LOV_IMPR -> LOV_APX.IMPORTERS');
    m('PROGRAM_UNIT', 'LOAD_ZATCA_LOGOS', 'REGION', 'TITLE (hero)', 2310, NULL, 'MAPPED', 'OLB');
    m('REPORT', 'IMPR2310.rdf', 'PACKAGE', 'IMPR2310_ARD', 2310, 'IMPR2310.PRINT_IMPR2310_ARD', 'MAPPED', 'REP.Run_Product -> ardpdf link');
    m('LOV_FORM', 'REP_LOV_SD_PORTS', 'LOV', 'LOV_SD_PORTS', 2310, NULL, 'MAPPED', 'IMPR1110 shared LOV');
    m('LOV_FORM', 'LOV_IMPR', 'LOV', 'LOV_IMPR2310_LOV_IMPR', 2310, NULL, 'MAPPED', 'importers of NVL(P_PORT_CD, P_CURR_PORT_CD)');
    m('ALERT', 'CFG_* / USR_* / CG$ASK_COMMIT', NULL, NULL, NULL, NULL, 'DROPPED', 'not used by this form''s code');
END;
/

COMMIT;
