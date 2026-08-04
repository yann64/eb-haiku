' Media Kit basics - play a real sound file via BSoundPlayer + BSound.
' IMPORTANT: every exit path stops/frees the player before exiting -
' see media.bas's own doc comment for why (a live BSoundPlayer
' background thread can hang process exit otherwise).

#include once "../src/lib.bas"

CONST SOUND_FILE = "/boot/system/lib/fpc/3.2.2/src/packages/libndsfpc/examples/audio/maxmod/basic_sound/audio/Boom.wav"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-PlaySoundExample")

DIM s AS HSound
s = HSoundCreate(SOUND_FILE)
IF HSoundInitCheck(s) = 0 THEN
    DIM player AS HSoundPlayer
    player = HSoundPlayerCreate("eb-haiku-play-sound-example")
    CALL HSoundPlayerStart(player)

    DIM playId AS INTEGER
    playId = HSoundPlayerStartPlaying(player, s)
    PRINT "playing... (duration ", HSoundDuration(s), " microseconds)"

    DO WHILE HSoundPlayerIsPlaying(player, playId) <> 0
        CALL Sleep(100)
    LOOP
    PRINT "done"

    CALL HSoundPlayerStop(player)
    CALL HSoundPlayerFree(player)
END IF
CALL HSoundRelease(s)
CALL HApplicationFree(app)
