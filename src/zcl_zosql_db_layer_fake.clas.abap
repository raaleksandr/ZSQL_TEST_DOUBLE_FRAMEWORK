class ZCL_ZOSQL_DB_LAYER_FAKE definition
  public
  inheriting from ZCL_ZOSQL_DB_LAYER_BASE
  create public .

public section.

  methods CREATE_EMPTY_TABLE_FOR_SELECT
    importing
      !IV_SELECT type CLIKE
    returning
      value(RD_DATA_SET_FOR_SELECT) type ref to DATA
    raising
      ZCX_ZOSQL_ERROR .
  methods CONSTRUCTOR
    importing
      !IO_ZOSQL_TEST_ENVIRONMENT type ref to ZIF_ZOSQL_TEST_ENVIRONMENT .

  methods ZIF_ZOSQL_DB_LAYER~COMMIT
    redefinition .
  methods ZIF_ZOSQL_DB_LAYER~DELETE
    redefinition .
  methods ZIF_ZOSQL_DB_LAYER~DELETE_BY_ITAB
    redefinition .
  methods ZIF_ZOSQL_DB_LAYER~FETCH_NEXT_CURSOR
    redefinition .
  methods ZIF_ZOSQL_DB_LAYER~FETCH_NEXT_CURSOR_TO_ITAB
    redefinition .
  methods ZIF_ZOSQL_DB_LAYER~INSERT_BY_ITAB
    redefinition .
  methods ZIF_ZOSQL_DB_LAYER~MODIFY_BY_ITAB
    redefinition .
  methods ZIF_ZOSQL_DB_LAYER~OPEN_CURSOR
    redefinition .
  methods ZIF_ZOSQL_DB_LAYER~SELECT_TO_ITAB
    redefinition .
  methods ZIF_ZOSQL_DB_LAYER~UPDATE
    redefinition .
  methods ZIF_ZOSQL_DB_LAYER~UPDATE_BY_ITAB
    redefinition .
protected section.
private section.

  types:
    BEGIN OF TY_CURSOR,
           cursor_number TYPE cursor,
           ref_to_result_of_select TYPE REF TO data,
           current_position        TYPE i,
           lines_count             TYPE i,
         END OF ty_cursor .

  data:
    mt_cursors TYPE STANDARD TABLE OF ty_cursor WITH KEY cursor_number .
  data MO_ZOSQL_TEST_ENVIRONMENT type ref to ZIF_ZOSQL_TEST_ENVIRONMENT .

  methods _EXECUTE_SQL
    importing
      !IT_PARAMETERS type ZOSQL_DB_LAYER_PARAMS
      value(IV_NEW_SYNTAX) type ABAP_BOOL default ABAP_FALSE
      !IO_ITERATOR type ref to ZIF_ZOSQL_ITERATOR
      !IO_SQL_EXECUTOR_FOR_LINE type ref to ZIF_ZOSQL_SQL_EXEC_LINE
      !IO_SQL_PARSER type ref to ZCL_ZOSQL_PARSER_RECURS_DESC optional
    raising
      ZCX_ZOSQL_ERROR .
  methods _PARSE_CONDITION_AS_PARAM
    importing
      !IV_FOR_ALL_ENTRIES_PARAM type STRING
      !IA_FOR_ALL_ENTRIES_TAB_LINE type ANY
    returning
      value(RS_PARAMETER) type ZOSQL_DB_LAYER_PARAM
    raising
      ZCX_ZOSQL_ERROR .
  methods _FIND_FOR_ALL_ENTRIES_CONDS
    importing
      !IO_SQL_PARSER type ref to ZCL_ZOSQL_PARSER_RECURS_DESC
    exporting
      !ET_FOUND_PARAMETERS type STRING_TABLE .
  methods _ADD_FOR_ALL_ENTRIES_TO_PARAMS
    importing
      !IO_SQL_PARSER type ref to ZCL_ZOSQL_PARSER_RECURS_DESC
      !IS_FOR_ALL_ENTRIES_TAB_LINE type ANY
    changing
      !CT_PARAMETERS type ZOSQL_DB_LAYER_PARAMS
    raising
      ZCX_ZOSQL_ERROR .
  methods _SELECT
    importing
      !IT_PARAMETERS type ZOSQL_DB_LAYER_PARAMS
      !IO_SQL_PARSER type ref to ZCL_ZOSQL_PARSER_RECURS_DESC
    exporting
      !ET_RESULT_TABLE type ANY TABLE
    raising
      ZCX_ZOSQL_ERROR .
  methods _SELECT_FOR_ALL_ENTRIES
    importing
      !IT_PARAMETERS type ZOSQL_DB_LAYER_PARAMS
      !IT_FOR_ALL_ENTRIES_TABLE type ANY TABLE
      !IO_SQL_PARSER type ref to ZCL_ZOSQL_PARSER_RECURS_DESC
    exporting
      !ET_RESULT_TABLE type ANY TABLE
    raising
      ZCX_ZOSQL_ERROR .
