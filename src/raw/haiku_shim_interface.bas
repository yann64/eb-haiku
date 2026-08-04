' Raw FFI layer: eb-haiku's Interface Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_interface.h.
'
' BRect is a plain public 4-float struct in real Haiku (Rect.h) -
' passed here as 4 separate floats rather than mirrored as its own
' TYPE or opaque handle, simpler than every other class in this package.

' Real Haiku window/view flag values (interface/Window.h,
' interface/View.h) - not hand-derived from the header's own #define
' expressions (B_FOLLOW_ALL in particular is a composed macro, not a
' plain literal) - confirmed by actually compiling and printing each
' one on the real Haiku host, matching this package's own established
' "verify, don't assume" discipline.
CONST H_NOT_RESIZABLE = 2
CONST H_NOT_ZOOMABLE = 64
CONST H_WILL_DRAW = 536870912
CONST H_FRAME_EVENTS = 67108864
CONST H_NAVIGABLE = 33554432
CONST H_FOLLOW_NONE = 0
CONST H_FOLLOW_ALL = 4660

' Real Haiku enum values (interface/InterfaceDefs.h) - a plain
' sequential enum starting at 0, confirmed directly against the header.
CONST H_HORIZONTAL = 0
CONST H_VERTICAL = 1

Extern "C" Lib "ebhaikushim"
    ' ---- BWindow (via ShimWindow) ----
    Declare Function eb_haiku_window_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL title AS ZSTRING, BYVAL flags AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_window_set_message_received_callback(BYVAL window AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_window_set_quit_requested_callback(BYVAL window AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_window_set_frame_resized_callback(BYVAL window AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_window_show(BYVAL window AS ANY PTR)
    Declare Sub eb_haiku_window_hide(BYVAL window AS ANY PTR)
    Declare Sub eb_haiku_window_add_child(BYVAL window AS ANY PTR, BYVAL view AS ANY PTR)
    Declare Sub eb_haiku_window_set_layout(BYVAL window AS ANY PTR, BYVAL layout AS ANY PTR)
    Declare Sub eb_haiku_window_close(BYVAL window AS ANY PTR)

    ' ---- BView (plain) ----
    Declare Function eb_haiku_view_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL resizingMode AS UINTEGER, BYVAL flags AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_view_add_child(BYVAL view AS ANY PTR, BYVAL child AS ANY PTR)
    Declare Sub eb_haiku_view_destroy(BYVAL view AS ANY PTR)

    ' ---- Stock controls - no callback machinery of their own, see
    ' shim_interface.h's own note: a click's "what" message reaches the
    ' *window's* MessageReceived callback (HWindowSetMessageReceived-
    ' Callback), not a separate per-control callback.
    Declare Function eb_haiku_button_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL label AS ZSTRING, BYVAL what AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_button_invoke(BYVAL button AS ANY PTR)

    Declare Function eb_haiku_stringview_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL text AS ZSTRING) AS ANY PTR
    Declare Sub eb_haiku_stringview_set_text(BYVAL view AS ANY PTR, BYVAL text AS ZSTRING)
    Declare Function eb_haiku_stringview_get_text(BYVAL view AS ANY PTR) AS ZSTRING

    Declare Function eb_haiku_textcontrol_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL label AS ZSTRING, BYVAL initialText AS ZSTRING, BYVAL what AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_textcontrol_set_text(BYVAL view AS ANY PTR, BYVAL text AS ZSTRING)
    Declare Function eb_haiku_textcontrol_get_text(BYVAL view AS ANY PTR) AS ZSTRING

    ' ---- Custom drawing/input (ShimView) - a view only receives Draw
    ' if created with the H_WILL_DRAW flag.
    Declare Function eb_haiku_shim_view_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL resizingMode AS UINTEGER, BYVAL flags AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_shim_view_set_draw_callback(BYVAL view AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_shim_view_set_mouse_down_callback(BYVAL view AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_shim_view_set_mouse_up_callback(BYVAL view AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_shim_view_set_key_down_callback(BYVAL view AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_shim_view_invalidate(BYVAL view AS ANY PTR)

    ' ---- Drawing primitives - only valid from within a Draw callback ----
    Declare Sub eb_haiku_view_set_high_color(BYVAL view AS ANY PTR, BYVAL r AS UBYTE, BYVAL g AS UBYTE, BYVAL b AS UBYTE)
    Declare Sub eb_haiku_view_fill_rect(BYVAL view AS ANY PTR, BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE)
    Declare Sub eb_haiku_view_stroke_rect(BYVAL view AS ANY PTR, BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE)
    Declare Sub eb_haiku_view_stroke_line(BYVAL view AS ANY PTR, BYVAL x1 AS SINGLE, BYVAL y1 AS SINGLE, BYVAL x2 AS SINGLE, BYVAL y2 AS SINGLE)
    Declare Sub eb_haiku_view_draw_string(BYVAL view AS ANY PTR, BYVAL text AS ZSTRING, BYVAL x AS SINGLE, BYVAL y AS SINGLE)

    ' ---- BGroupLayout ----
    Declare Function eb_haiku_group_layout_create(BYVAL layoutOrientation AS UINTEGER, BYVAL spacing AS SINGLE) AS ANY PTR
    Declare Sub eb_haiku_group_layout_add_view(BYVAL layout AS ANY PTR, BYVAL view AS ANY PTR)
End Extern
