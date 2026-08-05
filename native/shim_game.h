// eb-haiku native shim - Game Kit (os/game/) - BGameSound and its
// three leaf subclasses: BFileGameSound (play a whole file),
// BSimpleGameSound (one-shot, file or raw in-memory PCM),
// BPushGameSound (direct lock/unlock buffer-fill polling, for
// procedurally-generated audio). Plain new/delete throughout - no
// ref-counting anywhere in this Kit (confirmed via header, unlike
// MIDI Kit 2). `BGameSoundDevice* device` is always NULL (the default
// system device) - no public header for that class exists at all.
//
// BGameSound's own methods (InitCheck/StartPlaying/StopPlaying/
// IsPlaying/SetGain/SetPan/Gain/Pan) are shared across all three leaf
// types via a single set of shim functions taking a plain `void*` and
// static_cast-ing to BGameSound* - safe because every method involved
// is either non-virtual on the base or correctly virtual-dispatches to
// the real subclass override (e.g. BFileGameSound::StartPlaying).
// eb_haiku_game_sound_destroy is likewise shared - BGameSound has a
// public virtual destructor, so `delete` via a BGameSound* base
// pointer correctly runs the real most-derived destructor regardless
// of which leaf type was actually constructed.
#pragma once

extern "C" {

// ---- BGameSound (shared base - game/GameSound.h) ----

int eb_haiku_game_sound_init_check(void* sound);
int eb_haiku_game_sound_start_playing(void* sound);
int eb_haiku_game_sound_is_playing(void* sound);
int eb_haiku_game_sound_stop_playing(void* sound);
int eb_haiku_game_sound_set_gain(void* sound, float gain, long long duration);
int eb_haiku_game_sound_set_pan(void* sound, float pan, long long duration);
float eb_haiku_game_sound_gain(void* sound);
float eb_haiku_game_sound_pan(void* sound);
void eb_haiku_game_sound_destroy(void* sound);

// ---- BFileGameSound (game/FileGameSound.h) ----

void* eb_haiku_file_game_sound_create(const char* path, int looping);
int eb_haiku_file_game_sound_preload(void* sound);
int eb_haiku_file_game_sound_set_paused(void* sound, int isPaused, long long rampTime);
int eb_haiku_file_game_sound_is_paused(void* sound);

// ---- BSimpleGameSound (game/SimpleGameSound.h) ----

void* eb_haiku_simple_game_sound_create_from_path(const char* path);
// gs_audio_format's own fields, passed individually (matching this
// shim's own established by-value-struct-as-separate-params
// convention, e.g. BRect/rgb_color elsewhere) rather than exposing a
// packed struct across the ABI. `format` is one of
// gs_audio_format::format's own real enum values (B_GS_U8/S16/F/S32,
// bound as H_GS_U8 etc. in the raw layer).
void* eb_haiku_simple_game_sound_create_from_buffer(const void* data, unsigned long frameCount,
                                                     float frameRate, unsigned int channelCount,
                                                     unsigned int format, unsigned int byteOrder,
                                                     unsigned long bufferSize);
int eb_haiku_simple_game_sound_set_is_looping(void* sound, int looping);
int eb_haiku_simple_game_sound_is_looping(void* sound);

// ---- BPushGameSound (game/PushGameSound.h) ----

void* eb_haiku_push_game_sound_create(unsigned long bufferFrameCount, float frameRate,
                                       unsigned int channelCount, unsigned int format,
                                       unsigned int byteOrder, unsigned long bufferSize,
                                       unsigned long bufferCount);
// Fills outPagePtr/outPageSize (caller-owned int* / ANY PTR* out
// params). Returns a lock_status (0 = lock_ok).
int eb_haiku_push_game_sound_lock_next_page(void* sound, void** outPagePtr,
                                             unsigned long* outPageSize);
int eb_haiku_push_game_sound_unlock_page(void* sound, void* pagePtr);

} // extern "C"
