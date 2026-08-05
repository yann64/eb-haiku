' Game Kit: BFileGameSound (whole-file playback), BSimpleGameSound
' (one-shot from a file), BPushGameSound (direct lock/unlock buffer-
' fill, synthesizing a real 440Hz tone) - all plain new/delete, no
' BApplication required first (confirmed via a standalone C++ probe -
' a real, confirmed contrast with Media Kit's own BSoundPlayer, which
' does need one).

#include once "../src/lib.bas"

CONST SOUND_FILE = "/boot/system/lib/fpc/3.2.2/src/packages/libndsfpc/examples/audio/maxmod/basic_sound/audio/Boom.wav"

' ---- BFileGameSound ----

DIM fileSound AS HGameSound
fileSound = HFileGameSoundCreate(SOUND_FILE, 0)
IF HGameSoundInitCheck(fileSound) <> 0 THEN
    PRINT "FAIL: HFileGameSound InitCheck on the real test WAV file"
    CALL ExitProcess(1)
END IF

DIM rc AS INTEGER
rc = HGameSoundStartPlaying(fileSound)
IF rc <> 0 THEN
    PRINT "FAIL: HFileGameSound StartPlaying returned ", rc
    CALL ExitProcess(1)
END IF
CALL HSnooze(200000)
PRINT "IsPlaying=", HGameSoundIsPlaying(fileSound)
CALL HGameSoundSetGain(fileSound, 0.5, 0)
PRINT "gain=", HGameSoundGain(fileSound)
CALL HGameSoundStopPlaying(fileSound)
CALL HGameSoundFree(fileSound)
PRINT "BFileGameSound ok"

' ---- BSimpleGameSound (one-shot, from the same real file) ----

DIM simpleSound AS HGameSound
simpleSound = HSimpleGameSoundCreateFromPath(SOUND_FILE)
IF HGameSoundInitCheck(simpleSound) <> 0 THEN
    PRINT "FAIL: HSimpleGameSound InitCheck"
    CALL ExitProcess(1)
END IF
rc = HGameSoundStartPlaying(simpleSound)
IF rc <> 0 THEN
    PRINT "FAIL: HSimpleGameSound StartPlaying returned ", rc
    CALL ExitProcess(1)
END IF
CALL HSnooze(200000)
CALL HGameSoundStopPlaying(simpleSound)
CALL HGameSoundFree(simpleSound)
PRINT "BSimpleGameSound ok"

' ---- BPushGameSound - synthesize a real 440Hz tone via lock/unlock ----

DIM push AS HGameSound
push = HPushGameSoundCreate(1024, 44100.0, 1, H_GS_S16, 2, 4096, 2)
IF HGameSoundInitCheck(push) <> 0 THEN
    PRINT "FAIL: HPushGameSound InitCheck"
    CALL ExitProcess(1)
END IF
rc = HGameSoundStartPlaying(push)
IF rc <> 0 THEN
    PRINT "FAIL: HPushGameSound StartPlaying returned ", rc
    CALL ExitProcess(1)
END IF

DIM i AS INTEGER
DIM lockFailures AS INTEGER
lockFailures = 0
DIM sampleIndex AS LONGINT
sampleIndex = 0
DIM pagePtr AS ANY PTR
DIM pageSize AS ULONGINT
DIM lockRc AS INTEGER
FOR i = 1 TO 20
    lockRc = HPushGameSoundLockNextPage(push, @pagePtr, @pageSize)
    IF lockRc < 0 THEN
        lockFailures = lockFailures + 1
    ELSE
        DIM sampleCount AS INTEGER
        sampleCount = pageSize \ 2
        DIM s16 AS SHORT PTR
        s16 = pagePtr
        DIM j AS INTEGER
        FOR j = 0 TO sampleCount - 1
            DIM sampleValue AS INTEGER
            sampleValue = CInt(3000.0 * Sin(2.0 * 3.14159265 * 440.0 * CDbl(sampleIndex) / 44100.0))
            *(s16 + j) = sampleValue
            sampleIndex = sampleIndex + 1
        NEXT j
        CALL HPushGameSoundUnlockPage(push, pagePtr)
    END IF
    CALL HSnooze(20000)
NEXT i

PRINT "lock failures=", lockFailures
IF lockFailures > 5 THEN
    PRINT "FAIL: too many LockNextPage failures"
    CALL ExitProcess(1)
END IF

CALL HGameSoundStopPlaying(push)
CALL HGameSoundFree(push)
PRINT "BPushGameSound ok"

PRINT "game basics test ok"
