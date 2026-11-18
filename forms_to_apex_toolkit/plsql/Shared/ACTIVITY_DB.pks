CREATE OR REPLACE PACKAGE LIB_USR.activity_db
IS

   ----------------------------------------------------------------------------------------------
    /*
    Package is match with central database at 23-07-2026 sheta
    */
   ----------------------------------------------------------------------------------------------

v_pkg_version      VARCHAR2 (100) := 'Version No. Is:' || '4.00';

   FUNCTION pkg_version
      RETURN VARCHAR2;
----------------------------------------------------------------------------------------------
     v_last_modify_dt   VARCHAR2 (10)  := '22-01-2026'; --'20-06-2022';
     v_modified_by      VARCHAR2 (50)  := 'Ayman Gad';  --'Mohamed Taha22'; -- Change terminal name due to apply DR
     v_dm_cr             VARCHAR2 (50) := 'CRQ60631';    
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
   v_package_name     VARCHAR2 (50)  := 'activity_db';
   v_info             VARCHAR2 (500)
      :=    'Package name :  '
         || v_package_name
         || CHR (10)
         || CHR (13)
         || v_pkg_version
         || CHR (10)
         || CHR (13)
         || 'modified date : '
         || v_last_modify_dt
         || CHR (10)
         || CHR (13)
         || 'modified by : '
         || v_modified_by;

   FUNCTION get_info
      RETURN VARCHAR2;
   FUNCTION add_activity (
      sysobj_id             NUMBER,
      subj_code             NUMBER,
      actvy_type            NUMBER,
      actvy_subj_id         VARCHAR2,
      port_cd               NUMBER,
      user_id               VARCHAR2,
      wrkstn_id             VARCHAR2,
      v_msg_txt       OUT   VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION add_activity (
      sysobj_id             NUMBER,
      subj_code             NUMBER,
      actvy_type            NUMBER,
      actvy_subj_id         VARCHAR2,
      port_cd               NUMBER,
      user_id               VARCHAR2,
      wrkstn_id             VARCHAR2,
      msg_id                VARCHAR2,
      v_msg_txt       OUT   VARCHAR2
   )
      RETURN NUMBER;
   FUNCTION add_activity (
      sysobj_id             NUMBER,
      subj_code             NUMBER,
      actvy_type            NUMBER,
      actvy_subj_id         VARCHAR2,
      port_cd               NUMBER,
      user_id               VARCHAR2,
      wrkstn_id             VARCHAR2,
      track_seq_var         NUMBER,
      v_msg_txt       OUT   VARCHAR2
   )
      RETURN NUMBER;
END activity_db;
/


CREATE OR REPLACE PUBLIC SYNONYM ACTIVITY_DB FOR LIB_USR.ACTIVITY_DB;


GRANT EXECUTE ON LIB_USR.ACTIVITY_DB TO CUSTOMS;

GRANT EXECUTE ON LIB_USR.ACTIVITY_DB TO EDIDHL;

GRANT EXECUTE ON LIB_USR.ACTIVITY_DB TO LIB_USR_JN;

GRANT EXECUTE ON LIB_USR.ACTIVITY_DB TO PP_CUSTOMS;

GRANT EXECUTE ON LIB_USR.ACTIVITY_DB TO QA_CUSTOMS;

GRANT EXECUTE ON LIB_USR.ACTIVITY_DB TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_USR.ACTIVITY_DB TO SECURITY_PROD;

GRANT EXECUTE ON LIB_USR.ACTIVITY_DB TO UAT_CUSTOMS;
