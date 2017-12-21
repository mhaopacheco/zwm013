*&---------------------------------------------------------------------*
*&  Include           ZWM_013_RF_CAJAS_DEV_F01
*&---------------------------------------------------------------------*
FORM get_zbc_udc .

  DATA : ld_value TYPE zvalue.

  CALL METHOD zcl_bc_udc_utilities=>get_constant
    EXPORTING
      im_progname    = sy-repid
      im_id_constant = 'LGORT_FROM'
    IMPORTING
      ex_value       = ld_value.

  ld_lgort_from = ld_value.
  CLEAR ld_value.

  CALL METHOD zcl_bc_udc_utilities=>get_constant
    EXPORTING
      im_progname    = sy-repid
      im_id_constant = 'WERKS_FROM'
    IMPORTING
      ex_value       = ld_value.

  ld_werks_from = ld_value.
  CLEAR ld_value.

  CALL METHOD zcl_bc_udc_utilities=>get_constant
    EXPORTING
      im_progname    = sy-repid
      im_id_constant = 'LGORT_TO'
    IMPORTING
      ex_value       = ld_value.

  ld_lgort_to = ld_value.
  CLEAR ld_value.

  CALL METHOD zcl_bc_udc_utilities=>get_constant
    EXPORTING
      im_progname    = sy-repid
      im_id_constant = 'WERKS_TO'
    IMPORTING
      ex_value       = ld_value.

  ld_werks_to = ld_value.
  CLEAR ld_value.

  CALL METHOD zcl_bc_udc_utilities=>get_constant
    EXPORTING
      im_progname    = sy-repid
      im_id_constant = 'MOVE_TYPE'
    IMPORTING
      ex_value       = ld_value.

  ld_move_type = ld_value.
  CLEAR ld_value.

  CALL METHOD zcl_bc_udc_utilities=>get_constant
    EXPORTING
      im_progname    = sy-repid
      im_id_constant = 'LGNUM'
    IMPORTING
      ex_value       = ld_value.

  ld_lgnum = ld_value.
  CLEAR ld_value.

ENDFORM.

FORM start_over_again .

  CLEAR wa_log.
  CLEAR wa_0100.
  CLEAR wa_0200.

  CLEAR ld_lgort_from.
  CLEAR ld_werks_from.
  CLEAR ld_lgort_to.
  CLEAR ld_werks_to.
  CLEAR ld_move_type.
  CLEAR ld_lgnum.
  CLEAR ld_materialdocument.

  CLEAR ld_queue_error.
  CLEAR ld_not_complete.
  CLEAR ld_not_correct.
  CLEAR ld_qty_zero.
  CLEAR ld_qty_grt.
  CLEAR ld_not_exist.
  CLEAR ld_bapi_error.
  CLEAR ld_success.

ENDFORM.
FORM get_matnr .

  IF wa_0100-matnr IS NOT INITIAL.

    SELECT SINGLE matnr INTO wa_0100-matnrck
    FROM mara
      WHERE matnr = wa_0100-matnr.

    IF sy-subrc <> 0.

      DATA: ld_bismt        LIKE mara-bismt .

      SELECT SINGLE matnr INTO wa_0100-matnrck
      FROM mara
        WHERE bismt = ld_bismt.

    ELSE.
      wa_0200-matnr = wa_0100-matnrck.
      LEAVE TO SCREEN '0200'.
    ENDIF.

    IF wa_0100-matnrck IS INITIAL.

      CLEAR wa_log.
      ld_not_correct = abap_true.
      wa_log-txt  = 'Log.'.
      wa_log-txt1 = space.
      wa_log-txt2 = 'El Material ingresado'.
      wa_log-txt3 = 'no existe en el sistema.'.
      wa_log-txt4 = 'Verifique su entrada.'.
      LEAVE TO SCREEN '9999'.

    ELSE.
      wa_0200-matnr = wa_0100-matnrck.
      LEAVE TO SCREEN '0200'.
    ENDIF.

  ELSE.

    CLEAR wa_log.
    ld_not_complete = abap_true.
    wa_log-txt  = 'Log.'.
    wa_log-txt1 = space.
    wa_log-txt2 = 'El campo "Material" es'.
    wa_log-txt3 = 'Obligatorio.'.
    LEAVE TO SCREEN '9999'.

  ENDIF.

