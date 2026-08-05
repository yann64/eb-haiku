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

' ---- Real-time buffer-callback synthesis - a real 440Hz tone
' generated sample-by-sample inside the callback itself, on Haiku's own
' real-time audio thread. Adapts to whatever format was actually
' negotiated (only H_AUDIO_SHORT is filled with real samples here;
' other formats are left silent - not asserted, since the negotiated
' format is host-dependent). ----

DIM gBufferCallbackCount AS INTEGER
gBufferCallbackCount = 0
DIM gObservedFormat AS UINTEGER
gObservedFormat = 0
DIM gSampleIndex AS LONGINT
gSampleIndex = 0

SUB OnFillBuffer(cookie AS ANY PTR, buf AS ANY PTR, size AS UINTEGER, frameRate AS SINGLE, channelCount AS UINTEGER, audioFormat AS UINTEGER, byteOrder AS UINTEGER)
    gBufferCallbackCount = gBufferCallbackCount + 1
    gObservedFormat = audioFormat
    IF audioFormat = H_AUDIO_SHORT THEN
        DIM sampleCount AS INTEGER
        sampleCount = size \ 2
        DIM s16 AS SHORT PTR
        s16 = buf
        DIM j AS INTEGER
        FOR j = 0 TO sampleCount - 1
            DIM sampleValue AS INTEGER
            sampleValue = CInt(3000.0 * Sin(2.0 * 3.14159265 * 440.0 * CDbl(gSampleIndex) / CDbl(frameRate)))
            *(s16 + j) = sampleValue
            gSampleIndex = gSampleIndex + 1
        NEXT j
    END IF
END SUB

DIM bufferPlayer AS HSoundPlayer
bufferPlayer = HSoundPlayerCreateWithBufferCallback("eb-haiku-buffer-synth-test", @OnFillBuffer, 0)
IF HSoundPlayerInitCheck(bufferPlayer) <> 0 THEN
    PRINT "FAIL: HSoundPlayerInitCheck (buffer callback player)"
    CALL HApplicationFree(app)
    CALL ExitProcess(1)
END IF

rc = HSoundPlayerStart(bufferPlayer)
IF rc <> 0 THEN
    PRINT "FAIL: HSoundPlayerStart (buffer callback player) returned ", rc
    CALL HSoundPlayerFreeWithBufferCallback(bufferPlayer)
    CALL HApplicationFree(app)
    CALL ExitProcess(1)
END IF

CALL Sleep(500)

CALL HSoundPlayerStop(bufferPlayer)
CALL HSoundPlayerFreeWithBufferCallback(bufferPlayer)

PRINT "buffer callback fired ", gBufferCallbackCount, " times, observed format=", gObservedFormat
IF gBufferCallbackCount <= 0 THEN
    PRINT "FAIL: expected the real buffer callback to fire at least once"
    CALL HApplicationFree(app)
    CALL ExitProcess(1)
END IF
PRINT "buffer synthesis ok"

CALL HApplicationFree(app)

PRINT "media basics test ok"
