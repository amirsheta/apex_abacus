-- =============================================================================
-- utPLSQL v3 tests for IMPR1110 (pure logic only - no DML).
-- Run:  exec ut.run('test_impr1110');
-- Members that write globals (SET_GLOBAL -> FORMS_APX.set_global) need an APEX
-- session: the beforeall creates one when the app exists (app 2000 = placeholder).
-- Expected check digits for check_idno were computed with the same algorithm
-- (1000000008, 1234567897, 2100000005 valid).
-- Status: NOT executed - utPLSQL availability on the 12.1.0.2 DB is unknown.
-- =============================================================================
CREATE OR REPLACE PACKAGE test_impr1110
AS
    --%suite(IMPR1110 - IMPR1110)

    --%beforeall
    PROCEDURE setup_session;

    --%test(check_idno accepts valid national/iqama numbers)
    PROCEDURE idno_valid;
    --%test(check_idno rejects wrong check digit, length, letters, null)
    PROCEDURE idno_invalid;
    --%test(is_digit)
    PROCEDURE digit_cases;

    --%test(bank_iban adds SA prefix, removes spaces, upper-cases)
    PROCEDURE iban_normalise;
    --%test(bank_iban with wrong length raises -20000)
    --%throws(-20000)
    PROCEDURE iban_bad_length;
    --%test(bank_iban null or 'SA' is accepted)
    PROCEDURE iban_empty;

    --%test(eng_impr_name accepts letters/digits/spaces)
    PROCEDURE eng_name_ok;
    --%test(eng_impr_name rejects Arabic text)
    --%throws(-20000)
    PROCEDURE eng_name_arabic;

    --%test(b_mobile_no 9 digits starting with 5 ok)
    PROCEDURE mobile_ok;
    --%test(b_mobile_no with 10 digits raises)
    --%throws(-20000)
    PROCEDURE mobile_bad;

    --%test(b_email without @ raises)
    --%throws(-20000)
    PROCEDURE email_bad;
    --%test(impr_tel_nbr must be 10 digits)
    --%throws(-20000)
    PROCEDURE tel_bad;

    --%test(fun_allowed rules of ADJ_FUNS)
    PROCEDURE fun_rules;

    --%test(ui_state_json for existing record disables key items)
    PROCEDURE ui_existing;
    --%test(ui_state_json for new record CR type requires COMM_RGSTRTN_TYPE)
    PROCEDURE ui_new_cr;
END test_impr1110;
/