ENDCLASS.



CLASS ZCL_ZOSQL_DB_LAYER_FAKE IMPLEMENTATION.


  METHOD CONSTRUCTOR.

    DATA: lo_factory TYPE REF TO zif_zosql_factory.

    super->constructor( ).

    IF io_zosql_test_environment IS BOUND.
      mo_zosql_test_environment = io_zosql_test_environment.
    ELSE.
      CREATE OBJECT lo_factory TYPE zcl_zosql_factory.
      mo_zosql_test_environment = lo_factory->get_test_environment( ).
    ENDIF.
  ENDMETHOD.


  METHOD CREATE_EMPTY_TABLE_FOR_SELECT.

    DATA: lo_from_iterator     TYPE REF TO zcl_zosql_from_iterator,
          lo_select            TYPE REF TO zcl_zosql_select_processor,
          lo_sql_parser        TYPE REF TO zcl_zosql_parser_recurs_desc.

    CREATE OBJECT lo_sql_parser.
    lo_sql_parser->set_sql( iv_select ).
    lo_sql_parser->run_recursive_descent_parser( ).

    CREATE OBJECT lo_from_iterator
      EXPORTING
        io_zosql_test_environment = mo_zosql_test_environment.

    lo_from_iterator->init_by_sql_parser( lo_sql_parser ).

    CREATE OBJECT lo_select.

    lo_select->initialize_by_parsed_sql( io_sql_parser    = lo_sql_parser
                                         io_from_iterator = lo_from_iterator ).

    rd_data_set_for_select = lo_select->get_result_as_ref_to_data( ).
  ENDMETHOD.


  method ZIF_ZOSQL_DB_LAYER~COMMIT.
