-- =============================================================================
-- 001_ard_settings.sql - ARD report server settings (SC_PORT_SETTING), read by PRINT_<FORM>_ARD
--                        (IMPR2110.PRINT_IMPR2110_ARD) to build the ardpdf link of the ARD report packages
-- Author  : Claude Code (rows given by the user, 2026-11-25)
-- Date    : 2026-11-25
-- Version : 1.0
-- Rows    : SYSOBJ_ID 999, PORT_CD 99 (one setting for every port and module)
--             ARD_URL    = address of the ARD server ardpdf service
--             ARD_DSNAME = ARD data source name
--           Values below are the user's (staging server); change VAR_VALUE per environment.
-- Re-run  : deletes the two rows first. Rollback: 001_ard_settings_rollback.sql
-- NOT executed (CLAUDE.md 6.10).
-- =============================================================================
SET DEFINE OFF;

DELETE FROM SC_PORT_SETTING
 WHERE SYSOBJ_ID = 999
   AND PORT_CD   = 99
   AND VAR_NAME IN ('ARD_URL', 'ARD_DSNAME');

Insert into SC_PORT_SETTING
   (SYSOBJ_ID, VAR_NAME, VAR_ARB_DESC, VAR_VALUE, VAR_ENG_DESC,
    PORT_CD)
Values
   (999, 'ARD_URL', 'ARD_URL', 'http://stgnibrasapx01.myzatca.gov.sa:8001/ard/ardpdf', NULL,
    99);
Insert into SC_PORT_SETTING
   (SYSOBJ_ID, VAR_NAME, VAR_ARB_DESC, VAR_VALUE, VAR_ENG_DESC,
    PORT_CD)
Values
   (999, 'ARD_DSNAME', 'ARD_DSNAME', 'hqqaDS', NULL,
    99);
COMMIT;
