# ----------------------------------------------------------------------------- interactive grid (IMPR1116: read-only grids only)
def ig(page, plug_key, cols, hidden, empty_msg, rows_per_page=None, search=False):
    """read-only IG (spec 3): f345 standard 8 defaults; search=True -> the search-page variant of IMPR1120 112001"""
    gk, rk, vk = '%s:ig' % page, '%s:igr' % page, '%s:igv' % page
    nid(gk, 3); nid(rk, 3); nid(vk, 3)
    prm = [('p_id', ref(gk)), ('p_internal_uid', str(page) + '000201'), ('p_is_editable', 'false')]
    prm += [('p_lazy_loading', 'true' if search else 'false'), ('p_requires_filter', 'false'), ('p_select_first_row', 'true'),
            ('p_fixed_row_height', 'true'), ('p_pagination_type', q('SET')),
            ('p_show_total_row_count', 'true'), ('p_no_data_found_message', q(empty_msg)),
            ('p_show_toolbar', 'true'),
            ('p_toolbar_buttons', q('ACTIONS_MENU:RESET' if search else 'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET')),
            ('p_enable_save_public_report', 'false'), ('p_enable_subscriptions', 'true'), ('p_enable_flashback', 'true'),
            ('p_define_chart_view', 'true'), ('p_enable_download', 'true'), ('p_download_formats', q('CSV:HTML:XLSX:PDF')),
            ('p_enable_mail_download', 'true'), ('p_fixed_header', q('PAGE')), ('p_show_icon_view', 'false'), ('p_show_detail_view', 'false')]
    out = [call('create_interactive_grid', prm)]
    out.append(call('create_ig_report', [('p_id', ref(rk)), ('p_interactive_grid_id', ref(gk)), ('p_static_id', q(str(page) + '000202')),
                                         ('p_type', q('PRIMARY')), ('p_default_view', q('GRID')),
                                         ('p_rows_per_page', str(rows_per_page) if rows_per_page else None),
                                         ('p_show_row_number', 'false'), ('p_settings_area_expanded', 'true')]))
    if rows_per_page:
        UNCERTAIN.add('create_ig_report p_rows_per_page => %d (Forms Records Displayed; not in f345, IMPR1120 uses it)' % rows_per_page)
    out.append(call('create_ig_report_view', [('p_id', ref(vk)), ('p_report_id', ref(rk)), ('p_view_type', q('GRID')),
                                              ('p_stretch_columns', 'true'), ('p_srv_exclude_null_values', 'false'),
                                              ('p_srv_only_display_columns', 'true'), ('p_edit_mode', 'false')]))
    for i, name in enumerate(cols):
        key = '%s:igc:%s' % (page, name)
        nid(key, 3)
        out.append(call('create_ig_report_column', [('p_id', ref(key)), ('p_view_id', ref(vk)), ('p_display_seq', str(i)),
                                                    ('p_column_id', ref('%s:col:%s' % (page, name))),
                                                    ('p_is_visible', 'false' if name in hidden else 'true'), ('p_is_frozen', 'false')]))
    return out

