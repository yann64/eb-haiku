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

' Real Haiku alignment enum values (interface/InterfaceDefs.h) - NOT a
' plain sequential enum (B_ALIGN_TOP is 16, not 2) - confirmed by
' compiling and printing each one on the real Haiku host.
CONST H_ALIGN_LEFT = 0
CONST H_ALIGN_RIGHT = 1
CONST H_ALIGN_CENTER = 2
CONST H_ALIGN_TOP = 16
CONST H_ALIGN_BOTTOM = 48
CONST H_ALIGN_MIDDLE = 32
' Real "fill/stretch this axis" sentinels - both -2, distinct from the
' LEFT/RIGHT/CENTER/TOP/BOTTOM/MIDDLE values above. This is also
' BView's own real default alignment on both axes when
' HViewSetExplicitAlignment is never called at all - passing these
' explicitly only matters when you need to restore fill on ONE axis
' after having overridden the other.
CONST H_ALIGN_USE_FULL_WIDTH = -2
CONST H_ALIGN_USE_FULL_HEIGHT = -2

' A real Haiku sentinel value (interface/Layout.h) meaning "use this
' layout's own default spacing" - confirmed on the real Haiku host.
CONST H_USE_DEFAULT_SPACING = -1002

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
    Declare Sub eb_haiku_window_set_title(BYVAL window AS ANY PTR, BYVAL title AS ZSTRING)
    Declare Sub eb_haiku_window_move_to(BYVAL window AS ANY PTR, BYVAL x AS SINGLE, BYVAL y AS SINGLE)
    Declare Sub eb_haiku_window_resize_to(BYVAL window AS ANY PTR, BYVAL width AS SINGLE, BYVAL height AS SINGLE)
    Declare Sub eb_haiku_window_set_enabled(BYVAL window AS ANY PTR, BYVAL enabled AS INTEGER)
    Declare Sub eb_haiku_window_set_modal(BYVAL window AS ANY PTR, BYVAL parent AS ANY PTR)
    Declare Sub eb_haiku_window_clear_modal(BYVAL window AS ANY PTR, BYVAL parent AS ANY PTR)

    ' ---- BView (plain) ----
    Declare Function eb_haiku_view_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL resizingMode AS UINTEGER, BYVAL flags AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_view_add_child(BYVAL view AS ANY PTR, BYVAL child AS ANY PTR)
    Declare Sub eb_haiku_view_destroy(BYVAL view AS ANY PTR)

    ' ---- View-level layout attachment + per-view size/alignment
    ' constraints - works on any view/control handle.
    Declare Sub eb_haiku_view_set_layout(BYVAL view AS ANY PTR, BYVAL layout AS ANY PTR)
    Declare Sub eb_haiku_view_set_explicit_min_size(BYVAL view AS ANY PTR, BYVAL width AS SINGLE, BYVAL height AS SINGLE)
    Declare Sub eb_haiku_view_set_explicit_max_size(BYVAL view AS ANY PTR, BYVAL width AS SINGLE, BYVAL height AS SINGLE)
    Declare Sub eb_haiku_view_set_explicit_preferred_size(BYVAL view AS ANY PTR, BYVAL width AS SINGLE, BYVAL height AS SINGLE)
    Declare Sub eb_haiku_view_set_explicit_size(BYVAL view AS ANY PTR, BYVAL width AS SINGLE, BYVAL height AS SINGLE)
    Declare Sub eb_haiku_view_set_explicit_alignment(BYVAL view AS ANY PTR, BYVAL horizontalAlign AS INTEGER, BYVAL verticalAlign AS INTEGER)

    ' ---- Stock controls - no callback machinery of their own, see
    ' shim_interface.h's own note: a click's "what" message reaches the
    ' *window's* MessageReceived callback (HWindowSetMessageReceived-
    ' Callback), not a separate per-control callback.
    Declare Function eb_haiku_button_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL label AS ZSTRING, BYVAL what AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_button_invoke(BYVAL button AS ANY PTR)
    Declare Sub eb_haiku_button_set_label(BYVAL button AS ANY PTR, BYVAL label AS ZSTRING)
    Declare Function eb_haiku_button_get_label(BYVAL button AS ANY PTR) AS ZSTRING

    ' Generic across every stock control (BButton/BTextControl both
    ' derive from BControl) - pass any of their handles directly.
    Declare Sub eb_haiku_control_set_enabled(BYVAL control AS ANY PTR, BYVAL enabled AS INTEGER)
    Declare Function eb_haiku_control_is_enabled(BYVAL control AS ANY PTR) AS INTEGER

    Declare Function eb_haiku_stringview_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL text AS ZSTRING) AS ANY PTR
    Declare Sub eb_haiku_stringview_set_text(BYVAL view AS ANY PTR, BYVAL text AS ZSTRING)
    Declare Function eb_haiku_stringview_get_text(BYVAL view AS ANY PTR) AS ZSTRING

    Declare Function eb_haiku_textcontrol_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL label AS ZSTRING, BYVAL initialText AS ZSTRING, BYVAL what AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_textcontrol_set_text(BYVAL view AS ANY PTR, BYVAL text AS ZSTRING)
    Declare Function eb_haiku_textcontrol_get_text(BYVAL view AS ANY PTR) AS ZSTRING

    ' ---- BTextView (multi-line, plain-text editing only) ----
    Declare Function eb_haiku_textview_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING) AS ANY PTR
    Declare Sub eb_haiku_textview_set_text(BYVAL view AS ANY PTR, BYVAL text AS ZSTRING)
    Declare Function eb_haiku_textview_get_text(BYVAL view AS ANY PTR) AS ZSTRING
    Declare Function eb_haiku_textview_text_length(BYVAL view AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_textview_set_word_wrap(BYVAL view AS ANY PTR, BYVAL wrap AS INTEGER)
    Declare Sub eb_haiku_textview_make_editable(BYVAL view AS ANY PTR, BYVAL editable AS INTEGER)
    Declare Sub eb_haiku_textview_select(BYVAL view AS ANY PTR, BYVAL start AS INTEGER, BYVAL end_ AS INTEGER)
    Declare Sub eb_haiku_textview_set_stylable(BYVAL view AS ANY PTR, BYVAL stylable AS INTEGER)
    Declare Function eb_haiku_textview_is_stylable(BYVAL view AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_textview_set_color(BYVAL view AS ANY PTR, BYVAL start AS INTEGER, BYVAL end_ AS INTEGER, BYVAL r AS UBYTE, BYVAL g AS UBYTE, BYVAL b AS UBYTE, BYVAL a AS UBYTE)
    Declare Sub eb_haiku_textview_get_color(BYVAL view AS ANY PTR, BYVAL offset AS INTEGER, BYVAL outR AS ANY PTR, BYVAL outG AS ANY PTR, BYVAL outB AS ANY PTR, BYVAL outA AS ANY PTR)

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
    Declare Sub eb_haiku_view_draw_bitmap(BYVAL view AS ANY PTR, BYVAL bitmap AS ANY PTR, BYVAL x AS SINGLE, BYVAL y AS SINGLE)
    Declare Sub eb_haiku_view_drag_message(BYVAL view AS ANY PTR, BYVAL message AS ANY PTR, BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE)

    ' ---- BGroupLayout ----
    Declare Function eb_haiku_group_layout_create(BYVAL layoutOrientation AS UINTEGER, BYVAL spacing AS SINGLE) AS ANY PTR
    Declare Sub eb_haiku_group_layout_add_view(BYVAL layout AS ANY PTR, BYVAL view AS ANY PTR)
    Declare Sub eb_haiku_group_layout_set_orientation(BYVAL layout AS ANY PTR, BYVAL layoutOrientation AS UINTEGER)
    Declare Sub eb_haiku_group_layout_set_spacing(BYVAL layout AS ANY PTR, BYVAL spacing AS SINGLE)
    Declare Function eb_haiku_group_layout_item_weight(BYVAL layout AS ANY PTR, BYVAL index AS INTEGER) AS SINGLE
    Declare Sub eb_haiku_group_layout_set_item_weight(BYVAL layout AS ANY PTR, BYVAL index AS INTEGER, BYVAL weight AS SINGLE)

    ' ---- Generic BLayout operations - BGroupLayout/BGridLayout/
    ' BCardLayout all share this common base with a *virtual*
    ' AddView/AddItem, so these two functions work correctly no matter
    ' which concrete layout handle is actually passed in.
    Declare Sub eb_haiku_layout_add_view(BYVAL layout AS ANY PTR, BYVAL view AS ANY PTR)
    Declare Sub eb_haiku_layout_add_item(BYVAL layout AS ANY PTR, BYVAL item AS ANY PTR)
    ' SetInsets is on the shared base of Group *and* Grid specifically
    ' (not Card, which has no insets of its own).
    Declare Sub eb_haiku_two_dimensional_layout_set_insets(BYVAL layout AS ANY PTR, BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE)

    ' ---- BGridLayout ----
    Declare Function eb_haiku_grid_layout_create(BYVAL horizontalSpacing AS SINGLE, BYVAL verticalSpacing AS SINGLE) AS ANY PTR
    Declare Sub eb_haiku_grid_layout_add_view_at(BYVAL layout AS ANY PTR, BYVAL view AS ANY PTR, BYVAL column AS INTEGER, BYVAL row AS INTEGER, BYVAL columnCount AS INTEGER, BYVAL rowCount AS INTEGER)
    Declare Sub eb_haiku_grid_layout_set_spacing(BYVAL layout AS ANY PTR, BYVAL horizontalSpacing AS SINGLE, BYVAL verticalSpacing AS SINGLE)
    Declare Sub eb_haiku_grid_layout_set_column_weight(BYVAL layout AS ANY PTR, BYVAL column AS INTEGER, BYVAL weight AS SINGLE)
    Declare Sub eb_haiku_grid_layout_set_row_weight(BYVAL layout AS ANY PTR, BYVAL row AS INTEGER, BYVAL weight AS SINGLE)
    Declare Sub eb_haiku_grid_layout_set_min_column_width(BYVAL layout AS ANY PTR, BYVAL column AS INTEGER, BYVAL width AS SINGLE)
    Declare Sub eb_haiku_grid_layout_set_max_column_width(BYVAL layout AS ANY PTR, BYVAL column AS INTEGER, BYVAL width AS SINGLE)
    Declare Sub eb_haiku_grid_layout_set_min_row_height(BYVAL layout AS ANY PTR, BYVAL row AS INTEGER, BYVAL height AS SINGLE)
    Declare Sub eb_haiku_grid_layout_set_max_row_height(BYVAL layout AS ANY PTR, BYVAL row AS INTEGER, BYVAL height AS SINGLE)

    ' ---- BCardLayout - shows exactly one child at a time. Add children
    ' via the generic eb_haiku_layout_add_view above.
    Declare Function eb_haiku_card_layout_create() AS ANY PTR
    Declare Sub eb_haiku_card_layout_set_visible_item(BYVAL layout AS ANY PTR, BYVAL index AS INTEGER)
    Declare Function eb_haiku_card_layout_visible_index(BYVAL layout AS ANY PTR) AS INTEGER

    ' ---- BSplitView - a real BView subclass, not a BLayout ----
    Declare Function eb_haiku_split_view_create(BYVAL splitOrientation AS UINTEGER, BYVAL spacing AS SINGLE) AS ANY PTR
    Declare Sub eb_haiku_split_view_add_child(BYVAL splitView AS ANY PTR, BYVAL view AS ANY PTR, BYVAL weight AS SINGLE)
    Declare Sub eb_haiku_split_view_set_collapsible(BYVAL splitView AS ANY PTR, BYVAL collapsible AS INTEGER)
    Declare Sub eb_haiku_split_view_set_insets(BYVAL splitView AS ANY PTR, BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE)
    Declare Sub eb_haiku_split_view_set_splitter_size(BYVAL splitView AS ANY PTR, BYVAL size AS SINGLE)

    ' ---- BSpaceLayoutItem - real spacer items, added via the generic
    ' eb_haiku_layout_add_item above.
    Declare Function eb_haiku_space_layout_item_create_glue() AS ANY PTR
    Declare Function eb_haiku_space_layout_item_create_horizontal_strut(BYVAL width AS SINGLE) AS ANY PTR
    Declare Function eb_haiku_space_layout_item_create_vertical_strut(BYVAL height AS SINGLE) AS ANY PTR

    ' ---- BMenuBar/BMenu/BMenuItem ----
    Declare Function eb_haiku_menu_bar_create(BYVAL name AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_menu_create(BYVAL name AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_menu_item_create(BYVAL label AS ZSTRING, BYVAL message AS ANY PTR) AS ANY PTR
    Declare Function eb_haiku_menu_item_create_submenu(BYVAL submenu AS ANY PTR, BYVAL message AS ANY PTR) AS ANY PTR
    Declare Function eb_haiku_menu_add_item(BYVAL menu AS ANY PTR, BYVAL item AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_menu_add_submenu(BYVAL menu AS ANY PTR, BYVAL submenu AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_menu_add_separator_item(BYVAL menu AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_menu_item_set_enabled(BYVAL item AS ANY PTR, BYVAL enabled AS INTEGER)
    Declare Sub eb_haiku_menu_item_set_marked(BYVAL item AS ANY PTR, BYVAL marked AS INTEGER)
    Declare Function eb_haiku_menu_item_is_marked(BYVAL item AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_menu_item_invoke_via_messenger(BYVAL item AS ANY PTR)
    Declare Sub eb_haiku_menu_set_radio_mode(BYVAL menu AS ANY PTR, BYVAL isOn AS INTEGER)
    Declare Function eb_haiku_menu_is_radio_mode(BYVAL menu AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_menu_set_label_from_marked(BYVAL menu AS ANY PTR, BYVAL isOn AS INTEGER)

    ' ---- ShimHandler - a small, reusable per-object callback target ----
    Declare Function eb_haiku_handler_create() AS ANY PTR
    Declare Sub eb_haiku_handler_set_callback(BYVAL handler AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_window_add_handler(BYVAL window AS ANY PTR, BYVAL handler AS ANY PTR)
    Declare Sub eb_haiku_menu_item_set_target(BYVAL item AS ANY PTR, BYVAL handler AS ANY PTR)
    Declare Sub eb_haiku_button_set_target(BYVAL button AS ANY PTR, BYVAL handler AS ANY PTR)
    Declare Sub eb_haiku_textcontrol_set_target(BYVAL textControl AS ANY PTR, BYVAL handler AS ANY PTR)

    ' ---- BCheckBox/BRadioButton ----
    Declare Function eb_haiku_checkbox_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL label AS ZSTRING, BYVAL what AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_checkbox_set_value(BYVAL checkbox AS ANY PTR, BYVAL value AS INTEGER)
    Declare Function eb_haiku_checkbox_get_value(BYVAL checkbox AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_checkbox_set_target(BYVAL checkbox AS ANY PTR, BYVAL handler AS ANY PTR)

    Declare Function eb_haiku_radiobutton_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL label AS ZSTRING, BYVAL what AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_radiobutton_set_value(BYVAL radioButton AS ANY PTR, BYVAL value AS INTEGER)
    Declare Function eb_haiku_radiobutton_get_value(BYVAL radioButton AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_radiobutton_set_target(BYVAL radioButton AS ANY PTR, BYVAL handler AS ANY PTR)

    ' ---- BStatusBar/BSlider ----
    Declare Function eb_haiku_statusbar_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL label AS ZSTRING, BYVAL trailingLabel AS ZSTRING) AS ANY PTR
    Declare Sub eb_haiku_statusbar_set_max_value(BYVAL statusBar AS ANY PTR, BYVAL max AS SINGLE)
    Declare Function eb_haiku_statusbar_current_value(BYVAL statusBar AS ANY PTR) AS SINGLE
    Declare Sub eb_haiku_statusbar_set_to(BYVAL statusBar AS ANY PTR, BYVAL value AS SINGLE)

    Declare Function eb_haiku_slider_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL label AS ZSTRING, BYVAL minValue AS INTEGER, BYVAL maxValue AS INTEGER, BYVAL what AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_slider_set_value(BYVAL slider AS ANY PTR, BYVAL value AS INTEGER)
    Declare Function eb_haiku_slider_get_value(BYVAL slider AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_slider_set_limits(BYVAL slider AS ANY PTR, BYVAL minValue AS INTEGER, BYVAL maxValue AS INTEGER)
    Declare Sub eb_haiku_slider_set_target(BYVAL slider AS ANY PTR, BYVAL handler AS ANY PTR)

    ' ---- ShimListView (BListView) + BStringItem ----
    Declare Function eb_haiku_listview_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL multipleSelection AS INTEGER) AS ANY PTR
    Declare Sub eb_haiku_listview_set_selection_changed_callback(BYVAL listView AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_listview_add_item(BYVAL listView AS ANY PTR, BYVAL item AS ANY PTR)
    Declare Sub eb_haiku_listview_make_empty(BYVAL listView AS ANY PTR)
    Declare Function eb_haiku_listview_count_items(BYVAL listView AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_listview_current_selection(BYVAL listView AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_listview_select(BYVAL listView AS ANY PTR, BYVAL index AS INTEGER)

    Declare Function eb_haiku_stringitem_create(BYVAL text AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_stringitem_get_text(BYVAL item AS ANY PTR) AS ZSTRING

    ' ---- ShimTimer (BMessageRunner) ----
    Declare Function eb_haiku_timer_create(BYVAL handler AS ANY PTR) AS ANY PTR
    Declare Sub eb_haiku_timer_set_interval(BYVAL timer AS ANY PTR, BYVAL microseconds AS LONGINT)
    Declare Sub eb_haiku_timer_set_single_shot(BYVAL timer AS ANY PTR, BYVAL singleShot AS INTEGER)
    Declare Sub eb_haiku_timer_start(BYVAL timer AS ANY PTR)
    Declare Sub eb_haiku_timer_stop(BYVAL timer AS ANY PTR)
    Declare Function eb_haiku_timer_is_active(BYVAL timer AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_timer_destroy(BYVAL timer AS ANY PTR)

    ' ---- BPopUpMenu (IS-A BMenu - reuses BMenu's own add_item/
    ' add_submenu/add_separator_item declares above) ----
    Declare Function eb_haiku_popup_menu_create(BYVAL name AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_popup_menu_go(BYVAL popup AS ANY PTR, BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL autoInvoke AS INTEGER, BYVAL keepOpen AS INTEGER, BYVAL async AS INTEGER) AS ANY PTR

    ' ---- BMenuField ----
    Declare Function eb_haiku_menu_field_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL name AS ZSTRING, BYVAL label AS ZSTRING, BYVAL menu AS ANY PTR) AS ANY PTR
    Declare Function eb_haiku_menu_field_menu(BYVAL menuField AS ANY PTR) AS ANY PTR

    ' ---- BPrintJob ----
    Declare Function eb_haiku_print_job_create(BYVAL name AS ZSTRING) AS ANY PTR
    Declare Sub eb_haiku_print_job_set_draw_view_callback(BYVAL job AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_print_job_begin_job(BYVAL job AS ANY PTR)
    Declare Sub eb_haiku_print_job_commit_job(BYVAL job AS ANY PTR)
    Declare Function eb_haiku_print_job_config_job(BYVAL job AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_print_job_cancel_job(BYVAL job AS ANY PTR)
    Declare Function eb_haiku_print_job_config_page(BYVAL job AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_print_job_spool_page(BYVAL job AS ANY PTR)
    Declare Function eb_haiku_print_job_can_continue(BYVAL job AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_print_job_paper_rect(BYVAL job AS ANY PTR, BYVAL outLeft AS ANY PTR, BYVAL outTop AS ANY PTR, BYVAL outRight AS ANY PTR, BYVAL outBottom AS ANY PTR)
    Declare Sub eb_haiku_print_job_printable_rect(BYVAL job AS ANY PTR, BYVAL outLeft AS ANY PTR, BYVAL outTop AS ANY PTR, BYVAL outRight AS ANY PTR, BYVAL outBottom AS ANY PTR)
    Declare Sub eb_haiku_print_job_get_resolution(BYVAL job AS ANY PTR, BYVAL outXDPI AS ANY PTR, BYVAL outYDPI AS ANY PTR)
    Declare Function eb_haiku_print_job_settings(BYVAL job AS ANY PTR) AS ANY PTR
    Declare Sub eb_haiku_print_job_set_settings(BYVAL job AS ANY PTR, BYVAL archiveMessage AS ANY PTR)
    Declare Function eb_haiku_print_job_is_settings_message_valid(BYVAL job AS ANY PTR, BYVAL archiveMessage AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_print_job_first_page(BYVAL job AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_print_job_last_page(BYVAL job AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_print_job_printer_type(BYVAL job AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_print_job_destroy(BYVAL job AS ANY PTR)
End Extern
