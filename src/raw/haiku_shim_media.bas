' Raw FFI layer: eb-haiku's Media Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_media.h.
'
' IMPORTANT, a real deviation from this package's own original plan,
' confirmed by direct reproduction: real Haiku's plain free-function
' `play_sound`/`stop_sound`/`wait_for_sound` API is a literal
' UNIMPLEMENTED stub on this build - calling it does nothing. This
' file instead binds the real, fully functional `BSoundPlayer`/`BSound`
' path (confirmed working via a standalone C++ probe: real buffer
' negotiation with media_server, real audio playback with wall-clock
' timing matching the file's own duration).

Extern "C" Lib "ebhaikushim"
    ' ---- BSound ----
    Declare Function eb_haiku_sound_create(BYVAL path AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_sound_init_check(BYVAL sound AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_sound_duration(BYVAL sound AS ANY PTR) AS LONGINT
    ' NOT a destroy/free in the usual sense - BSound's own destructor is
    ' private, ref-counted; this calls ReleaseRef().
    Declare Sub eb_haiku_sound_release(BYVAL sound AS ANY PTR)

    ' ---- BSoundPlayer ----
    Declare Function eb_haiku_sound_player_create(BYVAL name AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_sound_player_init_check(BYVAL player AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_sound_player_start(BYVAL player AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_sound_player_stop(BYVAL player AS ANY PTR)
    Declare Function eb_haiku_sound_player_start_playing(BYVAL player AS ANY PTR, BYVAL sound AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_sound_player_is_playing(BYVAL player AS ANY PTR, BYVAL id AS INTEGER) AS INTEGER
    ' IMPORTANT: the return value is NOT a reliable success/failure
    ' indicator (confirmed by direct reproduction - it reports a
    ' generic error once a play_id has already finished, even though
    ' playback demonstrably completed correctly) - only useful to block
    ' until the sound has stopped playing, one way or another.
    Declare Function eb_haiku_sound_player_wait_for_sound(BYVAL player AS ANY PTR, BYVAL id AS INTEGER) AS INTEGER
    Declare Sub eb_haiku_sound_player_destroy(BYVAL player AS ANY PTR)
End Extern