# ----------------------------------------------------------------------------- design (spec 0-13)
# page 1116, Form region IMPR_PRTL_NAT (spec 4.1) - Forms navigation order
MASTER_ITEMS = [
    dict(name='P1116_ROW_ID', kind='NATIVE_HIDDEN', column='ROWID', data_type='ROWID', pk=True,
         comment='Source: IMPR1116.IMPR_PRTL_NAT key mode ROWID (Form region primary key, = P0_PAGE_PK)'),
    dict(name='P1116_PRTL_NAT_ISN', kind='NATIVE_DISPLAY_ONLY', label='مسلسل', column='PRTL_NAT_ISN', data_type='NUMBER',
         span=2, send=True, comment='Source: IMPR1116.IMPR_PRTL_NAT.PRTL_NAT_ISN (Update Allowed = No); sent: key of the PRE-UPDATE activity log'),
    dict(name='P1116_IMPR_TYPE_CD', kind='NATIVE_HIDDEN', column='IMPR_TYPE_CD', data_type='NUMBER',
         comment='Source: IMPR1116.IMPR_PRTL_NAT.IMPR_TYPE_CD (Visible = No) - bind of the IMPORTERS grid'),
    dict(name='P1116_CTRY_CD', kind='NATIVE_HIDDEN', column='CTRY_CD', data_type='NUMBER',
         comment='Source: IMPR1116.IMPR_PRTL_NAT.CTRY_CD (Visible = No) - bind of the IMPORTERS grid'),
    dict(name='P1116_BUS_ID_TYPE_CD', kind='NATIVE_HIDDEN', column='BUS_ID_TYPE_CD', data_type='NUMBER',
         comment='Source: IMPR1116.IMPR_PRTL_NAT.BUS_ID_TYPE_CD (Visible = No) - bind of the IMPORTERS grid'),
    dict(name='P1116_BUS_ID', kind='NATIVE_HIDDEN', column='BUS_ID', data_type='VARCHAR2',
         comment='Source: IMPR1116.IMPR_PRTL_NAT.BUS_ID (Visible = No) - bind of the IMPORTERS grid'),
    dict(name='P1116_BUS_ID_BRNCH', kind='NATIVE_HIDDEN', column='BUS_ID_BRNCH', data_type='VARCHAR2',
         comment='Source: IMPR1116.IMPR_PRTL_NAT.BUS_ID_BRNCH (Visible = No) - bind of the IMPORTERS grid (NVL ..., 0)'),
    dict(name='P1116_ID_TYPE_GZT', kind='NATIVE_DISPLAY_ONLY', label='نوع السجل', column='ID_TYPE_GZT', data_type='VARCHAR2',
         lov='LOV_ID_TYPE_GZT', newline=False, span=3,
         comment='Source: IMPR1116.IMPR_PRTL_NAT.ID_TYPE_GZT (list item, CG_REF_CODES ID_TYPE_GZT; Update Allowed = No)'),
    dict(name='P1116_BUS_ID_NEW', kind='NATIVE_DISPLAY_ONLY', label='رقم السجل', column='BUS_ID_NEW', data_type='VARCHAR2',
         newline=False, span=3, comment='Source: IMPR1116.IMPR_PRTL_NAT.BUS_ID_NEW (Update Allowed = No)'),
    dict(name='P1116_GAZT_NAME', kind='NATIVE_DISPLAY_ONLY', label='الاسم', column='GAZT_NAME', data_type='VARCHAR2',
         span=8, comment='Source: IMPR1116.IMPR_PRTL_NAT.GAZT_NAME (Update Allowed = No)'),
    dict(name='P1116_REVIEW_FLAG', kind='NATIVE_SELECT_LIST', label='حالة المراجعة', column='REVIEW_FLAG', data_type='NUMBER',
         lov='LOV_PRTL_NAT_FLAG', newline=False, span=4, read_only=('P0_PAGE_PK', 'ITEM_IS_NULL'),
         comment='Source: IMPR1116.IMPR_PRTL_NAT.REVIEW_FLAG (list item, CG_REF_CODES PRTL_NAT_FLAG; the only updatable item)'),
]
IMPORTERS_COLUMNS = [
    dict(name='ROW_ID', kind='HIDDEN', data_type='VARCHAR2', pk=True, comment='Source: IMPR1116.IMPORTERS ROWID (grid key)'),
    dict(name='PORT_CD', kind='DISPLAY', data_type='NUMBER', heading='الجمرك', comment='Source: IMPR1116.IMPORTERS.PORT_CD'),
    dict(name='IMPR_NBR', kind='DISPLAY', data_type='NUMBER', heading='الرقم', comment='Source: IMPR1116.IMPORTERS.IMPR_NBR'),
    dict(name='HQ_IMPR_NBR', kind='HIDDEN', data_type='NUMBER', comment='Source: IMPR1116.IMPORTERS.HQ_IMPR_NBR (Visible = No)'),
    dict(name='IMPR_TYPE_CD', kind='HIDDEN', data_type='NUMBER', comment='Source: IMPR1116.IMPORTERS.IMPR_TYPE_CD (Visible = No)'),
    dict(name='BUS_ID_TYPE_CD', kind='HIDDEN', data_type='NUMBER', comment='Source: IMPR1116.IMPORTERS.BUS_ID_TYPE_CD (Visible = No)'),
    dict(name='BUS_ID', kind='HIDDEN', data_type='VARCHAR2', comment='Source: IMPR1116.IMPORTERS.BUS_ID (Visible = No)'),
    dict(name='BUS_ID_BRNCH', kind='HIDDEN', data_type='VARCHAR2', comment='Source: IMPR1116.IMPORTERS.BUS_ID_BRNCH (Visible = No)'),
    dict(name='L_IT1_IMPR_TYPE_NAME', kind='DISPLAY', data_type='VARCHAR2', heading='نوع المستورد',
         comment='Source: IMPR1116.IMPORTERS.L_IT1_IMPR_TYPE_NAME (POST-QUERY CGFK$QRY_IMPORTERS_IMP_ITIDT_F -> outer join)'),
    dict(name='ARBC_IMPR_NAME', kind='DISPLAY', data_type='VARCHAR2', heading='اسم المستورد', comment='Source: IMPR1116.IMPORTERS.ARBC_IMPR_NAME'),
    dict(name='L_BIT_BUS_ID_TYPE_NAME', kind='DISPLAY', data_type='VARCHAR2', heading='مسمى الاستدلالى',
         comment='Source: IMPR1116.IMPORTERS.L_BIT_BUS_ID_TYPE_NAME (POST-QUERY CGFK$QRY_IMPORTERS_IMP_ITIDT_F -> outer join)'),
]
IMPORTERS_SQL = '\n'.join([
    '-- Forms block IMPORTERS: WHERE on the current IMPR_PRTL_NAT record + POST-QUERY lookup CGFK$QRY_IMPORTERS_IMP_ITIDT_F',
    'SELECT ROWIDTOCHAR(i.ROWID) AS row_id,',
    '       i.port_cd,',
    '       i.impr_nbr,',
    '       i.hq_impr_nbr,',
    '       i.impr_type_cd,',
    '       i.bus_id_type_cd,',
    '       i.bus_id,',
    '       i.bus_id_brnch,',
    '       l_it1.impr_type_name   AS l_it1_impr_type_name,',
    '       i.arbc_impr_name,',
    '       l_bit.bus_id_type_name AS l_bit_bus_id_type_name',
    '  FROM importers i,',
    '       impr_type_id_types l_itidt,',
    '       impr_types l_it1,',
    '       bus_id_types l_bit',
    ' WHERE i.impr_type_cd   = :P1116_IMPR_TYPE_CD',
    '   AND i.ctry_cd        = :P1116_CTRY_CD',
    '   AND i.bus_id_type_cd = :P1116_BUS_ID_TYPE_CD',
    '   AND i.bus_id         = :P1116_BUS_ID',
    '   AND NVL(i.bus_id_brnch, 0) = NVL(:P1116_BUS_ID_BRNCH, 0)',
    '   AND l_itidt.impr_type_cd (+)   = i.impr_type_cd',
    '   AND l_itidt.bus_id_type_cd (+) = i.bus_id_type_cd',
    '   AND l_it1.impr_type_cd (+)     = l_itidt.impr_type_cd',
    '   AND l_bit.bus_id_type_cd (+)   = l_itidt.bus_id_type_cd'])
