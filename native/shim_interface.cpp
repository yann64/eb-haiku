#include "shim_interface.h"

#include <AppDefs.h>
#include <Button.h>
#include <GroupLayout.h>
#include <Layout.h>
#include <Looper.h>
#include <Message.h>
#include <Messenger.h>
#include <StringView.h>
#include <TextControl.h>
#include <View.h>
#include <Window.h>

namespace {

/// The only way to reach BWindow's own virtual methods from eBasic at
/// all - eBasic's Extern mechanism can't override a foreign class's
/// virtuals directly, so this real C++ subclass forwards each one to a
/// stored callback (a plain function pointer + a caller-supplied
/// userData, exactly matching this package's own established
/// eb-gtk4-derived convention - see shim_interface.h's own top comment).
class ShimWindow : public BWindow {
public:
    ShimWindow(BRect frame, const char* title, unsigned int flags)
        : BWindow(frame, title, B_TITLED_WINDOW, flags) {}

    void SetMessageReceivedCallback(EbHaikuMessageReceivedCallback cb, void* userData) {
        fMessageCallback = cb;
        fMessageUserData = userData;
    }

    void SetQuitRequestedCallback(EbHaikuQuitRequestedCallback cb, void* userData) {
        fQuitCallback = cb;
        fQuitUserData = userData;
    }

    void SetFrameResizedCallback(EbHaikuFrameResizedCallback cb, void* userData) {
        fResizeCallback = cb;
        fResizeUserData = userData;
    }

    void MessageReceived(BMessage* message) override {
        if (fMessageCallback) {
            fMessageCallback(fMessageUserData, message);
        } else {
            BWindow::MessageReceived(message);
        }
    }

    bool QuitRequested() override {
        if (fQuitCallback) return fQuitCallback(fQuitUserData) != 0;
        return BWindow::QuitRequested();
    }

    void FrameResized(float newWidth, float newHeight) override {
        if (fResizeCallback) fResizeCallback(fResizeUserData, newWidth, newHeight);
        BWindow::FrameResized(newWidth, newHeight);
    }

private:
    EbHaikuMessageReceivedCallback fMessageCallback = nullptr;
    void* fMessageUserData = nullptr;
    EbHaikuQuitRequestedCallback fQuitCallback = nullptr;
    void* fQuitUserData = nullptr;
    EbHaikuFrameResizedCallback fResizeCallback = nullptr;
    void* fResizeUserData = nullptr;
};

/// Same forwarding pattern as ShimWindow (see its own top comment) -
/// the only way to reach BView's own virtual methods from eBasic.
class ShimView : public BView {
public:
    ShimView(BRect frame, const char* name, unsigned int resizingMode, unsigned int flags)
        : BView(frame, name, resizingMode, flags) {}

    void SetDrawCallback(EbHaikuDrawCallback cb, void* userData) {
        fDrawCallback = cb;
        fDrawUserData = userData;
    }
    void SetMouseDownCallback(EbHaikuMouseCallback cb, void* userData) {
        fMouseDownCallback = cb;
        fMouseDownUserData = userData;
    }
    void SetMouseUpCallback(EbHaikuMouseCallback cb, void* userData) {
        fMouseUpCallback = cb;
        fMouseUpUserData = userData;
    }
    void SetKeyDownCallback(EbHaikuKeyDownCallback cb, void* userData) {
        fKeyDownCallback = cb;
        fKeyDownUserData = userData;
    }

