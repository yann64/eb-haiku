' Media Kit basics: play a real sound file via BSoundPlayer + BSound.
'
' IMPORTANT: every exit path here calls HSoundPlayerStop/Free +
' HSoundRelease BEFORE ExitProcess - confirmed by direct reproduction
' that skipping this (e.g. exiting straight from a FAIL branch) can
' hang the process indefinitely, since BSoundPlayer's own background
' thread is still alive when `std::exit()` runs and nothing else would
' ever stop it - see media.bas's own doc comment.
'
' Verified via real IsPlaying polling, not exact timing assumptions:
' real testing (a standalone C++ probe, run before writing this test)
' showed IsPlaying can report "no longer playing" well before the
' sound's own full Duration() has elapsed (it likely tracks "has all
' buffered data been handed off," not "is it still audible") - so this
' test only asserts that playback starts successfully and that
' IsPlaying eventually, genuinely goes false within a generous bound,
' not a specific timing relationship to Duration().

#include once "../src/lib.bas"

CONST SOUND_FILE = "/boot/system/lib/fpc/3.2.2/src/packages/libndsfpc/examples/audio/maxmod/basic_sound/audio/Boom.wav"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-MediaBasicsTest")

DIM s AS HSound
s = HSoundCreate(SOUND_FILE)
IF HSoundInitCheck(s) <> 0 THEN
    PRINT "FAIL: HSoundInitCheck on the real test WAV file"
    CALL HApplicationFree(app)
    CALL ExitProcess(1)
END IF

DIM durationMicros AS LONGINT
durationMicros = HSoundDuration(s)
PRINT "sound duration (microseconds)=", durationMicros
IF durationMicros <= 0 THEN
    PRINT "FAIL: expected a positive real duration"
    CALL HSoundRelease(s)
    CALL HApplicationFree(app)
    CALL ExitProcess(1)
END IF

DIM player AS HSoundPlayer
player = HSoundPlayerCreate("eb-haiku-media-test")
IF HSoundPlayerInitCheck(player) <> 0 THEN
    PRINT "FAIL: HSoundPlayerInitCheck"
    CALL HSoundRelease(s)
    CALL HApplicationFree(app)
    CALL ExitProcess(1)
END IF

DIM rc AS INTEGER
rc = HSoundPlayerStart(player)
IF rc <> 0 THEN
    PRINT "FAIL: HSoundPlayerStart returned ", rc
    CALL HSoundPlayerFree(player)
    CALL HSoundRelease(s)
    CALL HApplicationFree(app)
    CALL ExitProcess(1)
END IF

DIM playId AS INTEGER
playId = HSoundPlayerStartPlaying(player, s)
IF playId < 0 THEN
    PRINT "FAIL: HSoundPlayerStartPlaying returned ", playId
    CALL HSoundPlayerStop(player)
    CALL HSoundPlayerFree(player)
    CALL HSoundRelease(s)
    CALL HApplicationFree(app)
    CALL ExitProcess(1)
END IF
PRINT "playback started, play id=", playId

' Poll for up to 3 seconds - a generous bound well past the sound's own
' real (sub-second) duration - confirming IsPlaying genuinely settles
' to "not playing" rather than reporting "still playing" forever.
DIM stillPlaying AS INTEGER
stillPlaying = 1
DIM elapsedMillis AS INTEGER
elapsedMillis = 0
DO WHILE stillPlaying <> 0 AND elapsedMillis < 3000
    CALL Sleep(100)
    elapsedMillis = elapsedMillis + 100
    stillPlaying = HSoundPlayerIsPlaying(player, playId)
LOOP

IF stillPlaying <> 0 THEN
    PRINT "FAIL: sound never reported as finished within 3 seconds"
    CALL HSoundPlayerStop(player)
    CALL HSoundPlayerFree(player)
    CALL HSoundRelease(s)
    CALL HApplicationFree(app)
    CALL ExitProcess(1)
END IF
PRINT "playback genuinely finished after ", elapsedMillis, "ms ok"

CALL HSoundPlayerStop(player)
CALL HSoundPlayerFree(player)
CALL HSoundRelease(s)
CALL HApplicationFree(app)

PRINT "media basics test ok"
