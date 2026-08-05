' Raw FFI layer: eb-haiku's OpenGL Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_gl.h.

' Real BGL_* option flags (opengl/GLView.h) - combine with OR.
CONST H_BGL_RGB = 0
CONST H_BGL_INDEX = 1
CONST H_BGL_SINGLE = 0
CONST H_BGL_DOUBLE = 2
CONST H_BGL_DIRECT = 0
CONST H_BGL_INDIRECT = 4
CONST H_BGL_ACCUM = 8
CONST H_BGL_ALPHA = 16
CONST H_BGL_DEPTH = 32
CONST H_BGL_OVERLAY = 64
CONST H_BGL_UNDERLAY = 128
CONST H_BGL_STENCIL = 512
CONST H_BGL_SHARE_CONTEXT = 1024

Extern "C" Lib "ebhaikushim"
    Declare Function eb_haiku_gl_view_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL resizingMode AS UINTEGER, BYVAL mode AS UINTEGER, BYVAL options AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_gl_view_set_draw_callback(BYVAL view AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_gl_view_lock_gl(BYVAL view AS ANY PTR)
    Declare Sub eb_haiku_gl_view_unlock_gl(BYVAL view AS ANY PTR)
    Declare Sub eb_haiku_gl_view_swap_buffers(BYVAL view AS ANY PTR)
End Extern
