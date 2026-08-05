// eb-haiku native shim - Screen Saver Kit (os/add-ons/screen_saver/
// ScreenSaver.h). Unlike every other Kit in this shim, the *whole
// program* consuming this Kit is itself a real, dynamically loadable
// add-on (a `.so` Haiku's own screensaver daemon `dlopen`s at runtime
// and calls `extern "C" instantiate_screen_saver(BMessage*, image_id)`
// on to get a real `BScreenSaver*`) - only possible now that `ebc`
// itself gained `--shared-lib`/`-dll` real shared-library output.
//
// BScreenSaver is single-inheritance (no MI-pointer-adjustment concern,
// unlike BFile's own second-base case) - a plain `static_cast<
// BScreenSaver*>` (or none at all; ShimScreenSaver* already converts)
// is always safe.
//
// REAL FINDING, confirmed by direct reproduction (a standalone C++
// probe, isolating this from eBasic/ebc entirely, before trusting it):
// any real screensaver `.so` - including a hand-written one with no
// eb-haiku/ebc involvement at all - needs `Lib "screensaver"` (Haiku's
// own `libscreensaver.so`, confirmed to exist alongside `libbe.so` and
// genuinely `NEEDED` by the real, stock `Leaves` add-on) *in addition
// to* `Lib "be"`. Without it, `dlopen`/`load_add_on` fails with a bare
// "Symbol not found" (no symbol name given) - BScreenSaver's own base-
// class virtual method bodies (the non-pure-virtual defaults for
// StartSaver/StopSaver/Draw/etc. an override doesn't replace) live in
// `libscreensaver.so`, not `libbe.so`. Not documented anywhere obvious
// in Haiku's own headers - found only by comparing a real, working
// installed add-on's own `readelf -d`/`nm -D` output against a minimal
// hand-written probe's, after RTLD_LAZY (a first, wrong guess) made no
// difference (vtable/RTTI relocations resolve eagerly regardless of
// RTLD_LAZY/RTLD_NOW).
//
// Scope, matching this package's own established "tractable,
// verifiable subset first" precedent (e.g. MIDI Kit 2 bound 5 of 14
// virtuals): bound here are the four virtuals every real screensaver
// actually needs (InitCheck/StartSaver/StopSaver/Draw) plus the five
// non-virtual utility methods that control animation timing
// (SetTickSize/TickSize/SetLoop/LoopOnCount/LoopOffCount).
// Deliberately NOT bound (a documented gap, not an oversight):
// DirectConnected/DirectDraw (direct-screen-access, exotic, no
// meaningful way to verify without real hardware framebuffer access),
// StartConfig/StopConfig (a config dialog needs human interaction to
// verify - same category as BPrintJob::ConfigJob, already deferred
// elsewhere in this shim for the same reason), SupplyInfo/
// ModulesChanged/SaveState (metadata/state-persistence, lower value, a
// reasonable follow-on).
//
// No "destroy" function anywhere in this file, unlike this shim's
// other conventions (refcounted release for MIDI, explicit free
// everywhere else): Haiku's screensaver daemon owns the object
// `instantiate_screen_saver` returns for its entire lifetime and
// deletes it itself when unloading the add-on.
#pragma once

extern "C" {

typedef int (*EbHaikuScreenSaverInitCheckCallback)(void* userData);
typedef int (*EbHaikuScreenSaverStartSaverCallback)(void* userData, void* view, int preview);
typedef void (*EbHaikuScreenSaverStopSaverCallback)(void* userData);
typedef void (*EbHaikuScreenSaverDrawCallback)(void* userData, void* view, int frame);

// `archive`/`id` are forwarded straight to the real BScreenSaver(BMessage*,
// image_id) base constructor. `archive` is also usable directly with
// this package's existing HMessage-family getters (message.bas) if a
// screensaver wants to read its own prior saved settings.
void* eb_haiku_screensaver_create(void* archive, int id);

void eb_haiku_screensaver_set_init_check_callback(void* saver, EbHaikuScreenSaverInitCheckCallback cb,
                                                   void* userData);
void eb_haiku_screensaver_set_start_saver_callback(void* saver,
                                                    EbHaikuScreenSaverStartSaverCallback cb,
                                                    void* userData);
void eb_haiku_screensaver_set_stop_saver_callback(void* saver, EbHaikuScreenSaverStopSaverCallback cb,
                                                   void* userData);
// `view` is *externally owned* (by the screensaver daemon, not by our
// own code) - forwarded to the callback by explicit handle, the same
// shape as eb_haiku_print_job_set_draw_view_callback's own
// externally-owned BView* (unlike eb_haiku_shim_view_set_draw_callback,
// whose view is one eBasic code itself created and already holds).
void eb_haiku_screensaver_set_draw_callback(void* saver, EbHaikuScreenSaverDrawCallback cb,
                                             void* userData);

// ---- Non-virtual utility methods (control animation frame timing) ----
void eb_haiku_screensaver_set_tick_size(void* saver, long long tickSize);
long long eb_haiku_screensaver_tick_size(void* saver);
void eb_haiku_screensaver_set_loop(void* saver, int onCount, int offCount);
int eb_haiku_screensaver_loop_on_count(void* saver);
int eb_haiku_screensaver_loop_off_count(void* saver);

} // extern "C"
