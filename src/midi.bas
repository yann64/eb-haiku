' Idiomatic layer: MIDI Kit 2 - the most novel binding in this
' package: BMidiRoster is a pure static-method facade (never
' instantiated - every HMidiRoster* function below is a free function,
' no handle/TYPE of its own). Every endpoint
' (HMidiProducer/HMidiConsumer) is real-refcounted in real Haiku
' (BMidiEndpoint's own fRefCount + Acquire()/Release()) - there is
' deliberately no HMidiProducerFree/HMidiConsumerFree "destroy"
' function anywhere in this file. Call HMidiEndpointRelease instead
' (works on either handle - see HMidiEndpointName's own doc comment)
' when you're done with an endpoint; real Haiku's own destructor is
' private/protected specifically to prevent a plain delete, enforced
' at compile time in the shim itself.
'
' BMidiRoster::StartWatching/StopWatching (live endpoint-registration
' notifications) not bound this pass - a reasonable follow-on, not
' needed for the real Connect+Spray+receive loopback path this binding
' targets. Only the most commonly used BMidiLocalConsumer overrides are
' forwarded (NoteOn/NoteOff/ControlChange/ProgramChange, plus the
' catch-all Data()) - see native/shim_midi.h's own top comment for the
' remaining 9 real virtuals left unbound.
'
' IMPORTANT, confirmed by direct reproduction: BOTH endpoints must be
' HMidiRosterRegister'd BEFORE HMidiProducerConnect/Spray* for any real
' MIDI data to actually be delivered - Connect() itself succeeds and
' HMidiProducerIsConnected reports true even without registering
' first, but SprayNoteOn/etc. then silently never reaches the
' consumer's own callback at all (confirmed via a standalone C++
' probe: identical code with Register() calls added delivers
' correctly). Real MIDI Kit 2 routing always goes through the
' out-of-process midi_server, even for two purely local, in-process
' endpoints - Register() is what actually publishes them to it.
'
' A second real finding, this time a genuine shim bug (fixed) rather
' than a Haiku API surprise: real BMidiLocalConsumer::Data() is what
' actually parses the raw MIDI byte stream and dispatches to
' NoteOn/NoteOff/ControlChange/etc. internally - the shim's own
' ShimMidiConsumer::Data() override MUST call
' BMidiLocalConsumer::Data(...) itself before (or regardless of)
' forwarding to any HMidiConsumerSetDataCallback - overriding Data()
' without calling the base implementation silently breaks EVERY other
' NoteOn/NoteOff/ControlChange/ProgramChange callback in this file (a
' standalone shim-level C++ probe, bypassing eBasic entirely, first
' confirmed the callbacks never fired at all until this fix).

#include once "raw/haiku_shim_midi.bas"

TYPE HMidiProducer
    handle AS ANY PTR
END TYPE

TYPE HMidiConsumer
    handle AS ANY PTR
END TYPE

' ---- BMidiRoster (static-only facade) ----

''' Advances `cookie` (BYREF, start at 0) and returns the next real
''' system MIDI producer, or a null handle once enumeration is
''' exhausted.
FUNCTION HMidiRosterNextProducer(BYREF cookie AS INTEGER) AS HMidiProducer
    DIM c AS INTEGER
    c = cookie
    DIM p AS HMidiProducer
    p.handle = eb_haiku_midi_roster_next_producer(@c)
    cookie = c
    HMidiRosterNextProducer = p
END FUNCTION

FUNCTION HMidiRosterNextConsumer(BYREF cookie AS INTEGER) AS HMidiConsumer
    DIM c AS INTEGER
    c = cookie
    DIM cons AS HMidiConsumer
    cons.handle = eb_haiku_midi_roster_next_consumer(@c)
    cookie = c
    HMidiRosterNextConsumer = cons
END FUNCTION

FUNCTION HMidiRosterFindProducer(BYVAL forId AS INTEGER, BYVAL localOnly AS INTEGER) AS HMidiProducer
    DIM p AS HMidiProducer
    p.handle = eb_haiku_midi_roster_find_producer(forId, localOnly)
    HMidiRosterFindProducer = p
END FUNCTION

FUNCTION HMidiRosterFindConsumer(BYVAL forId AS INTEGER, BYVAL localOnly AS INTEGER) AS HMidiConsumer
    DIM c AS HMidiConsumer
    c.handle = eb_haiku_midi_roster_find_consumer(forId, localOnly)
    HMidiRosterFindConsumer = c
END FUNCTION

''' Publishes an endpoint (its own `.handle`) so other real apps can
''' find it via HMidiRosterNextProducer/Consumer/FindProducer/
''' FindConsumer. Returns a status code (0 = success).
FUNCTION HMidiRosterRegister(BYVAL endpointHandle AS ANY PTR) AS INTEGER
    HMidiRosterRegister = eb_haiku_midi_roster_register(endpointHandle)
END FUNCTION

FUNCTION HMidiRosterUnregister(BYVAL endpointHandle AS ANY PTR) AS INTEGER
    HMidiRosterUnregister = eb_haiku_midi_roster_unregister(endpointHandle)
END FUNCTION

' ---- BMidiEndpoint (shared - takes an HMidiProducer's or
' HMidiConsumer's own `.handle` directly, both work) ----

FUNCTION HMidiEndpointName(BYVAL endpointHandle AS ANY PTR) AS ZSTRING
    HMidiEndpointName = eb_haiku_midi_endpoint_name(endpointHandle)
END FUNCTION

SUB HMidiEndpointSetName(BYVAL endpointHandle AS ANY PTR, name AS ZSTRING)
    CALL eb_haiku_midi_endpoint_set_name(endpointHandle, name)
END SUB

