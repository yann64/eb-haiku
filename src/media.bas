' Idiomatic layer: play a real sound file, via BSoundPlayer + BSound
' (see raw/haiku_shim_media.bas's own top comment for why this package
' uses this path rather than the plain play_sound() free function -
' the latter is a literal unimplemented stub on real Haiku).
'
' IMPORTANT, confirmed by direct reproduction: BSoundPlayer runs its
' own background thread talking to media_server. Since HSoundPlayer/
' HSound are opaque heap handles (not C++ RAII objects), nothing
' destructs them automatically - if the process calls ExitProcess (or
' otherwise reaches `std::exit()`) while an HSoundPlayer is still
' active, the still-running background thread can make the process
' hang indefinitely instead of exiting (std::exit() only runs static-
' storage-duration destructors/atexit handlers, never a live thread's
' own cleanup). Always call HSoundPlayerStop + HSoundPlayerFree (and
' HSoundRelease) before the program exits by any path, including an
' error/ExitProcess path - not just on the success path.

#include once "raw/haiku_shim_media.bas"

TYPE HSound
    handle AS ANY PTR
END TYPE

''' Loads `path` entirely into memory. Check HSoundInitCheck before use.
FUNCTION HSoundCreate(path AS ZSTRING) AS HSound
    DIM s AS HSound
    s.handle = eb_haiku_sound_create(path)
    HSoundCreate = s
END FUNCTION

FUNCTION HSoundInitCheck(BYVAL s AS HSound) AS INTEGER
    HSoundInitCheck = eb_haiku_sound_init_check(s.handle)
END FUNCTION

''' The sound's own real duration, in microseconds.
FUNCTION HSoundDuration(BYVAL s AS HSound) AS LONGINT
    HSoundDuration = eb_haiku_sound_duration(s.handle)
END FUNCTION

''' Releases an HSound - call exactly once, once no longer playing.
SUB HSoundRelease(BYVAL s AS HSound)
    CALL eb_haiku_sound_release(s.handle)
END SUB

TYPE HSoundPlayer
    handle AS ANY PTR
END TYPE

FUNCTION HSoundPlayerCreate(name AS ZSTRING) AS HSoundPlayer
    DIM p AS HSoundPlayer
    p.handle = eb_haiku_sound_player_create(name)
    HSoundPlayerCreate = p
END FUNCTION

FUNCTION HSoundPlayerInitCheck(BYVAL p AS HSoundPlayer) AS INTEGER
    HSoundPlayerInitCheck = eb_haiku_sound_player_init_check(p.handle)
END FUNCTION

''' Starts the player's own connection to the system mixer - call once,
''' before HSoundPlayerStartPlaying.
FUNCTION HSoundPlayerStart(BYVAL p AS HSoundPlayer) AS INTEGER
    HSoundPlayerStart = eb_haiku_sound_player_start(p.handle)
END FUNCTION

SUB HSoundPlayerStop(BYVAL p AS HSoundPlayer)
    CALL eb_haiku_sound_player_stop(p.handle)
END SUB

''' Begins playing `sound` - returns a real play_id, usable with
''' HSoundPlayerIsPlaying/WaitForSound.
FUNCTION HSoundPlayerStartPlaying(BYVAL p AS HSoundPlayer, BYVAL s AS HSound) AS INTEGER
    HSoundPlayerStartPlaying = eb_haiku_sound_player_start_playing(p.handle, s.handle)
END FUNCTION

FUNCTION HSoundPlayerIsPlaying(BYVAL p AS HSoundPlayer, BYVAL id AS INTEGER) AS INTEGER
    HSoundPlayerIsPlaying = eb_haiku_sound_player_is_playing(p.handle, id)
END FUNCTION

''' Blocks until `id` has stopped playing, one way or another.
''' IMPORTANT, confirmed by direct reproduction: the return value is
''' NOT a reliable success/failure indicator on real Haiku (it reports
''' a generic error once the sound has already finished, even after a
''' real, complete, correct playback) - don't treat it as pass/fail.
FUNCTION HSoundPlayerWaitForSound(BYVAL p AS HSoundPlayer, BYVAL id AS INTEGER) AS INTEGER
    HSoundPlayerWaitForSound = eb_haiku_sound_player_wait_for_sound(p.handle, id)
END FUNCTION

''' Frees an HSoundPlayer - call exactly once.
SUB HSoundPlayerFree(BYVAL p AS HSoundPlayer)
    CALL eb_haiku_sound_player_destroy(p.handle)
END SUB