ENDFORM.
FORM check_qty .

  IF wa_0200-input IS NOT INITIAL AND wa_0200-input > 0.

    SELECT SINGLE labst INTO wa_0200-labst
      FROM mard
      WHERE matnr = wa_0200-matnr
        AND werks = ld_werks_from
        AND lgort = ld_lgort_from.

    IF wa_0200-input > wa_0200-labst.

      CLEAR wa_log.
      ld_qty_grt  = abap_true.
      wa_log-txt  = 'Log.'.
      wa_log-txt1 = space.
      wa_log-txt2 = 'La cantidad en Stock es:'.
      wa_log-txt3 = wa_0200-labst.
      LEAVE TO SCREEN '9999'.

    ELSEIF wa_0200-labst = 0.

      CLEAR wa_log.
      ld_not_exist = abap_true.
      wa_log-txt  = 'Log.'.
      wa_log-txt1 = space.
      CONCATENATE 'El producto:' wa_0200-matnr INTO wa_log-txt2 SEPARATED BY space.
      wa_log-txt3 = 'no está en almacén.'.
      LEAVE TO SCREEN '9999'.

    ENDIF.

  ELSE.

    CLEAR wa_log.
    ld_qty_zero = abap_true.
    wa_log-txt  = 'Log.'.
    wa_log-txt1 = space.
    wa_log-txt2 = 'El campo "Cantidad" es'.
    wa_log-txt3 = 'necesario para continuar'.
    LEAVE TO SCREEN '9999'.
  ENDIF.

ENDFORM.

FORM create_new_document.

  DATA: ls_goodsmvt_header       TYPE bapi2017_gm_head_01,
        ls_goodsmvt_code         TYPE bapi2017_gm_code,

        ls_goodsmvt_headret      TYPE bapi2017_gm_head_ret,
        ld_matdocumentyear       TYPE bapi2017_gm_head_ret-doc_year,

        it_goodsmvt_item         TYPE STANDARD TABLE OF bapi2017_gm_item_create,
        ls_goodsmvt_item         TYPE bapi2017_gm_item_create,

        it_goodsmvt_serialnumber TYPE STANDARD TABLE OF bapi2017_gm_serialnumber,
        ls_goodsmvt_serialnumber TYPE bapi2017_gm_serialnumber,

        it_return                TYPE STANDARD TABLE OF bapiret2,
        wa_return                TYPE bapiret2,

        ld_bapi_lines            TYPE i,
        ld_bapi_cant             TYPE bapi2017_gm_item_create-entry_qnt,

        ld_bapi_lines_c(20)      TYPE c,
        ld_bapi_cant_c(20)       TYPE c.

  CLEAR ld_materialdocument.

  PERFORM set_ls_goodsmvt_header       CHANGING ls_goodsmvt_header.
  PERFORM set_ls_lgoodsmvt_code        CHANGING ls_goodsmvt_code.
  PERFORM set_it_goodsmvt_item         TABLES   it_goodsmvt_item
                                       USING    ls_goodsmvt_item.
  TRY.

      CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
        EXPORTING
          goodsmvt_header  = ls_goodsmvt_header
          goodsmvt_code    = ls_goodsmvt_code
        IMPORTING
          goodsmvt_headret = ls_goodsmvt_headret
          materialdocument = ld_materialdocument
          matdocumentyear  = ld_matdocumentyear
        TABLES
          goodsmvt_item    = it_goodsmvt_item
          return           = it_return.

      IF it_return[] IS INITIAL AND ld_materialdocument IS NOT INITIAL.

        DATA: ls_return     TYPE bapiret2.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait   = abap_true
          IMPORTING
            return = ls_return.
      ELSE.

        READ TABLE it_return INTO wa_return INDEX 1.
        IF sy-subrc EQ 0.
          CLEAR wa_log.
          ld_bapi_error = abap_true.
          wa_log-txt  = 'Log:'.
          wa_log-txt1 = space.
          wa_log-txt2 = wa_return-message+0(20).
          wa_log-txt3 = wa_return-message+21(20).
          wa_log-txt4 = wa_return-message+41(20).
          LEAVE TO SCREEN '9999'.
        ENDIF.

      ENDIF.

    CATCH cx_root.

      CLEAR wa_log.
      ld_bapi_error = abap_true.
      wa_log-txt  = 'Log. '.
      wa_log-txt1 = space.
      wa_log-txt2 = 'Ha ocurrido una'.
      wa_log-txt3 = 'excepción.'.
      LEAVE TO SCREEN '9999'.
  ENDTRY.


