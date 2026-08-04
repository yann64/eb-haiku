' Idiomatic layer: BView - basic, plain (non-subclassed) creation for
' Slice 1. Custom drawing/mouse/keyboard callbacks (which do need a real
' shim subclass, ShimView) are added separately once that surface
' exists - see this file's own later additions.

#include once "raw/haiku_shim_interface.bas"

TYPE HView
    handle AS ANY PTR
END TYPE

''' Creates a plain view (a container for child views/controls, or a
''' canvas once custom drawing is added). `resizingMode` is typically
''' `H_FOLLOW_ALL` (stretches with its parent) or `H_FOLLOW_NONE`
''' (stays a fixed size/position); `flags` is typically `H_WILL_DRAW`
''' if you plan to draw into it, `0` for a plain container.
FUNCTION HViewCreate(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, name AS ZSTRING, BYVAL resizingMode AS UINTEGER, BYVAL flags AS UINTEGER) AS HView
    DIM v AS HView
    v.handle = eb_haiku_view_create(left, top, right, bottom, name, resizingMode, flags)
    HViewCreate = v
END FUNCTION

''' Adds `child` (an HView, HButton, HStringView, ... - anything whose
''' own `.handle` is a real BView*) as a child of this view.
SUB HViewAddChild(BYVAL v AS HView, BYVAL child AS ANY PTR)
    CALL eb_haiku_view_add_child(v.handle, child)
END SUB

''' Frees a view that was never added to a window/another view (once
''' added via HWindowAddChild/HViewAddChild, Haiku owns it - freeing it
''' yourself afterward would be a double-free).
SUB HViewFree(BYVAL v AS HView)
    CALL eb_haiku_view_destroy(v.handle)
END SUB

' ---- View-level layout attachment + size/alignment constraints - take
' a plain ANY PTR handle (not HView specifically) so they work
' uniformly on any view/control (HView/HButton/HStringView/
' HTextControl/HShimView, all via their own `.handle`).

''' Attaches `layout` (an HGroupLayout/HGridLayout/HCardLayout's own
''' `.handle`) to `view` - lets a layout live nested inside an ordinary
''' view, itself added to a parent layout/window, instead of only ever
''' at the top (window) level.
SUB HViewSetLayout(BYVAL view AS ANY PTR, BYVAL layout AS ANY PTR)
    CALL eb_haiku_view_set_layout(view, layout)
END SUB

SUB HViewSetExplicitMinSize(BYVAL view AS ANY PTR, BYVAL width AS SINGLE, BYVAL height AS SINGLE)
    CALL eb_haiku_view_set_explicit_min_size(view, width, height)
END SUB

SUB HViewSetExplicitMaxSize(BYVAL view AS ANY PTR, BYVAL width AS SINGLE, BYVAL height AS SINGLE)
    CALL eb_haiku_view_set_explicit_max_size(view, width, height)
END SUB

SUB HViewSetExplicitPreferredSize(BYVAL view AS ANY PTR, BYVAL width AS SINGLE, BYVAL height AS SINGLE)
    CALL eb_haiku_view_set_explicit_preferred_size(view, width, height)
END SUB

''' Sets min, max, and preferred size all at once (Haiku's own
''' convenience for "pin this view to exactly this size").
SUB HViewSetExplicitSize(BYVAL view AS ANY PTR, BYVAL width AS SINGLE, BYVAL height AS SINGLE)
    CALL eb_haiku_view_set_explicit_size(view, width, height)
END SUB

''' `horizontalAlign` is `H_ALIGN_LEFT`/`RIGHT`/`CENTER`; `verticalAlign`
''' is `H_ALIGN_TOP`/`BOTTOM`/`MIDDLE`.
SUB HViewSetExplicitAlignment(BYVAL view AS ANY PTR, BYVAL horizontalAlign AS INTEGER, BYVAL verticalAlign AS INTEGER)
    CALL eb_haiku_view_set_explicit_alignment(view, horizontalAlign, verticalAlign)
END SUB

' ---- Custom drawing/input (via the shim's own ShimView subclass - the
' only way to reach Draw/MouseDown/MouseUp/KeyDown from eBasic, same
' reason as HWindow's own callbacks) ----

