// eb-haiku native shim - Interface Kit (GUI). See shim.h's own top
// comment for why a hand-written shim is needed at all.
//
// BRect is a plain public 4-float struct (Haiku's own Rect.h) - passed
// here as 4 separate floats rather than mirrored as its own opaque
// handle or eBasic TYPE, simpler than every other class in this package.
//
// Threading: BApplication::Run() blocks whichever thread calls it; each
// BWindow, once shown, runs its own message loop on its own separate
// thread. Callback functions set here (MessageReceived/QuitRequested/
// FrameResized/...) are invoked from that window's own thread, never
// the thread that called Run() - see this package's own README for the
// intended safe usage pattern (do nothing on the Run()-calling thread
// after calling it; all real logic lives in these callbacks).
#pragma once

extern "C" {

// ---- BWindow (via a real ShimWindow subclass - the only way to reach
// MessageReceived/QuitRequested/FrameResized from eBasic at all, since
// eBasic's own Extern mechanism can't override a foreign class's
// virtual methods directly) ----

typedef void (*EbHaikuMessageReceivedCallback)(void* userData, void* messageHandle);
// Return nonzero to allow the window to close, 0 to refuse - matching
// BWindow::QuitRequested()'s own bool return.
typedef int (*EbHaikuQuitRequestedCallback)(void* userData);
typedef void (*EbHaikuFrameResizedCallback)(void* userData, float newWidth, float newHeight);

void* eb_haiku_window_create(float left, float top, float right, float bottom,
                              const char* title, unsigned int flags);
void eb_haiku_window_set_message_received_callback(void* window,
                                                     EbHaikuMessageReceivedCallback cb,
                                                     void* userData);
void eb_haiku_window_set_quit_requested_callback(void* window, EbHaikuQuitRequestedCallback cb,
                                                  void* userData);
void eb_haiku_window_set_frame_resized_callback(void* window, EbHaikuFrameResizedCallback cb,
                                                 void* userData);
void eb_haiku_window_show(void* window);
void eb_haiku_window_hide(void* window);
void eb_haiku_window_add_child(void* window, void* view);
void eb_haiku_window_set_layout(void* window, void* layout);
// Posts B_QUIT_REQUESTED via BMessenger - the documented-safe way to
// close a window from outside its own thread (unlike calling Quit()
// directly, which real Haiku code only ever does from within the
// window's own thread).
void eb_haiku_window_close(void* window);

// ---- BView (plain, non-subclassed - see shim_interface.cpp's own
// ShimView, added when custom Draw/MouseDown/KeyDown is needed) ----

void* eb_haiku_view_create(float left, float top, float right, float bottom,
                            const char* name, unsigned int resizingMode, unsigned int flags);
void eb_haiku_view_add_child(void* view, void* child);
void eb_haiku_view_destroy(void* view);

// ---- Custom drawing/input (via a real ShimView subclass - the only
// way to reach Draw/MouseDown/MouseUp/KeyDown from eBasic, same reason
// as ShimWindow above). A view only receives these callbacks if
// created with the H_WILL_DRAW (Draw) and/or H_FRAME_EVENTS flags as
// appropriate - see raw/haiku_shim_interface.bas's own flag constants.

typedef void (*EbHaikuDrawCallback)(void* userData, float updateLeft, float updateTop,
                                     float updateRight, float updateBottom);
typedef void (*EbHaikuMouseCallback)(void* userData, float x, float y);
typedef void (*EbHaikuKeyDownCallback)(void* userData, const char* bytes, int numBytes);

void* eb_haiku_shim_view_create(float left, float top, float right, float bottom,
                                 const char* name, unsigned int resizingMode,
                                 unsigned int flags);
void eb_haiku_shim_view_set_draw_callback(void* view, EbHaikuDrawCallback cb, void* userData);
void eb_haiku_shim_view_set_mouse_down_callback(void* view, EbHaikuMouseCallback cb,
                                                 void* userData);
void eb_haiku_shim_view_set_mouse_up_callback(void* view, EbHaikuMouseCallback cb,
                                               void* userData);
void eb_haiku_shim_view_set_key_down_callback(void* view, EbHaikuKeyDownCallback cb,
                                               void* userData);
// Requests a redraw (queues a real Draw call) - the only safe way to
// trigger a repaint from outside the view's own Draw callback.
void eb_haiku_shim_view_invalidate(void* view);

// ---- Drawing primitives - callable only from within a Draw callback
// (Haiku's own real restriction: a view's graphics state is only valid
// while it's the "current" view being drawn) - work on any BView*
// (including a ShimView's own handle, or a stock control's).
void eb_haiku_view_set_high_color(void* view, unsigned char r, unsigned char g, unsigned char b);
void eb_haiku_view_fill_rect(void* view, float left, float top, float right, float bottom);
void eb_haiku_view_stroke_rect(void* view, float left, float top, float right, float bottom);
void eb_haiku_view_stroke_line(void* view, float x1, float y1, float x2, float y2);
void eb_haiku_view_draw_string(void* view, const char* text, float x, float y);

// ---- Stock controls (BButton/BStringView/BTextControl - plain,
// non-subclassed) ----
//
// None of these need their own callback-forwarding shim subclass:
// Haiku's own BControl/BInvoker already posts each control's `what`
// message to its target, which defaults to the window it's attached to
// once shown - so a button click (etc.) arrives at the *window's own*
// MessageReceived callback (already wired up above), not a separate
// per-control callback. `HWindowSetMessageReceivedCallback` from Slice
// 1 is the only callback surface stock controls need.

void* eb_haiku_button_create(float left, float top, float right, float bottom, const char* name,
                              const char* label, unsigned int what);
// Triggers the button exactly as a real click would - not implemented
// via BInvoker::Invoke() itself, which crashes when called from
// outside the window's own thread (confirmed by direct reproduction in
// a standalone C++ program - see shim_interface.cpp's own comment on
// eb_haiku_button_invoke); still a legitimate way to programmatically
// drive a button, not just a test-only hack.
void eb_haiku_button_invoke(void* button);

void* eb_haiku_stringview_create(float left, float top, float right, float bottom,
                                  const char* name, const char* text);
void eb_haiku_stringview_set_text(void* view, const char* text);
// Borrowed from the real BStringView's own long-lived storage - no
// heap allocation, no matching free needed (unlike Phase 1's
// HNodeReadAttrString and friends).
const char* eb_haiku_stringview_get_text(void* view);

void* eb_haiku_textcontrol_create(float left, float top, float right, float bottom,
                                   const char* name, const char* label, const char* initialText,
                                   unsigned int what);
void eb_haiku_textcontrol_set_text(void* view, const char* text);
const char* eb_haiku_textcontrol_get_text(void* view);

// ---- BGroupLayout ----
// orientation: 0 = B_HORIZONTAL, 1 = B_VERTICAL (Haiku's own real enum
// values - see raw/haiku_shim_interface.bas's own constants).
void* eb_haiku_group_layout_create(unsigned int orientation, float spacing);
void eb_haiku_group_layout_add_view(void* layout, void* view);

} // extern "C"