* No commit needed for fake
  endmethod.


  method ZIF_ZOSQL_DB_LAYER~DELETE.

    DATA: lo_table_iterator           TYPE REF TO zcl_zosql_table_iterator,
          ld_ref_to_buffer_for_delete TYPE REF TO data,
          lo_sql_executor_for_line    TYPE REF TO zcl_zosql_sql_exec_delete,
          lv_table_name               TYPE string,
          lo_sql_parser               TYPE REF TO zcl_zosql_parser_recurs_desc,
          lo_parser_helper            TYPE REF TO zcl_zosql_parser_helper,
          lv_new_syntax               TYPE abap_bool.

    FIELD-SYMBOLS: <lt_buffer> TYPE STANDARD TABLE.

    CREATE OBJECT lo_sql_parser.
    lo_sql_parser->set_sql( iv_delete_statement ).
    lo_sql_parser->run_recursive_descent_parser( ).

    CREATE OBJECT lo_parser_helper.
    lv_table_name = zcl_zosql_utils=>to_upper_case(
      lo_parser_helper->get_delete_table_name( lo_sql_parser ) ).
    lo_parser_helper->get_key_nodes_of_sql_delete( EXPORTING io_sql_parser = lo_sql_parser
                                                   IMPORTING ev_new_syntax = lv_new_syntax ).

    CREATE OBJECT lo_table_iterator
      EXPORTING
        io_zosql_test_environment = mo_zosql_test_environment
        iv_table_name             = lv_table_name.

    CREATE OBJECT lo_sql_executor_for_line
      EXPORTING
        iv_table_name        = lv_table_name.

    _execute_sql( it_parameters            = it_parameters
                  iv_new_syntax            = lv_new_syntax
                  io_iterator              = lo_table_iterator
                  io_sql_executor_for_line = lo_sql_executor_for_line
                  io_sql_parser            = lo_sql_parser ).

    ld_ref_to_buffer_for_delete = lo_sql_executor_for_line->get_buffer_with_processed_recs( ).

    ASSIGN ld_ref_to_buffer_for_delete->* TO <lt_buffer>.
    IF <lt_buffer> IS NOT INITIAL.
      zif_zosql_db_layer~delete_by_itab( iv_table_name       = lv_table_name
                                         it_lines_for_delete = <lt_buffer> ).
    ENDIF.
  endmethod.


  method ZIF_ZOSQL_DB_LAYER~DELETE_BY_ITAB.
    DATA: lv_table_name TYPE tabname16.

    lv_table_name = iv_table_name.
    mo_zosql_test_environment->delete_test_data_from_itab( it_lines_for_delete = it_lines_for_delete
                                                           iv_table_name       = lv_table_name ).
  endmethod.


  method ZIF_ZOSQL_DB_LAYER~FETCH_NEXT_CURSOR.
    DATA: lv_start_line TYPE i,
          lv_end_line   TYPE i.

    FIELD-SYMBOLS: <ls_cursor>                  LIKE LINE OF mt_cursors,
                   <lt_result_of_select_all>    TYPE STANDARD TABLE,
                   <lt_result_of_select_return> TYPE STANDARD TABLE.

    READ TABLE mt_cursors WITH KEY cursor_number = iv_cursor ASSIGNING <ls_cursor>.
    IF sy-subrc <> 0.
      MESSAGE e072 WITH iv_cursor INTO zcl_zosql_utils=>dummy.
      zcl_zosql_utils=>raise_exception_from_sy_msg( ).
    ENDIF.

    ASSIGN <ls_cursor>-ref_to_result_of_select->* TO <lt_result_of_select_all>.

    CREATE DATA ed_result_as_table LIKE <lt_result_of_select_all>.
    ASSIGN ed_result_as_table->* TO <lt_result_of_select_return>.

    IF <ls_cursor>-current_position > <ls_cursor>-lines_count.
      ev_subrc = 4.
      RETURN.
    ENDIF.

    lv_start_line = <ls_cursor>-current_position.
    lv_end_line = lv_start_line + iv_package_size - 1.

    IF lv_end_line > <ls_cursor>-lines_count.
      lv_end_line = <ls_cursor>-lines_count.
    ENDIF.

    APPEND LINES OF <lt_result_of_select_all> FROM lv_start_line TO lv_end_line TO <lt_result_of_select_return>.

    <ls_cursor>-current_position = lv_end_line + 1.
  endmethod.


  method ZIF_ZOSQL_DB_LAYER~FETCH_NEXT_CURSOR_TO_ITAB.
    DATA: ld_ref_to_result TYPE REF TO data.

    FIELD-SYMBOLS: <lt_result> TYPE STANDARD TABLE.

    REFRESH et_result_table.

    zif_zosql_db_layer~fetch_next_cursor( EXPORTING iv_cursor          = iv_cursor
                                                    iv_package_size    = iv_package_size
                                          IMPORTING ed_result_as_table = ld_ref_to_result
                                                    ev_subrc           = ev_subrc ).

    IF ev_subrc <> 0.
      RETURN.
    ENDIF.

    ASSIGN ld_ref_to_result->* TO <lt_result>.

    return_result_of_select_toitab( EXPORTING it_result_table          = <lt_result>
                                              iv_do_into_corresponding = iv_do_into_corresponding
                                    IMPORTING et_result_table          = et_result_table
                                              ev_subrc                 = ev_subrc ).
  endmethod.


  method ZIF_ZOSQL_DB_LAYER~INSERT_BY_ITAB.
    DATA: lv_table_name TYPE tabname16.

    lv_table_name = iv_table_name.
    mo_zosql_test_environment->insert_test_data( it_table      = it_new_lines
                                                 iv_table_name = lv_table_name ).
  endmethod.


  method ZIF_ZOSQL_DB_LAYER~MODIFY_BY_ITAB.
    zif_zosql_db_layer~insert_by_itab( iv_table_name = iv_table_name
                                       it_new_lines  = it_lines_for_modify ).
  endmethod.


  method ZIF_ZOSQL_DB_LAYER~OPEN_CURSOR.
    FIELD-SYMBOLS: <ls_cursor>           LIKE LINE OF mt_cursors,
                   <lt_result_of_select> TYPE STANDARD TABLE.

    APPEND INITIAL LINE TO mt_cursors ASSIGNING <ls_cursor>.
    <ls_cursor>-cursor_number    = sy-tabix.
    <ls_cursor>-current_position = 1.

    zif_zosql_db_layer~select( EXPORTING iv_select                = iv_select
                                         it_parameters            = it_parameters
                                         it_for_all_entries_table = it_for_all_entries_table
                               IMPORTING ed_result_as_table       = <ls_cursor>-ref_to_result_of_select ).

    ASSIGN <ls_cursor>-ref_to_result_of_select->* TO <lt_result_of_select>.
    <ls_cursor>-lines_count = LINES( <lt_result_of_select> ).

    rv_cursor = <ls_cursor>-cursor_number.
  endmethod.


  METHOD zif_zosql_db_layer~select_to_itab.

    DATA: ld_result_table           TYPE REF TO data,
          lv_up_to_n_rows           TYPE i,
          lv_delete_from_line       TYPE i,
          lo_sql_parser             TYPE REF TO zcl_zosql_parser_recurs_desc,
          lo_parser_helper          TYPE REF TO zcl_zosql_parser_helper,
          lv_up_to_n_rows_as_string TYPE string,
          ls_node_select_single     TYPE zcl_zosql_parser_recurs_desc=>ty_node.

    FIELD-SYMBOLS: <lt_result_table>      TYPE STANDARD TABLE,
                   <ls_result_first_line> TYPE any.

    CLEAR: et_result_table, es_result_line, ev_subrc.

    lo_sql_parser = parse_sql( iv_select ).
    ld_result_table = create_dynamic_tab_for_result( lo_sql_parser ).

    ASSIGN ld_result_table->* TO <lt_result_table>.

    IF it_for_all_entries_table IS NOT INITIAL.
      _select_for_all_entries( EXPORTING it_parameters              = it_parameters
                                         it_for_all_entries_table   = it_for_all_entries_table
                                         io_sql_parser              = lo_sql_parser
                               IMPORTING et_result_table            = <lt_result_table> ).
    ELSE.
      _select( EXPORTING it_parameters              = it_parameters
                         io_sql_parser              = lo_sql_parser
               IMPORTING et_result_table            = <lt_result_table> ).
    ENDIF.

    CREATE OBJECT lo_parser_helper.
    lv_up_to_n_rows_as_string = lo_parser_helper->get_up_to_n_rows_value( lo_sql_parser ).
    lo_parser_helper->get_key_nodes_of_sql_select( EXPORTING io_sql_parser  = lo_sql_parser
                                                   IMPORTING es_node_single = ls_node_select_single ).

    IF ls_node_select_single IS NOT INITIAL.
      lv_up_to_n_rows_as_string = '1'.
    ENDIF.

    IF lv_up_to_n_rows_as_string IS NOT INITIAL.
      lv_up_to_n_rows = prepare_n_of_rows_for_select( it_parameters          = it_parameters
                                                      iv_number_of_rows_expr = lv_up_to_n_rows_as_string ).
      lv_delete_from_line = lv_up_to_n_rows + 1.
      DELETE <lt_result_table> FROM lv_delete_from_line.
    ENDIF.

    return_result_of_select_toitab( EXPORTING it_result_table          = <lt_result_table>
                                              iv_do_into_corresponding = iv_do_into_corresponding
                                    IMPORTING et_result_table          = et_result_table
                                              es_result_line           = es_result_line
                                              ev_subrc                 = ev_subrc ).
  ENDMETHOD.


  method ZIF_ZOSQL_DB_LAYER~UPDATE.

    DATA: lo_parameters               TYPE REF TO zcl_zosql_parameters,
          lo_set                      TYPE REF TO zcl_zosql_set_processor,
          lo_table_iterator           TYPE REF TO zcl_zosql_table_iterator,
          ld_ref_to_buffer_for_update TYPE REF TO data,
          lo_sql_executor_for_line    TYPE REF TO zcl_zosql_sql_exec_update,
          lo_sql_parser               TYPE REF TO zcl_zosql_parser_recurs_desc,
          lo_parser_helper            TYPE REF TO zcl_zosql_parser_helper,
          lv_table_name               TYPE string,
          lv_new_syntax               TYPE abap_bool.

    FIELD-SYMBOLS: <lt_buffer> TYPE STANDARD TABLE.

    CREATE OBJECT lo_sql_parser.
    lo_sql_parser->set_sql( iv_update_statement ).
    lo_sql_parser->run_recursive_descent_parser( ).

    CREATE OBJECT lo_parser_helper.
    lv_table_name = lo_parser_helper->get_update_table_name( lo_sql_parser ).
    lo_parser_helper->get_key_nodes_of_sql_update( EXPORTING io_sql_parser = lo_sql_parser
                                                   IMPORTING ev_new_syntax = lv_new_syntax ).

    CREATE OBJECT lo_parameters
      EXPORTING
        it_parameters = it_parameters.

    CREATE OBJECT lo_set
      EXPORTING
        io_parameters = lo_parameters.

    lo_set->initialize_by_parsed_sql( lo_sql_parser ).

    CREATE OBJECT lo_table_iterator
      EXPORTING
        io_zosql_test_environment = mo_zosql_test_environment
        iv_table_name             = lv_table_name.

    CREATE OBJECT lo_sql_executor_for_line
      EXPORTING
        iv_table_name        = lv_table_name
        io_set_in_update_sql = lo_set.

    _execute_sql( it_parameters            = it_parameters
                  iv_new_syntax            = lv_new_syntax
                  io_iterator              = lo_table_iterator
                  io_sql_executor_for_line = lo_sql_executor_for_line
                  io_sql_parser            = lo_sql_parser ).

    ld_ref_to_buffer_for_update = lo_sql_executor_for_line->get_buffer_with_processed_recs( ).
    ASSIGN ld_ref_to_buffer_for_update->* TO <lt_buffer>.
    IF <lt_buffer> IS NOT INITIAL.
      zif_zosql_db_layer~update_by_itab( iv_table_name       = lv_table_name
                                         it_lines_for_update = <lt_buffer> ).
    ENDIF.
  endmethod.


  method ZIF_ZOSQL_DB_LAYER~UPDATE_BY_ITAB.
    zif_zosql_db_layer~insert_by_itab( iv_table_name = iv_table_name
                                       it_new_lines  = it_lines_for_update ).
  endmethod.


  method _ADD_FOR_ALL_ENTRIES_TO_PARAMS.

    DATA: lv_for_all_entries_tabname TYPE string,
          lv_for_all_entries_param   TYPE string,
          lt_for_all_entries_params  TYPE TABLE OF string,
          ls_param                   TYPE zosql_db_layer_param.

    _find_for_all_entries_conds( EXPORTING io_sql_parser       = io_sql_parser
                                 IMPORTING et_found_parameters = lt_for_all_entries_params ).

    LOOP AT lt_for_all_entries_params INTO lv_for_all_entries_param.

      ls_param = _parse_condition_as_param( iv_for_all_entries_param    = lv_for_all_entries_param
                                            ia_for_all_entries_tab_line = is_for_all_entries_tab_line ).

      IF ls_param IS NOT INITIAL.
        APPEND ls_param TO ct_parameters.
      ENDIF.
    ENDLOOP.
  endmethod.


  METHOD _execute_sql.

    DATA: lo_iter_pos            TYPE REF TO zcl_zosql_iterator_position,
          lo_where               TYPE REF TO zif_zosql_expression_processor,
          lo_parameters          TYPE REF TO zcl_zosql_parameters,
          lv_not_end_of_data     TYPE abap_bool,
          lo_zosql_parser_helper TYPE REF TO zcl_zosql_parser_helper,
          ls_node_where          TYPE zcl_zosql_parser_recurs_desc=>ty_node.

    CREATE OBJECT lo_parameters
      EXPORTING
        it_parameters = it_parameters.

    CREATE OBJECT lo_where TYPE zcl_zosql_where_processor
      EXPORTING
        io_zosql_test_environment = mo_zosql_test_environment
        io_parameters             = lo_parameters
        iv_new_syntax             = iv_new_syntax.

    CREATE OBJECT lo_zosql_parser_helper.
    lo_zosql_parser_helper->get_key_nodes_of_sql_select( EXPORTING io_sql_parser = io_sql_parser
                                                         IMPORTING es_node_where = ls_node_where ).

    lo_where->initialize_by_parsed_sql( io_sql_parser          = io_sql_parser
                                        iv_id_of_node_to_parse = ls_node_where-id ).

    lv_not_end_of_data = io_iterator->move_to_first( ).

    WHILE lv_not_end_of_data = abap_true.

      lo_iter_pos = io_iterator->get_iterator_position_object( ).

      IF lo_where->check_condition_for_cur_rec( lo_iter_pos ) = abap_true.
        io_sql_executor_for_line->execute_sql_for_line( lo_iter_pos ).
      ENDIF.

      lv_not_end_of_data = io_iterator->move_to_next( ).
    ENDWHILE.
  ENDMETHOD.


  method _FIND_FOR_ALL_ENTRIES_CONDS.

    DATA: lo_parser_helper           TYPE REF TO zcl_zosql_parser_helper,
          ls_node_where              TYPE zcl_zosql_parser_recurs_desc=>ty_node,
          lv_for_all_entries_tabname TYPE string,
          lt_all_nodes_of_where      TYPE zcl_zosql_parser_recurs_desc=>ty_tree,
          lv_search_substring        TYPE string.

    FIELD-SYMBOLS: <ls_node_of_where> TYPE zcl_zosql_parser_recurs_desc=>ty_node.

    REFRESH et_found_parameters.

    CREATE OBJECT lo_parser_helper.
    lo_parser_helper->get_key_nodes_of_sql_select( EXPORTING io_sql_parser = io_sql_parser
                                                   IMPORTING es_node_where = ls_node_where ).

    IF ls_node_where IS INITIAL.
      RETURN.
    ENDIF.

    lv_for_all_entries_tabname = zcl_zosql_utils=>to_upper_case(
      lo_parser_helper->get_for_all_entries_tabname( io_sql_parser ) ).

    IF lv_for_all_entries_tabname IS INITIAL.
      lv_for_all_entries_tabname = 'IT_FOR_ALL_ENTRIES_TABLE'.
    ENDIF.

    CONCATENATE lv_for_all_entries_tabname '-' INTO lv_search_substring.

    lt_all_nodes_of_where = io_sql_parser->get_child_nodes_recursive( ls_node_where-id ).
    LOOP AT lt_all_nodes_of_where ASSIGNING <ls_node_of_where>.
      FIND FIRST OCCURRENCE OF lv_search_substring IN <ls_node_of_where>-token_ucase.
      IF sy-subrc = 0.
        COLLECT <ls_node_of_where>-token_ucase INTO et_found_parameters.
      ENDIF.
    ENDLOOP.

