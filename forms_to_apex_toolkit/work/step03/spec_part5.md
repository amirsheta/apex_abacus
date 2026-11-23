
`P1110_SUPPORT_URL` (URL of the SUPPORT_ENTRY dialog): **TODO**, added when that form's page exists.

## 10. Dynamic Actions (page 1110)

### 10.1 How the DAs are built

- **FOS - Execute PL/SQL Code** (f345 plug-in `COM.FOS.EXECUTE_PLSQL_CODE`) with the attributes of standard §9:
  `p_attribute_01` = the call below; `p_attribute_02` = *Items to Submit* (only items the user can change,
  plus the answer / function-code items; everything else is read from session state); `p_attribute_03` =
  *Items to Return* (the IN OUT / OUT parameters); `p_attribute_05 => '#SQLERRM#'`; `p_wait_for_result => 'Y'`.
  `p_attribute_15 => 'suppressChangeEvent:escape-message'`, except on the `READ_ONLY_FLAGS` action, which
  must fire the change events of the flag items.
- An error raised by the package (`FORMS_APX.FORM_TRIGGER_FAILURE`, ORA-20001) stops the DA, and FOS
  shows the text, as Forms does with `RAISE FORM_TRIGGER_FAILURE`.
- Messages that do not stop processing (`INFO` → `FORMS_APX.MESSAGE` → `apex_application.g_print_success_message`)
  are shown by FOS as its success message (TODO-VERIFY with the f345 FOS version in step 04).
- POST-CHANGE + WHEN-VALIDATE-ITEM → event *Change*. WHEN-NEW-ITEM-INSTANCE → *Get Focus*. KEY-NEXT-ITEM →
  *Lose Focus*. WHEN-LIST-CHANGED → *Change*.
- Forms fires WHEN-VALIDATE-ITEM when the user leaves a changed item; *Change* fires at the same moment for
  text items, and at once for select lists and LOVs.

### 10.2 All dynamic actions

The table is generated. *Code / setting* is the exact call; one row per action.

