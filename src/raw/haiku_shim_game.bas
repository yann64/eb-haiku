' Raw FFI layer: eb-haiku's Game Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_game.h.

' Real gs_audio_format::format enum values (game/GameSoundDefs.h) -
' 0x11/0x2/0x24/0x4 written as decimal (no hex literal syntax in
' eBasic).
CONST H_GS_U8 = 17
CONST H_GS_S16 = 2
CONST H_GS_F = 36
CONST H_GS_S32 = 4

Extern "C" Lib "ebhaikushim"
    ' ---- BGameSound (shared base) ----
    Declare Function eb_haiku_game_sound_init_check(BYVAL soundHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_game_sound_start_playing(BYVAL soundHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_game_sound_is_playing(BYVAL soundHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_game_sound_stop_playing(BYVAL soundHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_game_sound_set_gain(BYVAL soundHandle AS ANY PTR, BYVAL gain AS SINGLE, BYVAL duration AS LONGINT) AS INTEGER
    Declare Function eb_haiku_game_sound_set_pan(BYVAL soundHandle AS ANY PTR, BYVAL pan AS SINGLE, BYVAL duration AS LONGINT) AS INTEGER
    Declare Function eb_haiku_game_sound_gain(BYVAL soundHandle AS ANY PTR) AS SINGLE
    Declare Function eb_haiku_game_sound_pan(BYVAL soundHandle AS ANY PTR) AS SINGLE
    Declare Sub eb_haiku_game_sound_destroy(BYVAL soundHandle AS ANY PTR)

    ' ---- BFileGameSound ----
    Declare Function eb_haiku_file_game_sound_create(BYVAL path AS ZSTRING, BYVAL looping AS INTEGER) AS ANY PTR
    Declare Function eb_haiku_file_game_sound_preload(BYVAL soundHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_file_game_sound_set_paused(BYVAL soundHandle AS ANY PTR, BYVAL isPaused AS INTEGER, BYVAL rampTime AS LONGINT) AS INTEGER
    Declare Function eb_haiku_file_game_sound_is_paused(BYVAL soundHandle AS ANY PTR) AS INTEGER

    ' ---- BSimpleGameSound ----
    Declare Function eb_haiku_simple_game_sound_create_from_path(BYVAL path AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_simple_game_sound_create_from_buffer(BYVAL data AS ANY PTR, BYVAL frameCount AS ULONGINT, BYVAL frameRate AS SINGLE, BYVAL channelCount AS UINTEGER, BYVAL forFormat AS UINTEGER, BYVAL byteOrder AS UINTEGER, BYVAL bufferSize AS ULONGINT) AS ANY PTR
    Declare Function eb_haiku_simple_game_sound_set_is_looping(BYVAL soundHandle AS ANY PTR, BYVAL looping AS INTEGER) AS INTEGER
    Declare Function eb_haiku_simple_game_sound_is_looping(BYVAL soundHandle AS ANY PTR) AS INTEGER

    ' ---- BPushGameSound ----
    Declare Function eb_haiku_push_game_sound_create(BYVAL bufferFrameCount AS ULONGINT, BYVAL frameRate AS SINGLE, BYVAL channelCount AS UINTEGER, BYVAL forFormat AS UINTEGER, BYVAL byteOrder AS UINTEGER, BYVAL bufferSize AS ULONGINT, BYVAL bufferCount AS ULONGINT) AS ANY PTR
    Declare Function eb_haiku_push_game_sound_lock_next_page(BYVAL soundHandle AS ANY PTR, BYVAL outPagePtr AS ANY PTR, BYVAL outPageSize AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_push_game_sound_unlock_page(BYVAL soundHandle AS ANY PTR, BYVAL pagePtr AS ANY PTR) AS INTEGER
End Extern
