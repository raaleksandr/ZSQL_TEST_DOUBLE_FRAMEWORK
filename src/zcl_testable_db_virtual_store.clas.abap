class ZCL_TESTABLE_DB_VIRTUAL_STORE definition
  public
  create public .

public section.

  interfaces ZIF_TESTABLE_DB_VIRTUAL_STORE .

  methods CONSTRUCTOR
    importing
      !IO_FACTORY type ref to ZIF_TESTABLE_DB_FACTORY optional .
protected section.
private section.

  types:
    BEGIN OF TY_VIRTUAL_TABLE,
           table_name TYPE tabname16,
           virt_table TYPE REF TO zcl_testable_db_one_virt_table,
         END OF ty_virtual_table .

  data MO_FACTORY type ref to ZIF_TESTABLE_DB_FACTORY .
  data:
    MT_VIRTUAL_TABLES  TYPE HASHED TABLE OF ty_virtual_table WITH UNIQUE KEY table_name .

  methods _CREATE_TABLE_RECORD
    importing
      !IV_TABLE_NAME type CLIKE .
  methods _RAISE_CANNOT_DETECT_TABNAME
    raising
      ZCX_TESTABLE_DB_LAYER .
  methods _IS_TRANSPARENT_TABLE
    importing
      !IV_DICTIONARY_TYPE type CLIKE
    returning
      value(RV_IS_TRANSPARENT_TABLE) type ABAP_BOOL .
ENDCLASS.



CLASS ZCL_TESTABLE_DB_VIRTUAL_STORE IMPLEMENTATION.


  method CONSTRUCTOR.

    IF io_factory IS BOUND.
      mo_factory = io_factory.
    ELSE.
      CREATE OBJECT mo_factory TYPE zcl_testable_db_factory.
    ENDIF.
  endmethod.


  method ZIF_TESTABLE_DB_VIRTUAL_STORE~CLEAR_ALL.
    REFRESH mt_virtual_tables.
  endmethod.


  method ZIF_TESTABLE_DB_VIRTUAL_STORE~CLEAR_ON_TABLE.

    DATA: lv_table_name TYPE tabname16.

    lv_table_name = zcl_testable_db_layer_utils=>to_upper_case( iv_table_name ).
    DELETE mt_virtual_tables WHERE table_name = lv_table_name.
  endmethod.


  method ZIF_TESTABLE_DB_VIRTUAL_STORE~DELETE_TEST_DATA_FROM_ITAB.
    DATA: lv_table_name    TYPE tabname16.

    FIELD-SYMBOLS: <ls_virtual_table> LIKE LINE OF mt_virtual_tables.

    lv_table_name = iv_table_name.

    IF lv_table_name IS INITIAL.
      lv_table_name = zcl_testable_db_layer_utils=>try_to_guess_tabname_by_data( it_lines_for_delete ).
    ENDIF.

    IF lv_table_name IS INITIAL.
      _raise_cannot_detect_tabname( ).
    ENDIF.

    READ TABLE mt_virtual_tables WITH TABLE KEY table_name = lv_table_name ASSIGNING <ls_virtual_table>.
    IF sy-subrc = 0.
      <ls_virtual_table>-virt_table->delete_test_data_from_itab( it_lines_for_delete ).
    ENDIF.
  endmethod.


  method ZIF_TESTABLE_DB_VIRTUAL_STORE~GET_DATA_OF_TABLE.

    FIELD-SYMBOLS: <ls_virtual_table> LIKE LINE OF mt_virtual_tables.

    REFRESH et_table[].
    READ TABLE mt_virtual_tables WITH TABLE KEY table_name = iv_table_name ASSIGNING <ls_virtual_table>.
    IF sy-subrc = 0.
      <ls_virtual_table>-virt_table->get_data( IMPORTING et_table = et_table ).
    ENDIF.
  endmethod.


  method ZIF_TESTABLE_DB_VIRTUAL_STORE~GET_DATA_OF_TABLE_AS_REF.

    FIELD-SYMBOLS: <ls_virtual_table> LIKE LINE OF mt_virtual_tables.

    READ TABLE mt_virtual_tables WITH TABLE KEY table_name = iv_table_name ASSIGNING <ls_virtual_table>.
    IF sy-subrc = 0.
      rd_ref_to_data = <ls_virtual_table>-virt_table->get_data_as_ref( ).
    ELSEIF _is_transparent_table( iv_table_name ) = abap_true.
      _create_table_record( iv_table_name ).
      rd_ref_to_data = zif_testable_db_virtual_store~get_data_of_table_as_ref( iv_table_name ).
    ENDIF.
  endmethod.


  method ZIF_TESTABLE_DB_VIRTUAL_STORE~INSERT_TEST_DATA_FROM_ITAB.

    DATA: lv_table_name    TYPE tabname16.

    FIELD-SYMBOLS: <ls_virtual_table> LIKE LINE OF mt_virtual_tables.

    lv_table_name = iv_table_name.

    IF lv_table_name IS INITIAL.
      lv_table_name = zcl_testable_db_layer_utils=>try_to_guess_tabname_by_data( it_table ).
    ENDIF.

    IF lv_table_name IS INITIAL.
      _raise_cannot_detect_tabname( ).
    ENDIF.

    READ TABLE mt_virtual_tables WITH TABLE KEY table_name = lv_table_name ASSIGNING <ls_virtual_table>.
    IF sy-subrc <> 0.
      _create_table_record( lv_table_name ).
      READ TABLE mt_virtual_tables WITH TABLE KEY table_name = lv_table_name ASSIGNING <ls_virtual_table>.
    ENDIF.
    <ls_virtual_table>-virt_table->insert_test_data_from_itab( it_table ).
  endmethod.


  method _CREATE_TABLE_RECORD.

    DATA: ls_virtual_table LIKE LINE OF mt_virtual_tables.

    ls_virtual_table-table_name = iv_table_name.
    ls_virtual_table-virt_table = mo_factory->get_one_virtual_table( iv_table_name ).
    INSERT ls_virtual_table INTO TABLE mt_virtual_tables.
  endmethod.


  METHOD _is_transparent_table.
    rv_is_transparent_table = zcl_testable_db_layer_utils=>transparent_table_exists( iv_dictionary_type ).
  ENDMETHOD.


  METHOD _raise_cannot_detect_tabname.
    MESSAGE e053 INTO zcl_testable_db_layer_utils=>dummy.
    zcl_testable_db_layer_utils=>raise_exception_from_sy_msg( ).
  ENDMETHOD.
ENDCLASS.
