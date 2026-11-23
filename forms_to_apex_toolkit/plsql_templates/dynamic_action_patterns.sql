-- =============================================================================
-- dynamic_action_patterns.sql — APEX 21.2 Dynamic Action reference patterns (f345 standard)
-- Reference only (not a runnable script). Form ORDERS, page 120 / items P120_* are examples.
-- Rules: docs/f345_reference_standard.md §9 (declarative first) and §10 (package layout).
-- Order of preference in every pattern:
--   1. validation / item condition / FOS "Execute PL/SQL Code" (Items to Submit / Return)
--   2. native DA actions (Enable, Disable, Show, Hide, Set Value, Set Focus, Refresh, Confirm)
--   3. "Execute JavaScript Code" - at most 3 lines, only when 1-2 cannot do it (write the reason)
-- No JavaScript file per form, no AJAX callback processes, no UI state in PL/SQL.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PATTERN 1: WHEN-VALIDATE-ITEM that checks a value
-- Forms: ORDERS.CUSTOMER_ID WHEN-VALIDATE-ITEM
--          IF NOT exists(...) THEN MESSAGE('Unknown customer'); RAISE FORM_TRIGGER_FAILURE; END IF;
-- Package : FUNCTION CUSTOMER_ID_VALIDATION (P_CUSTOMER_ID IN VARCHAR2) RETURN VARCHAR2
--           (returns the error text, NULL when valid)
-- APEX 1  : Validation "CUSTOMER_ID VALIDATION" - PL/SQL Function Body returning Error Text,
--           associated item P120_CUSTOMER_ID, condition request CREATE / SAVE:
--             return ORDERS.CUSTOMER_ID_VALIDATION(P_CUSTOMER_ID => :P120_CUSTOMER_ID);
-- APEX 2  : DA "CUSTOMER_ID WHEN-VALIDATE-ITEM" - Event Change, Item P120_CUSTOMER_ID
--           True action: FOS - Execute PL/SQL Code
--             Code (p_attribute_01):
--               ORDERS.CHECK_ERROR(ORDERS.CUSTOMER_ID_VALIDATION(P_CUSTOMER_ID => :P120_CUSTOMER_ID));
--             Items to Submit (p_attribute_02): P120_CUSTOMER_ID
--             Error message  (p_attribute_05): #SQLERRM#
--           The user sees the error at once; the validation still enforces it at submit.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- PATTERN 2: WHEN-VALIDATE-ITEM that fills other items
-- Forms: ORDERS.CUSTOMER_ID WHEN-VALIDATE-ITEM fills CUSTOMER_NAME / CREDIT_LIMIT
-- Package : PROCEDURE CUSTOMER_ID_WHEN_VALIDATE_ITEM (P_CUSTOMER_ID   IN VARCHAR2,
--                                                    P_CUSTOMER_NAME IN OUT VARCHAR2,
--                                                    P_CREDIT_LIMIT  IN OUT NUMBER)
-- APEX    : DA "CUSTOMER_ID WHEN-VALIDATE-ITEM" - Event Change, Item P120_CUSTOMER_ID
--           True action: FOS - Execute PL/SQL Code
--             ORDERS.CUSTOMER_ID_WHEN_VALIDATE_ITEM(P_CUSTOMER_ID => :P120_CUSTOMER_ID,
--                 P_CUSTOMER_NAME => :P120_CUSTOMER_NAME, P_CREDIT_LIMIT => :P120_CREDIT_LIMIT);
--             Items to Submit: P120_CUSTOMER_ID
--             Items to Return: P120_CUSTOMER_NAME,P120_CREDIT_LIMIT
-- No JavaScript: FOS writes the returned values into the page items.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- PATTERN 3: Make_Field_Entrable / SET_ITEM_PROPERTY(ENABLED) decided by stored data
-- Forms: WHEN-NEW-RECORD-INSTANCE
--          IF :ORDERS.STATUS = 'CLOSED' THEN Make_Field_Entrable('ORDERS.AMOUNT', FALSE); END IF;
-- Package : FUNCTION AMOUNT_IS_READ_ONLY (P_STATUS IN VARCHAR2) RETURN BOOLEAN
--             IS BEGIN RETURN P_STATUS = 'CLOSED'; END;
-- APEX    : item P120_AMOUNT - Read Only: PL/SQL Expression
--             ORDERS.AMOUNT_IS_READ_ONLY(P_STATUS => :P120_STATUS)
--           APEX evaluates it when the page is rendered. Several items with the same rule share
--           one function, named by the rule in full words (e.g. CLOSED_ORDER_IS_READ_ONLY).
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- PATTERN 4: Make_Field_Entrable decided while the user types
-- Forms: ORDERS.ORDER_TYPE WHEN-VALIDATE-ITEM
--          IF :ORDERS.ORDER_TYPE = 'EXPORT' THEN Make_Field_Entrable('ORDERS.COUNTRY', TRUE);
--          ELSE Make_Field_Entrable('ORDERS.COUNTRY', FALSE); END IF;
-- APEX (rule uses only page values): DA "ORDER_TYPE WHEN-VALIDATE-ITEM" - Event Change
--   Client-side condition: Item = Value, P120_ORDER_TYPE, EXPORT
--   True  action: Enable  -> P120_COUNTRY   (Fire on Initialization = Yes)
--   False action: Disable -> P120_COUNTRY   (Fire on Initialization = Yes)
-- APEX (rule needs the database): FOS returns a flag item
--   True action 1: FOS - Execute PL/SQL Code
--     :P120_COUNTRY_READ_ONLY := CASE WHEN ORDERS.COUNTRY_IS_READ_ONLY(P_ORDER_TYPE => :P120_ORDER_TYPE)
--                                     THEN 'Y' ELSE 'N' END;
--     Items to Submit: P120_ORDER_TYPE | Items to Return: P120_COUNTRY_READ_ONLY
--   True action 2: Enable P120_COUNTRY, client-side condition Item = Value P120_COUNTRY_READ_ONLY N
--   True action 3: Disable P120_COUNTRY, client-side condition Item = Value P120_COUNTRY_READ_ONLY Y
-- Note: a disabled item is not submitted; the package reads the stored value when it needs it.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- PATTERN 5: Show / hide items
-- Forms: SET_ITEM_PROPERTY('ORDERS.COUNTRY', VISIBLE, PROPERTY_TRUE / FALSE)
-- APEX : DA on change, client-side condition Item = Value
--   True action: Show -> P120_COUNTRY | False action: Hide -> P120_COUNTRY (Fire on Initialization = Yes)
--   Stored-data rule: item Server-side Condition instead (the item is not rendered at all).
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- PATTERN 6: Conditional required field
-- Forms: SET_ITEM_PROPERTY('ORDERS.PO_NUMBER', REQUIRED, PROPERTY_TRUE) when PAY_TYPE = 'INVOICE'
-- Package : FUNCTION PO_NUMBER_IS_REQUIRED (P_PAY_TYPE IN VARCHAR2) RETURN BOOLEAN
-- APEX    : Validation "PO_NUMBER REQUIRED" - PL/SQL Function Body returning Error Text
--             return ORDERS.REQUIRED_VALIDATION(:P120_PO_NUMBER, '<label>');
--           Server-side Condition: PL/SQL Expression
--             ORDERS.PO_NUMBER_IS_REQUIRED(P_PAY_TYPE => :P120_PAY_TYPE)
--           No client-side script for the "required" marker.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- PATTERN 7: Cascading LOV (refresh a list when its parent changes)
-- Forms: LOV record group filtered by :ORDERS.COUNTRY_ID
-- APEX : no DA - declarative cascading LOV on P120_CITY_ID:
--   Cascading List of Values > Parent Item(s): P120_COUNTRY_ID | Items to Submit: P120_COUNTRY_ID
SELECT city_name AS display_value,
       city_id   AS return_value
  FROM cities
 WHERE country_id = :P120_COUNTRY_ID
 ORDER BY city_name;
