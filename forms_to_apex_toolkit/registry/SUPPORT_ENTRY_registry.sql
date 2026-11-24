-- =============================================================================
-- SUPPORT_ENTRY - migration registry rows (scripts/create_migration_registry.sql)
-- Purpose : MIG_FORM_REGISTRY row for the form + one MIG_OBJECT_MAP row per Forms object
--           (traceability matrix, analysis/SUPPORT_ENTRY/SUPPORT_ENTRY_apex_page_spec.md section 14)
-- Form    : Support_Entry.fmb
-- Author  : Claude Code
-- Date    : 2026-11-24
-- Version : 1.1 (step 04: status BUILD; step 03 revision 1, package SUPPORT_ENTRY version 002)
-- 59 objects: DROPPED 28, MAPPED 29, TODO 2.
-- app_id 202530 = the application installed from f345. Re-runnable: deletes the form's rows first.
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF

DELETE FROM mig_object_map    WHERE form_name = 'SUPPORT_ENTRY';
DELETE FROM mig_form_registry WHERE form_name = 'SUPPORT_ENTRY';

INSERT INTO mig_form_registry
    (form_name, forms_app, subsystem, app_id, page_from, page_to, page_alias,
     package_name, complexity, status, owner, business_owner, notes)
VALUES
    ('SUPPORT_ENTRY', 'SC', 'SC', 202530, 9001, 9001, 'SUPPORT_ENTRY',
     'SUPPORT_ENTRY', 'SIMPLE', 'BUILD', NULL, NULL,
     'بيانات المساندة الفنية - shared modal dialog (callers IMPR1110, IMPR1130); step 04 export apex/SUPPORT_ENTRY/f345_support_entry.sql not imported; package SUPPORT_ENTRY 002 not compiled');

DECLARE
    PROCEDURE m (p_type    VARCHAR2, p_name   VARCHAR2, p_comp  VARCHAR2, p_comp_name VARCHAR2,
                 p_page    NUMBER,   p_member VARCHAR2, p_status VARCHAR2, p_notes   VARCHAR2)
    IS
    BEGIN
        INSERT INTO mig_object_map
            (form_name, forms_object_type, forms_object_name, apex_comp_type,
             apex_comp_name, page_id, plsql_member, status, notes)
        VALUES ('SUPPORT_ENTRY', p_type, p_name, p_comp, p_comp_name, p_page, p_member, p_status, p_notes);
    END m;