FUNCTION HMidiEndpointId(BYVAL endpointHandle AS ANY PTR) AS INTEGER
    HMidiEndpointId = eb_haiku_midi_endpoint_id(endpointHandle)
END FUNCTION

FUNCTION HMidiEndpointIsValid(BYVAL endpointHandle AS ANY PTR) AS INTEGER
    HMidiEndpointIsValid = eb_haiku_midi_endpoint_is_valid(endpointHandle)
END FUNCTION

FUNCTION HMidiEndpointIsLocal(BYVAL endpointHandle AS ANY PTR) AS INTEGER
    HMidiEndpointIsLocal = eb_haiku_midi_endpoint_is_local(endpointHandle)
END FUNCTION

''' Releases this endpoint - call exactly once when done with it,
''' NEVER a plain "free" (real Haiku's own BMidiEndpoint is
''' ref-counted; this calls the real Release(), which self-deletes
''' once the count reaches zero).
FUNCTION HMidiEndpointRelease(BYVAL endpointHandle AS ANY PTR) AS INTEGER
    HMidiEndpointRelease = eb_haiku_midi_endpoint_release(endpointHandle)
END FUNCTION

SUB HMidiEndpointAcquire(BYVAL endpointHandle AS ANY PTR)
    CALL eb_haiku_midi_endpoint_acquire(endpointHandle)
END SUB

' ---- BMidiLocalProducer ----

FUNCTION HMidiProducerCreate(name AS ZSTRING) AS HMidiProducer
    DIM p AS HMidiProducer
    p.handle = eb_haiku_midi_local_producer_create(name)
    HMidiProducerCreate = p
END FUNCTION

FUNCTION HMidiProducerConnect(BYVAL producer AS HMidiProducer, BYVAL consumer AS HMidiConsumer) AS INTEGER
    HMidiProducerConnect = eb_haiku_midi_producer_connect(producer.handle, consumer.handle)
END FUNCTION

FUNCTION HMidiProducerDisconnect(BYVAL producer AS HMidiProducer, BYVAL consumer AS HMidiConsumer) AS INTEGER
    HMidiProducerDisconnect = eb_haiku_midi_producer_disconnect(producer.handle, consumer.handle)
END FUNCTION

FUNCTION HMidiProducerIsConnected(BYVAL producer AS HMidiProducer, BYVAL consumer AS HMidiConsumer) AS INTEGER
    HMidiProducerIsConnected = eb_haiku_midi_producer_is_connected(producer.handle, consumer.handle)
END FUNCTION

SUB HMidiProducerSprayNoteOn(BYVAL producer AS HMidiProducer, BYVAL channel AS UBYTE, BYVAL note AS UBYTE, BYVAL velocity AS UBYTE, BYVAL time AS LONGINT)
    CALL eb_haiku_midi_producer_spray_note_on(producer.handle, channel, note, velocity, time)
END SUB

SUB HMidiProducerSprayNoteOff(BYVAL producer AS HMidiProducer, BYVAL channel AS UBYTE, BYVAL note AS UBYTE, BYVAL velocity AS UBYTE, BYVAL time AS LONGINT)
    CALL eb_haiku_midi_producer_spray_note_off(producer.handle, channel, note, velocity, time)
END SUB

SUB HMidiProducerSprayControlChange(BYVAL producer AS HMidiProducer, BYVAL channel AS UBYTE, BYVAL controlNumber AS UBYTE, BYVAL controlValue AS UBYTE, BYVAL time AS LONGINT)
    CALL eb_haiku_midi_producer_spray_control_change(producer.handle, channel, controlNumber, controlValue, time)
END SUB

SUB HMidiProducerSprayProgramChange(BYVAL producer AS HMidiProducer, BYVAL channel AS UBYTE, BYVAL programNumber AS UBYTE, BYVAL time AS LONGINT)
    CALL eb_haiku_midi_producer_spray_program_change(producer.handle, channel, programNumber, time)
END SUB

' ---- BMidiLocalConsumer ----

FUNCTION HMidiConsumerCreate(name AS ZSTRING) AS HMidiConsumer
    DIM c AS HMidiConsumer
    c.handle = eb_haiku_midi_local_consumer_create(name)
    HMidiConsumerCreate = c
END FUNCTION

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, b1 AS UBYTE, b2 AS UBYTE, b3 AS UBYTE, time AS LONGINT) -
''' (channel, note, velocity, time) for NoteOn/NoteOff, (channel,
''' controlNumber, controlValue, time) for ControlChange.
SUB HMidiConsumerSetNoteOnCallback(BYVAL consumer AS HMidiConsumer, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_midi_consumer_set_note_on_callback(consumer.handle, cb, userData)
END SUB

SUB HMidiConsumerSetNoteOffCallback(BYVAL consumer AS HMidiConsumer, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_midi_consumer_set_note_off_callback(consumer.handle, cb, userData)
END SUB

SUB HMidiConsumerSetControlChangeCallback(BYVAL consumer AS HMidiConsumer, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_midi_consumer_set_control_change_callback(consumer.handle, cb, userData)
END SUB

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, b1 AS UBYTE, b2 AS UBYTE, b3 AS UBYTE, time AS LONGINT) - b1
''' is the channel, b2 the program number, b3 always 0.
SUB HMidiConsumerSetProgramChangeCallback(BYVAL consumer AS HMidiConsumer, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_midi_consumer_set_program_change_callback(consumer.handle, cb, userData)
END SUB

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, midiData AS ANY PTR, length AS UINTEGER, atomicFlag AS
''' INTEGER, time AS LONGINT) - the catch-all raw-bytes callback,
''' fired for every real incoming MIDI message regardless of type.
SUB HMidiConsumerSetDataCallback(BYVAL consumer AS HMidiConsumer, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_midi_consumer_set_data_callback(consumer.handle, cb, userData)
END SUB
