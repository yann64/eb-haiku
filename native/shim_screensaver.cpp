#include "shim_screensaver.h"

#include <ScreenSaver.h>
#include <View.h>

namespace {

/// The only way to reach BScreenSaver's own virtual methods from eBasic
/// at all - forwards each bound one to a stored callback (a plain
/// function pointer + a caller-supplied userData), the same convention
/// every other Shim* subclass in this package already uses. See
/// shim_screensaver.h's own top comment for exactly which virtuals are
/// bound and why the rest are deliberately not.
class ShimScreenSaver : public BScreenSaver {
public:
    ShimScreenSaver(BMessage* archive, image_id id) : BScreenSaver(archive, id) {}

    void SetInitCheckCallback(EbHaikuScreenSaverInitCheckCallback cb, void* userData) {
        fInitCheckCb = cb;
        fInitCheckUserData = userData;
    }
    void SetStartSaverCallback(EbHaikuScreenSaverStartSaverCallback cb, void* userData) {
        fStartSaverCb = cb;
        fStartSaverUserData = userData;
    }
    void SetStopSaverCallback(EbHaikuScreenSaverStopSaverCallback cb, void* userData) {
        fStopSaverCb = cb;
        fStopSaverUserData = userData;
    }
    void SetDrawCallback(EbHaikuScreenSaverDrawCallback cb, void* userData) {
        fDrawCb = cb;
        fDrawUserData = userData;
    }

    status_t InitCheck() override {
        if (fInitCheckCb) return (status_t)fInitCheckCb(fInitCheckUserData);
        return BScreenSaver::InitCheck();
    }

    status_t StartSaver(BView* view, bool preview) override {
        if (fStartSaverCb) return (status_t)fStartSaverCb(fStartSaverUserData, view, preview ? 1 : 0);
        return B_OK;
    }

    void StopSaver() override {
        if (fStopSaverCb) fStopSaverCb(fStopSaverUserData);
    }

    void Draw(BView* view, int32 frame) override {
        if (fDrawCb) fDrawCb(fDrawUserData, view, frame);
    }

private:
    EbHaikuScreenSaverInitCheckCallback fInitCheckCb = nullptr;
    void* fInitCheckUserData = nullptr;
    EbHaikuScreenSaverStartSaverCallback fStartSaverCb = nullptr;
    void* fStartSaverUserData = nullptr;
    EbHaikuScreenSaverStopSaverCallback fStopSaverCb = nullptr;
    void* fStopSaverUserData = nullptr;
    EbHaikuScreenSaverDrawCallback fDrawCb = nullptr;
    void* fDrawUserData = nullptr;
};

} // namespace

extern "C" {

void* eb_haiku_screensaver_create(void* archive, int id) {
    return new ShimScreenSaver(static_cast<BMessage*>(archive), (image_id)id);
}

void eb_haiku_screensaver_set_init_check_callback(void* saver, EbHaikuScreenSaverInitCheckCallback cb,
                                                   void* userData) {
    static_cast<ShimScreenSaver*>(saver)->SetInitCheckCallback(cb, userData);
}

void eb_haiku_screensaver_set_start_saver_callback(void* saver,
                                                    EbHaikuScreenSaverStartSaverCallback cb,
                                                    void* userData) {
    static_cast<ShimScreenSaver*>(saver)->SetStartSaverCallback(cb, userData);
}

void eb_haiku_screensaver_set_stop_saver_callback(void* saver, EbHaikuScreenSaverStopSaverCallback cb,
                                                   void* userData) {
    static_cast<ShimScreenSaver*>(saver)->SetStopSaverCallback(cb, userData);
}

void eb_haiku_screensaver_set_draw_callback(void* saver, EbHaikuScreenSaverDrawCallback cb,
                                             void* userData) {
    static_cast<ShimScreenSaver*>(saver)->SetDrawCallback(cb, userData);
}

void eb_haiku_screensaver_set_tick_size(void* saver, long long tickSize) {
    static_cast<ShimScreenSaver*>(saver)->SetTickSize((bigtime_t)tickSize);
}

long long eb_haiku_screensaver_tick_size(void* saver) {
    return (long long)static_cast<ShimScreenSaver*>(saver)->TickSize();
}

void eb_haiku_screensaver_set_loop(void* saver, int onCount, int offCount) {
    static_cast<ShimScreenSaver*>(saver)->SetLoop((int32)onCount, (int32)offCount);
}

int eb_haiku_screensaver_loop_on_count(void* saver) {
    return (int)static_cast<ShimScreenSaver*>(saver)->LoopOnCount();
}

int eb_haiku_screensaver_loop_off_count(void* saver) {
    return (int)static_cast<ShimScreenSaver*>(saver)->LoopOffCount();
}

} // extern "C"