    void Draw(BRect updateRect) override {
        if (fDrawCallback) {
            fDrawCallback(fDrawUserData, updateRect.left, updateRect.top, updateRect.right,
                          updateRect.bottom);
        }
    }
    void MouseDown(BPoint where) override {
        if (fMouseDownCallback) fMouseDownCallback(fMouseDownUserData, where.x, where.y);
        else BView::MouseDown(where);
    }
    void MouseUp(BPoint where) override {
        if (fMouseUpCallback) fMouseUpCallback(fMouseUpUserData, where.x, where.y);
        else BView::MouseUp(where);
    }
    void KeyDown(const char* bytes, int32 numBytes) override {
        if (fKeyDownCallback) fKeyDownCallback(fKeyDownUserData, bytes, numBytes);
        else BView::KeyDown(bytes, numBytes);
    }

private:
    EbHaikuDrawCallback fDrawCallback = nullptr;
    void* fDrawUserData = nullptr;
    EbHaikuMouseCallback fMouseDownCallback = nullptr;
    void* fMouseDownUserData = nullptr;
    EbHaikuMouseCallback fMouseUpCallback = nullptr;
    void* fMouseUpUserData = nullptr;
    EbHaikuKeyDownCallback fKeyDownCallback = nullptr;
    void* fKeyDownUserData = nullptr;
};

/// Locks a BView's own window before touching it, matching real
/// Haiku's own threading requirement for BLooper-owned objects (a
/// window's own thread holds this lock implicitly while processing its
/// message loop - Draw/MessageReceived/etc. callbacks never need this
/// themselves - but code running on any *other* thread, like a plain
/// shim function called from eBasic's own main thread, must acquire it
/// explicitly first). `BLooper::Lock()` is safe to call even from the
/// looper's own thread (it's recursive), so this is always correct
/// regardless of which thread actually calls it - found the hard way:
/// BView::Invalidate() (called from outside the window's own thread,
/// with no lock held) crashed deep inside Haiku's own implementation,
/// confirmed via a standalone C++ reproduction with no eBasic involved
/// at all, exactly like BInvoker::Invoke()'s own cross-thread issue
/// (see eb_haiku_button_invoke's own comment).
class ViewAutolock {
public:
    explicit ViewAutolock(BView* view) : fLooper(view->Looper()) {
        fLocked = fLooper != nullptr && fLooper->Lock();
    }
    ~ViewAutolock() {
        if (fLocked) fLooper->Unlock();
    }

private:
    BLooper* fLooper;
    bool fLocked;
};

} // namespace