-- In Interactive Grid columns use :COUNTRY_ID and Cascading LOV Parent Column(s) = COUNTRY_ID.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- PATTERN 8: GO_ITEM
-- Forms: GO_ITEM('ORDERS.ENG_NAME');
-- APEX : native action Set Focus -> P120_ENG_NAME (last action of the DA that did the work)
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- PATTERN 9: Confirmation (SHOW_ALERT with Yes / No)
-- Forms: IF SHOW_ALERT('AL_CONFIRM_SEND') = ALERT_BUTTON1 THEN <send>; END IF;
-- APEX (fixed text, declarative): DA on the button / event
--   True action 1: Confirm (text from Text Message AL_CONFIRM_SEND)
--   True action 2: Submit Page, request SEND   (cancel stops the following actions)
-- APEX (text computed on the server): FOS returns P120_CONFIRM_TEXT, then ONE line:
--   apex.message.confirm($v('P120_CONFIRM_TEXT'), function (ok) { if (ok) { apex.page.submit('SEND'); } });
-- Page 0 toolbar DELETE already confirms - nothing to build for KEY-DELREC.
-- Confirm before page 0 CREATE / SAVE (they submit directly): DA "Before Page Submit", the only
--   accepted 3-line JavaScript case - list it in the page spec §10.
-- -----------------------------------------------------------------------------
