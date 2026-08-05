' Raw FFI layer: a handful of plain OpenGL entry points from real
' Haiku's own libGL.so - NOT Haiku API at all (no eb-haiku shim
' involved), bound directly via Extern "C" Lib "GL", matching the
' direct-Lib-declare precedent already used for Kernel Kit's own
' Lib "root" (raw/haiku_kernel.bas). Only the small set needed for a
' real "clear the screen and draw a triangle" demo - real OpenGL apps
' would call many more of these; add more Declare lines here as
' needed, following the same pattern (no shim wrapper required for any
' of them).

' Real GL_* constants (GL/gl.h) needed for the bound calls below.
CONST H_GL_COLOR_BUFFER_BIT = 16384
CONST H_GL_TRIANGLES = 4

Extern "C" Lib "GL"
    Declare Sub glClearColor(BYVAL red AS SINGLE, BYVAL green AS SINGLE, BYVAL blue AS SINGLE, BYVAL alpha AS SINGLE)
    Declare Sub glClear(BYVAL mask AS UINTEGER)
    Declare Sub glViewport(BYVAL x AS INTEGER, BYVAL y AS INTEGER, BYVAL width AS INTEGER, BYVAL height AS INTEGER)
    Declare Sub glBegin(BYVAL mode AS UINTEGER)
    Declare Sub glEnd()
    Declare Sub glVertex3f(BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL z AS SINGLE)
    Declare Sub glColor3f(BYVAL r AS SINGLE, BYVAL g AS SINGLE, BYVAL b AS SINGLE)
    Declare Sub glFlush()
End Extern
