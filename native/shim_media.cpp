#include "shim_media.h"

#include <Entry.h>
#include <Sound.h>
#include <SoundPlayer.h>

extern "C" {

// ---- BSound ----

void* eb_haiku_sound_create(const char* path) {
    BEntry entry(path);
    entry_ref ref;
    if (entry.GetRef(&ref) != B_OK) return nullptr;
    return new BSound(&ref, true);
}

int eb_haiku_sound_init_check(void* sound) {
    return static_cast<BSound*>(sound)->InitCheck();
}

long long eb_haiku_sound_duration(void* sound) {
    return static_cast<long long>(static_cast<BSound*>(sound)->Duration());
}

void eb_haiku_sound_release(void* sound) { static_cast<BSound*>(sound)->ReleaseRef(); }

// ---- BSoundPlayer ----

void* eb_haiku_sound_player_create(const char* name) { return new BSoundPlayer(name); }

namespace {

struct BufferCallbackContext {
    EbHaikuBufferPlayerCallback cb;
    void* userCookie;
};

void TrampolineBufferPlayerFunc(void* cookie, void* buffer, size_t size,
                                 const media_raw_audio_format& format) {
    auto* ctx = static_cast<BufferCallbackContext*>(cookie);
    if (ctx->cb) {
        ctx->cb(ctx->userCookie, buffer, static_cast<unsigned long>(size), format.frame_rate,
                format.channel_count, format.format, format.byte_order);
    }
}

} // namespace

void* eb_haiku_sound_player_create_with_buffer_callback(const char* name,
                                                         EbHaikuBufferPlayerCallback cb,
                                                         void* cookie) {
    auto* ctx = new BufferCallbackContext{cb, cookie};
    return new BSoundPlayer(name, TrampolineBufferPlayerFunc, nullptr, ctx);
}

int eb_haiku_sound_player_init_check(void* player) {
    return static_cast<BSoundPlayer*>(player)->InitCheck();
}

int eb_haiku_sound_player_start(void* player) { return static_cast<BSoundPlayer*>(player)->Start(); }

void eb_haiku_sound_player_stop(void* player) { static_cast<BSoundPlayer*>(player)->Stop(); }

int eb_haiku_sound_player_start_playing(void* player, void* sound) {
    return static_cast<BSoundPlayer*>(player)->StartPlaying(static_cast<BSound*>(sound));
}

int eb_haiku_sound_player_is_playing(void* player, int id) {
    return static_cast<BSoundPlayer*>(player)->IsPlaying(id) ? 1 : 0;
}

int eb_haiku_sound_player_wait_for_sound(void* player, int id) {
    return static_cast<BSoundPlayer*>(player)->WaitForSound(id);
}

void eb_haiku_sound_player_destroy(void* player) { delete static_cast<BSoundPlayer*>(player); }

void eb_haiku_sound_player_destroy_with_buffer_callback(void* player) {
    BSoundPlayer* p = static_cast<BSoundPlayer*>(player);
    delete static_cast<BufferCallbackContext*>(p->Cookie());
    delete p;
}

} // extern "C"
