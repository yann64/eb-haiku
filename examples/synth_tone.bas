' Media Kit real-time buffer synthesis - a real 440Hz tone generated
' sample-by-sample on Haiku's own real-time audio thread.

#include once "../src/lib.bas"

DIM gSampleIndex AS LONGINT
gSampleIndex = 0

SUB OnFillBuffer(cookie AS ANY PTR, buf AS ANY PTR, size AS UINTEGER, frameRate AS SINGLE, channelCount AS UINTEGER, audioFormat AS UINTEGER, byteOrder AS UINTEGER)
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

DIM player AS HSoundPlayer
player = HSoundPlayerCreateWithBufferCallback("eb-haiku-synth-tone", @OnFillBuffer, 0)
CALL HSoundPlayerStart(player)
CALL Sleep(1000)
CALL HSoundPlayerStop(player)
CALL HSoundPlayerFreeWithBufferCallback(player)
