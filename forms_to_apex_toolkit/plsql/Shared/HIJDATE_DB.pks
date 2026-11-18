CREATE OR REPLACE PACKAGE LIB_USR.HIJDATE_DB
IS
    /*Package is match with central database at 22-07-2026 modified By Mohamed Taha */
 v_pkg_version      VARCHAR2 (100) := 'Version No. Is:' || '2.00';

   FUNCTION pkg_version
      RETURN VARCHAR2;

----------------------------------------------------------------------------------------------
   v_last_modify_dt   VARCHAR2 (10)  := '12-11-2017';
   v_modified_by      VARCHAR2 (50)  := 'M.ALI';
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
   v_package_name     VARCHAR2 (50)  := 'HIJDATE_DB';
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

   PROCEDURE to_greg (hdate IN DATE, gdate OUT DATE, v_msg_txt OUT VARCHAR2);

   PROCEDURE to_hijri (gdate IN DATE, hdate OUT DATE, v_msg_txt OUT VARCHAR2);

   FUNCTION cur_hij_date (v_msg_txt OUT VARCHAR2)
      RETURN DATE;

   FUNCTION cur_hij_date
      RETURN DATE;

   FUNCTION add_hij_days (
      hdate       IN       DATE,
      days        IN       INTEGER,
      v_msg_txt   OUT      VARCHAR2
   )
      RETURN DATE;

   FUNCTION add_hij_days (hdate IN DATE, days IN INTEGER)
      RETURN DATE;

   FUNCTION add_hij_months (
      hdate       IN       DATE,
      months      IN       INTEGER,
      v_msg_txt   OUT      VARCHAR2
   )
      RETURN DATE;

   FUNCTION hij_date_diff_in_days (
      hdate1      IN       DATE,
      hdate2      IN       DATE,
      v_msg_txt   OUT      VARCHAR2
   )
      RETURN INTEGER;

   FUNCTION hij_date_diff_in_months (
      hdate1      IN       DATE,
      hdate2      IN       DATE,
      v_msg_txt   OUT      VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION valid_hij_date (hdate IN DATE, v_msg_txt OUT VARCHAR2)
      RETURN NUMBER;

   FUNCTION compare_hij_dates (hdate1 IN DATE, hdate2 IN DATE)
      RETURN INTEGER;

   FUNCTION last_hij_date (hdate IN DATE, v_msg_txt OUT VARCHAR2)
      RETURN DATE;

   FUNCTION last_hij_day (hdate IN DATE, v_msg_txt OUT VARCHAR2)
      RETURN NUMBER;

   ------------------------------------------------------------------------------------------
-- ADDED BY A.HASSAN 30-5-2006
-- OVERRLOADING OF PERIVIOUS FUNCTION (NO OUT ARGUMENTS) TO BE USED INSIDE SQL STATMENT
   FUNCTION hij_date_diff_in_days (hdate1 IN DATE, hdate2 IN DATE)
      RETURN INTEGER;

---

   -- ADDED BY OMAR.HASSAN 22-6-2008
-- OVERRLOADING OF PERIVIOUS FUNCTION (NO OUT ARGUMENTS) TO BE USED INSIDE SQL STATMENT
   FUNCTION to_greg (hdate IN DATE)
      RETURN DATE;

   FUNCTION to_hijri (gdate IN DATE)
      RETURN DATE;
--
------------------------------------------------------------------------------------------
END;
/


CREATE OR REPLACE PUBLIC SYNONYM HIJDATE_DB FOR LIB_USR.HIJDATE_DB;


GRANT EXECUTE ON LIB_USR.HIJDATE_DB TO CNTRL_CONTROL;

GRANT EXECUTE ON LIB_USR.HIJDATE_DB TO CUSTOMS;

GRANT EXECUTE ON LIB_USR.HIJDATE_DB TO LIB_USR_JN;

GRANT EXECUTE ON LIB_USR.HIJDATE_DB TO PP_CUSTOMS;

GRANT EXECUTE ON LIB_USR.HIJDATE_DB TO PP_LIB_USR;

GRANT EXECUTE ON LIB_USR.HIJDATE_DB TO QA_CUSTOMS;

GRANT EXECUTE ON LIB_USR.HIJDATE_DB TO QA_LIB_USR;

GRANT EXECUTE ON LIB_USR.HIJDATE_DB TO SECURITY_DEFAULT;

GRANT EXECUTE ON LIB_USR.HIJDATE_DB TO SECURITY_PROD;

GRANT EXECUTE ON LIB_USR.HIJDATE_DB TO UAT_CUSTOMS;
