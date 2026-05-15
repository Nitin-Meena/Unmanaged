CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Travel.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Travel.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Travel.

    METHODS read FOR READ
      IMPORTING keys FOR READ Travel RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Travel.

    METHODS rba_Booking FOR READ
      IMPORTING keys_rba FOR READ Travel\_Booking FULL result_requested RESULT result LINK association_links.

    METHODS cba_Booking FOR MODIFY
      IMPORTING entities_cba FOR CREATE Travel\_Booking.

    TYPES: tt_failed   TYPE TABLE FOR FAILED EARLY  zi_travel_tech_m1_u\\travel,
           tt_reported TYPE TABLE FOR REPORTED EARLY zi_travel_tech_m1_u\\travel.

    METHODS map_messages
      IMPORTING
        cid          TYPE abp_behv_cid   OPTIONAL
        travel_id    TYPE /dmo/travel_id OPTIONAL
        messages     TYPE /dmo/t_message
      EXPORTING
        failed_added TYPE abap_boolean
      CHANGING
        failed       TYPE tt_failed
        reported     TYPE tt_reported.

    TYPES tt_booking_failed   TYPE TABLE FOR FAILED   zi_booking_tech_m1_u.
    TYPES tt_booking_reported TYPE TABLE FOR REPORTED zi_booking_tech_m1_u.

    METHODS map_messages_assoc_to_booking
      IMPORTING
        cid          TYPE string
        is_dependend TYPE abap_bool       DEFAULT  abap_false
        messages     TYPE /dmo/t_message
      EXPORTING
        failed_added TYPE abap_bool
      CHANGING
        failed       TYPE tt_booking_failed
        reported     TYPE tt_booking_reported.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD create.

    DATA : ls_travel_in  TYPE /dmo/travel,
           ls_travel_out TYPE /dmo/travel,
*           lv_failed_added TYPE boolean,
           lt_messages   TYPE /dmo/t_message.


    LOOP AT entities INTO DATA(ls_entity).

      ls_travel_in = CORRESPONDING #( ls_entity MAPPING FROM ENTITY USING CONTROL ).

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_CREATE'
        EXPORTING
          is_travel         = CORRESPONDING /dmo/s_travel_in( ls_travel_in )
*         it_booking        =
*         it_booking_supplement =
          iv_numbering_mode = /dmo/if_flight_legacy=>numbering_mode-late
        IMPORTING
          es_travel         = ls_travel_out
*         et_booking        =
*         et_booking_supplement =
          et_messages       = lt_messages.

      map_messages(
        EXPORTING
          cid = ls_entity-%cid
          messages = lt_messages
        IMPORTING
          failed_added = DATA(lv_failed_added)
        CHANGING
          failed  = failed-travel
          reported = reported-travel
      ).

      IF lv_failed_added = abap_false.

        INSERT VALUE #( %cid = ls_entity-%cid
                              TravelID  = ls_travel_out-travel_id
                       ) INTO  TABLE mapped-travel.

      ENDIF.


    ENDLOOP.
  ENDMETHOD.

  METHOD update.
  ENDMETHOD.

  METHOD delete.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_Booking.
  ENDMETHOD.

  METHOD cba_Booking.
  ENDMETHOD.

  METHOD map_messages.

    failed_added  = abap_false.
    LOOP AT messages INTO DATA(ls_message).

      IF ls_message-msgty = 'E' OR ls_message-msgty = 'A'.

        APPEND VALUE #(  %cid = cid
                         travelid  = travel_id
                         %fail-cause  = zcl_travel_aux_nit_u=>get_cause_from_message(
                                          msgid        = ls_message-msgid
                                          msgno        =  ls_message-msgno
*                                          is_dependend = abap_false
                                        )
           )  TO failed.
        failed_added = abap_true.
      ENDIF.

      reported = VALUE #( ( %cid  = cid
                            travelid  = travel_id
                           %msg  = new_message(
                                     id       = ls_message-msgid
                                     number   = ls_message-msgno
                                     severity = if_abap_behv_message=>severity-error
                                     v1       = ls_message-msgv1
                                     v2       = ls_message-msgv2
                                     v3       = ls_message-msgv3
                                     v4       = ls_message-msgv4
                                   ) ) ).


    ENDLOOP.

  ENDMETHOD.

  METHOD map_messages_assoc_to_booking.
    ASSERT cid IS NOT INITIAL.  "In a create case, the %cid has to be present
    failed_added = abap_false.
    LOOP AT messages INTO DATA(message).
      IF message-msgty = 'E' OR message-msgty = 'A'.
        APPEND VALUE #( %cid        = cid
                        %fail-cause = /dmo/cl_travel_auxiliary=>get_cause_from_message(
                                        msgid = message-msgid
                                        msgno = message-msgno
                                        is_dependend = is_dependend
                                      ) )
               TO failed.
        failed_added = abap_true.
      ENDIF.

      APPEND VALUE #( %msg          = new_message(
                                        id       = message-msgid
                                        number   = message-msgno
                                        severity = if_abap_behv_message=>severity-error
                                        v1       = message-msgv1
                                        v2       = message-msgv2
                                        v3       = message-msgv3
                                        v4       = message-msgv4 )
                      %cid          = cid )
             TO reported.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
