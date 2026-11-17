-- =============================================================================
-- dynamic_action_patterns.sql — APEX 21.2 Dynamic Action reference patterns
-- Reference only (not a runnable script). Page 10 / items P10_* are examples.
-- Each pattern: Forms original -> declarative DA settings -> code snippets.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PATTERN 1: Show / hide items based on another item's value
-- Forms: WHEN-LIST-CHANGED on ORDERS.ORDER_TYPE
--        IF :ORDERS.ORDER_TYPE = 'EXPORT' THEN
--           SET_ITEM_PROPERTY('ORDERS.COUNTRY', VISIBLE, PROPERTY_TRUE); ...
-- APEX : DA "Toggle Country"
--   Event: Change | Selection: Item P10_ORDER_TYPE
--   Client-side condition: Item = Value, P10_ORDER_TYPE, EXPORT
--   True  action: Show  -> P10_COUNTRY   (Fire on Initialization = Yes)
--   False action: Hide  -> P10_COUNTRY   (Fire on Initialization = Yes)
--   Tip: also set "Clear when hidden"? Use False action Clear -> P10_COUNTRY if needed.
-- Server side safety: P10_COUNTRY server-side condition is NOT used (item must render);
--   instead add a validation so hidden values cannot be submitted incorrectly.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- PATTERN 2: Cascading LOV (refresh select list when parent changes)
-- Forms: LOV record group filtered by :ORDERS.COUNTRY_ID, re-populated in WHEN-VALIDATE-ITEM
-- APEX : no DA needed — declarative cascading LOV on P10_CITY_ID:
--   Type: Select List | List of Values: SQL Query
--   Cascading List of Values > Parent Item(s): P10_COUNTRY_ID
--   Items to Submit: P10_COUNTRY_ID | Parent Required: Yes
SELECT city_name AS display_value,
       city_id   AS return_value
  FROM cities
 WHERE country_id = :P10_COUNTRY_ID
 ORDER BY city_name;
-- In Interactive Grid columns use the same SQL with :COUNTRY_ID (column bind)
-- and set Cascading LOV Parent Column(s) = COUNTRY_ID.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- PATTERN 3: Conditional required field
-- Forms: SET_ITEM_PROPERTY('ORDERS.PO_NUMBER', REQUIRED, PROPERTY_TRUE) when PAY_TYPE='INVOICE'
-- APEX (server-side = authoritative): Validation "PO number required for invoices"
--   Type: PL/SQL Function Body (returning Error Text) | Associated Item: P10_PO_NUMBER
--   Code:
--     RETURN CASE WHEN :P10_PAY_TYPE = 'INVOICE' AND :P10_PO_NUMBER IS NULL
--                 THEN 'PO Number is required for invoice payments.' END;
--   (or Type "Item is NOT NULL" + Server-side Condition: Item = Value P10_PAY_TYPE INVOICE)
-- APEX (client-side visual cue): DA on change of P10_PAY_TYPE, True action Execute JavaScript:
--     apex.item('P10_PO_NUMBER').setRequired?.( $v('P10_PAY_TYPE') === 'INVOICE' );
--     $('#P10_PO_NUMBER_CONTAINER').toggleClass('is-required', $v('P10_PAY_TYPE') === 'INVOICE');
--   Note: verify item.setRequired availability in your 21.2 patch; the CSS class
--   approach works everywhere. The validation above is what enforces the rule.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- PATTERN 4: Call a PL/SQL procedure from a Dynamic Action
-- Forms: WHEN-VALIDATE-ITEM on ORDERS.CUSTOMER_ID fills CUSTOMER_NAME / CREDIT_LIMIT
-- APEX : DA "Fetch customer" — Event: Change | Item: P10_CUSTOMER_ID
--   True action: Execute Server-side Code
--     Items to Submit: P10_CUSTOMER_ID
--     Items to Return: P10_CUSTOMER_NAME,P10_CREDIT_LIMIT
BEGIN
    pkg_orders.get_customer_info(
        p_customer_id   => :P10_CUSTOMER_ID,
        p_customer_name => :P10_CUSTOMER_NAME,
        p_credit_limit  => :P10_CREDIT_LIMIT);
END;
--   Errors raised (raise_application_error) are shown as an error notification.
--   Add "Wait for Result = Yes" (default) before dependent actions.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- PATTERN 5: Confirmation dialog before DML
-- Forms: v_btn := SHOW_ALERT('CONFIRM_DELETE'); IF v_btn = ALERT_BUTTON1 THEN DELETE_RECORD; COMMIT_FORM; END IF;
-- APEX option A (declarative, simplest): Button DELETE
--   Behavior > Action: Submit Page, Request: DELETE
--   Confirmation > Message: 'Are you sure you want to delete this order?'
--   (Database Action: SQL DELETE action; DML process condition: request = DELETE)
-- APEX option B (Dynamic Action): Button Action = Defined by Dynamic Action
--   DA Event: Click on button DELETE
--   True action 1: Confirm  (Text: 'Are you sure you want to delete this order?')
--   True action 2: Submit Page (Request / Button Name: DELETE)
--   -> if the user cancels, subsequent actions are not executed.
-- APEX option C (JavaScript, custom text/logic):
--   apex.message.confirm('Delete order ' + $v('P10_ORDER_ID') + '?', function (okPressed) {
--       if (okPressed) { apex.page.submit({ request: 'DELETE', showWait: true }); }
--   });
-- Server process "ORDERS.PRE-DELETE" (Processing, condition request = DELETE),
-- before Automatic Row Processing:
BEGIN
    pkg_orders.orders_pre_del(p_rec => pkg_orders.get_order(:P10_ORDER_ID));
END;
-- Confirm text taken from the Forms alert (Text Message AL_CONFIRM_DEL), JS:
--   apex.message.confirm(apex.lang.getMessage('AL_CONFIRM_DEL'), function (ok) { ... });
--   (Text Message must have "Used in JavaScript" = Yes)
-- =============================================================================