SEARCH_SQL = '\n'.join([
    '-- Forms block IMPR_PRTL_NAT query: WHERE REVIEW_FLAG = 0 AND GAZT_NAME IS NOT NULL (IMPR1116.IMPR_PRTL_NAT_IS_PENDING);',
    "-- optional search text over every shown column. URL-safe ROWID: a '+' in f?p arrives as a space.",
    "SELECT TRANSLATE(ROWIDTOCHAR(n.ROWID), '+/', '-_') AS row_id,",
    '       n.prtl_nat_isn,',
    '       n.id_type_gzt,',
    '       (SELECT r.rv_meaning FROM cg_ref_codes r',
    "         WHERE r.rv_domain = 'ID_TYPE_GZT' AND r.rv_low_value = n.id_type_gzt AND ROWNUM = 1) AS id_type_gzt_name,",
    '       n.bus_id_new,',
    '       n.gazt_name',
    '  FROM impr_prtl_nat n',
    " WHERE (SELECT IMPR1116.IMPR_PRTL_NAT_IS_PENDING(REVIEW_FLAG => n.review_flag, GAZT_NAME => n.gazt_name) FROM dual) = 'Y'",
    '   AND (:P111601_SEARCH IS NULL',
    "        OR INSTR(UPPER(n.prtl_nat_isn || '|' || n.id_type_gzt || '|' || n.bus_id_new || '|' || n.gazt_name),",
    '                 UPPER(TRIM(:P111601_SEARCH))) > 0)'])
SEARCH_COLUMNS = [
    ('ROW_ID', None, 'VARCHAR2'), ('PRTL_NAT_ISN', 'مسلسل', 'NUMBER'), ('ID_TYPE_GZT', 'رمز نوع السجل', 'VARCHAR2'),
    ('ID_TYPE_GZT_NAME', 'نوع السجل', 'VARCHAR2'), ('BUS_ID_NEW', 'رقم السجل', 'VARCHAR2'), ('GAZT_NAME', 'الاسم', 'VARCHAR2')]