TYPE HShimView
    handle AS ANY PTR
END TYPE

''' Creates a view that can receive Draw/MouseDown/MouseUp/KeyDown
''' callbacks - pass `H_WILL_DRAW` in `flags` if you plan to draw into
''' it (otherwise Draw never fires, matching real Haiku's own rule).
FUNCTION HShimViewCreate(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, name AS ZSTRING, BYVAL resizingMode AS UINTEGER, BYVAL flags AS UINTEGER) AS HShimView
    DIM v AS HShimView
    v.handle = eb_haiku_shim_view_create(left, top, right, bottom, name, resizingMode, flags)
    HShimViewCreate = v
END FUNCTION

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, updateLeft AS SINGLE, updateTop AS SINGLE, updateRight AS
''' SINGLE, updateBottom AS SINGLE) - only the drawing primitives below
''' (SetHighColor/FillRect/StrokeRect/StrokeLine/DrawString) are valid
''' to call from within it (Haiku's own real restriction - a view's
''' graphics state is only valid while it's actually being drawn).
SUB HShimViewSetDrawCallback(BYVAL v AS HShimView, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_shim_view_set_draw_callback(v.handle, cb, userData)
END SUB

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, x AS SINGLE, y AS SINGLE) - the click position in the view's
''' own coordinates.
SUB HShimViewSetMouseDownCallback(BYVAL v AS HShimView, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_shim_view_set_mouse_down_callback(v.handle, cb, userData)
END SUB

SUB HShimViewSetMouseUpCallback(BYVAL v AS HShimView, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_shim_view_set_mouse_up_callback(v.handle, cb, userData)
END SUB

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, bytes AS ZSTRING, numBytes AS INTEGER).
SUB HShimViewSetKeyDownCallback(BYVAL v AS HShimView, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_shim_view_set_key_down_callback(v.handle, cb, userData)
END SUB

''' Requests a redraw (queues a real Draw call) - the only safe way to
''' trigger a repaint from outside the view's own Draw callback (e.g.
''' after changing some state a MouseDown callback should visibly
''' reflect).
SUB HShimViewInvalidate(BYVAL v AS HShimView)
    CALL eb_haiku_shim_view_invalidate(v.handle)
END SUB

' ---- Drawing primitives - call only from within a Draw callback.
' Take a plain ANY PTR view handle (not HView/HShimView specifically) so
' they work uniformly on whatever real BView you're drawing into.

SUB HViewSetHighColor(BYVAL view AS ANY PTR, BYVAL r AS UBYTE, BYVAL g AS UBYTE, BYVAL b AS UBYTE)
    CALL eb_haiku_view_set_high_color(view, r, g, b)
END SUB

SUB HViewFillRect(BYVAL view AS ANY PTR, BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE)
    CALL eb_haiku_view_fill_rect(view, left, top, right, bottom)
END SUB

SUB HViewStrokeRect(BYVAL view AS ANY PTR, BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE)
    CALL eb_haiku_view_stroke_rect(view, left, top, right, bottom)
END SUB

SUB HViewStrokeLine(BYVAL view AS ANY PTR, BYVAL x1 AS SINGLE, BYVAL y1 AS SINGLE, BYVAL x2 AS SINGLE, BYVAL y2 AS SINGLE)
    CALL eb_haiku_view_stroke_line(view, x1, y1, x2, y2)
END SUB

SUB HViewDrawString(BYVAL view AS ANY PTR, text AS ZSTRING, BYVAL x AS SINGLE, BYVAL y AS SINGLE)
    CALL eb_haiku_view_draw_string(view, text, x, y)
END SUB

''' Draws `bitmap` (an HBitmap's own `.handle` - see bitmap.bas) with
''' its top-left corner at (x, y), at its own native size (no scaling).
SUB HViewDrawBitmap(BYVAL view AS ANY PTR, BYVAL bitmap AS ANY PTR, BYVAL x AS SINGLE, BYVAL y AS SINGLE)
    CALL eb_haiku_view_draw_bitmap(view, bitmap, x, y)
END SUB
