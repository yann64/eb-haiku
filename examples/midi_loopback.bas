' MIDI Kit 2: connect a local producer to a local consumer and send a
' real note - a self-contained loopback needing no external MIDI
' hardware.
'
' IMPORTANT: both endpoints must be registered with the roster before
' Connect/Spray for any data to actually be delivered - see midi.bas's
' own top comment.

#include once "../src/lib.bas"

SUB OnNoteOn(userData AS ANY PTR, channel AS UBYTE, note AS UBYTE, velocity AS UBYTE, time AS LONGINT)
    PRINT "received NoteOn: channel=", channel, " note=", note, " velocity=", velocity
END SUB

DIM producer AS HMidiProducer
producer = HMidiProducerCreate("eb-haiku-example-producer")

DIM consumer AS HMidiConsumer
consumer = HMidiConsumerCreate("eb-haiku-example-consumer")
CALL HMidiConsumerSetNoteOnCallback(consumer, @OnNoteOn, 0)

CALL HMidiRosterRegister(producer.handle)
CALL HMidiRosterRegister(consumer.handle)
CALL HMidiProducerConnect(producer, consumer)

CALL HMidiProducerSprayNoteOn(producer, 1, 60, 100, 0)
CALL HSnooze(300000)

CALL HMidiProducerDisconnect(producer, consumer)
CALL HMidiRosterUnregister(producer.handle)
CALL HMidiRosterUnregister(consumer.handle)
CALL HMidiEndpointRelease(producer.handle)
CALL HMidiEndpointRelease(consumer.handle)
