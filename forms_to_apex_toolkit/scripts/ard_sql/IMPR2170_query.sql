-- --> 22/04/2009 AHMED A-MONIM

                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1          port_f0,
                           1          sts_f0,
                           imp.port_cd port_cd_f1,
                           imp.impr_nbr impr_nbr_f1,
                              ' إيقاف '
                           || ' من تاريخ '
                           || TO_CHAR (is_1.suspn_strt_dt, 'MI-MM-YYYY')
                           || ' إلى تاريخ '
                           || TO_CHAR (is_1.suspn_end_dt, 'MI-MM-YYYY')
                           || ' بسبب '
                           || is_1.suspn_rsn_text
                              txt_f1,
                              ' '
                           || DECODE (
                                 is_1.port_cd,
                                 99, DECODE (9,
                                             1, 'القيود',
                                             2, 'الإيرادات',
                                             4, 'الادارة القانونية',
                                             'المصلحة'),
                                 'الجمرك')
                              txt_f9
                      FROM importers imp, impr_suspns is_1
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND is_1.port_cd = imp.port_cd
                           AND is_1.impr_nbr = imp.impr_nbr
                           AND TO_CHAR (is_1.suspn_strt_dt, 'YYYY-MM-MI') <=
                                  TO_CHAR (v_cf_curr_dt, 'YYYY-MM-MI')
                           AND TO_CHAR (is_1.suspn_end_dt, 'YYYY-MM-MI') >=
                                  TO_CHAR (v_cf_curr_dt, 'YYYY-MM-MI')
                           AND is_1.suspn_rlse_dt IS NULL
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           1,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' إيقاف '
                           || ' من تاريخ '
                           || TO_CHAR (is_1.suspn_strt_dt, 'MI-MM-YYYY')
                           || ' إلى تاريخ '
                           || TO_CHAR (is_1.suspn_end_dt, 'MI-MM-YYYY')
                           || ' بسبب '
                           || is_1.suspn_rsn_text,
                              ' '
                           || DECODE (
                                 is_1.port_cd,
                                 99, DECODE (9,
                                             1, 'القيود',
                                             2, 'الإيرادات',
                                             4, 'الادارة القانونية',
                                             'المصلحة'),
                                 'الجمرك')
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           2,
                           imp.port_cd,
                           imp.impr_nbr,
                           DECODE (
                              imp.bus_id_exprd_dt,
                              NULL, 'تاريخ إنتهاء النشاط غير مدخل',
                                 'السجل منتهي في '
                              || TO_CHAR (imp.bus_id_exprd_dt, 'MI-MM-YYYY')),
                           'الجمرك'
                      FROM importers imp
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND (imp.bus_id_exprd_dt IS NULL OR imp.bus_id_exprd_dt < v_cf_curr_dt)
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           2,
                           imp.port_cd,
                           imp.impr_nbr,
                           DECODE (
                              imp.bus_id_exprd_dt,
                              NULL, 'تاريخ إنتهاء النشاط غير مدخل',
                                 'السجل منتهي في '
                              || TO_CHAR (imp.bus_id_exprd_dt, 'MI-MM-YYYY')),
                           'الجمرك'
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           0,
                           0,
                           0,
                           0,
                              ' حجز المستوردات'
                           || ' بالقرار رقم '
                           || is_1.seizure_nbr
                           || ' وتاريخ '
                           || TO_CHAR (is_1.seizure_date, 'MI-MM-YYYY')
                           || DECODE (9, 4, '', ' ومبلغ الحجز ' || is_1.szr_amount)
                           || ' وتاريخ بداية الحجز '
                           || TO_CHAR (is_1.szr_strt_date, 'MI-MM-YYYY')
                           || ' '
                           || 'وسبب الحجز الرئيسي'
                           || ' '
                           || decode(is_1.IMPR_SZR_M_RSN_CD,null,'لا يوجد',IMPR_UTILITIES.get_main_szr_rsn(is_1.IMPR_SZR_M_RSN_CD))
                           || ' '
                           ||'وسبب الحجز الفرعي'
                           || ' '
                           || decode(is_1.IMPR_SZR_S_RSN_CD,null,'لا يوجد',IMPR_UTILITIES.get_sub_szr_rsn(is_1.IMPR_SZR_M_RSN_CD,is_1.IMPR_SZR_S_RSN_CD))
                           || ' '
                           || is_1.rmrks status_txt,
                              ' '
                           || DECODE (9,
                                      1, 'القيود',
                                      2, 'الإيرادات',
                                      4, 'الادارة القانونية',
                                      'المصلحة')
                      FROM importers imp, importer_seizures is_1
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND is_1.hq_impr_nbr = imp.hq_impr_nbr
                           AND is_1.szr_status = 1
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           0,
                           0,
                           0,
                           0,
                              ' حجز المستوردات'
                           || ' بالقرار رقم '
                           || is_1.seizure_nbr
                           || ' وتاريخ '
                           || TO_CHAR (is_1.seizure_date, 'MI-MM-YYYY')
                           || DECODE (9, 4, '', ' ومبلغ الحجز ' || is_1.szr_amount)
                           || ' وتاريخ بداية الحجز '
                           || TO_CHAR (is_1.szr_strt_date, 'MI-MM-YYYY')
                           || ' '
                           || 'وسبب الحجز الرئيسي'
                           || ' '
                           || decode(is_1.IMPR_SZR_M_RSN_CD,null,'لا يوجد',IMPR_UTILITIES.get_main_szr_rsn(is_1.IMPR_SZR_M_RSN_CD))
                           || ' '
                           ||'وسبب الحجز الفرعي'
                           || ' '
                           || decode(is_1.IMPR_SZR_S_RSN_CD,null,'لا يوجد',IMPR_UTILITIES.get_sub_szr_rsn(is_1.IMPR_SZR_M_RSN_CD,is_1.IMPR_SZR_S_RSN_CD))
                           || ' '
                           || is_1.rmrks,
                              ' '
                           || DECODE (9,
                                      1, 'القيود',
                                      2, 'الإيرادات',
                                      4, 'الادارة القانونية',
                                      'المصلحة')
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           4,
                           ci.port_cd,
                           ci.impr_nbr,
                              ' تعليمة جمركية رقم '
                           || ci.inst_isn
                           || ' وتاريخ '
                           || TO_CHAR (ci.inst_dt, 'MI-MM-YYYY')
                           || ' مصدرها '
                           || ci.inst_source
                           || ' رقم القرار '
                           || ci.dcre_nbr
                           || ' وتاريخ القرار '
                           || TO_CHAR (ci.dcre_dt, 'MI-MM-YYYY')
                           || '  '
                           || ci.notes,
                           'الجمرك'
                      FROM importers imp, cstms_insts ci
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND ci.port_cd = imp.port_cd
                           AND ci.impr_nbr = imp.impr_nbr
                           AND ci.inst_type = 1
                           AND ci.inst_status = 1
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           4,
                           ci.port_cd,
                           ci.impr_nbr,
                              ' تعليمة جمركية رقم '
                           || ci.inst_isn
                           || ' وتاريخ '
                           || TO_CHAR (ci.inst_dt, 'MI-MM-YYYY')
                           || ' مصدرها '
                           || ci.inst_source
                           || ' رقم القرار '
                           || ci.dcre_nbr
                           || ' وتاريخ القرار '
                           || TO_CHAR (ci.dcre_dt, 'MI-MM-YYYY')
                           || '  '
                           || ci.notes,
                           'الجمرك'
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           DECODE (blk_deploy_dt, NULL, 1, 0),
                           5,
                           DECODE (blk.port_cd, NULL, blk.port_cd, 0),
                           0,
                              ' عدم تسديد فروقات الرسوم الجمركية يمسلسل '
                           || blk.blk_isn
                           || ' وتاريخ '
                           || TO_CHAR (blk.blk_start_dt, 'MI-MM-YYYY')
                           || DECODE (blk.diff_duty_amount,
                                      0, '',
                                      ' ومبلغ الفرق ' || blk.diff_duty_amount)
                           || DECODE (
                                 blk.blk_deploy_dt,
                                 NULL, '',
                                    ' وتاريخ تعميم الإيقاف '
                                 || TO_CHAR (blk.blk_deploy_dt, 'MI-MM-YYYY'))
                           || DECODE (blk.BLK_PORT_CD,
                                      NULL, '',
                                      ' ورمز جمرك الإيقاف ' || blk.BLK_PORT_CD)
                           || DECODE (blk.DIFFERENCE_ISN,
                                      NULL, '',
                                      ' ورقم مسلسل الفرق  ' || blk.DIFFERENCE_ISN)
                           || ' '
                           || blk.blk_rls_rmrks,
                           'التدقيق العام'
                      FROM importers         imp,
                           impr_duty_diff_blks blk,
                           cg_ref_codes      cg1,
                           cg_ref_codes      cg2,
                           cg_ref_codes      cg3
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND blk.hq_impr_nbr = imp.hq_impr_nbr
                           AND blk.blk_rls_dt IS NULL
                           AND cg1.rv_domain = 'BLK_RSN_CD'
                           AND cg1.rv_low_value = blk.blk_rsn_cd
                           AND cg2.rv_domain = 'BLK_SIDE_CD'
                           AND cg2.rv_low_value = blk.blk_side_cd
                           AND cg3.rv_domain = 'BLK_TYPE'
                           AND cg3.rv_low_value = blk.blk_type
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           DECODE (blk_deploy_dt, NULL, 1, 0),
                           5,
                           DECODE (blk.port_cd, NULL, blk.port_cd, 0),
                           0,
                              ' عدم تسديد فروقات الرسوم الجمركية يمسلسل '
                           || blk.blk_isn
                           || ' وتاريخ '
                           || TO_CHAR (blk.blk_start_dt, 'MI-MM-YYYY')
                           || DECODE (blk.diff_duty_amount,
                                      0, '',
                                      ' ومبلغ الفرق ' || blk.diff_duty_amount)
                           || DECODE (
                                 blk.blk_deploy_dt,
                                 NULL, '',
                                    ' وتاريخ تعميم الإيقاف '
                                 || TO_CHAR (blk.blk_deploy_dt, 'MI-MM-YYYY'))
                           || DECODE (blk.BLK_PORT_CD,
                                      NULL, '',
                                      ' ورمز جمرك الإيقاف ' || blk.BLK_PORT_CD)
                           || DECODE (
                                 blk.DIFFERENCE_ISN,
                                 NULL, '',
                                 ' ورقم مسلسل الفرق  ' || blk.DIFFERENCE_ISN)
                           || ' '
                           || blk.blk_rls_rmrks,
                           'التدقيق العام'
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           0,
                           6,
                           0,
                           0,
                              ' ملاحظة تفتبش دقيق يمسلسل '
                           || ins.inspctn_isn
                           || ' ورقم القرار '
                           || ins.decree_nbr
                           || ' وتاريخ '
                           || TO_CHAR (ins.decree_dt, 'MI-MM-YYYY')
                           || ins.decree_rsn,
                           'القيود'
                      FROM importers imp, impr_accur_inspctns ins
                     WHERE     imp.bus_id = v_p_bus_id
                           AND (ins.hq_impr_nbr = imp.hq_impr_nbr)
                           AND imp.PORT_CD = v_p_curr_port_cd
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           0,
                           6,
                           0,
                           0,
                              ' ملاحظة تفتبش دقيق يمسلسل '
                           || ins.inspctn_isn
                           || ' ورقم القرار '
                           || ins.decree_nbr
                           || ' وتاريخ '
                           || TO_CHAR (ins.decree_dt, 'MI-MM-YYYY')
                           || ins.decree_rsn,
                           'القيود'
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           7,
                           imp.port_cd port_cd_f1,
                           imp.impr_nbr impr_nbr_f1,
                              ' قضية غير مقفلة على هذا المستورد وحالة القضية هي ( '
                           || rv_meaning
                           || ')'
                           || ' رقم القضية ( '
                           || case_accuseds.case_seq
                           || ')'
                           || ' تاريخ القضية ( '
                           || TO_CHAR (case_accuseds.case_date, 'MI-MM-YYYY')
                           || ')'
                              txt_f1,
                           ' '
                      FROM importers imp,
                           case_accuseds,
                           cg_ref_codes,
                           customs_cases
                     WHERE     rv_domain = 'CASE_STAGE'
                           AND rv_low_value = CASE_STAGE
                           AND CASE_STAGE != 21
                           AND imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND case_accuseds.port_cd = imp.port_cd
                           AND case_accuseds.impr_nbr = imp.impr_nbr
                           AND accused_type = 1
                           AND case_accuseds.port_cd = customs_cases.port_cd
                           AND case_accuseds.case_seq = customs_cases.case_seq
                           AND case_accuseds.case_date = customs_cases.case_date
                           AND v_pselect1 = 1
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           7,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' قضية غير مقفلة على هذا المستورد وحالة القضية هي ( '
                           || rv_meaning
                           || ')'
                           || ' رقم القضية ( '
                           || case_accuseds.case_seq
                           || ')'
                           || ' تاريخ القضية ( '
                           || TO_CHAR (case_accuseds.case_date, 'MI-MM-YYYY')
                           || ')',
                           ' '
                  ---------------------------------------------------------------------------------------
                  ---------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           8,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد يوجد تعهد فاتورة للمستورد لم يسدد '
                           || '   برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                      FROM importers imp, waivers wvr, wvr_items wi
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND wi.wvr_port_cd = wvr.wvr_port_cd
                           AND wi.wvr_seq_nbr = wvr.wvr_seq_nbr
                           AND wi.issued_dt = wvr.issued_dt
                           AND wi.item_type_cd = 1
                           AND wvr.wvr_status = 1
                           AND wvr.wvr_port_cd = imp.port_cd(+)
                           AND wvr.impr_nbr = imp.impr_nbr(+)
                           AND (wi.item_status IS NULL OR wi.item_status = '0')
                           AND wi.item_end_dt < v_cf_curr_dt
                           AND TO_CHAR (wi.item_issue_dt, 'YYYY-MM-MI') > '1427-02-26'
                           AND v_p_curr_port_cd != 99
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           8,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد يوجد تعهد فاتورة للمستورد لم يسدد '
                           || '   برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           9,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد يوجد تعهد شهادة منشأ للمستورد  لم    يسدد '
                           || ' برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                      FROM importers imp, waivers wvr, wvr_items wi
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND wi.wvr_port_cd = wvr.wvr_port_cd
                           AND wi.wvr_seq_nbr = wvr.wvr_seq_nbr
                           AND wi.issued_dt = wvr.issued_dt
                           AND wi.item_type_cd = 2
                           AND wvr.wvr_status = 1
                           AND wvr.wvr_port_cd = imp.port_cd(+)
                           AND wvr.impr_nbr = imp.impr_nbr(+)
                           AND (wi.item_status IS NULL OR wi.item_status = '0')
                           AND wi.item_end_dt < v_cf_curr_dt
                           AND TO_CHAR (wi.item_issue_dt, 'YYYY-MM-MI') > '1427-02-26'
                           AND v_p_curr_port_cd != 99
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           9,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد يوجد تعهد شهادة منشأ للمستورد  لم    يسدد '
                           || ' برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           10,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد لهذا المستورد لوجود حرمان من ميزة الفسح بتعهد '
                           || ' برقم '
                           || ex.ed_dcre_nbr
                           || ' وتاريخ '
                           || TO_CHAR (ex.ed_dcre_date, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                      FROM importers imp, importer_excludeds ex
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND imp.hq_impr_nbr = ex.hq_impr_nbr
                           AND (ex.dcre_type = 1)
                           AND v_p_curr_port_cd != 99
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           10,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد لهذا المستورد لوجود حرمان من ميزة الفسح بتعهد '
                           || ' برقم '
                           || ex.ed_dcre_nbr
                           || ' وتاريخ '
                           || TO_CHAR (ex.ed_dcre_date, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           11,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد لهذا المستورد لوجود حرمان من ميزة الفسح بتعهد '
                           || ' برقم '
                           || ex.ed_dcre_nbr
                           || ' وتاريخ '
                           || TO_CHAR (ex.ed_dcre_date, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                      FROM importers imp, importer_excludeds ex, exclusion_decrees DEC
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND imp.hq_impr_nbr = ex.hq_impr_nbr
                           AND ex.dcre_type = 2
                           AND ex.ed_dcre_nbr = DEC.dcre_nbr
                           AND ex.ed_dcre_date = DEC.dcre_date
                           AND DEC.dcre_expr_date > v_cf_curr_dt
                           AND v_p_curr_port_cd != 99
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           11,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد لهذا المستورد لوجود حرمان من ميزة الفسح بتعهد '
                           || ' برقم '
                           || ex.ed_dcre_nbr
                           || ' وتاريخ '
                           || TO_CHAR (ex.ed_dcre_date, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                  ---------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           12,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد يوجد تعهد (عدم تصرف) منتهي للمستورد لم يسدد '
                           || ' برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                      FROM importers imp, waivers wvr, wvr_items wi
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND wi.wvr_port_cd = wvr.wvr_port_cd
                           AND wi.wvr_seq_nbr = wvr.wvr_seq_nbr
                           AND wi.issued_dt = wvr.issued_dt
                           AND wi.item_type_cd = 9
                           AND wvr.wvr_status = 1
                           AND wvr.wvr_port_cd = imp.port_cd(+)
                           AND wvr.impr_nbr = imp.impr_nbr(+)
                           AND (wi.item_status IS NULL OR wi.item_status = '0')
                           AND TO_CHAR (wi.item_end_dt, 'YYYY-MM-MI') <
                                  TO_CHAR (v_cf_curr_dt, 'YYYY-MM-MI')
                           --AND TO_CHAR (wi.item_end_dt, 'YYYY-MM-MI') < TO_CHAR(HIJDATE_DB.Cur_Hij_Date,'YYYY-MM-MI')
                           AND v_p_curr_port_cd != 99
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           12,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' لا يمكن إضافة تعهد جديد يوجد تعهد (عدم تصرف) منتهي للمستورد لم يسدد '
                           || ' برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                  --------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           13,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' توجد بضاعة ليس مسجل عليها دلالة منشأ سيتم إلزام المستورد بإعادة تصدير البضاعة وتغريمه 5000 ريال لوجود   تعهدات سابقة '
                           || ' برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                      FROM importers imp, wvr_items_globals wvr
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND wvr.wvr_port_cd = imp.port_cd(+)
                           AND wvr.impr_nbr = imp.impr_nbr(+)
                           AND wvr.item_type_cd = 7
                           AND wvr.bus_id = v_p_bus_id
                           AND (wvr.item_status <> 9 OR wvr.item_status IS NULL)
                           AND TO_CHAR (wvr.item_issue_dt, 'RRRR-MM-MI') >= '1430-02-01'
                           AND v_p_curr_port_cd != 99
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           13,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' توجد بضاعة ليس مسجل عليها دلالة منشأ سيتم إلزام المستورد بإعادة تصدير البضاعة وتغريمه 5000 ريال لوجود   تعهدات سابقة '
                           || ' برقم '
                           || wvr.wvr_seq_nbr
                           || ' وتاريخ '
                           || TO_CHAR (wvr.issued_dt, 'MI-MM-YYYY')
                           || ' ',
                           ' '
                  --------------------------------------------------------------------------------------
                  UNION ALL
                    SELECT imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           14,
                           imp.port_cd port_cd_f1,
                           imp.impr_nbr impr_nbr_f1,
                              ' إيقاف مركزي '
                           || ' من تاريخ '
                           || TO_CHAR (is_1.suspn_strt_dt, 'MI-MM-YYYY')
                           || ' إلى تاريخ '
                           || TO_CHAR (is_1.suspn_end_dt, 'MI-MM-YYYY')
                           || ' بسبب '
                           || is_1.suspn_rsn_text
                              txt_f1,
                           ' ' || cg1.rv_meaning
                      FROM importers imp, impr_cntrl_suspns is_1, cg_ref_codes cg1
                     WHERE     imp.bus_id = v_p_bus_id
                           AND imp.PORT_CD = v_p_curr_port_cd
                           AND is_1.hq_impr_nbr = imp.hq_impr_nbr
                           AND TO_CHAR (is_1.suspn_strt_dt, 'YYYY-MM-MI') <=
                                  TO_CHAR (v_cf_curr_dt, 'YYYY-MM-MI')
                           AND TO_CHAR (is_1.suspn_end_dt, 'YYYY-MM-MI') >=
                                  TO_CHAR (v_cf_curr_dt, 'YYYY-MM-MI')
                           AND is_1.suspn_rlse_dt IS NULL
                           AND cg1.rv_domain = 'SUSPN SIDE CD'
                           AND cg1.rv_low_value = is_1.suspn_side_cd
                  GROUP BY imp.bus_id,
                           imp.bus_id_brnch,
                           1,
                           14,
                           imp.port_cd,
                           imp.impr_nbr,
                              ' إيقاف مركزي '
                           || ' من تاريخ '
                           || TO_CHAR (is_1.suspn_strt_dt, 'MI-MM-YYYY')
                           || ' إلى تاريخ '
                           || TO_CHAR (is_1.suspn_end_dt, 'MI-MM-YYYY')
                           || ' بسبب '
                           || is_1.suspn_rsn_text,
                           ' ' || cg1.rv_meaning
                  ---------------------------------------------------------------------------------------
                  --------------------------------------------------------------------------------------
                  ---------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                  ---------------------------------------------------------------------------------------
                  ---------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                  ORDER BY 3, 5, 4
