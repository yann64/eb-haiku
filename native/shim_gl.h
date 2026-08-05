// eb-haiku native shim - OpenGL Kit (os/opengl/GLView.h) - BGLView, a
// real BView subclass, addable to a window exactly like any other
// view (HWindowAddChild). Reuses shim_interface.h's own
// EbHaikuDrawCallback typedef - identical signature to ShimView's own
// Draw forwarding, no new callback type needed. Owned/destroyed the
// same way any other child view is (no separate destroy function - a
// window destroys its own children), matching eb_haiku_shim_view_create's
// own established convention.
//
// Raw OpenGL calls (glClear/glViewport/glBegin/etc.) are a separate
// libGL.so surface, not Haiku API - not wrapped here at all; bound
// directly via Extern "C" Lib "GL" in the raw .bas layer instead
// (src/raw/haiku_gl.bas), matching the direct-Lib-declare precedent
// already used for Kernel Kit's Lib "root".
//
// BGLRenderer not bound - internal-only, BGLView owns/drives one
// transparently; no public API surface a consumer would ever touch
// directly.
#pragma once

#include "shim_interface.h"

extern "C" {

void* eb_haiku_gl_view_create(float left, float top, float right, float bottom, const char* name,
                               unsigned int resizingMode, unsigned int mode,
                               unsigned int options);
void eb_haiku_gl_view_set_draw_callback(void* view, EbHaikuDrawCallback cb, void* userData);

void eb_haiku_gl_view_lock_gl(void* view);
void eb_haiku_gl_view_unlock_gl(void* view);
void eb_haiku_gl_view_swap_buffers(void* view);

} // extern "C"
