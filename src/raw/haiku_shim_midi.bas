' Raw FFI layer: eb-haiku's MIDI Kit 2 shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_midi.h.

Extern "C" Lib "ebhaikushim"
    ' ---- BMidiRoster (static-only facade) ----
    Declare Function eb_haiku_midi_roster_next_producer(BYVAL cookie AS ANY PTR) AS ANY PTR
    Declare Function eb_haiku_midi_roster_next_consumer(BYVAL cookie AS ANY PTR) AS ANY PTR
    Declare Function eb_haiku_midi_roster_find_producer(BYVAL forId AS INTEGER, BYVAL localOnly AS INTEGER) AS ANY PTR
    Declare Function eb_haiku_midi_roster_find_consumer(BYVAL forId AS INTEGER, BYVAL localOnly AS INTEGER) AS ANY PTR
    Declare Function eb_haiku_midi_roster_register(BYVAL endpointHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_midi_roster_unregister(BYVAL endpointHandle AS ANY PTR) AS INTEGER

    ' ---- BMidiEndpoint (shared) ----
    Declare Function eb_haiku_midi_endpoint_name(BYVAL endpointHandle AS ANY PTR) AS ZSTRING
    Declare Sub eb_haiku_midi_endpoint_set_name(BYVAL endpointHandle AS ANY PTR, BYVAL name AS ZSTRING)
    Declare Function eb_haiku_midi_endpoint_id(BYVAL endpointHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_midi_endpoint_is_valid(BYVAL endpointHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_midi_endpoint_is_local(BYVAL endpointHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_midi_endpoint_release(BYVAL endpointHandle AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_midi_endpoint_acquire(BYVAL endpointHandle AS ANY PTR)

    ' ---- BMidiLocalProducer ----
    Declare Function eb_haiku_midi_local_producer_create(BYVAL name AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_midi_producer_connect(BYVAL producerHandle AS ANY PTR, BYVAL consumerHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_midi_producer_disconnect(BYVAL producerHandle AS ANY PTR, BYVAL consumerHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_midi_producer_is_connected(BYVAL producerHandle AS ANY PTR, BYVAL consumerHandle AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_midi_producer_spray_note_on(BYVAL producerHandle AS ANY PTR, BYVAL channel AS UBYTE, BYVAL note AS UBYTE, BYVAL velocity AS UBYTE, BYVAL time AS LONGINT)
    Declare Sub eb_haiku_midi_producer_spray_note_off(BYVAL producerHandle AS ANY PTR, BYVAL channel AS UBYTE, BYVAL note AS UBYTE, BYVAL velocity AS UBYTE, BYVAL time AS LONGINT)
    Declare Sub eb_haiku_midi_producer_spray_control_change(BYVAL producerHandle AS ANY PTR, BYVAL channel AS UBYTE, BYVAL controlNumber AS UBYTE, BYVAL controlValue AS UBYTE, BYVAL time AS LONGINT)
    Declare Sub eb_haiku_midi_producer_spray_program_change(BYVAL producerHandle AS ANY PTR, BYVAL channel AS UBYTE, BYVAL programNumber AS UBYTE, BYVAL time AS LONGINT)

    ' ---- BMidiLocalConsumer ----
    Declare Function eb_haiku_midi_local_consumer_create(BYVAL name AS ZSTRING) AS ANY PTR
    Declare Sub eb_haiku_midi_consumer_set_note_on_callback(BYVAL consumerHandle AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_midi_consumer_set_note_off_callback(BYVAL consumerHandle AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_midi_consumer_set_control_change_callback(BYVAL consumerHandle AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_midi_consumer_set_program_change_callback(BYVAL consumerHandle AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_midi_consumer_set_data_callback(BYVAL consumerHandle AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
End Extern
