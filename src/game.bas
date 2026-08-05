' Idiomatic layer: Game Kit - BGameSound and its three leaf
' subclasses. Plain new/delete throughout - no ref-counting anywhere
' in this Kit (a real, confirmed contrast with MIDI Kit 2's own
' Acquire/Release convention). `BGameSoundDevice` (the optional custom
' output-device parameter every real constructor takes) is never
' exposed - no public header for it exists at all; the default system
' device is always used.
'
' Every constructor below (HFileGameSoundCreate/
' HSimpleGameSoundCreateFromPath/CreateFromBuffer/HPushGameSoundCreate)
' returns the single shared HGameSound type directly - every leaf class
' IS-A BGameSound in real Haiku, matching this package's own
' established reuse convention (e.g. HPopUpMenuCreate returning HMenu
' directly, menu.bas). Leaf-specific functions (HFileGameSound*/
' HSimpleGameSound*/HPushGameSound*) likewise just take an HGameSound
' handle - the real C++ static_cast to the specific leaf type happens
' inside the shim, which is safe because callers only ever pass a
' handle actually created by that same leaf constructor.

#include once "raw/haiku_shim_game.bas"

TYPE HGameSound
    handle AS ANY PTR
END TYPE

FUNCTION HGameSoundInitCheck(BYVAL s AS HGameSound) AS INTEGER
    HGameSoundInitCheck = eb_haiku_game_sound_init_check(s.handle)
END FUNCTION

FUNCTION HGameSoundStartPlaying(BYVAL s AS HGameSound) AS INTEGER
    HGameSoundStartPlaying = eb_haiku_game_sound_start_playing(s.handle)
END FUNCTION

FUNCTION HGameSoundIsPlaying(BYVAL s AS HGameSound) AS INTEGER
    HGameSoundIsPlaying = eb_haiku_game_sound_is_playing(s.handle)
END FUNCTION

FUNCTION HGameSoundStopPlaying(BYVAL s AS HGameSound) AS INTEGER
    HGameSoundStopPlaying = eb_haiku_game_sound_stop_playing(s.handle)
END FUNCTION

FUNCTION HGameSoundSetGain(BYVAL s AS HGameSound, BYVAL gain AS SINGLE, BYVAL duration AS LONGINT) AS INTEGER
    HGameSoundSetGain = eb_haiku_game_sound_set_gain(s.handle, gain, duration)
END FUNCTION

FUNCTION HGameSoundSetPan(BYVAL s AS HGameSound, BYVAL pan AS SINGLE, BYVAL duration AS LONGINT) AS INTEGER
    HGameSoundSetPan = eb_haiku_game_sound_set_pan(s.handle, pan, duration)
END FUNCTION

FUNCTION HGameSoundGain(BYVAL s AS HGameSound) AS SINGLE
    HGameSoundGain = eb_haiku_game_sound_gain(s.handle)
END FUNCTION

FUNCTION HGameSoundPan(BYVAL s AS HGameSound) AS SINGLE
    HGameSoundPan = eb_haiku_game_sound_pan(s.handle)
END FUNCTION

''' Frees any HGameSound-family handle (from HFileGameSoundCreate/
''' HSimpleGameSoundCreateFromPath/CreateFromBuffer/
''' HPushGameSoundCreate alike) - BGameSound's own destructor is public
''' and virtual, so a plain `delete` via its base pointer correctly
''' runs the real most-derived destructor regardless of which leaf
''' type was actually constructed. Call exactly once.
SUB HGameSoundFree(BYVAL s AS HGameSound)
    CALL eb_haiku_game_sound_destroy(s.handle)
END SUB

CONST H_NOT_PAUSED = 0
CONST H_PAUSE_IN_PROGRESS = 1
CONST H_PAUSED = 2

''' Plays a whole real sound file, decoding its format automatically -
''' the primary Game Kit target for "just play this file."
FUNCTION HFileGameSoundCreate(path AS ZSTRING, BYVAL looping AS INTEGER) AS HGameSound
    DIM s AS HGameSound
    s.handle = eb_haiku_file_game_sound_create(path, looping)
    HFileGameSoundCreate = s
END FUNCTION

FUNCTION HFileGameSoundPreload(BYVAL s AS HGameSound) AS INTEGER
    HFileGameSoundPreload = eb_haiku_file_game_sound_preload(s.handle)
END FUNCTION

