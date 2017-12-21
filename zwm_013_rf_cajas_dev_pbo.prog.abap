MODULE status_0100 OUTPUT.
  SET PF-STATUS 'ZSG_013_0100'.
  SET CURSOR FIELD 'WA_0100-MATNR'.
ENDMODULE.

MODULE start_over_again_0100 OUTPUT.
  PERFORM start_over_again.
ENDMODULE.

MODULE get_zbc_udc OUTPUT.
  PERFORM get_zbc_udc.
ENDMODULE.

MODULE find_queue_0100 OUTPUT.

  SELECT SINGLE lgnum devty INTO ( wa_0100-lgnum, wa_0100-devty )
  FROM lrf_wkqu
  WHERE bname = sy-uname
    AND statu = abap_true.

  IF wa_0100-lgnum IS INITIAL.

    ld_queue_error = abap_true.

    CLEAR wa_log.
    wa_log-txt  = 'Log. '.
    wa_log-txt1 = space.
    wa_log-txt2 = 'Completar parametrización '.
    wa_log-txt3 = 'para el Usuario:'.
    wa_log-txt4 = sy-uname.
    LEAVE TO SCREEN '9999'.
  ENDIF.

ENDMODULE.

MODULE status_9999 OUTPUT.
  SET PF-STATUS 'ZSG_013_0100'.
ENDMODULE.

MODULE status_0200 OUTPUT.
  SET PF-STATUS 'ZSG_013_0200'.
  SET CURSOR FIELD 'WA_0200-INPUT'.
ENDMODULE.

MODULE get_matnr_info OUTPUT.

  SELECT SINGLE maktx meins INTO ( wa_0200-maktx, wa_0200-meins )
  FROM makt INNER JOIN mara
    ON makt~matnr EQ mara~matnr
    WHERE mara~matnr EQ wa_0200-matnr
      AND makt~spras EQ sy-langu.

ENDMODULE.
