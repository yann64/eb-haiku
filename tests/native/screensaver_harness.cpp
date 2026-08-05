// Real dlopen/factory/virtual-dispatch harness for Screen Saver Kit's
// automated test (../screensaver_basics.bas) - genuine proof of dynamic
// loadability and real BScreenSaver virtual dispatch through the exact
// call shape Haiku's own screensaver daemon uses (a real BWindow/BView
// context, not a bare unattached object), not just "the file exists".
//
// A real BApplication is constructed first (no Run() needed) - several
// Haiku APIs elsewhere in this package hang indefinitely without one
// (see this package's own README "Threading" section) - not assumed
// unnecessary here without checking.
#include <Application.h>
#include <ScreenSaver.h>
#include <View.h>
#include <Window.h>

#include <cstdio>
#include <dlfcn.h>

typedef BScreenSaver* (*InstantiateScreenSaverFn)(BMessage*, image_id);

int main(int argc, char** argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: screensaver_harness <path-to-shared-lib>\n");
        return 2;
    }

    BApplication app("application/x-vnd.eb-haiku-screensaver-test");

    /// RTLD_NOW: a real, confirmed-by-direct-reproduction finding while
    /// writing this test - a shared library's Shim* class vtable/RTTI
    /// relocations are resolved *eagerly* at load time regardless of
    /// RTLD_LAZY/RTLD_NOW (unlike ordinary lazy PLT function binding),
    /// so `screensaver_basics.bas` deliberately #includes only
    /// screensaver.bas (not eb-haiku's whole aggregated lib.bas) to
    /// avoid pulling in every other Kit's own Shim* subclass - see that
    /// file's own top comment.
    void* handle = dlopen(argv[1], RTLD_NOW);
    if (!handle) {
        fprintf(stderr, "dlopen failed: %s\n", dlerror());
        return 1;
    }
    InstantiateScreenSaverFn instantiate =
        (InstantiateScreenSaverFn)dlsym(handle, "instantiate_screen_saver");
    if (!instantiate) {
        fprintf(stderr, "dlsym failed: %s\n", dlerror());
        return 1;
    }

    BScreenSaver* saver = instantiate(nullptr, 0);
    if (!saver) {
        fprintf(stderr, "instantiate_screen_saver returned NULL\n");
        return 1;
    }

    BWindow* window = new BWindow(BRect(0, 0, 99, 99), "screensaver-test", B_TITLED_WINDOW,
                                   B_NOT_ZOOMABLE | B_NOT_RESIZABLE);
    BView* view = new BView(BRect(0, 0, 99, 99), "screensaver-view", B_FOLLOW_ALL, B_WILL_DRAW);
    window->Lock();
    window->AddChild(view);
    window->Unlock();

    printf("InitCheck returned %d\n", (int)saver->InitCheck());

    status_t rc = saver->StartSaver(view, true);
    printf("StartSaver returned %d\n", (int)rc);

    saver->Draw(view, 0);
    saver->Draw(view, 1);

    saver->StopSaver();

    delete saver;
    window->Lock();
    window->Quit();

    dlclose(handle);
    return 0;
}
