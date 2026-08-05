' OpenGL Kit: BGLView - clear the screen to a real solid color and draw
' a real triangle. GUI/drawing behavior has no automated visual check
' (same limitation as every other Layout Kit/GUI example in this
' package) - this test only confirms it runs without crashing; the
' color/triangle was verified by hand via Haiku's own `screenshot -s`
' during development.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

SUB OnGLDraw(userData AS ANY PTR, updateLeft AS SINGLE, updateTop AS SINGLE, updateRight AS SINGLE, updateBottom AS SINGLE)
    DIM v AS HGLView
    v.handle = userData
    CALL HGLViewLockGL(v)
    CALL glClearColor(0.1, 0.2, 0.4, 1.0)
    CALL glClear(H_GL_COLOR_BUFFER_BIT)
    CALL glBegin(H_GL_TRIANGLES)
    CALL glColor3f(1.0, 0.0, 0.0)
    CALL glVertex3f(0.0, 0.5, 0.0)
    CALL glColor3f(0.0, 1.0, 0.0)
    CALL glVertex3f(-0.5, -0.5, 0.0)
    CALL glColor3f(0.0, 0.0, 1.0)
    CALL glVertex3f(0.5, -0.5, 0.0)
    CALL glEnd()
    CALL glFlush()
    CALL HGLViewSwapBuffers(v)
    CALL HGLViewUnlockGL(v)
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-GLViewBasicsTest")

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 320, "eb-haiku GLView test", H_QUIT_ON_WINDOW_CLOSE)

DIM glView AS HGLView
glView = HGLViewCreate(0, 0, 400, 300, "glview", 0, 0, H_BGL_RGB OR H_BGL_DOUBLE OR H_BGL_DEPTH)
CALL HGLViewSetDrawCallback(glView, @OnGLDraw, glView.handle)
CALL HWindowAddChild(w, glView.handle)

CALL HWindowShow(w)
CALL Sleep(1000) ' visible for an external screenshot

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)

PRINT "gl view basics test ok"
