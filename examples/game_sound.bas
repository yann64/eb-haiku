' Game Kit: play a real sound file via BFileGameSound - no
' BApplication needed first, unlike Media Kit's own BSoundPlayer.

#include once "../src/lib.bas"

CONST SOUND_FILE = "/boot/system/lib/fpc/3.2.2/src/packages/libndsfpc/examples/audio/maxmod/basic_sound/audio/Boom.wav"

DIM snd AS HGameSound
snd = HFileGameSoundCreate(SOUND_FILE, 0)
IF HGameSoundInitCheck(snd) <> 0 THEN
    PRINT "FAIL: could not load ", SOUND_FILE
    CALL ExitProcess(1)
END IF

CALL HGameSoundStartPlaying(snd)
CALL Sleep(500)
CALL HGameSoundStopPlaying(snd)
CALL HGameSoundFree(snd)

PRINT "played ", SOUND_FILE
