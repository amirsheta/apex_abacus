CREATE OR REPLACE PACKAGE BODY LIB_USR.hijdate_db
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

   ------------------------------------------------------------------------------------------
   PROCEDURE to_greg (hdate IN DATE, gdate OUT DATE, v_msg_txt OUT VARCHAR2)
   IS
      ------------------------------------------------------------------------------------------
      v_dd_num          NUMBER;
      bgdate            DATE;
      bhdate            DATE;
      half_month_date   DATE;
   BEGIN
      v_msg_txt := NULL;
      gdate := NULL;

      IF hdate IS NULL
      THEN
         RETURN;
      END IF;

      IF valid_hij_date (hdate, v_msg_txt) = 1
      THEN
         half_month_date :=
            TO_DATE ('15' || '-' || TO_CHAR (hdate, 'MM-YYYY'), 'DD-MM-YYYY');

         SELECT greg_date, hij_date
           INTO bgdate, bhdate
           FROM greg_hij_dates
          WHERE hij_date = (SELECT MAX (hij_date)
                              FROM greg_hij_dates
                             WHERE hij_date < half_month_date);

         v_dd_num := TO_NUMBER (TO_CHAR (hdate, 'MI'));
         gdate := bgdate + v_dd_num - 1;
      END IF;
   END to_greg;

   ------------------------------------------------------------------------------------------
   FUNCTION to_greg (hdate IN DATE)
      RETURN DATE
   IS
      ------------------------------------------------------------------------------------------
      g_date      DATE;
      v_txt_msg   VARCHAR2 (200);
   BEGIN
      to_greg (hdate, g_date, v_txt_msg);
      RETURN (g_date);
   END;

   ------------------------------------------------------------------------------------------
   PROCEDURE to_hijri (gdate IN DATE, hdate OUT DATE, v_msg_txt OUT VARCHAR2)
   IS
      ------------------------------------------------------------------------------------------
      bgdate           DATE;
      bhdate           DATE;
      bgdate2          DATE;
      bhdate2          DATE;
      v_dd_num         NUMBER;
      v_mm_num         NUMBER;
      v_yyyy_num       NUMBER;
      v_g_dd_num       INTEGER;
      v_dd_last_date   NUMBER;
      pure_date        DATE;
   BEGIN
      v_msg_txt := NULL;
      hdate := NULL;

      IF gdate IS NULL
      THEN
         RETURN;
      END IF;

      pure_date := TO_DATE (TO_CHAR (gdate, 'YYYY-MM-DD'), 'YYYY-MM-DD');

      SELECT greg_date, hij_date
        INTO bgdate, bhdate
        FROM greg_hij_dates
       WHERE greg_date = (SELECT MIN (greg_date)
                            FROM greg_hij_dates
                           WHERE greg_date <= pure_date);

      SELECT greg_date, hij_date
        INTO bgdate2, bhdate2
        FROM greg_hij_dates
       WHERE greg_date = (SELECT MAX (greg_date)
                            FROM greg_hij_dates
                           WHERE greg_date > pure_date);

      IF pure_date BETWEEN bgdate AND bgdate2
      THEN
         SELECT greg_date, hij_date
           INTO bgdate, bhdate
           FROM greg_hij_dates
          WHERE greg_date = (SELECT MAX (greg_date)
                               FROM greg_hij_dates
                              WHERE greg_date <= pure_date);

         v_g_dd_num := pure_date - bgdate;
         v_dd_last_date := last_hij_day (bhdate, v_msg_txt);

         IF v_dd_last_date IS NULL
         THEN
            RETURN;
         END IF;

         v_dd_num := TO_NUMBER (TO_CHAR (bhdate, 'DD'));
         v_mm_num := TO_NUMBER (TO_CHAR (bhdate, 'MM'));
         v_yyyy_num := TO_NUMBER (TO_CHAR (bhdate, 'YYYY'));

         IF (v_dd_last_date >= v_g_dd_num + 1)
         THEN
            v_dd_num := v_g_dd_num + 1;
         ELSE
            v_mm_num := v_mm_num + 1;

            IF v_mm_num = 13
            THEN
               v_mm_num := 1;
               v_yyyy_num := v_yyyy_num + 1;
            END IF;

            v_dd_num := v_g_dd_num - v_dd_last_date + 1;
         END IF;

         hdate :=
            TO_DATE (v_yyyy_num || '-' || v_mm_num || '-' || v_dd_num,
                     'YYYY-MM-MI');
      ELSE
         v_msg_txt := 'التاريخ خارج المدي المسموح به';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_msg_txt := 'التاريخ خارج المدي المسموح به';
   END to_hijri;

   ------------------------------------------------------------------------------------------
   FUNCTION to_hijri (gdate IN DATE)
      RETURN DATE
   IS
      ------------------------------------------------------------------------------------------
      h_date      DATE;
      v_txt_msg   VARCHAR2 (200);
   BEGIN
      to_hijri (gdate, h_date, v_txt_msg);
      RETURN (h_date);
   END;

   ------------------------------------------------------------------------------------------
   FUNCTION add_hij_days (hdate       IN     DATE,
                          days        IN     INTEGER,
                          v_msg_txt      OUT VARCHAR2)
      RETURN DATE
   IS
      ------------------------------------------------------------------------------------------
      gdate      DATE;
      gnewdate   DATE;
      hnewdate   DATE;
   BEGIN
      v_msg_txt := NULL;

      IF hdate IS NULL OR days IS NULL
      THEN
         RETURN (hdate);
      END IF;

      to_greg (hdate, gdate, v_msg_txt);

      IF gdate IS NULL
      THEN
         RETURN (NULL);
      END IF;

      gnewdate := gdate + days;
      to_hijri (gnewdate, hnewdate, v_msg_txt);

      IF hnewdate IS NULL
      THEN
         RETURN (NULL);
      END IF;

      RETURN (hnewdate);
   END add_hij_days;

   ------------------------------------------------------------------------------------------
   FUNCTION add_hij_days (hdate IN DATE, days IN INTEGER)
      RETURN DATE
   IS
      ------------------------------------------------------------------------------------------
      gdate       DATE;
      gnewdate    DATE;
      hnewdate    DATE;
      v_msg_txt   VARCHAR2 (200);
   BEGIN
      v_msg_txt := NULL;

      IF hdate IS NULL OR days IS NULL
      THEN
         RETURN (hdate);
      END IF;

      to_greg (hdate, gdate, v_msg_txt);

      IF gdate IS NULL
      THEN
         RETURN (NULL);
      END IF;

      gnewdate := gdate + days;
      to_hijri (gnewdate, hnewdate, v_msg_txt);

      IF hnewdate IS NULL
      THEN
         RETURN (NULL);
      END IF;

      RETURN (hnewdate);
   END add_hij_days;

   FUNCTION add_hij_months (hdate       IN     DATE,
                            months      IN     INTEGER,
                            v_msg_txt      OUT VARCHAR2)
      RETURN DATE
   IS
      ------------------------------------------------------------------------------------------
      v_dd         NUMBER;
      v_mm         NUMBER;
      v_yyyy       NUMBER;
      v_mm_n       INTEGER;
      v_yyyy_n     INTEGER;
      hnewdate     DATE;
      v_last_day   NUMBER;
   BEGIN
      v_msg_txt := NULL;

      IF hdate IS NULL OR months IS NULL
      THEN
         RETURN (hdate);
      END IF;

      v_dd := TO_NUMBER (TO_CHAR (hdate, 'MI'));
      v_mm := TO_NUMBER (TO_CHAR (hdate, 'MM'));
      v_yyyy := TO_NUMBER (TO_CHAR (hdate, 'YYYY'));
      v_yyyy_n := TRUNC (months / 12);
      v_mm_n := MOD (months, 12);
      v_mm := v_mm + v_mm_n;
      v_yyyy := v_yyyy + v_yyyy_n;

      IF v_mm < 0
      THEN
         v_yyyy_n := TRUNC (v_mm / 12);
         v_mm_n := MOD (v_mm, 12);
         v_mm := 12 + v_mm_n;
         v_yyyy := v_yyyy + v_yyyy_n - 1;
      END IF;

      IF v_mm = 0
      THEN
         v_mm := 12;
         v_yyyy := v_yyyy - 1;
      END IF;

      IF v_mm > 12
      THEN
         v_yyyy_n := TRUNC (v_mm / 12);
         v_mm_n := MOD (v_mm, 12);
         v_mm := v_mm_n;
         v_yyyy := v_yyyy + v_yyyy_n;
      END IF;

      hnewdate := TO_DATE (v_dd || '-' || v_mm || '-' || v_yyyy, 'MI-MM-YYYY');
      v_last_day := last_hij_day (hnewdate, v_msg_txt);

      IF v_last_day IS NULL
      THEN
         RETURN (NULL);
      END IF;

      IF v_dd > v_last_day
      THEN
         hnewdate :=
            TO_DATE (v_last_day || '-' || v_mm || '-' || v_yyyy,
                     'MI-MM-YYYY');
      END IF;

      RETURN (hnewdate);
   END add_hij_months;

   ------------------------------------------------------------------------------------------
   FUNCTION hij_date_diff_in_days (hdate1      IN     DATE,
                                   hdate2      IN     DATE,
                                   v_msg_txt      OUT VARCHAR2)
      RETURN INTEGER
   IS
      ------------------------------------------------------------------------------------------
      gdate1   DATE;
      gdate2   DATE;
      days     INTEGER;
   BEGIN
      v_msg_txt := NULL;

      IF hdate1 IS NULL OR hdate2 IS NULL
      THEN
         RETURN (NULL);
      END IF;

      to_greg (hdate1, gdate1, v_msg_txt);

      IF gdate1 IS NULL
      THEN
         RETURN (NULL);
      END IF;

      to_greg (hdate2, gdate2, v_msg_txt);

      IF gdate2 IS NULL
      THEN
         RETURN (NULL);
      END IF;

      days := gdate2 - gdate1;
      RETURN days;
   END hij_date_diff_in_days;

   ------------------------------------------------------------------------------------------
   FUNCTION hij_date_diff_in_days (hdate1 IN DATE, hdate2 IN DATE)
      RETURN INTEGER
   IS
      ------------------------------------------------------------------------------------------
      gdate1      DATE;
      gdate2      DATE;
      days        INTEGER;
      v_msg_txt   VARCHAR2 (1000);
   BEGIN
      v_msg_txt := NULL;

      IF hdate1 IS NULL OR hdate2 IS NULL
      THEN
         RETURN (NULL);
      END IF;

      to_greg (hdate1, gdate1, v_msg_txt);

      IF gdate1 IS NULL
      THEN
         RETURN (NULL);
      END IF;

      to_greg (hdate2, gdate2, v_msg_txt);

      IF gdate2 IS NULL
      THEN
         RETURN (NULL);
      END IF;

      days := gdate2 - gdate1;
      RETURN days;
   END hij_date_diff_in_days;

   ------------------------------------------------------------------------------------------
   FUNCTION hij_date_diff_in_months (hdate1      IN     DATE,
                                     hdate2      IN     DATE,
                                     v_msg_txt      OUT VARCHAR2)
      RETURN NUMBER
   IS
      ------------------------------------------------------------------------------------------
      gdate1   DATE;
      gdate2   DATE;
      months   NUMBER;
   BEGIN
      v_msg_txt := NULL;

      IF hdate1 IS NULL OR hdate2 IS NULL
      THEN
         RETURN (NULL);
      END IF;

      to_greg (hdate1, gdate1, v_msg_txt);

      IF gdate1 IS NULL
      THEN
         RETURN (NULL);
      END IF;

      to_greg (hdate2, gdate2, v_msg_txt);

      IF gdate2 IS NULL
      THEN
         RETURN (NULL);
      END IF;

      months := MONTHS_BETWEEN (gdate1, gdate2);
      RETURN months;
   END hij_date_diff_in_months;

   ------------------------------------------------------------------------------------------
   FUNCTION valid_hij_date (hdate IN DATE, v_msg_txt OUT VARCHAR2)
      RETURN NUMBER
   IS
      ------------------------------------------------------------------------------------------
      v_dd_num          NUMBER;
      hdate1            DATE;
      hdate2            DATE;
      gdate1            DATE;
      gdate2            DATE;
      half_month_date   DATE;
      date_num          INTEGER;
   BEGIN
      v_msg_txt := NULL;

      IF hdate IS NULL
      THEN
         RETURN (NULL);
      END IF;

      half_month_date :=
         TO_DATE ('15' || '-' || TO_CHAR (hdate, 'MM-YYYY'), 'DD-MM-YYYY');

      SELECT greg_date, hij_date
        INTO gdate1, hdate1
        FROM greg_hij_dates
       WHERE hij_date = (SELECT MIN (hij_date)
                           FROM greg_hij_dates
                          WHERE hij_date < half_month_date);

      SELECT greg_date, hij_date
        INTO gdate2, hdate2
        FROM greg_hij_dates
       WHERE hij_date = (SELECT MAX (hij_date)
                           FROM greg_hij_dates
                          WHERE hij_date > half_month_date);

      IF half_month_date BETWEEN hdate1 AND hdate2
      THEN
         date_num := last_hij_day (hdate, v_msg_txt);

         IF date_num IS NULL
         THEN
            RETURN 0;
         END IF;

         v_dd_num := TO_NUMBER (TO_CHAR (hdate, 'MI'));

         IF v_dd_num > date_num OR v_dd_num <= 0
         THEN
            v_msg_txt :=
                  ' التاريخ يجب أن يتراوح بين 1 و '
               || date_num;
            RETURN 0;
         ELSE
            RETURN 1;
         END IF;
      ELSE
         v_msg_txt :=
            'التاريخ الهجرى خارج المدى المسموح به - اتصل بمكتب المسانده الفنية';
         RETURN 0;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_msg_txt :=
            'التاريخ الهجرى خارج المدى المسموح به - اتصل بمكتب المسانده الفنية';
         RETURN (0);
   END valid_hij_date;

   ------------------------------------------------------------------------------------------
   FUNCTION compare_hij_dates (hdate1 IN DATE, hdate2 IN DATE)
      RETURN INTEGER
   IS
   ------------------------------------------------------------------------------------------
   BEGIN
      IF hdate1 IS NULL OR hdate2 IS NULL
      THEN
         RETURN (NULL);
      END IF;

      IF TO_CHAR (hdate1, 'YYYY-MM-MI') < TO_CHAR (hdate2, 'YYYY-MM-MI')
      THEN
         RETURN (-1);
      ELSIF TO_CHAR (hdate1, 'YYYY-MM-MI') > TO_CHAR (hdate2, 'YYYY-MM-MI')
      THEN
         RETURN (1);
      ELSIF TO_CHAR (hdate1, 'YYYY-MM-MI') = TO_CHAR (hdate2, 'YYYY-MM-MI')
      THEN
         RETURN (0);
      END IF;
   END compare_hij_dates;

   ------------------------------------------------------------------------------------------
   FUNCTION cur_hij_date (v_msg_txt OUT VARCHAR2)
      RETURN DATE
   IS
      ------------------------------------------------------------------------------------------
      gdate    DATE;
      hdate    DATE;
      gdate2   DATE;
   BEGIN
      /* Select SYSDATE
         into GDATE
         from dual
         ;
         */
      gdate := SYSDATE;
      --DBMS_LOCK.SLEEP(.1);
      gdate2 := SYSDATE;

      IF TO_CHAR (gdate, 'YYYYMMDD') != TO_CHAR (gdate2, 'YYYYMMDD')
      THEN
         raise_application_error (
            -20001,
            'خطأ في استرجاع التاريخ الهجري');
      END IF;

      to_hijri (gdate, hdate, v_msg_txt);

      IF hdate IS NULL
      THEN
         RETURN (NULL);
      END IF;

      RETURN (hdate);
   END cur_hij_date;

   ------------------------------------------------------------------------------------------
   FUNCTION cur_hij_date
      RETURN DATE
   IS
      ------------------------------------------------------------------------------------------
      gdate2      DATE;
      gdate       DATE;
      hdate       DATE;
      v_msg_txt   VARCHAR2 (200);
   BEGIN
      /* Select SYSDATE
         into GDATE
         from dual
         ;*/
      gdate := SYSDATE;
      --DBMS_LOCK.SLEEP(.1);
      gdate2 := SYSDATE;

      IF TO_CHAR (gdate, 'YYYYMMDD') != TO_CHAR (gdate2, 'YYYYMMDD')
      THEN
         raise_application_error (
            -20001,
            'خطأ في استرجاع التاريخ الهجري');
      END IF;

      to_hijri (gdate, hdate, v_msg_txt);

      IF hdate IS NULL
      THEN
         RETURN (NULL);
      END IF;

      RETURN (hdate);
   END cur_hij_date;

   ------------------------------------------------------------------------------------------
   FUNCTION last_hij_day (hdate IN DATE, v_msg_txt OUT VARCHAR2)
      RETURN NUMBER
   IS
      ------------------------------------------------------------------------------------------
      hdate1            DATE;
      hdate2            DATE;
      gdate1            DATE;
      gdate2            DATE;
      half_month_date   DATE;
      date_num          INTEGER;
   BEGIN
      v_msg_txt := NULL;

      IF hdate IS NULL
      THEN
         RETURN (NULL);
      END IF;

      half_month_date :=
         TO_DATE ('15' || '-' || TO_CHAR (hdate, 'MM-YYYY'), 'DD-MM-YYYY');

      SELECT greg_date, hij_date
        INTO gdate1, hdate1
        FROM greg_hij_dates
       WHERE hij_date = (SELECT MAX (hij_date)
                           FROM greg_hij_dates
                          WHERE hij_date < half_month_date);

      SELECT greg_date, hij_date
        INTO gdate2, hdate2
        FROM greg_hij_dates
       WHERE hij_date = (SELECT MIN (hij_date)
                           FROM greg_hij_dates
                          WHERE hij_date > half_month_date);

      date_num := gdate2 - gdate1;

      IF date_num > 30 OR date_num IS NULL
      THEN
         v_msg_txt :=
            'خطأ داخلى فى جدول التاريخ الهجرى - إتصل بالمساندة الفنية';
         RETURN (NULL);
      END IF;

      RETURN (date_num);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_msg_txt :=
            'التاريخ الهجرى خارج المدى المسموح به - اتصل بمكتب المسانده الفنية';
         RETURN (NULL);
   END last_hij_day;

   ------------------------------------------------------------------------------------------
   FUNCTION last_hij_date (hdate IN DATE, v_msg_txt OUT VARCHAR2)
      RETURN DATE
   IS
      ------------------------------------------------------------------------------------------
      date_num   NUMBER;
   BEGIN
      v_msg_txt := NULL;

      IF hdate IS NULL
      THEN
         RETURN (NULL);
      END IF;

      date_num := last_hij_day (hdate, v_msg_txt);

      IF date_num IS NULL
      THEN
         RETURN (NULL);
      END IF;

      RETURN (TO_DATE (date_num || '-' || TO_CHAR (hdate, 'MM-YYYY'),
                       'MI-MM-YYYY'));
   END last_hij_date;
END hijdate_db;
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