ENDFORM.

FORM set_ls_goodsmvt_header CHANGING ls_goodsmvt_header TYPE bapi2017_gm_head_01.

  ls_goodsmvt_header-pstng_date = sy-datum.
  ls_goodsmvt_header-doc_date   = sy-datum.
  ls_goodsmvt_header-pr_uname   = sy-uname.
  ls_goodsmvt_header-header_txt = 'Traslado RF'.

ENDFORM.

FORM set_ls_lgoodsmvt_code CHANGING ls_goodsmvt_code TYPE bapi2017_gm_code.

  "Dato tomado de la Tabla T158G, para Tcode: MB1B.
  ls_goodsmvt_code-gm_code = '04'.

ENDFORM.

FORM set_it_goodsmvt_item  TABLES   it_goodsmvt_item STRUCTURE bapi2017_gm_item_create
                           USING    ls_goodsmvt_item TYPE bapi2017_gm_item_create.
  "Origen
  ls_goodsmvt_item-material  = wa_0200-matnr.
  ls_goodsmvt_item-plant     = ld_werks_from.
  ls_goodsmvt_item-stge_loc  = ld_lgort_from.
  ls_goodsmvt_item-move_type = ld_move_type.
  ls_goodsmvt_item-entry_uom = wa_0200-meins.
  ls_goodsmvt_item-entry_qnt = wa_0200-input.

  "Destino
  ls_goodsmvt_item-move_plant = ld_werks_to.
  ls_goodsmvt_item-move_stloc = ld_lgort_to.

  APPEND ls_goodsmvt_item TO it_goodsmvt_item.
  CLEAR ls_goodsmvt_item.

ENDFORM.

