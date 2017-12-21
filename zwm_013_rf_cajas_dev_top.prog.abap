*&---------------------------------------------------------------------*
*&  Include           ZWM_013_RF_CAJAS_DEV_TOP
*&---------------------------------------------------------------------*
REPORT zwm_013_rf_cajas_dev_picking .

TYPES: BEGIN OF ty_log,
         txt(31),
         txt1(31),
         txt2(31),
         txt3(31),
         txt4(31),
         txt5(31),
         txt6(31),
       END OF ty_log,

       BEGIN OF ty_0100,
         matnr   TYPE mara-matnr,     "Material de entrada
         matnrck TYPE mara-matnr,     "Material obtenido
         lgnum   TYPE lrf_wkqu-lgnum,
         devty   TYPE lrf_wkqu-devty,
       END OF ty_0100,

       BEGIN OF ty_0200,
         matnr TYPE mara-matnr,
         maktx TYPE makt-maktx,
         meins TYPE mara-meins,
         input TYPE mard-labst,       "Cantidad del material ingresada por el usuario
         labst TYPE mard-labst,
       END OF ty_0200.

DATA wa_log  TYPE ty_log.
DATA wa_0100 TYPE ty_0100.
DATA wa_0200 TYPE ty_0200.

DATA ld_lgort_from       TYPE mard-lgort.                   "Almacen que envia
DATA ld_werks_from       TYPE mard-werks.                   "Centro que envia
DATA ld_lgort_to         TYPE mard-lgort.                   "Almacen que recibe
DATA ld_werks_to         TYPE mard-werks.                   "Centro que recibe
DATA ld_move_type        TYPE bwart.                        "Tipo de Movimiento
DATA ld_lgnum            TYPE ltbk-lgnum.                   "Número de almacén
DATA ld_materialdocument TYPE bapi2017_gm_head_ret-mat_doc. "Documento de traslado creado


"Variables de Log:
DATA ld_queue_error  TYPE abap_bool. "El usuario no tiene asociada cola de WM
DATA ld_not_complete TYPE abap_bool. "No se diligencio el material en la primera dynpro
DATA ld_not_correct  TYPE abap_bool. "El material no es correcto
DATA ld_qty_zero     TYPE abap_bool. "El campo cantidad se encuentra vacío o es cero.
DATA ld_qty_grt      TYPE abap_bool. "La cantidad ingresada es mayor que la cantidad en Stock.
DATA ld_not_exist    TYPE abap_bool. "No hay existencias del material en el almacén.
DATA ld_bapi_error   TYPE abap_bool. "Error en la ejecución de la BAPI_GOODSMVT_CREATE
DATA ld_success      TYPE abap_bool. "Documento de Material y OT creados satisfactoriamente