CREATE OR REPLACE PACKAGE BODY test_impr1110
AS
    FUNCTION ctx (p_class NUMBER DEFAULT 1, p_utype NUMBER DEFAULT 1, p_port NUMBER DEFAULT 1)
        RETURN IMPR1110.T_CONTEXT
    IS
        c IMPR1110.T_CONTEXT;
    BEGIN
        c.curr_port_cd := p_port;
        c.class_cd     := p_class;
        c.user_type    := p_utype;
        c.prsnl_impr   := 0;
        RETURN c;
    END ctx;

    PROCEDURE setup_session IS
    BEGIN
        apex_session.create_session(p_app_id => 2000, p_page_id => 1110, p_username => 'UT_TEST');
    EXCEPTION
        WHEN OTHERS THEN NULL;   -- no app yet: tests not touching globals still run
    END setup_session;

    PROCEDURE idno_valid IS
    BEGIN
        ut.expect(IMPR1110.check_idno('1000000008')).to_be_true();
        ut.expect(IMPR1110.check_idno('1234567897')).to_be_true();
        ut.expect(IMPR1110.check_idno('2100000005')).to_be_true();
    END idno_valid;

    PROCEDURE idno_invalid IS
    BEGIN
        ut.expect(IMPR1110.check_idno('1234567890')).to_be_false();
        ut.expect(IMPR1110.check_idno('123456789')).to_be_false();
        ut.expect(IMPR1110.check_idno('12345678A7')).to_be_false();
        ut.expect(IMPR1110.check_idno(NULL)).to_be_false();
    END idno_invalid;

    PROCEDURE digit_cases IS
    BEGIN
        ut.expect(IMPR1110.is_digit('0123456789')).to_be_true();
        ut.expect(IMPR1110.is_digit('12 3')).to_be_false();
        ut.expect(IMPR1110.is_digit('١٢٣')).to_be_false();   -- Arabic-Indic digits
        ut.expect(IMPR1110.is_digit(NULL)).to_be_false();
    END digit_cases;

    PROCEDURE iban_normalise IS
        r IMPR1110.T_RECORD;
    BEGIN
        r.bank_iban := '80 0000 0000 6080 1016 7519';      -- 22 chars without SA
        IMPR1110.BANK_IBAN_WHEN_VALIDATE_ITEM(r);
        ut.expect(r.bank_iban).to_equal('SA8000000000608010167519');
        r.bank_iban := 'sa8000000000608010167519';
        IMPR1110.BANK_IBAN_WHEN_VALIDATE_ITEM(r);
        ut.expect(r.bank_iban).to_equal('SA8000000000608010167519');
    END iban_normalise;

    PROCEDURE iban_bad_length IS
        r IMPR1110.T_RECORD;
    BEGIN
        r.bank_iban := 'SA80000';
        IMPR1110.BANK_IBAN_WHEN_VALIDATE_ITEM(r);
    END iban_bad_length;

    PROCEDURE iban_empty IS
        r IMPR1110.T_RECORD;
    BEGIN
        IMPR1110.BANK_IBAN_WHEN_VALIDATE_ITEM(r);
        ut.expect(r.bank_iban).to_be_null();
        r.bank_iban := 'SA';
        IMPR1110.BANK_IBAN_WHEN_VALIDATE_ITEM(r);
        ut.expect(r.bank_iban).to_equal('SA');
    END iban_empty;

    PROCEDURE eng_name_ok IS
        r IMPR1110.T_RECORD;
    BEGIN
        r.eng_impr_name := 'ALSAFI TRADING CO 2';
        IMPR1110.ENG_IMPR_NAME_VALIDATE_ITEM(r);
        ut.expect(r.eng_impr_name).to_equal('ALSAFI TRADING CO 2');
    END eng_name_ok;

    PROCEDURE eng_name_arabic IS
        r IMPR1110.T_RECORD;
    BEGIN
        r.eng_impr_name := 'شركة';
        IMPR1110.ENG_IMPR_NAME_VALIDATE_ITEM(r);
    END eng_name_arabic;

    PROCEDURE mobile_ok IS
        r IMPR1110.T_RECORD;
    BEGIN
        r.b_mobile_no := '512345678';
        IMPR1110.B_MOBILE_NO_WHEN_VALIDATE_ITEM(r, ctx);
        ut.expect(r.b_mobile_no).to_equal('512345678');
    END mobile_ok;

    PROCEDURE mobile_bad IS
        r IMPR1110.T_RECORD;
    BEGIN
        r.b_mobile_no := '0512345678';
        IMPR1110.B_MOBILE_NO_WHEN_VALIDATE_ITEM(r, ctx);
    END mobile_bad;

    PROCEDURE email_bad IS
        r IMPR1110.T_RECORD;
    BEGIN
        r.b_email := 'abc.com';
        IMPR1110.B_EMAIL_WHEN_VALIDATE_ITEM(r);
    END email_bad;

    PROCEDURE tel_bad IS
        r IMPR1110.T_RECORD;
    BEGIN
        r.impr_tel_nbr := '12345';
        IMPR1110.IMPR_TEL_NBR_VALIDATE_ITEM(r);
    END tel_bad;

    PROCEDURE fun_rules IS
        r IMPR1110.T_RECORD;
    BEGIN
        ut.expect(IMPR1110.fun_allowed('IMPR1110F1', r, ctx)).to_be_false();   -- no record
        ut.expect(IMPR1110.fun_allowed('IMPR1110F2', r, ctx)).to_be_false();
        r.impr_nbr := 3000001;
        ut.expect(IMPR1110.fun_allowed('IMPR1110F1', r, ctx)).to_be_true();
        ut.expect(IMPR1110.fun_allowed('IMPR1110F3', r, ctx)).to_be_true();
        ut.expect(IMPR1110.fun_allowed('IMPR1110F2', r, ctx)).to_be_false();
        ut.expect(IMPR1110.fun_allowed('CREATE_BRKR_IMPR_AUTH', r, ctx(1, 3))).to_be_true();
        ut.expect(IMPR1110.fun_allowed('CREATE_BRKR_IMPR_AUTH', r, ctx(1, 1))).to_be_false();
        ut.expect(IMPR1110.fun_allowed('IMPR1110_MOB', r, ctx(p_port => 99))).to_be_true();
        ut.expect(IMPR1110.fun_allowed('IMPR1110_MOB', r, ctx(p_port => 1))).to_be_false();
    END fun_rules;

    PROCEDURE ui_existing IS
        r IMPR1110.T_RECORD;
        j CLOB;
    BEGIN
        r.impr_nbr := 10; r.impr_type_cd := 1; r.bus_id_type_cd := 2;
        j := IMPR1110.ui_state_json(r, ctx);
        ut.expect(j).to_be_like('%"disabled":[%"P1110_BUS_ID"%');
        ut.expect(j).to_be_like('%"P1110_IMPR_TYPE_CD"%');
        ut.expect(j).to_be_like('%"P1110_CTRY_CD"%');            -- type 1 -> country disabled
        ut.expect(j).to_be_like('%"required":[%"P1110_CITY_CODE_OF_ID"%');
    END ui_existing;

    PROCEDURE ui_new_cr IS
        r IMPR1110.T_RECORD;
        j CLOB;
    BEGIN
        r.impr_type_cd := 3; r.bus_id_type_cd := 2;               -- commercial register
        j := IMPR1110.ui_state_json(r, ctx);
        ut.expect(j).to_be_like('%"required":[%"P1110_COMM_RGSTRTN_TYPE"%');
        ut.expect(j).not_to_be_like('%"disabled":[%"P1110_BUS_ID"%"required"%');
    END ui_new_cr;
END test_impr1110;
/
SHOW ERRORS