FORM create_new_ot.

  DATA ld_tanum TYPE ltak-tanum.
  DATA ld_teilk TYPE t340d-teilv.
  DATA ld_nlenr TYPE ltap_nlenr.
  DATA ld_lety1 TYPE mlgn-lety1.

  DATA: BEGIN OF it_ltbp OCCURS 0,
          lgnum TYPE ltbp-lgnum,
          tbnum TYPE ltbp-tbnum,
          tbpos TYPE ltbp-tbpos,
          menga TYPE ltbp-menga,
          lgort TYPE ltbp-lgort,
          lety1 TYPE ltbp-lety1,
          altme TYPE ltbp-altme,
        END OF it_ltbp.

  DATA wa_ltbp  LIKE LINE OF it_ltbp.
  DATA wa_trite TYPE l03b_trite.
  DATA it_trite TYPE l03b_trite_t.

  SELECT p~lgnum p~tbnum p~tbpos p~menga p~lgort p~lety1 p~altme
    INTO TABLE it_ltbp
    FROM ltbk AS k
    INNER JOIN ltbp AS p
    ON  k~lgnum EQ p~lgnum
    AND k~tbnum EQ p~tbnum
    WHERE k~mblnr EQ ld_materialdocument.

  READ TABLE it_ltbp INTO wa_ltbp INDEX 1.

  SELECT SINGLE lety1
    INTO ld_lety1
    FROM mlgn
    WHERE matnr EQ wa_0200-matnr
      AND lgnum EQ wa_ltbp-lgnum.

  IF it_ltbp[] IS NOT INITIAL.

    LOOP AT it_ltbp[] INTO wa_ltbp.

      SELECT SINGLE object, nrrangenr
        INTO @DATA(ls_exit)
        FROM ztwm_exit_ua
        WHERE lgort = @wa_ltbp-lgort
          AND lety1 = @ld_lety1.

      DATA: ld_number TYPE nriv-nrlevel.
      CLEAR ld_nlenr.

      CALL FUNCTION 'NUMBER_GET_NEXT'
        EXPORTING
          nr_range_nr             = ls_exit-nrrangenr
          object                  = ls_exit-object
        IMPORTING
          number                  = ld_number
        EXCEPTIONS
          interval_not_found      = 1
          number_range_not_intern = 2
          object_not_found        = 3
          quantity_is_0           = 4
          quantity_is_not_1       = 5
          interval_overflow       = 6
          buffer_overflow         = 7
          OTHERS                  = 8.
      IF sy-subrc <> 0.
      ENDIF.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = ld_number
        IMPORTING
          output = ld_nlenr.

      wa_trite-tbpos = wa_ltbp-tbpos.
      wa_trite-anfme = wa_ltbp-menga.
      wa_trite-altme = wa_ltbp-altme.
      wa_trite-nlenr = ld_nlenr.
      wa_trite-letyp = ld_lety1.
      APPEND wa_trite TO it_trite[].
      CLEAR wa_trite.
    ENDLOOP.

    TRY.
        CALL FUNCTION 'L_TO_CREATE_TR'
          EXPORTING
            i_lgnum                        = wa_ltbp-lgnum
            i_tbnum                        = wa_ltbp-tbnum
            i_commit_work                  = abap_true
            i_bname                        = sy-uname
            it_trite                       = it_trite
          IMPORTING
            e_tanum                        = ld_tanum
            e_teilk                        = ld_teilk
          EXCEPTIONS
            foreign_lock                   = 1
            qm_relevant                    = 2
            tr_completed                   = 3
            xfeld_wrong                    = 4
            ldest_wrong                    = 5
            drukz_wrong                    = 6
            tr_wrong                       = 7
            squit_forbidden                = 8
            no_to_created                  = 9
            update_without_commit          = 10
            no_authority                   = 11
            preallocated_stock             = 12
            partial_transfer_req_forbidden = 13
            input_error                    = 14
            OTHERS                         = 15.

        IF sy-subrc EQ 0.
          CLEAR wa_log.
          ld_success  = abap_true.
          wa_log-txt  = 'Log:'.
          wa_log-txt1 = space.
          wa_log-txt2 = 'Documento de Material:'.
          CONCATENATE ld_materialdocument 'y OT:' INTO wa_log-txt3 SEPARATED BY space.
          CONCATENATE ld_tanum 'creados'          INTO wa_log-txt4 SEPARATED BY space.
          LEAVE TO SCREEN '9999'.
        ELSE.
          CLEAR wa_log.
          ld_bapi_error = abap_true.
          wa_log-txt  = 'Log. '.
          wa_log-txt1 = space.
          wa_log-txt2 = 'Ha ocurrido un error'.
          wa_log-txt3 = 'durante la creación'.
          wa_log-txt4 = 'de la OT.'.
          LEAVE TO SCREEN '9999'.
        ENDIF.

      CATCH cx_root.

        CLEAR wa_log.
        ld_bapi_error = abap_true.
        wa_log-txt  = 'Log. '.
        wa_log-txt1 = space.
        wa_log-txt2 = 'Ha ocurrido una'.
        wa_log-txt3 = 'excepción.'.
        LEAVE TO SCREEN '9999'.
    ENDTRY.

  ENDIF.


ENDFORM.
