-- =============================================================================
-- setup_apex_workspace.sql
-- Oracle Forms 12c -> Oracle APEX 21.2 migration: schema + workspace setup
--
-- Creates:
--   1. Database schema FORMS_MIGRATION (APEX parsing schema for migrated forms)
--   2. System + object privileges required by APEX and by the migrated packages
--   3. APEX workspace FORMS_MIGRATION mapped to that schema
--   4. A workspace administrator account
--
-- Run as: SYS / a DBA account that can execute APEX_INSTANCE_ADMIN
--         (in a PDB: connect to the PDB where APEX 21.2 is installed)
--   sqlplus / as sysdba   (then ALTER SESSION SET CONTAINER = <pdb>;)
--   SQL> @setup_apex_workspace.sql
--
-- SECURITY: no passwords are stored in this file. They are prompted with ACCEPT ... HIDE.
--
-- Rollback: see section 9 at the end of this file (commented out).
-- =============================================================================

SET VERIFY OFF
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE UNLIMITED
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

-- -----------------------------------------------------------------------------
-- 0. Parameters  (TODO: DBA review defaults before running)
-- -----------------------------------------------------------------------------
DEFINE schema_name     = FORMS_MIGRATION
DEFINE workspace_name  = FORMS_MIGRATION
-- TODO: DBA - choose tablespaces (must exist)
DEFINE data_tbs        = USERS
DEFINE temp_tbs        = TEMP
-- TODO: DBA - quota for migration schema (e.g. 2G or UNLIMITED)
DEFINE data_quota      = 2G
-- TODO: DBA - legacy schema owning the Forms application tables (for object grants)
DEFINE legacy_schema   = LEGACY_APP
-- TODO: DBA - workspace admin user name and e-mail
DEFINE ws_admin_user   = MIGRATION_ADMIN
DEFINE ws_admin_email  = migration.admin@example.com

ACCEPT schema_pwd   CHAR PROMPT 'Password for schema &schema_name: ' HIDE
ACCEPT ws_admin_pwd CHAR PROMPT 'Password for workspace admin &ws_admin_user: ' HIDE

-- -----------------------------------------------------------------------------
-- 1. Pre-checks: APEX version must be 21.2
-- -----------------------------------------------------------------------------
DECLARE
    v_version VARCHAR2(30);
BEGIN
    SELECT version_no INTO v_version FROM apex_release;
    dbms_output.put_line('APEX version installed: ' || v_version);
    IF v_version NOT LIKE '21.2.%' THEN
        raise_application_error(-20001,
            'Expected APEX 21.2.x but found ' || v_version || '. Aborting.');
    END IF;
END;
/

-- Database version: toolkit targets 12.1.0.2 (warning only, does not abort)
DECLARE
    v_db_version VARCHAR2(30);
BEGIN
    SELECT version INTO v_db_version FROM v$instance;
    dbms_output.put_line('Database version: ' || v_db_version);
    IF v_db_version NOT LIKE '12.1.0.2%' THEN
        dbms_output.put_line('WARNING: toolkit rules (CLAUDE.md section 2a) assume 12.1.0.2.');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 2. Create the migration schema
-- -----------------------------------------------------------------------------
CREATE USER &schema_name IDENTIFIED BY "&schema_pwd"
    DEFAULT TABLESPACE &data_tbs
    TEMPORARY TABLESPACE &temp_tbs
    QUOTA &data_quota ON &data_tbs;

-- TODO: DBA - assign the corporate password profile if required
-- ALTER USER &schema_name PROFILE <app_profile>;

-- -----------------------------------------------------------------------------
-- 3. System privileges (standard set for an APEX parsing schema)
-- -----------------------------------------------------------------------------
GRANT CREATE SESSION           TO &schema_name;
GRANT CREATE TABLE             TO &schema_name;
GRANT CREATE VIEW              TO &schema_name;
GRANT CREATE SEQUENCE          TO &schema_name;
GRANT CREATE PROCEDURE         TO &schema_name;
GRANT CREATE TRIGGER           TO &schema_name;
GRANT CREATE TYPE              TO &schema_name;
GRANT CREATE SYNONYM           TO &schema_name;
GRANT CREATE MATERIALIZED VIEW TO &schema_name;
GRANT CREATE JOB               TO &schema_name;   -- replaces Forms HOST / batch calls via DBMS_SCHEDULER

-- Optional - only if the migrated logic needs them (TODO: DBA decide)
-- GRANT EXECUTE ON SYS.DBMS_CRYPTO TO &schema_name;
-- GRANT EXECUTE ON SYS.UTL_FILE    TO &schema_name;   -- replaces TEXT_IO server-side
-- GRANT READ, WRITE ON DIRECTORY <migration_dir> TO &schema_name;
-- GRANT CREATE DATABASE LINK TO &schema_name;          -- only for data comparison with a remote legacy DB