NEW_LOVS = [  # spec 6
    ('LOV_ID_TYPE_GZT', lov_apx.call('REFERENCE_CODES', P_DOMAIN='ID_TYPE_GZT'),
     'list item IMPR_PRTL_NAT.ID_TYPE_GZT (CGDV$POPULATE_DYNAMIC_LISTS)'),
    ('LOV_PRTL_NAT_FLAG', lov_apx.call('REFERENCE_CODES', P_DOMAIN='PRTL_NAT_FLAG'),
     'list item IMPR_PRTL_NAT.REVIEW_FLAG (CGDV$POPULATE_DYNAMIC_LISTS)')]
PRE_UPDATE = ('IMPR1116.PRE_UPDATE(P_PRTL_NAT_ISN => :P1116_PRTL_NAT_ISN, P_CURR_PORT_CD => :P_CURR_PORT_CD, '
              'SSO_APP_USER => :SSO_APP_USER, P_GLOBAL_V_WS_ID => :P_GLOBAL_V_WS_ID);')

# ----------------------------------------------------------------------------- generation
def gen():
    out = []
    W = out.append
    W('''-- =============================================================================
-- REVIEW BEFORE IMPORT
-- File        : apex/IMPR1116/f345_impr1116.sql
-- Generated by: Claude Code (scripts/gen_apex_impr1116.py, step 04 revision 1) from
--               analysis/IMPR1116/IMPR1116_apex_page_spec.md, %s, form IMPR1116
-- Target      : Oracle APEX 21.2 (export version 2021.10.15), Oracle Database 12.1.0.2,
--               reference application f345 (apex/Reference/f345.sql)
-- Standard    : CLAUDE.md 4b / 4c, docs/f345_reference_standard.md 3-9: Form region (ROWID, update only),
--               read-only Interactive Grid detail, one-line calls into package IMPR1116 (version 001).
--               No JavaScript action, no AJAX callback.
-- Contents    : component export INTO the application installed from f345 AND already holding the
--               IMPR1110 export (page group IMPR is reused):
--               pages 1116 (main) and 111601 (search) + 2 LOVs.
-- Placeholders: __WORKSPACE_ID__, __APP_ID__, __SCHEMA_NAME__, __ID_OFFSET__ - see apex/IMPR1116/import_notes.md
-- WARNING     : generated wwv_flow_api code is not an officially supported way to build APEX
--               applications. Import into a DEV workspace first, back up the application,
--               review every page in Page Designer.
-- Status      : NOT IMPORTED.
-- =============================================================================
prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
begin
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2021.10.15'
,p_release=>'21.2.0'
,p_default_workspace_id=>__WORKSPACE_ID__
,p_default_application_id=>__APP_ID__
,p_default_id_offset=>__ID_OFFSET__
,p_default_owner=>'__SCHEMA_NAME__'
);
end;
/
''' % DATE)
    # ---------------------------------------------------------------- shared components (spec 13)
    UNCERTAIN.add(lov_apx.UNCERTAIN)
    for name, sql, s in NEW_LOVS:
        nid('9116:lov:' + name, 5)
        W(block('application/shared_components/user_interface/lovs/' + name.lower(), call('create_list_of_values', [
            ('p_id', ref('9116:lov:' + name)), ('p_lov_name', q(name))] + lov_apx.lov_attributes(sql, q),
            'Source: IMPR1116 ' + s + ' / spec 6')))

    # ---------------------------------------------------------------- page 1116 (spec 2-12)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG)
    A(call('create_page', [
        ('p_id', str(PG)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM)), ('p_alias', q(FORM)),
        ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('Y')), ('p_autocomplete_on_off', q('OFF')),
        ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']), ('p_step_template', fid('PAGE_MAIN')),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_protection_level', q('C')),
        ('p_page_comment', src('IMPR1116.fmb (window CGSO$WINDOW_1, canvas CG$PAGE_1) / spec 2')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: IMPR1116.fmb - spec 2 / f345 standard 4'))
    hero = ('<div class="cg-hero-row"><div class="cg-hero-top"><span class="cg-hero-ic fa fa-check-square-o" aria-hidden="true"></span>'
            '<div><div class="cg-hero-k">المستوردون</div><div class="cg-hero-t">&P1116_HERO_TITLE.</div>'
            '<div class="cg-hero-d">مراجعة بيانات رقم المنشأة 700 المدخلة من البوابة</div></div></div></div>')
    nid('1116:plug:IMPR_PRTL_NAT_HERO', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1116:plug:IMPR_PRTL_NAT_HERO')), ('p_plug_name', q('الهيدر')), ('p_region_name', q('IMPR_PRTL_NAT_HERO')),
        ('p_region_css_classes', q('cg-hero')), ('p_region_template_options', q('#DEFAULT#')), ('p_plug_template', fid('REGION_HERO')),
        ('p_plug_display_sequence', '10'), ('p_plug_source', q(hero)), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_attribute_01', q('N')), ('p_attribute_02', q('HTML')), ('p_plug_comment', src('IMPR1116.TITLE (OLB) -> f345 hero / spec 3'))]))
    nid('1116:plug:IMPR_PRTL_NAT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1116:plug:IMPR_PRTL_NAT')), ('p_plug_name', q('بيانات رقم المنشأة 700 للمستورد')), ('p_region_name', q('IMPR_PRTL_NAT')),
        ('p_region_css_classes', q('zatca-forms cg-form cg-card')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_FORM')), ('p_plug_display_sequence', '20'), ('p_query_type', q('TABLE')),
        ('p_query_table', q('IMPR_PRTL_NAT')), ('p_include_rowid_column', 'true'), ('p_is_editable', 'true'),
        ('p_edit_operations', q('u')), ('p_lost_update_check_type', q('VALUES')),
        ('p_plug_source_type', q('NATIVE_FORM')), ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1116.IMPR_PRTL_NAT (Insert / Delete Allowed = No, only REVIEW_FLAG updatable; key mode ROWID; '
                               'one record from page 111601, spec decision 1) / spec 3'))]))
    UNCERTAIN.add("Form region p_edit_operations => 'u' (update only; IMPR1110 uses 'i:u')")
    UNCERTAIN.add('ROWID primary key of the Form region: p_include_rowid_column, item source ROWID / p_source_data_type ROWID (as IMPR1110)')
    nid('1116:plug:IMPORTERS', 1)
    A(call('create_page_plug', [
        ('p_id', ref('1116:plug:IMPORTERS')), ('p_plug_name', q('المستوردين')), ('p_region_name', q('IMPORTERS')),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', '30'), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(IMPORTERS_SQL)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q('P1116_IMPR_TYPE_CD,P1116_CTRY_CD,P1116_BUS_ID_TYPE_CD,P1116_BUS_ID,P1116_BUS_ID_BRNCH')),
        ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_display_condition_type', q('ITEM_IS_NOT_NULL')), ('p_plug_display_when_condition', q('P0_PAGE_PK')),
        ('p_plug_comment', src('IMPR1116.IMPORTERS (query only; WHERE on :IMPR_PRTL_NAT.*, requeried by IMPR_PRTL_NAT.WHEN-NEW-RECORD-INSTANCE; '
                               'POST-QUERY lookup as outer joins) / spec 3'))]))
    for i, c in enumerate(IMPORTERS_COLUMNS):
        A(ig_column(PG, c, (i + 1) * 10))
    for c in ig(PG, '1116:plug:IMPORTERS', [c['name'] for c in IMPORTERS_COLUMNS],
                {c['name'] for c in IMPORTERS_COLUMNS if c['kind'] == 'HIDDEN'},
                'لا يوجد مستوردون بنفس بيانات التعريف', rows_per_page=10):
        A(c)
    # branch (spec 12)
    nid('1116:branch:STAY', 3)
    A(call('create_page_branch', [
        ('p_id', ref('1116:branch:STAY')), ('p_branch_name', q('IMPR1116 - stay in the form')),
        ('p_branch_action', q('f?p=&APP_ID.:1116:&SESSION.::&DEBUG.:::&success_msg=#SUCCESS_MSG#')),
        ('p_branch_point', q('AFTER_PROCESSING')), ('p_branch_type', q('REDIRECT_URL')), ('p_branch_sequence', '10'),
        ('p_branch_comment', src('Forms stays in the form after COMMIT / spec 12'))]))
    # items (spec 4.1, 4.2)
    for i, it in enumerate(MASTER_ITEMS, 1):
        A(page_item(PG, '1116:plug:IMPR_PRTL_NAT', i * 10, it, form_region=True))
    for seq, it in [(10, dict(name='P1116_HERO_TITLE', kind='NATIVE_HIDDEN', value_protected='Y',
                              comment='Source: IMPR1116.TITLE (OLB) - shown by the hero region (&P1116_HERO_TITLE.)')),
                    (20, dict(name='P1116_MODULE_ID', kind='NATIVE_HIDDEN', value_protected='Y', protect='S',
                              comment='Source: IMPR1116 :PARAMETER.P_MODULE_ID (f345, kept by SCREEN ENTRY RESET)'))]:
        A(page_item(PG, '1116:plug:IMPR_PRTL_NAT_HERO', seq, it))
    # processes (spec 8)
    NEW = 'NULL;  -- f345 session setup (SSO_APP_USER, P_CURR_PORT_CD, V_USR_TYPE ...) is done by the application; disabled as in AGR1100'
    BH, AS = 'BEFORE_HEADER', 'AFTER_SUBMIT'
    procs = [
        (BH, 10, 'New', NEW, ('', 'NEVER'), 'f345 session setup copied from AGR1100 (condition Never, as in AGR1100 / IMPR1120) / standard 6', {}),
        (BH, 20, 'P0_PAGE_PK CHECK', 'IMPR1116.P0_PAGE_PK_CHECK(P_PAGE_PK => :P0_PAGE_PK);', None, 'f345 record key / spec 8', {}),
        (BH, 40, 'PARAMETERS', ":P1116_MODULE_ID := FORMS_APX.GET_MODULE_ID(P_MODULE_ID => :P1116_MODULE_ID, FORM_NAME => 'IMPR1116');",
         None, 'f345 / spec 8', {}),
        (BH, 70, 'P0_PAGE_PK', ':P1116_ROW_ID := :P0_PAGE_PK;', None, 'f345 (key = ROWID) / spec 8', {}),
        (BH, 80, 'Initialize form', None, None, 'IMPR1116 block IMPR_PRTL_NAT fetch / spec 8',
         dict(ptype='NATIVE_FORM_INIT', region='1116:plug:IMPR_PRTL_NAT')),
        (BH, 100, 'HEADER TITLE', "FORMS_APX.HEADER_TITLE(P_MODULE_ID => :P1116_MODULE_ID, P_HERO_TITLE => :P1116_HERO_TITLE, "
                                  "DEFAULT_TITLE => 'استعراض بيانات رقم المنشأة 700 المدخلة من البوابة');",
         None, 'f345 (OLB block TITLE) / spec 8', {}),
        (AS, 10, 'PRE-INSERT', 'IMPR1116.PRE_INSERT;', (":P0_PAGE_PK IS NULL AND :REQUEST = 'CREATE'", 'EXPRESSION', 'PLSQL'),
         'IMPR1116.IMPR_PRTL_NAT.PRE-INSERT (block Insert Allowed = No) / spec 8', {}),
        (AS, 20, 'PRE-UPDATE', PRE_UPDATE, (":P0_PAGE_PK IS NOT NULL AND :REQUEST = 'SAVE'", 'EXPRESSION', 'PLSQL'),
         'IMPR1116.IMPR_PRTL_NAT.PRE-UPDATE (activity log) / spec 8', {}),
        (AS, 30, 'PRE-DELETE', 'IMPR1116.PRE_DELETE;', ('DELETE', 'REQUEST_EQUALS_CONDITION'),
         'IMPR1116.IMPR_PRTL_NAT.PRE-DELETE (block Delete Allowed = No) / spec 8', {}),
        (AS, 40, 'Process form', None, ('SAVE', 'REQUEST_EQUALS_CONDITION'), 'IMPR1116 Forms default UPDATE of block IMPR_PRTL_NAT / spec 8',
         dict(ptype='NATIVE_FORM_DML', region='1116:plug:IMPR_PRTL_NAT',
              extra=[('p_attribute_01', q('REGION_SOURCE')), ('p_attribute_05', q('Y')), ('p_attribute_06', q('Y')),
                     ('p_attribute_08', q('Y')), ('p_process_success_message', q('تم الحفظ بنجاح'))])),
    ]
    for point, seq, name, code, cond, s, kw in procs:
        key = '1116:proc:%s:%s' % (point, name)
        A(process(PG, key, seq, point, name, code, cond, s, ptype=kw.get('ptype', 'NATIVE_PLSQL'),
                  extra=kw.get('extra'), region=kw.get('region')))
    W(block('application/pages/page_01116', '\n'.join(P)))

    # ---------------------------------------------------------------- page 111601 (search, spec 3.2 / 4.4)
    P = []
    A = P.append
    A('wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>%d);' % PG_SEARCH)
    A(call('create_page', [
        ('p_id', str(PG_SEARCH)), ('p_user_interface_id', fid('UI')), ('p_name', q(FORM + '_SEARCH')), ('p_alias', q(FORM + '-SEARCH')),
        ('p_page_mode', q('MODAL')), ('p_step_title', q('&SYS_ANAME.')), ('p_warn_on_unsaved_changes', q('N')),
        ('p_autocomplete_on_off', q('OFF')), ('p_group_id', 'wwv_flow_api.id(%s)' % IMPR1110_IDS['PAGE_GROUP_IMPR']),
        ('p_page_css_classes', q('zf')), ('p_page_template_options', q('#DEFAULT#')), ('p_dialog_height', q('800')),
        ('p_dialog_width', q('1800')), ('p_protection_level', q('C')), ('p_first_item', q('AUTO_FIRST_ITEM')),
        ('p_page_comment', src('IMPR1116 Enter-Query / Execute-Query of block IMPR_PRTL_NAT / spec 2, 3')),
        ('p_last_upd_yyyymmddhh24miss', q(STAMP))], 'Source: f345 search page <page>01 (page 0 SEARCH)'))
    nid('111601:plug:CRIT', 1)
    A(call('create_page_plug', [
        ('p_id', ref('111601:plug:CRIT')), ('p_plug_name', q('بحث')), ('p_region_name', q('IMPR_PRTL_NAT_SEARCH_CRITERIA')),
        ('p_region_css_classes', q('zatca-forms cg-form')), ('p_region_template_options', q('#DEFAULT#')),
        ('p_plug_template', fid('REGION_HERO')), ('p_plug_display_sequence', '10'), ('p_attribute_01', q('N')),
        ('p_attribute_02', q('TEXT')), ('p_attribute_03', q('Y')),
        ('p_plug_comment', src('IMPR1116.IMPR_PRTL_NAT Enter-Query criteria, as one search text over all columns / spec 3'))]))
    nid('111601:plug:IG', 1)
    A(call('create_page_plug', [
        ('p_id', ref('111601:plug:IG')), ('p_plug_name', q('بيانات البوابة غير المراجعة')), ('p_region_name', q('IMPR_PRTL_NAT_SEARCH')),
        ('p_region_css_classes', q('cg-card cg-grid')), ('p_region_template_options', q('#DEFAULT#:t-Region--noPadding')),
        ('p_plug_template', fid('REGION_GRID')), ('p_plug_display_sequence', '20'), ('p_query_type', q('SQL')),
        ('p_plug_source', lit(SEARCH_SQL)), ('p_plug_source_type', q('NATIVE_IG')),
        ('p_ajax_items_to_submit', q('P111601_SEARCH')),
        ('p_plug_query_options', q('DERIVED_REPORT_COLUMNS')),
        ('p_plug_comment', src('IMPR1116.IMPR_PRTL_NAT block query (WHERE REVIEW_FLAG = 0 AND GAZT_NAME IS NOT NULL); pending rows shown at once, '
                               'optional search text (spec decision 2) / spec 3'))]))
    for i, (c, h, dt) in enumerate(SEARCH_COLUMNS):
        if c == 'ROW_ID':
            col = dict(name=c, kind='HIDDEN', data_type=dt, pk=True)
        elif c == 'PRTL_NAT_ISN':
            col = dict(name=c, kind='LINK', data_type=dt, heading=h,
                       link_target='f?p=&APP_ID.:1116:&SESSION.::&DEBUG.:1116:P0_PAGE_PK:&ROW_ID.', link_text='&PRTL_NAT_ISN.',
                       comment='Source: IMPR1116.IMPR_PRTL_NAT.PRTL_NAT_ISN - opens the record on page 1116 (P0_PAGE_PK = URL-safe ROWID)')
        else:
            col = dict(name=c, kind='DISPLAY', data_type=dt, heading=h)
        A(ig_column(PG_SEARCH, col, (i + 1) * 10))
    for c in ig(PG_SEARCH, '111601:plug:IG', [c for c, _, _ in SEARCH_COLUMNS], {'ROW_ID'},
                'لا توجد بيانات بوابة بانتظار المراجعة', search=True):
        A(c)
    UNCERTAIN.add('search IG: p_lazy_loading true, toolbar ACTIONS_MENU:RESET (own search text, as IMPR1120 112001)')
    A(page_item(PG_SEARCH, '111601:plug:CRIT', 10, dict(
        name='P111601_SEARCH', kind='NATIVE_TEXT_FIELD', label='بحث في كل الأعمدة', maxlen=200, span=6,
        comment='Source: IMPR1116.IMPR_PRTL_NAT query criteria (PRTL_NAT_ISN, ID_TYPE_GZT, BUS_ID_NEW, GAZT_NAME) as one text over all columns')))
    nid('111601:btn:SEARCH', 2)
    A(call('create_page_button', [
        ('p_id', ref('111601:btn:SEARCH')), ('p_button_sequence', '40'), ('p_button_plug_id', ref('111601:plug:CRIT')),
        ('p_button_name', q('SEARCH')), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
        ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q('بحث')), ('p_button_position', q('BODY')),
        ('p_icon_css_classes', q('fa-search')), ('p_button_css_classes', q('cg-b-search')),
        ('p_button_comment', src('IMPR1116 TOOLBAR.EXECUTE (Execute Query of block IMPR_PRTL_NAT) / spec 5'))]))
    nid('111601:btn:CLEAR', 2)
    A(call('create_page_button', [
        ('p_id', ref('111601:btn:CLEAR')), ('p_button_sequence', '50'), ('p_button_plug_id', ref('111601:plug:CRIT')),
        ('p_button_name', q('CLEAR')), ('p_button_action', q('DEFINED_BY_DA')), ('p_button_template_options', q('#DEFAULT#:t-Button--iconLeft')),
        ('p_button_template_id', fid('BUTTON')), ('p_button_image_alt', q('مسح البحث')), ('p_button_position', q('BODY')),
        ('p_icon_css_classes', q('fa-eraser')), ('p_button_css_classes', q('cg-b-clear')),
        ('p_button_comment', src('IMPR1116 TOOLBAR.CLEAR_ALL for the search / spec 5'))]))
    refresh = [('p_action', q('NATIVE_REFRESH')), ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', ref('111601:plug:IG'))]
    A(da(PG_SEARCH, 10, 'SEARCH WHEN-BUTTON-PRESSED', ('BUTTON', '111601:btn:SEARCH'), 'click', [refresh],
         'IMPR1116 TOOLBAR.EXECUTE / spec 10'))
    A(da(PG_SEARCH, 12, 'SEARCH KEY-ENTER', ('ITEM', 'P111601_SEARCH'), 'keyup', [refresh],
         'IMPR1116 KEY-EXEQRY (Enter in the search text; f345 AGR1100_SEARCH keyup pattern) / spec 10', cond='ENTER'))
    A(da(PG_SEARCH, 15, 'CLEAR WHEN-BUTTON-PRESSED', ('BUTTON', '111601:btn:CLEAR'), 'click',
         [[('p_action', q('NATIVE_CLEAR')), ('p_affected_elements_type', q('ITEM')), ('p_affected_elements', q('P111601_SEARCH'))], refresh],
         'IMPR1116 TOOLBAR.CLEAR_ALL (search criteria) / spec 10'))
    UNCERTAIN.add('NATIVE_CLEAR action with p_affected_elements (search CLEAR; as IMPR1120 112001)')
    UNCERTAIN.add('button DA: p_triggering_button_id (search SEARCH / CLEAR; IMPR1110 uses it)')
    ek, ak = '111601:da:Hide', '111601:daa:Hide:10'
    nid(ek, 8); nid(ak, 9)
    A(call('create_page_da_event', [('p_id', ref(ek)), ('p_name', q('Hide')), ('p_event_sequence', '20'),
                                    ('p_bind_type', q('bind')), ('p_bind_event_type', q('ready')),
                                    ('p_da_event_comment', src('f345 AGR1100_SEARCH "Hide" (page 0 toolbar not used in a dialog)'))]))
    A(call('create_page_da_action', [('p_id', ref(ak)), ('p_event_id', ref(ek)), ('p_event_result', q('TRUE')),
                                     ('p_action_sequence', '10'), ('p_execute_on_page_init', q('Y')), ('p_action', q('NATIVE_HIDE')),
                                     ('p_affected_elements_type', q('REGION')), ('p_affected_region_id', fid('P0_ACTIONS'))]))
    W(block('application/pages/page_111601', '\n'.join(P)))

    W('''prompt --application/end_environment
begin
wwv_flow_api.component_end;
end;
/
set verify on feedback on define on
prompt  ...done
''')
    text = '\n'.join(out)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    return text

