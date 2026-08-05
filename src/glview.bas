' Idiomatic layer: OpenGL Kit - BGLView, a real BView subclass adding
' actual OpenGL rendering into a window (HWindowAddChild(w,
' glView.handle), exactly like any other view/control). Real raw GL
' calls themselves (glClear/glViewport/glBegin/etc.) live in
' raw/haiku_gl.bas, bound directly against libGL.so - not Haiku API,
' no shim wrapper.
'
' Real usage: create with HGLViewCreate, add to a window, register a
' draw callback via HGLViewSetDrawCallback. Inside that callback, call
' HGLViewLockGL, issue raw GL calls, HGLViewSwapBuffers, then
' HGLViewUnlockGL - matching real Haiku's own documented GL rendering
' sequence (BGLView::Draw is the one legitimate place to call LockGL/
' UnlockGL from).

#include once "raw/haiku_shim_gl.bas"

TYPE HGLView
    handle AS ANY PTR
END TYPE

''' `mode`/`options` are H_BGL_* flags (raw/haiku_shim_gl.bas, combine
''' with OR) - e.g. H_BGL_RGB OR H_BGL_DOUBLE OR H_BGL_DEPTH for a
''' typical double-buffered, depth-tested view.
FUNCTION HGLViewCreate(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, name AS ZSTRING, BYVAL resizingMode AS UINTEGER, BYVAL mode AS UINTEGER, BYVAL options AS UINTEGER) AS HGLView
    DIM v AS HGLView
    v.handle = eb_haiku_gl_view_create(left, top, right, bottom, name, resizingMode, mode, options)
    HGLViewCreate = v
END FUNCTION

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, updateLeft AS SINGLE, updateTop AS SINGLE, updateRight AS
''' SINGLE, updateBottom AS SINGLE) - call HGLViewLockGL/UnlockGL
''' around any real GL calls inside it, and HGLViewSwapBuffers before
''' unlocking.
SUB HGLViewSetDrawCallback(BYVAL v AS HGLView, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_gl_view_set_draw_callback(v.handle, cb, userData)
END SUB

SUB HGLViewLockGL(BYVAL v AS HGLView)
    CALL eb_haiku_gl_view_lock_gl(v.handle)
END SUB

SUB HGLViewUnlockGL(BYVAL v AS HGLView)
    CALL eb_haiku_gl_view_unlock_gl(v.handle)
END SUB

SUB HGLViewSwapBuffers(BYVAL v AS HGLView)
    CALL eb_haiku_gl_view_swap_buffers(v.handle)
END SUB
