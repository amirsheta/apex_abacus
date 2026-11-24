CREATE OR REPLACE PACKAGE JOURNAL./*journal.*/DB_JOURNAL IS
 procedure journaling_on(supp_srce_cd number,supp_title_cd number,supp_letr_no varchar2,supp_letr_dt date);
 procedure journaling_off;
 function is_journaling_on return boolean;
 procedure get_journaling_params(supp_srce_cd in out number,supp_title_cd in out number,supp_letr_no in out varchar2,supp_letr_dt  in out date , Old_Key in out varchar2);
 procedure create_stuff(schemaName varchar2,tableName varchar2);
 procedure set_oldkey(oldkey_value varchar2) ;
 procedure clear_oldkey ;
END;

/


CREATE OR REPLACE PUBLIC SYNONYM DB_JOURNAL FOR JOURNAL.DB_JOURNAL;


GRANT EXECUTE ON JOURNAL.DB_JOURNAL TO CUSTOMS;

GRANT EXECUTE ON JOURNAL.DB_JOURNAL TO PP_CUSTOMS;

GRANT EXECUTE ON JOURNAL.DB_JOURNAL TO QA_CUSTOMS;

GRANT EXECUTE ON JOURNAL.DB_JOURNAL TO UAT_CUSTOMS;
