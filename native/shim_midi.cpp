#include "shim_midi.h"

#include <MidiConsumer.h>
#include <MidiProducer.h>
#include <MidiRoster.h>

namespace {

/// Same forwarding pattern as shim_interface.cpp's own ShimView/
/// ShimWindow (see their top comments) - the only way to reach
/// BMidiLocalConsumer's own virtual NoteOn/NoteOff/etc. from eBasic.
/// Only the most commonly used overrides are forwarded (see
/// shim_midi.h's own top comment for the rest).
class ShimMidiConsumer : public BMidiLocalConsumer {
public:
    explicit ShimMidiConsumer(const char* name) : BMidiLocalConsumer(name) {}

    void SetNoteOnCallback(EbHaikuMidi3ByteCallback cb, void* userData) {
        fNoteOnCallback = cb;
        fNoteOnUserData = userData;
    }
    void SetNoteOffCallback(EbHaikuMidi3ByteCallback cb, void* userData) {
        fNoteOffCallback = cb;
        fNoteOffUserData = userData;
    }
    void SetControlChangeCallback(EbHaikuMidi3ByteCallback cb, void* userData) {
        fControlChangeCallback = cb;
        fControlChangeUserData = userData;
    }
    void SetProgramChangeCallback(EbHaikuMidi3ByteCallback cb, void* userData) {
        fProgramChangeCallback = cb;
        fProgramChangeUserData = userData;
    }
    void SetDataCallback(EbHaikuMidiDataCallback cb, void* userData) {
        fDataCallback = cb;
        fDataUserData = userData;
    }

    void NoteOn(uchar channel, uchar note, uchar velocity, bigtime_t time) override {
        if (fNoteOnCallback) fNoteOnCallback(fNoteOnUserData, channel, note, velocity, time);
    }
    void NoteOff(uchar channel, uchar note, uchar velocity, bigtime_t time) override {
        if (fNoteOffCallback) fNoteOffCallback(fNoteOffUserData, channel, note, velocity, time);
    }
    void ControlChange(uchar channel, uchar controlNumber, uchar controlValue,
                        bigtime_t time) override {
        if (fControlChangeCallback) {
            fControlChangeCallback(fControlChangeUserData, channel, controlNumber, controlValue,
                                   time);
        }
    }
    void ProgramChange(uchar channel, uchar programNumber, bigtime_t time) override {
        if (fProgramChangeCallback) {
            fProgramChangeCallback(fProgramChangeUserData, channel, programNumber, 0, time);
        }
    }
    void Data(uchar* data, size_t length, bool atomic, bigtime_t time) override {
        // IMPORTANT, confirmed by direct reproduction: real
        // BMidiLocalConsumer::Data() is what actually parses the raw
        // MIDI byte stream and dispatches to NoteOn/NoteOff/
        // ControlChange/etc. internally - overriding it without
        // calling the base implementation silently breaks EVERY other
        // override in this class (they simply never fire). Always
        // forward to the real base implementation first.
        BMidiLocalConsumer::Data(data, length, atomic, time);
        if (fDataCallback) {
            fDataCallback(fDataUserData, data, static_cast<unsigned long>(length),
                          atomic ? 1 : 0, time);
        }
    }

private:
    EbHaikuMidi3ByteCallback fNoteOnCallback = nullptr;
    void* fNoteOnUserData = nullptr;
    EbHaikuMidi3ByteCallback fNoteOffCallback = nullptr;
    void* fNoteOffUserData = nullptr;
    EbHaikuMidi3ByteCallback fControlChangeCallback = nullptr;
    void* fControlChangeUserData = nullptr;
    EbHaikuMidi3ByteCallback fProgramChangeCallback = nullptr;
    void* fProgramChangeUserData = nullptr;
    EbHaikuMidiDataCallback fDataCallback = nullptr;
    void* fDataUserData = nullptr;
};

} // namespace

