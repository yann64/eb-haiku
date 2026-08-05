' MIDI Kit 2: BMidiLocalProducer/BMidiLocalConsumer - a real, self-
' contained loopback test (no external MIDI hardware needed). Every
' endpoint here is real-refcounted - HMidiEndpointRelease is called
' instead of any "free" function (see midi.bas's own top comment).

#include once "../src/lib.bas"

DIM gGotNoteOn AS INTEGER
DIM gNoteOnChannel AS INTEGER
DIM gNoteOnNote AS INTEGER
DIM gNoteOnVelocity AS INTEGER
gGotNoteOn = 0

SUB OnNoteOn(userData AS ANY PTR, b1 AS UBYTE, b2 AS UBYTE, b3 AS UBYTE, time AS LONGINT)
    gGotNoteOn = 1
    gNoteOnChannel = b1
    gNoteOnNote = b2
    gNoteOnVelocity = b3
END SUB

DIM gGotNoteOff AS INTEGER
gGotNoteOff = 0

SUB OnNoteOff(userData AS ANY PTR, b1 AS UBYTE, b2 AS UBYTE, b3 AS UBYTE, time AS LONGINT)
    gGotNoteOff = 1
END SUB

DIM gGotControlChange AS INTEGER
gGotControlChange = 0

SUB OnControlChange(userData AS ANY PTR, b1 AS UBYTE, b2 AS UBYTE, b3 AS UBYTE, time AS LONGINT)
    gGotControlChange = 1
END SUB

DIM producer AS HMidiProducer
producer = HMidiProducerCreate("eb-haiku-test-producer")
IF HMidiEndpointIsValid(producer.handle) <> 1 THEN
    PRINT "FAIL: HMidiProducerCreate did not produce a valid endpoint"
    CALL ExitProcess(1)
END IF

DIM consumer AS HMidiConsumer
consumer = HMidiConsumerCreate("eb-haiku-test-consumer")
IF HMidiEndpointIsValid(consumer.handle) <> 1 THEN
    PRINT "FAIL: HMidiConsumerCreate did not produce a valid endpoint"
    CALL ExitProcess(1)
END IF

CALL HMidiConsumerSetNoteOnCallback(consumer, @OnNoteOn, 0)
CALL HMidiConsumerSetNoteOffCallback(consumer, @OnNoteOff, 0)
CALL HMidiConsumerSetControlChangeCallback(consumer, @OnControlChange, 0)

' IMPORTANT, confirmed by direct reproduction: BOTH endpoints must be
' registered with the roster BEFORE Connect/Spray* for any real data
' to actually be delivered - real MIDI Kit 2 routing always goes
' through the out-of-process midi_server, even for two purely local
' endpoints (see midi.bas's own top comment).
DIM rc AS INTEGER
rc = HMidiRosterRegister(producer.handle)
IF rc <> 0 THEN
    PRINT "FAIL: HMidiRosterRegister(producer) returned ", rc
    CALL ExitProcess(1)
END IF
rc = HMidiRosterRegister(consumer.handle)
IF rc <> 0 THEN
    PRINT "FAIL: HMidiRosterRegister(consumer) returned ", rc
    CALL ExitProcess(1)
END IF

rc = HMidiProducerConnect(producer, consumer)
IF rc <> 0 THEN
    PRINT "FAIL: HMidiProducerConnect returned ", rc
    CALL ExitProcess(1)
END IF
IF HMidiProducerIsConnected(producer, consumer) <> 1 THEN
    PRINT "FAIL: expected IsConnected to be true after a successful Connect"
    CALL ExitProcess(1)
END IF
PRINT "Connect ok"

CALL HMidiProducerSprayNoteOn(producer, 1, 60, 100, 0)
CALL HMidiProducerSprayNoteOff(producer, 1, 60, 0, 0)
CALL HMidiProducerSprayControlChange(producer, 1, 7, 127, 0)

' Real MIDI delivery happens on a background thread inside libmidi2 -
' give it a moment to arrive, matching this package's own established
' "poll, don't assume instant delivery" discipline.
DIM waited AS INTEGER
waited = 0
DO WHILE (gGotNoteOn = 0 OR gGotNoteOff = 0 OR gGotControlChange = 0) AND waited < 2000000
    CALL HSnooze(50000)
    waited = waited + 50000
LOOP

PRINT "gGotNoteOn=", gGotNoteOn, " channel=", gNoteOnChannel, " note=", gNoteOnNote, " velocity=", gNoteOnVelocity
PRINT "gGotNoteOff=", gGotNoteOff
PRINT "gGotControlChange=", gGotControlChange

IF gGotNoteOn <> 1 THEN
    PRINT "FAIL: never received a real NoteOn"
    CALL ExitProcess(1)
END IF
IF gNoteOnChannel <> 1 OR gNoteOnNote <> 60 OR gNoteOnVelocity <> 100 THEN
    PRINT "FAIL: NoteOn field mismatch"
    CALL ExitProcess(1)
END IF
IF gGotNoteOff <> 1 THEN
    PRINT "FAIL: never received a real NoteOff"
    CALL ExitProcess(1)
END IF
IF gGotControlChange <> 1 THEN
    PRINT "FAIL: never received a real ControlChange"
    CALL ExitProcess(1)
END IF

CALL HMidiProducerDisconnect(producer, consumer)
CALL HMidiRosterUnregister(producer.handle)
CALL HMidiRosterUnregister(consumer.handle)
CALL HMidiEndpointRelease(producer.handle)
CALL HMidiEndpointRelease(consumer.handle)

PRINT "midi basics test ok"