FUNCTION HFileGameSoundSetPaused(BYVAL s AS HGameSound, BYVAL isPaused AS INTEGER, BYVAL rampTime AS LONGINT) AS INTEGER
    HFileGameSoundSetPaused = eb_haiku_file_game_sound_set_paused(s.handle, isPaused, rampTime)
END FUNCTION

''' Returns H_NOT_PAUSED/H_PAUSE_IN_PROGRESS/H_PAUSED.
FUNCTION HFileGameSoundIsPaused(BYVAL s AS HGameSound) AS INTEGER
    HFileGameSoundIsPaused = eb_haiku_file_game_sound_is_paused(s.handle)
END FUNCTION

''' A one-shot sound loaded from a real file.
FUNCTION HSimpleGameSoundCreateFromPath(path AS ZSTRING) AS HGameSound
    DIM s AS HGameSound
    s.handle = eb_haiku_simple_game_sound_create_from_path(path)
    HSimpleGameSoundCreateFromPath = s
END FUNCTION

''' A one-shot sound from raw in-memory PCM (`gameData`, `frameCount`
''' frames) in the given format (H_GS_U8/S16/F/S32, raw/
''' haiku_shim_game.bas).
FUNCTION HSimpleGameSoundCreateFromBuffer(BYVAL gameData AS ANY PTR, BYVAL frameCount AS ULONGINT, BYVAL frameRate AS SINGLE, BYVAL channelCount AS UINTEGER, BYVAL forFormat AS UINTEGER, BYVAL byteOrder AS UINTEGER, BYVAL bufferSize AS ULONGINT) AS HGameSound
    DIM s AS HGameSound
    s.handle = eb_haiku_simple_game_sound_create_from_buffer(gameData, frameCount, frameRate, channelCount, forFormat, byteOrder, bufferSize)
    HSimpleGameSoundCreateFromBuffer = s
END FUNCTION

FUNCTION HSimpleGameSoundSetIsLooping(BYVAL s AS HGameSound, BYVAL looping AS INTEGER) AS INTEGER
    HSimpleGameSoundSetIsLooping = eb_haiku_simple_game_sound_set_is_looping(s.handle, looping)
END FUNCTION

FUNCTION HSimpleGameSoundIsLooping(BYVAL s AS HGameSound) AS INTEGER
    HSimpleGameSoundIsLooping = eb_haiku_simple_game_sound_is_looping(s.handle)
END FUNCTION

''' A direct lock/unlock buffer-fill sound, for procedurally-generated
''' audio - no callback needed. Format fields as
''' HSimpleGameSoundCreateFromBuffer.
FUNCTION HPushGameSoundCreate(BYVAL bufferFrameCount AS ULONGINT, BYVAL frameRate AS SINGLE, BYVAL channelCount AS UINTEGER, BYVAL forFormat AS UINTEGER, BYVAL byteOrder AS UINTEGER, BYVAL bufferSize AS ULONGINT, BYVAL bufferCount AS ULONGINT) AS HGameSound
    DIM s AS HGameSound
    s.handle = eb_haiku_push_game_sound_create(bufferFrameCount, frameRate, channelCount, forFormat, byteOrder, bufferSize, bufferCount)
    HPushGameSoundCreate = s
END FUNCTION

''' Locks the next real page for writing, filling `outPagePtr`/
''' `outPageSize` - pass `@yourPagePtrVar`/`@yourPageSizeVar` (matching
''' this package's own established buffer-out convention, e.g.
''' HAreaCreate - a real eBasic codegen limitation prevents a `BYREF
''' ... AS ANY PTR` parameter shape from compiling at any real call
''' site, confirmed by direct reproduction). Returns a lock_status (0 =
''' lock_ok, see PushGameSound.h's own enum - a negative value means
''' lock_failed). Write up to `outPageSize` bytes of real PCM data into
''' `outPagePtr`, then call HPushGameSoundUnlockPage.
FUNCTION HPushGameSoundLockNextPage(BYVAL s AS HGameSound, BYVAL outPagePtr AS ANY PTR, BYVAL outPageSize AS ANY PTR) AS INTEGER
    HPushGameSoundLockNextPage = eb_haiku_push_game_sound_lock_next_page(s.handle, outPagePtr, outPageSize)
END FUNCTION

FUNCTION HPushGameSoundUnlockPage(BYVAL s AS HGameSound, BYVAL pagePtr AS ANY PTR) AS INTEGER
    HPushGameSoundUnlockPage = eb_haiku_push_game_sound_unlock_page(s.handle, pagePtr)
END FUNCTION
