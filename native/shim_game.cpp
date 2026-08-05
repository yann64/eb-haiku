#include "shim_game.h"

#include <FileGameSound.h>
#include <GameSoundDefs.h>
#include <PushGameSound.h>
#include <SimpleGameSound.h>

extern "C" {

// ---- BGameSound (shared base) ----

int eb_haiku_game_sound_init_check(void* sound) {
    return static_cast<BGameSound*>(sound)->InitCheck();
}

int eb_haiku_game_sound_start_playing(void* sound) {
    return static_cast<BGameSound*>(sound)->StartPlaying();
}

int eb_haiku_game_sound_is_playing(void* sound) {
    return static_cast<BGameSound*>(sound)->IsPlaying() ? 1 : 0;
}

int eb_haiku_game_sound_stop_playing(void* sound) {
    return static_cast<BGameSound*>(sound)->StopPlaying();
}

int eb_haiku_game_sound_set_gain(void* sound, float gain, long long duration) {
    return static_cast<BGameSound*>(sound)->SetGain(gain, static_cast<bigtime_t>(duration));
}

int eb_haiku_game_sound_set_pan(void* sound, float pan, long long duration) {
    return static_cast<BGameSound*>(sound)->SetPan(pan, static_cast<bigtime_t>(duration));
}

float eb_haiku_game_sound_gain(void* sound) { return static_cast<BGameSound*>(sound)->Gain(); }

float eb_haiku_game_sound_pan(void* sound) { return static_cast<BGameSound*>(sound)->Pan(); }

void eb_haiku_game_sound_destroy(void* sound) { delete static_cast<BGameSound*>(sound); }

// ---- BFileGameSound ----

void* eb_haiku_file_game_sound_create(const char* path, int looping) {
    return new BFileGameSound(path, looping != 0);
}

int eb_haiku_file_game_sound_preload(void* sound) {
    return static_cast<BFileGameSound*>(sound)->Preload();
}

int eb_haiku_file_game_sound_set_paused(void* sound, int isPaused, long long rampTime) {
    return static_cast<BFileGameSound*>(sound)->SetPaused(isPaused != 0,
                                                            static_cast<bigtime_t>(rampTime));
}

int eb_haiku_file_game_sound_is_paused(void* sound) {
    return static_cast<BFileGameSound*>(sound)->IsPaused();
}

// ---- BSimpleGameSound ----

void* eb_haiku_simple_game_sound_create_from_path(const char* path) {
    return new BSimpleGameSound(path);
}

void* eb_haiku_simple_game_sound_create_from_buffer(const void* data, unsigned long frameCount,
                                                     float frameRate, unsigned int channelCount,
                                                     unsigned int format, unsigned int byteOrder,
                                                     unsigned long bufferSize) {
    gs_audio_format fmt;
    fmt.frame_rate = frameRate;
    fmt.channel_count = channelCount;
    fmt.format = format;
    fmt.byte_order = byteOrder;
    fmt.buffer_size = bufferSize;
    return new BSimpleGameSound(data, frameCount, &fmt);
}

int eb_haiku_simple_game_sound_set_is_looping(void* sound, int looping) {
    return static_cast<BSimpleGameSound*>(sound)->SetIsLooping(looping != 0);
}

int eb_haiku_simple_game_sound_is_looping(void* sound) {
    return static_cast<BSimpleGameSound*>(sound)->IsLooping() ? 1 : 0;
}

// ---- BPushGameSound ----

void* eb_haiku_push_game_sound_create(unsigned long bufferFrameCount, float frameRate,
                                       unsigned int channelCount, unsigned int format,
                                       unsigned int byteOrder, unsigned long bufferSize,
                                       unsigned long bufferCount) {
    gs_audio_format fmt;
    fmt.frame_rate = frameRate;
    fmt.channel_count = channelCount;
    fmt.format = format;
    fmt.byte_order = byteOrder;
    fmt.buffer_size = bufferSize;
    return new BPushGameSound(bufferFrameCount, &fmt, bufferCount);
}

int eb_haiku_push_game_sound_lock_next_page(void* sound, void** outPagePtr,
                                             unsigned long* outPageSize) {
    size_t size = 0;
    BPushGameSound::lock_status status =
        static_cast<BPushGameSound*>(sound)->LockNextPage(outPagePtr, &size);
    *outPageSize = static_cast<unsigned long>(size);
    return static_cast<int>(status);
}

int eb_haiku_push_game_sound_unlock_page(void* sound, void* pagePtr) {
    return static_cast<BPushGameSound*>(sound)->UnlockPage(pagePtr);
}

} // extern "C"