extern "C" {

void* eb_haiku_window_create(float left, float top, float right, float bottom,
                              const char* title, unsigned int flags) {
    return new ShimWindow(BRect(left, top, right, bottom), title, flags);
}

void eb_haiku_window_set_message_received_callback(void* window,
                                                     EbHaikuMessageReceivedCallback cb,
                                                     void* userData) {
    static_cast<ShimWindow*>(window)->SetMessageReceivedCallback(cb, userData);
}

void eb_haiku_window_set_quit_requested_callback(void* window, EbHaikuQuitRequestedCallback cb,
                                                  void* userData) {
    static_cast<ShimWindow*>(window)->SetQuitRequestedCallback(cb, userData);
}

void eb_haiku_window_set_frame_resized_callback(void* window, EbHaikuFrameResizedCallback cb,
                                                 void* userData) {
    static_cast<ShimWindow*>(window)->SetFrameResizedCallback(cb, userData);
}

void eb_haiku_window_show(void* window) { static_cast<BWindow*>(window)->Show(); }
void eb_haiku_window_hide(void* window) { static_cast<BWindow*>(window)->Hide(); }

void eb_haiku_window_add_child(void* window, void* view) {
    static_cast<BWindow*>(window)->AddChild(static_cast<BView*>(view));
}

void eb_haiku_window_set_layout(void* window, void* layout) {
    static_cast<BWindow*>(window)->SetLayout(static_cast<BLayout*>(layout));
}

void eb_haiku_window_close(void* window) {
    BMessenger(static_cast<BWindow*>(window)).SendMessage(B_QUIT_REQUESTED);
}

void* eb_haiku_view_create(float left, float top, float right, float bottom, const char* name,
                            unsigned int resizingMode, unsigned int flags) {
    return new BView(BRect(left, top, right, bottom), name, resizingMode, flags);
}

void eb_haiku_view_add_child(void* view, void* child) {
    static_cast<BView*>(view)->AddChild(static_cast<BView*>(child));
}

void eb_haiku_view_destroy(void* view) { delete static_cast<BView*>(view); }

void* eb_haiku_button_create(float left, float top, float right, float bottom, const char* name,
                              const char* label, unsigned int what) {
    return new BButton(BRect(left, top, right, bottom), name, label, new BMessage(what));
}

void eb_haiku_button_invoke(void* button) {
    // Not BInvoker::Invoke() directly - confirmed by direct
    // reproduction in a standalone C++ program (no eBasic involved at
    // all) that calling it here hangs/crashes deep inside Haiku's own
    // implementation. This manually does what Invoke() is documented
    // to do (send the control's own message to its own established
    // target) - confirmed working via the same standalone reproduction
    // - sidestepping whatever Invoke()'s own internal issue is.
    BButton* btn = static_cast<BButton*>(button);
    BMessage* msg = btn->Message();
    if (msg) btn->Messenger().SendMessage(msg);
}

void* eb_haiku_stringview_create(float left, float top, float right, float bottom,
                                  const char* name, const char* text) {
    return new BStringView(BRect(left, top, right, bottom), name, text);
}

void eb_haiku_stringview_set_text(void* view, const char* text) {
    static_cast<BStringView*>(view)->SetText(text);
}

const char* eb_haiku_stringview_get_text(void* view) {
    return static_cast<BStringView*>(view)->Text();
}

void* eb_haiku_textcontrol_create(float left, float top, float right, float bottom,
                                   const char* name, const char* label, const char* initialText,
                                   unsigned int what) {
    return new BTextControl(BRect(left, top, right, bottom), name, label, initialText,
                             new BMessage(what));
}

void eb_haiku_textcontrol_set_text(void* view, const char* text) {
    static_cast<BTextControl*>(view)->SetText(text);
}

const char* eb_haiku_textcontrol_get_text(void* view) {
    return static_cast<BTextControl*>(view)->Text();
}

void* eb_haiku_group_layout_create(unsigned int orientation, float spacing) {
    return new BGroupLayout(static_cast<::orientation>(orientation), spacing);
}

void eb_haiku_group_layout_add_view(void* layout, void* view) {
    static_cast<BGroupLayout*>(layout)->AddView(static_cast<BView*>(view));
}

void* eb_haiku_shim_view_create(float left, float top, float right, float bottom,
                                 const char* name, unsigned int resizingMode,
                                 unsigned int flags) {
    return new ShimView(BRect(left, top, right, bottom), name, resizingMode, flags);
}

void eb_haiku_shim_view_set_draw_callback(void* view, EbHaikuDrawCallback cb, void* userData) {
    static_cast<ShimView*>(view)->SetDrawCallback(cb, userData);
}

void eb_haiku_shim_view_set_mouse_down_callback(void* view, EbHaikuMouseCallback cb,
                                                 void* userData) {
    static_cast<ShimView*>(view)->SetMouseDownCallback(cb, userData);
}

void eb_haiku_shim_view_set_mouse_up_callback(void* view, EbHaikuMouseCallback cb,
                                               void* userData) {
    static_cast<ShimView*>(view)->SetMouseUpCallback(cb, userData);
}

void eb_haiku_shim_view_set_key_down_callback(void* view, EbHaikuKeyDownCallback cb,
                                               void* userData) {
    static_cast<ShimView*>(view)->SetKeyDownCallback(cb, userData);
}

void eb_haiku_shim_view_invalidate(void* view) {
    BView* v = static_cast<BView*>(view);
    ViewAutolock lock(v);
    v->Invalidate();
}

void eb_haiku_view_set_high_color(void* view, unsigned char r, unsigned char g,
                                   unsigned char b) {
    static_cast<BView*>(view)->SetHighColor(r, g, b);
}

void eb_haiku_view_fill_rect(void* view, float left, float top, float right, float bottom) {
    static_cast<BView*>(view)->FillRect(BRect(left, top, right, bottom));
}

void eb_haiku_view_stroke_rect(void* view, float left, float top, float right, float bottom) {
    static_cast<BView*>(view)->StrokeRect(BRect(left, top, right, bottom));
}

void eb_haiku_view_stroke_line(void* view, float x1, float y1, float x2, float y2) {
    static_cast<BView*>(view)->StrokeLine(BPoint(x1, y1), BPoint(x2, y2));
}

void eb_haiku_view_draw_string(void* view, const char* text, float x, float y) {
    static_cast<BView*>(view)->DrawString(text, BPoint(x, y));
}

} // extern "C"