extern "C" {

// ---- BMidiRoster ----

void* eb_haiku_midi_roster_next_producer(int* cookie) {
    int32 c = *cookie;
    BMidiProducer* p = BMidiRoster::NextProducer(&c);
    *cookie = c;
    return p;
}

void* eb_haiku_midi_roster_next_consumer(int* cookie) {
    int32 c = *cookie;
    BMidiConsumer* p = BMidiRoster::NextConsumer(&c);
    *cookie = c;
    return p;
}

void* eb_haiku_midi_roster_find_producer(int id, int localOnly) {
    return BMidiRoster::FindProducer(id, localOnly != 0);
}

void* eb_haiku_midi_roster_find_consumer(int id, int localOnly) {
    return BMidiRoster::FindConsumer(id, localOnly != 0);
}

int eb_haiku_midi_roster_register(void* endpoint) {
    return BMidiRoster::Register(static_cast<BMidiEndpoint*>(endpoint));
}

int eb_haiku_midi_roster_unregister(void* endpoint) {
    return BMidiRoster::Unregister(static_cast<BMidiEndpoint*>(endpoint));
}

// ---- BMidiEndpoint (shared) ----

const char* eb_haiku_midi_endpoint_name(void* endpoint) {
    return static_cast<BMidiEndpoint*>(endpoint)->Name();
}

void eb_haiku_midi_endpoint_set_name(void* endpoint, const char* name) {
    static_cast<BMidiEndpoint*>(endpoint)->SetName(name);
}

int eb_haiku_midi_endpoint_id(void* endpoint) {
    return static_cast<BMidiEndpoint*>(endpoint)->ID();
}

int eb_haiku_midi_endpoint_is_valid(void* endpoint) {
    return static_cast<BMidiEndpoint*>(endpoint)->IsValid() ? 1 : 0;
}

int eb_haiku_midi_endpoint_is_local(void* endpoint) {
    return static_cast<BMidiEndpoint*>(endpoint)->IsLocal() ? 1 : 0;
}

int eb_haiku_midi_endpoint_release(void* endpoint) {
    return static_cast<BMidiEndpoint*>(endpoint)->Release();
}

void eb_haiku_midi_endpoint_acquire(void* endpoint) {
    static_cast<BMidiEndpoint*>(endpoint)->Acquire();
}

// ---- BMidiLocalProducer ----

void* eb_haiku_midi_local_producer_create(const char* name) {
    return new BMidiLocalProducer(name);
}

int eb_haiku_midi_producer_connect(void* producer, void* consumer) {
    return static_cast<BMidiLocalProducer*>(producer)->Connect(
        static_cast<BMidiConsumer*>(consumer));
}

int eb_haiku_midi_producer_disconnect(void* producer, void* consumer) {
    return static_cast<BMidiLocalProducer*>(producer)->Disconnect(
        static_cast<BMidiConsumer*>(consumer));
}

int eb_haiku_midi_producer_is_connected(void* producer, void* consumer) {
    return static_cast<BMidiLocalProducer*>(producer)->IsConnected(
               static_cast<BMidiConsumer*>(consumer))
               ? 1
               : 0;
}

void eb_haiku_midi_producer_spray_note_on(void* producer, unsigned char channel,
                                           unsigned char note, unsigned char velocity,
                                           long long time) {
    static_cast<BMidiLocalProducer*>(producer)->SprayNoteOn(channel, note, velocity, time);
}

void eb_haiku_midi_producer_spray_note_off(void* producer, unsigned char channel,
                                            unsigned char note, unsigned char velocity,
                                            long long time) {
    static_cast<BMidiLocalProducer*>(producer)->SprayNoteOff(channel, note, velocity, time);
}

void eb_haiku_midi_producer_spray_control_change(void* producer, unsigned char channel,
                                                  unsigned char controlNumber,
                                                  unsigned char controlValue, long long time) {
    static_cast<BMidiLocalProducer*>(producer)->SprayControlChange(channel, controlNumber,
                                                                     controlValue, time);
}

void eb_haiku_midi_producer_spray_program_change(void* producer, unsigned char channel,
                                                  unsigned char programNumber, long long time) {
    static_cast<BMidiLocalProducer*>(producer)->SprayProgramChange(channel, programNumber, time);
}

// ---- BMidiLocalConsumer ----

void* eb_haiku_midi_local_consumer_create(const char* name) { return new ShimMidiConsumer(name); }

void eb_haiku_midi_consumer_set_note_on_callback(void* consumer, EbHaikuMidi3ByteCallback cb,
                                                  void* userData) {
    static_cast<ShimMidiConsumer*>(consumer)->SetNoteOnCallback(cb, userData);
}

void eb_haiku_midi_consumer_set_note_off_callback(void* consumer, EbHaikuMidi3ByteCallback cb,
                                                   void* userData) {
    static_cast<ShimMidiConsumer*>(consumer)->SetNoteOffCallback(cb, userData);
}

void eb_haiku_midi_consumer_set_control_change_callback(void* consumer,
                                                         EbHaikuMidi3ByteCallback cb,
                                                         void* userData) {
    static_cast<ShimMidiConsumer*>(consumer)->SetControlChangeCallback(cb, userData);
}

void eb_haiku_midi_consumer_set_program_change_callback(void* consumer,
                                                         EbHaikuMidi3ByteCallback cb,
                                                         void* userData) {
    static_cast<ShimMidiConsumer*>(consumer)->SetProgramChangeCallback(cb, userData);
}

void eb_haiku_midi_consumer_set_data_callback(void* consumer, EbHaikuMidiDataCallback cb,
                                               void* userData) {
    static_cast<ShimMidiConsumer*>(consumer)->SetDataCallback(cb, userData);
}

} // extern "C"
