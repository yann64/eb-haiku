// eb-haiku native shim - MIDI Kit 2 (os/midi2/) - the most novel
// binding in this shim so far: every endpoint class
// (BMidiEndpoint/BMidiProducer/BMidiConsumer/BMidiLocalProducer/
// BMidiLocalConsumer) is real-refcounted (a real fRefCount field +
// Acquire()/Release() inherited from BMidiEndpoint), with private
// (BMidiRoster/BMidiEndpoint/BMidiProducer/BMidiConsumer) or protected
// (BMidiLocalProducer/BMidiLocalConsumer) destructors enforcing it at
// compile time - eb_haiku_midi_endpoint_release below calls
// Release(), NEVER delete (there is deliberately no "destroy"
// function using `delete` anywhere in this file).
//
// BMidiRoster itself has a private ctor/dtor too - a pure static-
// method facade, never instantiated; every eb_haiku_midi_roster_*
// function below calls a BMidiRoster:: static method directly.
//
// BMidiLocalConsumer receives incoming MIDI entirely via virtual
// method overrides - needs a real shim subclass (ShimMidiConsumer,
// native/shim_midi.cpp), the same forwarding pattern as
// shim_interface.cpp's own ShimWindow/ShimView. Only the most
// commonly used overrides are forwarded (NoteOn/NoteOff/
// ControlChange/ProgramChange, plus the catch-all Data()) - the
// remaining 9 real virtuals (KeyPressure/ChannelPressure/PitchBend/
// SystemExclusive/SystemCommon/SystemRealTime/TempoChange/
// AllNotesOff/Timeout) are a reasonable follow-on, not bound here.
//
// BMidiRoster::StartWatching/StopWatching (live endpoint-registration
// notifications) likewise not bound this pass - a reasonable
// follow-on, not needed for the real Connect+Spray+receive loopback
// path this binding targets.
#pragma once

extern "C" {

// ---- BMidiRoster (static-only facade - never instantiated) ----

// `cookie` is caller-owned (BYVAL ANY PTR pointing at an int32,
// matching this shim's own established cookie-iteration convention,
// e.g. eb_haiku_network_roster_get_next_interface) - start at 0,
// updated in place. Returns NULL once enumeration is exhausted.
void* eb_haiku_midi_roster_next_producer(int* cookie);
void* eb_haiku_midi_roster_next_consumer(int* cookie);
void* eb_haiku_midi_roster_find_producer(int id, int localOnly);
void* eb_haiku_midi_roster_find_consumer(int id, int localOnly);
int eb_haiku_midi_roster_register(void* endpoint);
int eb_haiku_midi_roster_unregister(void* endpoint);

// ---- BMidiEndpoint (shared base - BMidiLocalProducer/
// BMidiLocalConsumer, and any BMidiProducer*/BMidiConsumer* obtained
// via the roster, all work through these via a plain static_cast,
// matching Game Kit's own shared-base-function convention: every
// class in this inheritance chain uses single inheritance, so the
// address never needs adjustment) ----

const char* eb_haiku_midi_endpoint_name(void* endpoint);
void eb_haiku_midi_endpoint_set_name(void* endpoint, const char* name);
int eb_haiku_midi_endpoint_id(void* endpoint);
int eb_haiku_midi_endpoint_is_valid(void* endpoint);
int eb_haiku_midi_endpoint_is_local(void* endpoint);
// NEVER `delete` - see this header's own top comment.
int eb_haiku_midi_endpoint_release(void* endpoint);
void eb_haiku_midi_endpoint_acquire(void* endpoint);

// ---- BMidiLocalProducer (public ctor) ----

void* eb_haiku_midi_local_producer_create(const char* name);
int eb_haiku_midi_producer_connect(void* producer, void* consumer);
int eb_haiku_midi_producer_disconnect(void* producer, void* consumer);
int eb_haiku_midi_producer_is_connected(void* producer, void* consumer);

void eb_haiku_midi_producer_spray_note_on(void* producer, unsigned char channel,
                                           unsigned char note, unsigned char velocity,
                                           long long time);
void eb_haiku_midi_producer_spray_note_off(void* producer, unsigned char channel,
                                            unsigned char note, unsigned char velocity,
                                            long long time);
void eb_haiku_midi_producer_spray_control_change(void* producer, unsigned char channel,
                                                  unsigned char controlNumber,
                                                  unsigned char controlValue, long long time);
void eb_haiku_midi_producer_spray_program_change(void* producer, unsigned char channel,
                                                  unsigned char programNumber, long long time);

// ---- BMidiLocalConsumer (public ctor - needs ShimMidiConsumer) ----

typedef void (*EbHaikuMidi3ByteCallback)(void* userData, unsigned char b1, unsigned char b2,
                                         unsigned char b3, long long time);
typedef void (*EbHaikuMidiDataCallback)(void* userData, const unsigned char* data,
                                        unsigned long length, int atomic, long long time);

void* eb_haiku_midi_local_consumer_create(const char* name);
void eb_haiku_midi_consumer_set_note_on_callback(void* consumer, EbHaikuMidi3ByteCallback cb,
                                                  void* userData);
void eb_haiku_midi_consumer_set_note_off_callback(void* consumer, EbHaikuMidi3ByteCallback cb,
                                                   void* userData);
void eb_haiku_midi_consumer_set_control_change_callback(void* consumer,
                                                         EbHaikuMidi3ByteCallback cb,
                                                         void* userData);
void eb_haiku_midi_consumer_set_program_change_callback(void* consumer,
                                                         EbHaikuMidi3ByteCallback cb,
                                                         void* userData);
void eb_haiku_midi_consumer_set_data_callback(void* consumer, EbHaikuMidiDataCallback cb,
                                               void* userData);

} // extern "C"