*    DATA: lt_words            TYPE TABLE OF string,
*          lv_search_substring TYPE string,
*          lt_results          TYPE TABLE OF match_result,
*          lv_for_all_entries_param TYPE string.
*
*    FIELD-SYMBOLS: <ls_result> LIKE LINE OF lt_results.
*
*    REFRESH et_found_parameters.
*
*    SPLIT iv_where AT space INTO TABLE lt_words.
*    CONCATENATE iv_for_all_entries_tabname '-' INTO lv_search_substring.
*    CONDENSE lv_search_substring NO-GAPS.
*
*    FIND ALL OCCURRENCES OF lv_search_substring IN TABLE lt_words IGNORING CASE RESULTS lt_results.
*    LOOP AT lt_results ASSIGNING <ls_result>.
*      READ TABLE lt_words INDEX <ls_result>-line INTO lv_for_all_entries_param.
*      APPEND lv_for_all_entries_param TO et_found_parameters.
*    ENDLOOP.
  endmethod.


  METHOD _parse_condition_as_param.

    DATA: lv_fieldname_for_all_entries TYPE fieldname.

    FIELD-SYMBOLS: <lv_value_for_all_entries> TYPE any.

    SPLIT iv_for_all_entries_param AT '-' INTO zcl_zosql_utils=>dummy lv_fieldname_for_all_entries.
    ASSIGN COMPONENT lv_fieldname_for_all_entries OF STRUCTURE ia_for_all_entries_tab_line TO <lv_value_for_all_entries>.
    IF sy-subrc <> 0.
      MESSAGE e054 WITH lv_fieldname_for_all_entries INTO zcl_zosql_utils=>dummy.
      zcl_zosql_utils=>raise_exception_from_sy_msg( ).
    ENDIF.

    rs_parameter-param_name_in_select   = iv_for_all_entries_param.
    rs_parameter-parameter_value_single = <lv_value_for_all_entries>.
  ENDMETHOD.


  METHOD _SELECT.

    DATA: lo_from_iterator         TYPE REF TO zcl_zosql_from_iterator,
          lo_select                TYPE REF TO zcl_zosql_select_processor,
          lo_group_by              TYPE REF TO zcl_zosql_groupby_processor,
          lo_sql_executor_for_line TYPE REF TO zif_zosql_sql_exec_line,
          lo_sql_parser_helper     TYPE REF TO zcl_zosql_parser_helper,
          ls_node_group_by         TYPE zcl_zosql_parser_recurs_desc=>ty_node,
          ls_node_distinct         TYPE zcl_zosql_parser_recurs_desc=>ty_node,
          lv_new_syntax            TYPE abap_bool.

    REFRESH et_result_table.

    CREATE OBJECT lo_from_iterator
      EXPORTING
        io_zosql_test_environment = mo_zosql_test_environment.

    lo_from_iterator->init_by_sql_parser( io_sql_parser ).

    CREATE OBJECT lo_select.

    lo_select->initialize_by_parsed_sql( io_sql_parser    = io_sql_parser
                                         io_from_iterator = lo_from_iterator ).

    CREATE OBJECT lo_sql_executor_for_line TYPE zcl_zosql_sql_exec_select
      EXPORTING
        io_select = lo_select.

    CREATE OBJECT lo_sql_parser_helper.
    lo_sql_parser_helper->get_key_nodes_of_sql_select( EXPORTING io_sql_parser    = io_sql_parser
                                                       IMPORTING es_node_distinct = ls_node_distinct
                                                                 es_node_group_by = ls_node_group_by
                                                                 ev_new_syntax    = lv_new_syntax ).

    _execute_sql( it_parameters            = it_parameters
                  iv_new_syntax            = lv_new_syntax
                  io_iterator              = lo_from_iterator
                  io_sql_executor_for_line = lo_sql_executor_for_line
                  io_sql_parser            = io_sql_parser ).

    IF ls_node_group_by IS NOT INITIAL.
      CREATE OBJECT lo_group_by.
      lo_group_by->initialize_by_parsed_sql( io_sql_parser       = io_sql_parser
                                             iv_group_by_node_id = ls_node_group_by-id ).
      lo_select->apply_group_by( lo_group_by ).
    ELSEIF lo_select->has_aggregation_functions( ) = abap_true.
      lo_select->apply_aggr_func_no_group_by( ).
    ENDIF.

    IF ls_node_distinct IS NOT INITIAL.
      lo_select->apply_distinct( ).
    ENDIF.

    lo_select->get_result_move_corresponding( CHANGING ct_result_table = et_result_table ).
  ENDMETHOD.


  METHOD _SELECT_FOR_ALL_ENTRIES.

    DATA: lt_parameters    LIKE it_parameters,
          ld_result_table  TYPE REF TO data,
          lo_parser_helper TYPE REF TO zcl_zosql_parser_helper,
          lv_for_all_entries_tabname TYPE string.

    FIELD-SYMBOLS: <la_for_all_entries_line> TYPE any,
                   <lt_result_one_fae_line>  TYPE ANY TABLE.

    CREATE DATA ld_result_table LIKE et_result_table.
    ASSIGN ld_result_table->* TO <lt_result_one_fae_line>.

    LOOP AT it_for_all_entries_table ASSIGNING <la_for_all_entries_line>.

      REFRESH <lt_result_one_fae_line>.

      lt_parameters = it_parameters.
      _add_for_all_entries_to_params( EXPORTING io_sql_parser               = io_sql_parser
                                                is_for_all_entries_tab_line = <la_for_all_entries_line>
                                      CHANGING  ct_parameters               = lt_parameters ).

      _select( EXPORTING it_parameters   = lt_parameters
                         io_sql_parser   = io_sql_parser
               IMPORTING et_result_table = <lt_result_one_fae_line> ).

      INSERT LINES OF <lt_result_one_fae_line> INTO TABLE et_result_table.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