-- -----------------------------------------------------------------------------
-- 4. Object privileges on the legacy application schema
--    The migrated pages normally work on the EXISTING Forms tables.
--    Generates GRANTs for all tables/views/sequences/packages of &legacy_schema.
--    TODO: DBA - review; restrict to the objects actually used by migrated forms.
-- -----------------------------------------------------------------------------
BEGIN
    FOR r IN (
        SELECT owner, object_name, object_type
          FROM dba_objects
         WHERE owner = UPPER('&legacy_schema')
           AND object_type IN ('TABLE', 'VIEW', 'SEQUENCE', 'PACKAGE', 'PROCEDURE', 'FUNCTION', 'TYPE')
           AND object_name NOT LIKE 'BIN$%'
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE
                'GRANT ' ||
                CASE r.object_type
                    WHEN 'TABLE'    THEN 'SELECT, INSERT, UPDATE, DELETE'
                    WHEN 'VIEW'     THEN 'SELECT'
                    WHEN 'SEQUENCE' THEN 'SELECT'
                    ELSE 'EXECUTE'
                END ||
                ' ON ' || dbms_assert.enquote_name(r.owner) || '.' ||
                dbms_assert.enquote_name(r.object_name) ||
                ' TO ' || dbms_assert.enquote_name(UPPER('&schema_name'));
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('WARN: grant failed on ' || r.owner || '.' ||
                                     r.object_name || ' - ' || SQLERRM);
        END;
    END LOOP;
END;
/

-- utPLSQL (if installed) for prompt 05 unit tests - TODO: DBA confirm utPLSQL owner
-- GRANT EXECUTE ON ut3.ut TO &schema_name;

-- -----------------------------------------------------------------------------
-- 5. Create the APEX workspace
-- -----------------------------------------------------------------------------
BEGIN
    apex_instance_admin.add_workspace(
        p_workspace_id       => NULL,                  -- NULL = let APEX generate the ID
        p_workspace          => UPPER('&workspace_name'),
        p_primary_schema     => UPPER('&schema_name'),
        p_additional_schemas => NULL                   -- TODO: DBA - e.g. '&legacy_schema' if pages must parse as legacy schema
    );
    COMMIT;
    dbms_output.put_line('Workspace &workspace_name created.');
END;
/

-- -----------------------------------------------------------------------------
-- 6. Create the workspace administrator
-- -----------------------------------------------------------------------------
DECLARE
    v_workspace_id NUMBER;
BEGIN
    v_workspace_id := apex_util.find_security_group_id(p_workspace => UPPER('&workspace_name'));
    apex_util.set_security_group_id(p_security_group_id => v_workspace_id);

    apex_util.create_user(
        p_user_name                    => UPPER('&ws_admin_user'),
        p_email_address                => '&ws_admin_email',
        p_web_password                 => '&ws_admin_pwd',
        p_developer_privs              => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
        p_default_schema               => UPPER('&schema_name'),
        p_change_password_on_first_use => 'Y'
    );
    COMMIT;
    dbms_output.put_line('Workspace admin &ws_admin_user created (workspace_id=' || v_workspace_id || ').');
END;
/

-- TODO: DBA - create additional developer accounts the same way with
--       p_developer_privs => 'CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL'

-- -----------------------------------------------------------------------------
-- 7. Optional workspace settings (TODO: DBA decide)
-- -----------------------------------------------------------------------------
-- BEGIN
--     apex_instance_admin.set_workspace_parameter(
--         p_workspace => UPPER('&workspace_name'),
--         p_parameter => 'MAX_SESSION_LENGTH_SEC',
--         p_value     => '28800');
--     COMMIT;
-- END;
-- /

-- -----------------------------------------------------------------------------
-- 8. Verification
-- -----------------------------------------------------------------------------
SELECT workspace, workspace_id, schemas
  FROM apex_workspaces
 WHERE workspace = UPPER('&workspace_name');

SELECT workspace_name, schema
  FROM apex_workspace_schemas
 WHERE workspace_name = UPPER('&workspace_name');

SELECT privilege FROM dba_sys_privs WHERE grantee = UPPER('&schema_name') ORDER BY privilege;

UNDEFINE schema_pwd
UNDEFINE ws_admin_pwd

PROMPT
PROMPT Setup complete. Log in to APEX with workspace &workspace_name / user &ws_admin_user.
PROMPT

-- -----------------------------------------------------------------------------
-- 9. ROLLBACK (run manually, as SYS/DBA, only if you need to undo this setup)
-- -----------------------------------------------------------------------------
-- BEGIN
--     apex_instance_admin.remove_workspace(
--         p_workspace         => 'FORMS_MIGRATION',
--         p_drop_users        => 'N',
--         p_drop_tablespaces  => 'N');
--     COMMIT;
-- END;
-- /
-- DROP USER forms_migration CASCADE;
