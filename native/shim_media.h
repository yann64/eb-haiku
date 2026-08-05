// eb-haiku native shim - Media Kit basics: play a real sound file. See
// shim.h's own top comment for why a hand-written shim is needed at
// all. Links against libmedia.so (confirmed real, present on the host
// via `ls /boot/system/lib/`).
//
// IMPORTANT, confirmed by direct reproduction, a real deviation from
// this package's own approved plan: the plain free-function
// `play_sound`/`stop_sound`/`wait_for_sound` API (media/PlaySound.h) -
// originally intended as the simplest possible path - is a literal
// UNIMPLEMENTED stub on this real Haiku build (hrev59922): calling it
// prints "UNIMPLEMENTED" to the log and does nothing. `BSoundPlayer` +
// `BSound` are real and fully functional (confirmed via a standalone
// C++ probe - real buffer negotiation with media_server, real audio
// playback with wall-clock timing matching the file's own duration) -
// this shim uses that path instead. `BSound`'s own destructor is
// private (ref-counted via AcquireRef/ReleaseRef) - eb_haiku_sound_
// release calls ReleaseRef(), not delete.
//
// A second real, confirmed finding: BSoundPlayer::WaitForSound's own
// return code is NOT a reliable success indicator here - it reports
// B_NOT_ALLOWED once a play_id has already finished/been removed from
// the player's internal table, even though playback demonstrably
// completed correctly (confirmed via real elapsed wall-clock time
// matching the file's own Duration()). Don't treat its return value as
// pass/fail.
#pragma once

extern "C" {

// ---- BSound (loads a whole file into memory) ----

// Takes a plain path - constructs the BEntry/entry_ref internally in
// C++, matching this package's own established "don't expose a new
// type unless it's genuinely reusable" philosophy.
void* eb_haiku_sound_create(const char* path);
int eb_haiku_sound_init_check(void* sound);
// bigtime_t (real 8-byte type, microseconds).
long long eb_haiku_sound_duration(void* sound);
// NOT delete - BSound's own destructor is private, ref-counted.
void eb_haiku_sound_release(void* sound);

// ---- BSoundPlayer ----

void* eb_haiku_sound_player_create(const char* name);
// Real-time buffer-callback synthesis - lower-level than the
// whole-file HSound/HSoundPlayerStartPlaying path above. `cb` is
// called repeatedly on Haiku's own real-time audio thread whenever
// more data is needed; fill up to `size` bytes of raw PCM into
// `buffer` before returning. The real BufferPlayerFunc's own
// media_raw_audio_format parameter is unpacked into plain scalars
// here (frame_rate/channel_count/format/byte_order) rather than
// exposed as a C++ reference across the ABI - matching this shim's
// own established "unpack the C++ struct into plain params" pattern
// (e.g. ShimView::Draw's BRect). The heap-allocated context pairing
// `cb`+`cookie` together is freed automatically by
// eb_haiku_sound_player_destroy - no separate destroy function needed.
typedef void (*EbHaikuBufferPlayerCallback)(void* cookie, void* buffer, unsigned long size,
                                             float frameRate, unsigned int channelCount,
                                             unsigned int audioFormat, unsigned int byteOrder);
void* eb_haiku_sound_player_create_with_buffer_callback(const char* name,
                                                         EbHaikuBufferPlayerCallback cb,
                                                         void* cookie);
// IMPORTANT, confirmed by direct reproduction: real BSoundPlayer's own
// Cookie() returns a real, non-NULL internal pointer even for a
// plain eb_haiku_sound_player_create result (NOT nullptr, as might be
// assumed) - it does NOT point at a BufferCallbackContext in that
// case. A single shared destroy function that tried to
// `delete Cookie()` unconditionally corrupted the heap and hung the
// process. A player created via
// eb_haiku_sound_player_create_with_buffer_callback MUST be destroyed
// with this function instead of the plain eb_haiku_sound_player_destroy.
void eb_haiku_sound_player_destroy_with_buffer_callback(void* player);
int eb_haiku_sound_player_init_check(void* player);
int eb_haiku_sound_player_start(void* player);
void eb_haiku_sound_player_stop(void* player);
// Returns a real play_id (int32), usable with IsPlaying/WaitForSound.
int eb_haiku_sound_player_start_playing(void* player, void* sound);
int eb_haiku_sound_player_is_playing(void* player, int id);
// See this header's own top comment - the return value is not a
// reliable success/failure indicator, only useful to block until the
// sound has stopped playing (one way or another).
int eb_haiku_sound_player_wait_for_sound(void* player, int id);
// For a plain eb_haiku_sound_player_create result ONLY - see
// eb_haiku_sound_player_destroy_with_buffer_callback's own doc comment
// above for why these must not be mixed.
void eb_haiku_sound_player_destroy(void* player);

} // extern "C"
