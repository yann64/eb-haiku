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
void eb_haiku_sound_player_destroy(void* player);

} // extern "C"
