' Screen Saver Kit: a real, installable add-on - a simple animated
' filled rectangle whose color cycles with the frame counter, plus a
' label. Unlike every other example in this package, this one is meant
' to be manually copied into Haiku's own non-packaged Screen Savers
' directory and confirmed via the real Screensaver preferences panel
' (listed, selectable, previewable) - not run directly:
'
'   ebc examples/screensaver_example.bas --shared-lib -o EbHaikuDemo -L /boot/system/non-packaged/develop/lib -l ebhaikushim -l be -l screensaver
'   mkdir -p "/boot/system/non-packaged/add-ons/Screen Savers"
'   cp libEbHaikuDemo.so "/boot/system/non-packaged/add-ons/Screen Savers/EbHaikuDemo"
'
' (the real add-on convention has no `lib` prefix/`.so` extension - just
' the bare display name, confirmed against Haiku's own stock add-ons,
' e.g. /boot/system/add-ons/Screen Savers/Leaves).
'
' Deliberately #includes only screensaver.bas + view.bas (drawing
' primitives), NOT the whole aggregated lib.bas - see
' tests/screensaver_basics.bas's own top comment: a real shared library
' resolves every Shim* class's vtable/RTTI eagerly at load time, so
' pulling in Kits this add-on never uses would need their own real
' Haiku libraries linked for no reason.

#include once "../src/screensaver.bas"
#include once "../src/view.bas"

Extern "C"
    Function instantiate_screen_saver(BYVAL archive AS ANY PTR, BYVAL id AS INTEGER) AS ANY PTR
        DIM saver AS HScreenSaver
        saver = HScreenSaverCreate(archive, id)
        CALL HScreenSaverSetDrawCallback(saver, @OnDraw, 0)
        CALL HScreenSaverSetTickSize(saver, 50000) ' 50ms between frames
        instantiate_screen_saver = saver.handle
    End Function
End Extern

SUB OnDraw(userData AS ANY PTR, view AS ANY PTR, frame AS INTEGER)
    DIM r AS INTEGER
    DIM g AS INTEGER
    DIM b AS INTEGER
    r = (frame * 4) MOD 255
    g = (frame * 7) MOD 255
    b = (frame * 11) MOD 255
    ' A generously oversized rect - BView::FillRect clips to the view's
    ' own real bounds automatically, whatever the actual screen/preview
    ' size turns out to be, so there's no need to query it first.
    CALL HViewSetHighColor(view, r, g, b)
    CALL HViewFillRect(view, 0, 0, 2000, 2000)
    CALL HViewSetHighColor(view, 255, 255, 255)
    CALL HViewDrawString(view, "eb-haiku Screen Saver Kit demo", 20, 30)
END SUB
