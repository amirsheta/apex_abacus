-- =============================================================================
-- 001_ard_settings_rollback.sql - removes the ARD report server settings of 001_ard_settings.sql
-- Author  : Claude Code      Date: 2026-11-25      Version: 1.0
-- After this, PRINT_<FORM>_ARD stops with «إعداد خادم التقارير غير موجود ...».
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF;

DELETE FROM SC_PORT_SETTING
 WHERE SYSOBJ_ID = 999
   AND PORT_CD   = 99
   AND VAR_NAME IN ('ARD_URL', 'ARD_DSNAME');
COMMIT;
