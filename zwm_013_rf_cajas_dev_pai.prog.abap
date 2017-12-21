MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'F2'.
      CLEAR sy-ucomm.
      CLEAR wa_0100-matnr.
    WHEN 'F3'.
      CLEAR sy-ucomm.
      LEAVE PROGRAM.
    WHEN 'F4'.
      CLEAR sy-ucomm.
      PERFORM get_matnr.
  ENDCASE.
ENDMODULE.

MODULE user_command_9999 INPUT.

  CASE sy-ucomm.
    WHEN 'F3'.
      CLEAR sy-ucomm.
      IF ld_queue_error EQ abap_true.
        CLEAR ld_queue_error.
        LEAVE TO SCREEN '0100'.
      ELSEIF ld_not_complete EQ abap_true.
        CLEAR ld_not_complete.
        LEAVE TO SCREEN '0100'.
      ELSEIF ld_not_correct EQ abap_true.
        CLEAR ld_not_correct.
        CLEAR wa_0100-matnr.
        LEAVE TO SCREEN '0100'.
      ELSEIF ld_qty_zero EQ abap_true.
        CLEAR ld_qty_zero.
        CLEAR wa_0200-input.
        LEAVE TO SCREEN '0200'.
      ELSEIF ld_qty_grt EQ abap_true.
        CLEAR ld_qty_grt.
        CLEAR wa_0200-input.
        CLEAR wa_0200-labst.
        LEAVE TO SCREEN '0200'.
      ELSEIF ld_not_exist EQ abap_true.
        CLEAR ld_not_exist.
        CLEAR wa_0200-input.
        CLEAR wa_0200-labst.
        LEAVE TO SCREEN '0200'.
      ELSEIF ld_bapi_error EQ abap_true.
        CLEAR ld_bapi_error.
        PERFORM start_over_again.
        LEAVE TO SCREEN '0100'.
      ELSEIF ld_success EQ abap_true.
        CLEAR ld_success.
        PERFORM start_over_again.
        LEAVE TO SCREEN '0100'.
      ENDIF.
  ENDCASE.

ENDMODULE.

MODULE user_command_0200 INPUT.
  CASE sy-ucomm.
    WHEN 'F1'.
      CLEAR sy-ucomm.
      PERFORM check_qty.
      PERFORM create_new_document.
      IF ld_materialdocument IS NOT INITIAL.
        PERFORM create_new_ot.
      ENDIF.
    WHEN 'F2'.
      CLEAR sy-ucomm.
      CLEAR wa_0200-input.
      CLEAR wa_0200-labst.
    WHEN 'F3'.
      CLEAR sy-ucomm.
      CLEAR wa_0200-input.
      CLEAR wa_0200-labst.
      LEAVE TO SCREEN '0100'.
  ENDCASE.
ENDMODULE.
