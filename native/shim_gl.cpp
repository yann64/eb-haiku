#include "shim_gl.h"

#include <GLView.h>

namespace {

/// Same forwarding pattern as shim_interface.cpp's own ShimView/
/// ShimWindow (see their top comments) - the only way to reach
/// BGLView's own virtual Draw() from eBasic.
class ShimGLView : public BGLView {
public:
    ShimGLView(BRect rect, const char* name, unsigned int resizingMode, unsigned int mode,
               unsigned int options)
        : BGLView(rect, name, resizingMode, mode, options) {}

    void SetDrawCallback(EbHaikuDrawCallback cb, void* userData) {
        fDrawCallback = cb;
        fDrawUserData = userData;
    }

    void Draw(BRect updateRect) override {
        if (fDrawCallback) {
            fDrawCallback(fDrawUserData, updateRect.left, updateRect.top, updateRect.right,
                          updateRect.bottom);
        } else {
            BGLView::Draw(updateRect);
        }
    }

private:
    EbHaikuDrawCallback fDrawCallback = nullptr;
    void* fDrawUserData = nullptr;
};

} // namespace

extern "C" {

void* eb_haiku_gl_view_create(float left, float top, float right, float bottom, const char* name,
                               unsigned int resizingMode, unsigned int mode,
                               unsigned int options) {
    return new ShimGLView(BRect(left, top, right, bottom), name, resizingMode, mode, options);
}

void eb_haiku_gl_view_set_draw_callback(void* view, EbHaikuDrawCallback cb, void* userData) {
    static_cast<ShimGLView*>(view)->SetDrawCallback(cb, userData);
}

void eb_haiku_gl_view_lock_gl(void* view) { static_cast<BGLView*>(view)->LockGL(); }

void eb_haiku_gl_view_unlock_gl(void* view) { static_cast<BGLView*>(view)->UnlockGL(); }

void eb_haiku_gl_view_swap_buffers(void* view) { static_cast<BGLView*>(view)->SwapBuffers(); }

} // extern "C"