BEGIN
    m('FORM', 'SUPPORT_ENTRY', 'PAGE', '9001 SUPPORT_ENTRY (Modal Dialog)', 9001, NULL, 'MAPPED', 'shared dialog, page number user decision 2026-11-24');
    m('WINDOW', 'RP_WINDOW', 'PAGE', '9001 dialog title بيانات المساندة الفنية', 9001, NULL, 'MAPPED', 'dialog style window -> modal dialog page');
    m('CANVAS', 'CANVAS1', 'REGION', 'RP layout', 9001, NULL, 'MAPPED', NULL);
    m('BLOCK', 'RP', 'REGION', 'RP (Static Content) + RP_BUTTONS (Buttons Container)', 9001, NULL, 'MAPPED', 'control block');
    m('ITEM', 'RP.AGREE', 'BUTTON', 'AGREE (موافق) / AGREE_EDIT (تعديل)', 9001, 'SUPPORT_ENTRY.IS_NEW_LETTER', 'MAPPED', 'labels by P_MODE (WNFI SET_ITEM_PROPERTY LABEL)');
    m('ITEM', 'RP.CANCEL', 'BUTTON', 'CANCEL (تراجع) / CANCEL_EDIT (إغلاق)', 9001, 'SUPPORT_ENTRY.IS_NEW_LETTER', 'MAPPED', NULL);
    m('ITEM', 'RP.P_PORT_CD', 'ITEM', 'P9001_P_PORT_CD (Popup LOV LOV_SD_PORTS_TYPES)', 9001, NULL, 'MAPPED', NULL);
    m('ITEM', 'RP.P_LOV_PORT', 'ITEM', 'Popup LOV button of P9001_P_PORT_CD', 9001, NULL, 'DROPPED', 'iconic LOV button');
    m('ITEM', 'RP.P_PORT_NAME', 'ITEM', 'P9001_P_PORT_NAME (Display Only)', 9001, NULL, 'MAPPED', NULL);
    m('ITEM', 'RP.SUPP_TITLE_CD', 'ITEM', 'P9001_SUPP_TITLE_CD (Popup LOV LOV_SUPP_TITLES)', 9001, NULL, 'MAPPED', NULL);
    m('ITEM', 'RP.P_LOV_SUPP_TITLES', 'ITEM', 'Popup LOV button of P9001_SUPP_TITLE_CD', 9001, NULL, 'DROPPED', 'iconic LOV button');
    m('ITEM', 'RP.SUPP_TITLE_NM', 'ITEM', 'P9001_SUPP_TITLE_NM (Display Only)', 9001, NULL, 'MAPPED', NULL);
    m('ITEM', 'RP.LETTER_NBR', 'ITEM', 'P9001_LETTER_NBR (Text Field 50)', 9001, NULL, 'MAPPED', NULL);
    m('ITEM', 'RP.LETTER_DT', 'ITEM', 'P9001_LETTER_DT (Text Field hijri-date-default)', 9001, NULL, 'MAPPED', 'format &P9001_HIJRI_DATE_FORMAT. (Forms MI-MM-RRRR)');
    m('TRIGGER', 'SUPPORT_ENTRY.WHEN-NEW-FORM-INSTANCE', 'PROCESS', 'WHEN-NEW-FORM-INSTANCE (Before Header)', 9001, 'SUPPORT_ENTRY.INIT_FORM', 'MAPPED', 'labels -> button conditions IS_NEW_LETTER');
    m('TRIGGER', 'SUPPORT_ENTRY.PRE-FORM', NULL, NULL, NULL, NULL, 'DROPPED', 'window position');
    m('TRIGGER', 'RP.AGREE.WHEN-BUTTON-PRESSED', 'DYNAMIC_ACTION', 'AGREE WHEN-BUTTON-PRESSED (FOS + Close Dialog)', 9001, 'SUPPORT_ENTRY.AGREE_WHEN_BUTTON_PRESSED', 'MAPPED', 'closes in both modes (D1)');
    m('TRIGGER', 'RP.CANCEL.WHEN-BUTTON-PRESSED', 'DYNAMIC_ACTION', 'CANCEL WHEN-BUTTON-PRESSED (FOS + Close Dialog)', 9001, 'SUPPORT_ENTRY.CANCEL_WHEN_BUTTON_PRESSED', 'MAPPED', NULL);
    m('TRIGGER', 'RP.P_PORT_CD.WHEN-VALIDATE-ITEM', 'DYNAMIC_ACTION', 'P_PORT_CD WHEN-VALIDATE-ITEM', 9001, 'SUPPORT_ENTRY.P_PORT_CD_VALIDATION / P_PORT_CD_WHEN_VALIDATE_ITEM', 'MAPPED', 'no page validation: the page does not submit');
    m('TRIGGER', 'RP.P_LOV_PORT.WHEN-BUTTON-PRESSED', 'ITEM', 'Popup LOV of P9001_P_PORT_CD', 9001, NULL, 'DROPPED', 'GO_ITEM + DO_KEY(LIST_VALUES); commented CALL_FORM REP_LOV_SD_PORTS not converted');
    m('TRIGGER', 'RP.SUPP_TITLE_CD.WHEN-VALIDATE-ITEM', 'DYNAMIC_ACTION', 'SUPP_TITLE_CD WHEN-VALIDATE-ITEM', 9001, 'SUPPORT_ENTRY.SUPP_TITLE_CD_VALIDATION / SUPP_TITLE_CD_VALIDATE_ITEM', 'MAPPED', NULL);
    m('TRIGGER', 'RP.P_LOV_SUPP_TITLES.WHEN-BUTTON-PRESSED', 'ITEM', 'Popup LOV of P9001_SUPP_TITLE_CD', 9001, NULL, 'DROPPED', 'commented CALL_FORM LOV_SUPP_TITLES not converted');
    m('TRIGGER', 'RP.LETTER_DT.KEY-LISTVAL', NULL, NULL, NULL, NULL, 'DROPPED', 'empty trigger');
    m('TRIGGER', 'RP.LETTER_DT.KEY-F4', NULL, NULL, NULL, NULL, 'DROPPED', 'empty trigger');
    m('TRIGGER', 'RP.LETTER_DT.WHEN-VALIDATE-ITEM', 'DYNAMIC_ACTION', 'LETTER_DT WHEN-VALIDATE-ITEM', 9001, 'SUPPORT_ENTRY.LETTER_DT_VALIDATION', 'MAPPED', 'empty trigger; the format mask check');
    m('LOV', 'LOV_SD_PORTS', 'LOV', 'LOV_SD_PORTS_TYPES', 9001, NULL, 'MAPPED', 'new LOV (D2); IMPR1110 LOV_SD_PORTS unchanged');
    m('LOV', 'LOV_SUPP_TITLES', 'LOV', 'LOV_SUPP_TITLES', 9001, NULL, 'MAPPED', 'new LOV');
    m('RECORD_GROUP', 'LOV_SD_PORTS', 'LOV', 'query of LOV_SD_PORTS_TYPES', 9001, NULL, 'MAPPED', NULL);
    m('RECORD_GROUP', 'LOV_SUPP_TITLES', 'LOV', 'query of LOV_SUPP_TITLES', 9001, NULL, 'MAPPED', NULL);
    m('PARAMETER', 'P_MODE', 'ITEM', 'P9001_P_MODE (Hidden, URL checksum)', 9001, 'SUPPORT_ENTRY.OPEN_DIALOG', 'MAPPED', '0 new, 1 edit (D1)');
    m('PARAMETER', 'P_CURR_PORT_CD', 'ITEM', 'P9001_P_CURR_PORT_CD (Hidden, URL checksum)', 9001, 'SUPPORT_ENTRY.OPEN_DIALOG', 'MAPPED', 'not the f345 application item');
    m('PARAMETER', 'WINDOW_X_POS', NULL, NULL, NULL, NULL, 'DROPPED', 'window position');
    m('PARAMETER', 'WINDOW_Y_POS', NULL, NULL, NULL, NULL, 'DROPPED', 'window position');
    m('GLOBAL', 'PORT_CD', 'APP_ITEM', 'G_PORT_CD', NULL, 'SUPPORT_ENTRY.AGREE_WHEN_BUTTON_PRESSED', 'MAPPED', 'exists (IMPR1110 export)');
    m('GLOBAL', 'SUPP_TITLE_CD', 'APP_ITEM', 'G_SUPP_TITLE_CD', NULL, 'SUPPORT_ENTRY.AGREE_WHEN_BUTTON_PRESSED', 'MAPPED', 'exists');
    m('GLOBAL', 'LETTER_NBR', 'APP_ITEM', 'G_LETTER_NBR', NULL, 'SUPPORT_ENTRY.AGREE_WHEN_BUTTON_PRESSED', 'MAPPED', 'callers test it after Dialog Closed');
    m('GLOBAL', 'LETTER_DT', 'APP_ITEM', 'G_LETTER_DT', NULL, 'SUPPORT_ENTRY.AGREE_WHEN_BUTTON_PRESSED', 'MAPPED', 'HIJRI_DATE_FORMAT text; callers convert for DB_JOURNAL (DATE)');
    m('GLOBAL', 'PORT_NAME', NULL, NULL, NULL, NULL, 'DROPPED', 'no reader (inventory Q5)');
    m('GLOBAL', 'SUPP_TITLE_NAME', NULL, NULL, NULL, NULL, 'DROPPED', 'no reader (inventory Q5)');
    m('ALERT', 'CG$ASK_COMMIT', NULL, NULL, NULL, NULL, 'DROPPED', 'not used');
    m('ALERT', 'CFG_ASK_COMMIT', NULL, NULL, NULL, NULL, 'DROPPED', 'not used');
    m('ALERT', 'CFG_SYSTEM_ERROR', NULL, NULL, NULL, NULL, 'DROPPED', 'not used');
    m('ALERT', 'CFG_ERROR', NULL, NULL, NULL, NULL, 'DROPPED', 'not used');
    m('ALERT', 'CFG_INFORMATION', NULL, NULL, NULL, NULL, 'DROPPED', 'not used');
    m('ALERT', 'CFG_WARNING_A', NULL, NULL, NULL, NULL, 'DROPPED', 'not used');
    m('ALERT', 'USR_WARNING_B', NULL, NULL, NULL, NULL, 'DROPPED', 'not used');
    m('ALERT', 'USR_WARNING_C', NULL, NULL, NULL, NULL, 'DROPPED', 'not used');
    m('ALERT', 'USR_CONFIRM', NULL, NULL, NULL, NULL, 'DROPPED', 'not used');
    m('ALERT', 'USR_CONFIRM_B', NULL, NULL, NULL, NULL, 'DROPPED', 'not used');
    m('LIBRARY', 'OFGTEL', NULL, NULL, NULL, NULL, 'DROPPED', 'attached, not called (MISSING SOURCE)');
    m('LIBRARY', 'OFGMES', NULL, NULL, NULL, NULL, 'DROPPED', 'attached, not called');
    m('LIBRARY', 'OFGHPL', NULL, NULL, NULL, NULL, 'DROPPED', 'attached, not called');
    m('LIBRARY', 'CIC_LIB', NULL, NULL, NULL, NULL, 'DROPPED', 'attached, not called');
    m('LIBRARY', 'D2KWUTIL', NULL, NULL, NULL, NULL, 'DROPPED', 'attached, not called');
    m('LIBRARY', 'CAPTION', NULL, NULL, NULL, NULL, 'DROPPED', 'attached, not called');
    m('CALLER', 'IMPR1110.EXEC_FUNS CALL_FORM(SUPPORT_ENTRY)', 'DYNAMIC_ACTION', 'IMPR1110F1/F2/F3/F5 EXECUTE-FUNCTION + FOS OPEN_DIALOG', 1110, 'SUPPORT_ENTRY.OPEN_DIALOG', 'TODO', 'IMPR1110 session: page spec 10.1');
    m('CALLER', 'IMPR1130.WHEN-NEW-FORM-INSTANCE CALL_FORM / OPEN_FORM(SUPPORT_ENTRY)', 'DYNAMIC_ACTION', 'FOS OPEN_DIALOG P_MODE 0, edit on demand P_MODE 1', 1130, 'SUPPORT_ENTRY.OPEN_DIALOG', 'TODO', 'IMPR1130 not converted yet');
    m('CALLER', 'CIC_OLB toolbar CLOSE_FORM(SUPPORT_ENTRY)', NULL, NULL, NULL, NULL, 'DROPPED', 'modal dialog cannot stay open');
    m('STANDARD', 'f345 SCREEN ENTRY RESET on a shared page', 'PROCESS', 'G_LAST_PAGE KEEP + application item G_SUPPORT_ENTRY_CALLER', 9001, 'SUPPORT_ENTRY.OPEN_DIALOG', 'MAPPED', 'page spec 0.2');
END;
/

COMMIT;
