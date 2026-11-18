CREATE OR REPLACE PACKAGE BODY LIB_USR.activity_db
IS

   FUNCTION get_info
      RETURN VARCHAR2
   IS
   BEGIN
      DBMS_OUTPUT.put_line (v_info);
      RETURN v_info;
   END get_info;

   FUNCTION pkg_version
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN (v_pkg_version);
   END pkg_version;

---------------------------------------------------------------------------------------------
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
      RETURN NUMBER
   IS
---------------------------------------------------------------------------------------------
      g_date_time   DATE;
      isn           NUMBER;
      V_wrkstn_id  VARCHAR2(100):= NULL;
      
   BEGIN
      v_msg_txt := NULL;
      IF wrkstn_id = 'NO_TRM_DEF'
      THEN
      
      V_wrkstn_id := 'GLOBAL_TERMINAL';
        -- v_msg_txt :=  '.لايمكن إتمام العملية, الجهاز غير معرف,راجع المساندة الفنية لتعريف ا;لجهاز';
        -- RETURN 0;
      END IF;
        

      SELECT SYSDATE
        INTO g_date_time
        FROM DUAL;

      SELECT gnrl.GET_SEQUENCE_VALUE (port_cd, 'actvy_seq') -- CNTRL FATIMAH FEB-26-25
        INTO isn
        FROM DUAL;

      INSERT INTO activity_trans_daily
                  (actvy_isn, sysobj_id, subj_code, actvy_type, actvy_date,
                   user_id, port_cd, wrkstn_id, actvy_sub_id
                  )
           VALUES (isn, sysobj_id, subj_code, actvy_type, g_date_time,
                   user_id, port_cd, NVL(V_wrkstn_id,wrkstn_id), actvy_subj_id
                  );

      INSERT INTO msg_activities
                  (port_cd, actvy_isn, msg_id
                  )
           VALUES (port_cd, isn, msg_id
                  );

      RETURN 1;
/*EXCEPTION
    WHEN OTHERS THEN
        V_MSG_TXT := 'لا يمكن إضافة سجل الأنشطه - إتصل بالمسانده الفنيه';
        RETURN 0;*/
   END add_activity;

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
      RETURN NUMBER
   IS
---------------------------------------------------------------------------------------------
      g_date_time    DATE;
      isn            NUMBER;
      V_wrkstn_id  VARCHAR2(100):= NULL;
   BEGIN
      v_msg_txt := NULL;

      IF wrkstn_id = 'NO_TRM_DEF'
      THEN
      V_wrkstn_id := 'GLOBAL_TERMINAL';
        -- v_msg_txt := '.لايمكن إتمام العملية, الجهاز غير معرف,راجع المساندة الفنية لتعريف ا;لجهاز';
       --  RETURN 0;
      END IF;

      SELECT SYSDATE
        INTO g_date_time
        FROM DUAL;

      SELECT gnrl.GET_SEQUENCE_VALUE (port_cd, 'actvy_seq') -- CNTRL FATIMAH FEB-26-25
        INTO isn
        FROM DUAL;
          INSERT INTO activity_trans_daily
                  (actvy_isn, sysobj_id, subj_code, actvy_type, actvy_date,
                   user_id, port_cd, wrkstn_id, actvy_sub_id
                  )
           VALUES (isn, sysobj_id, subj_code, actvy_type, g_date_time,
                   user_id, port_cd, NVL(V_wrkstn_id,wrkstn_id), actvy_subj_id
                  );

      RETURN 1;
/*EXCEPTION
    WHEN OTHERS THEN
        V_MSG_TXT := 'لا يمكن إضافة سجل الأنشطه - إتصل بالمسانده الفنيه';
        RETURN 0;*/
   END add_activity;
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
      RETURN NUMBER
   IS
---------------------------------------------------------------------------------------------
      g_date_time    DATE;
      isn            NUMBER;
      v_main_actvy   NUMBER;
      V_wrkstn_id  VARCHAR2(100):= NULL;
   BEGIN
      v_msg_txt := NULL;

      IF wrkstn_id = 'NO_TRM_DEF'
      THEN
           V_wrkstn_id := 'GLOBAL_TERMINAL';
       --  v_msg_txt :=  '.لايمكن إتمام العملية, الجهاز غير معرف,راجع المساندة الفنية لتعريف ا;لجهاز';
        -- RETURN 0;
      END IF;

      SELECT SYSDATE
        INTO g_date_time
        FROM DUAL;

      SELECT gnrl.GET_SEQUENCE_VALUE (port_cd, 'actvy_seq') -- CNTRL FATIMAH FEB-26-25
        INTO isn
        FROM DUAL;

      IF track_seq_var <> 0
      THEN
         SELECT COUNT (*)
           INTO v_main_actvy
           FROM actor_track_activity
          WHERE port_cd = port_cd
            AND track_seq = track_seq_var
            AND actvy_isn = isn;

         IF v_main_actvy > 0
         THEN
            v_main_actvy := 0;
         ELSE
            v_main_actvy := 1;
         END IF;

         ---- Ayman Gad 22-01-2026 CRQ
          
         /*INSERT INTO actor_track_activity
                     (port_cd, track_seq, actvy_isn, main_actvy
                     )
              VALUES (port_cd, track_seq_var, isn, v_main_actvy
                     );*/
      END IF;

      INSERT INTO activity_trans_daily
                  (actvy_isn, sysobj_id, subj_code, actvy_type, actvy_date,
                   user_id, port_cd, wrkstn_id, actvy_sub_id
                  )
           VALUES (isn, sysobj_id, subj_code, actvy_type, g_date_time,
                   user_id, port_cd, NVL(V_wrkstn_id,wrkstn_id), actvy_subj_id
                  );

      RETURN 1;
   END add_activity;

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
