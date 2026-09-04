// eb-haiku native shim - Interface Kit (GUI). See shim.h's own top
// comment for why a hand-written shim is needed at all.
//
// BRect is a plain public 4-float struct (Haiku's own Rect.h) - passed
// here as 4 separate floats rather than mirrored as its own opaque
// handle or eBasic TYPE, simpler than every other class in this package.
//
// Threading: BApplication::Run() blocks whichever thread calls it; each
// BWindow, once shown, runs its own message loop on its own separate
// thread. Callback functions set here (MessageReceived/QuitRequested/
// FrameResized/...) are invoked from that window's own thread, never
// the thread that called Run() - see this package's own README for the
// intended safe usage pattern (do nothing on the Run()-calling thread
// after calling it; all real logic lives in these callbacks).
#pragma once

extern "C" {

// ---- BWindow (via a real ShimWindow subclass - the only way to reach
// MessageReceived/QuitRequested/FrameResized from eBasic at all, since
// eBasic's own Extern mechanism can't override a foreign class's
// virtual methods directly) ----

typedef void (*EbHaikuMessageReceivedCallback)(void* userData, void* messageHandle);
// Return nonzero to allow the window to close, 0 to refuse - matching
// BWindow::QuitRequested()'s own bool return.
typedef int (*EbHaikuQuitRequestedCallback)(void* userData);
typedef void (*EbHaikuFrameResizedCallback)(void* userData, float newWidth, float newHeight);

void* eb_haiku_window_create(float left, float top, float right, float bottom,
                              const char* title, unsigned int flags);
void eb_haiku_window_set_message_received_callback(void* window,
                                                     EbHaikuMessageReceivedCallback cb,
                                                     void* userData);
void eb_haiku_window_set_quit_requested_callback(void* window, EbHaikuQuitRequestedCallback cb,
                                                  void* userData);
void eb_haiku_window_set_frame_resized_callback(void* window, EbHaikuFrameResizedCallback cb,
                                                 void* userData);
void eb_haiku_window_show(void* window);
void eb_haiku_window_hide(void* window);
void eb_haiku_window_add_child(void* window, void* view);
void eb_haiku_window_set_layout(void* window, void* layout);
// Posts B_QUIT_REQUESTED via BMessenger - the documented-safe way to
// close a window from outside its own thread (unlike calling Quit()
// directly, which real Haiku code only ever does from within the
// window's own thread).
void eb_haiku_window_close(void* window);

// ---- Window title/geometry/enable/modal - added for the eb-gui
// universal cross-toolkit GUI API (see eb-gui-haiku). Locked internally
// (a WindowAutolock, matching this file's own eb_haiku_button_set_label/
// eb_haiku_control_set_enabled convention) since these mutate an
// already-running window's redraw/layout state from a thread other
// than its own, unlike eb_haiku_window_show/hide (which start/stop the
// window's own thread and are confirmed safe uncalled-for-a-lock, per
// this file's existing code).
void eb_haiku_window_set_title(void* window, const char* title);
void eb_haiku_window_move_to(void* window, float x, float y);
void eb_haiku_window_resize_to(void* window, float width, float height);
// Recursively enables/disables every BControl found under `window`'s
// own direct children (Haiku has no BView-level or BWindow-level
// SetEnabled at all - only BControl does - so this walks the real view
// tree and toggles each BControl found, mirroring GTK4's own recursive
// widget-sensitivity propagation, which Haiku has no built-in
// equivalent of).
void eb_haiku_window_set_enabled(void* window, int enabled);
// Real Haiku modal: SetFeel(B_MODAL_SUBSET_WINDOW_FEEL) + AddToSubset
// (parent)/RemoveFromSubset(parent) - `parent` is required on both, not
// just SetModal, since RemoveFromSubset needs the exact same window
// reference that was added.
void eb_haiku_window_set_modal(void* window, void* parent);
void eb_haiku_window_clear_modal(void* window, void* parent);

// ---- BView (plain, non-subclassed - see shim_interface.cpp's own
// ShimView, added when custom Draw/MouseDown/KeyDown is needed) ----

void* eb_haiku_view_create(float left, float top, float right, float bottom,
                            const char* name, unsigned int resizingMode, unsigned int flags);
void eb_haiku_view_add_child(void* view, void* child);
void eb_haiku_view_destroy(void* view);

// ---- Custom drawing/input (via a real ShimView subclass - the only
// way to reach Draw/MouseDown/MouseUp/KeyDown from eBasic, same reason
// as ShimWindow above). A view only receives these callbacks if
// created with the H_WILL_DRAW (Draw) and/or H_FRAME_EVENTS flags as
// appropriate - see raw/haiku_shim_interface.bas's own flag constants.

typedef void (*EbHaikuDrawCallback)(void* userData, float updateLeft, float updateTop,
                                     float updateRight, float updateBottom);
typedef void (*EbHaikuMouseCallback)(void* userData, float x, float y);
typedef void (*EbHaikuKeyDownCallback)(void* userData, const char* bytes, int numBytes);

void* eb_haiku_shim_view_create(float left, float top, float right, float bottom,
                                 const char* name, unsigned int resizingMode,
                                 unsigned int flags);
void eb_haiku_shim_view_set_draw_callback(void* view, EbHaikuDrawCallback cb, void* userData);
void eb_haiku_shim_view_set_mouse_down_callback(void* view, EbHaikuMouseCallback cb,
                                                 void* userData);
void eb_haiku_shim_view_set_mouse_up_callback(void* view, EbHaikuMouseCallback cb,
                                               void* userData);
void eb_haiku_shim_view_set_key_down_callback(void* view, EbHaikuKeyDownCallback cb,
                                               void* userData);
// Requests a redraw (queues a real Draw call) - the only safe way to
// trigger a repaint from outside the view's own Draw callback.
void eb_haiku_shim_view_invalidate(void* view);

// ---- Drawing primitives - callable only from within a Draw callback
// (Haiku's own real restriction: a view's graphics state is only valid
// while it's the "current" view being drawn) - work on any BView*
// (including a ShimView's own handle, or a stock control's).
void eb_haiku_view_set_high_color(void* view, unsigned char r, unsigned char g, unsigned char b);
void eb_haiku_view_fill_rect(void* view, float left, float top, float right, float bottom);
void eb_haiku_view_stroke_rect(void* view, float left, float top, float right, float bottom);
void eb_haiku_view_stroke_line(void* view, float x1, float y1, float x2, float y2);
void eb_haiku_view_draw_string(void* view, const char* text, float x, float y);
// Draws `bitmap` (an eb_haiku_bitmap_create/eb_haiku_translation_utils_
// get_bitmap result - see shim_translation.h) with its top-left corner
// at (x, y), at its own native size (no scaling).
void eb_haiku_view_draw_bitmap(void* view, void* bitmap, float x, float y);

// Initiates a real drag - call from inside an existing MouseDown
// callback (no new callback plumbing needed: DragMessage() is
// synchronous, and the dropped message later arrives at the drop
// target's own, already-existing MessageReceived callback, read via
// eb_haiku_message_was_dropped/drop_point below). The simplest, no-
// bitmap overload - real drag-visual bitmaps are a reasonable follow-on,
// not bound here.
//
// IMPORTANT, confirmed by direct reproduction: calling this OUTSIDE a
// real MouseDown callback while an actual mouse button is held down
// blocks indefinitely - real Haiku's own mouse-tracking wait never
// completes with no real button pressed - the same "not triggerable
// over SSH" limitation already documented for BPrintJob::ConfigJob/
// BPopUpMenu::Go. This package's own tests never call this headlessly;
// only a real, interactive desktop session can exercise it end to end.
void eb_haiku_view_drag_message(void* view, void* message, float left, float top, float right,
                                 float bottom);

// ---- Stock controls (BButton/BStringView/BTextControl - plain,
// non-subclassed) ----
//
// None of these need their own callback-forwarding shim subclass:
// Haiku's own BControl/BInvoker already posts each control's `what`
// message to its target, which defaults to the window it's attached to
// once shown - so a button click (etc.) arrives at the *window's own*
// MessageReceived callback (already wired up above), not a separate
// per-control callback. `HWindowSetMessageReceivedCallback` from Slice
// 1 is the only callback surface stock controls need.

void* eb_haiku_button_create(float left, float top, float right, float bottom, const char* name,
                              const char* label, unsigned int what);
// Triggers the button exactly as a real click would - not implemented
// via BInvoker::Invoke() itself, which crashes when called from
// outside the window's own thread (confirmed by direct reproduction in
// a standalone C++ program - see shim_interface.cpp's own comment on
// eb_haiku_button_invoke); still a legitimate way to programmatically
// drive a button, not just a test-only hack.
void eb_haiku_button_invoke(void* button);
// BButton's own label (its own BControl::Label()/SetLabel(), distinct
// from BStringView/BTextControl's "text" concept above).
void eb_haiku_button_set_label(void* button, const char* label);
// Borrowed from the real BButton's own long-lived storage - no heap
// allocation, no matching free needed (same convention as
// eb_haiku_stringview_get_text/textcontrol_get_text).
const char* eb_haiku_button_get_label(void* button);

// BControl's own Enabled state - generic across every stock control
// above (BButton/BTextControl both derive from BControl), so `control`
// takes any of their handles directly rather than needing a per-type
// overload.
void eb_haiku_control_set_enabled(void* control, int enabled);
int eb_haiku_control_is_enabled(void* control);

void* eb_haiku_stringview_create(float left, float top, float right, float bottom,
                                  const char* name, const char* text);
void eb_haiku_stringview_set_text(void* view, const char* text);
// Borrowed from the real BStringView's own long-lived storage - no
// heap allocation, no matching free needed (unlike Phase 1's
// HNodeReadAttrString and friends).
const char* eb_haiku_stringview_get_text(void* view);

void* eb_haiku_textcontrol_create(float left, float top, float right, float bottom,
                                   const char* name, const char* label, const char* initialText,
                                   unsigned int what);
void eb_haiku_textcontrol_set_text(void* view, const char* text);
const char* eb_haiku_textcontrol_get_text(void* view);

// ---- BTextView (multi-line, plain-text editing - a concrete BView
// subclass needing no shim subclass of its own, unlike BWindow/BView:
// Text() returns a plain const char*, so it marshals exactly like
// eb_haiku_stringview_get_text/textcontrol_get_text above). Font
// family/size/style changes are deliberately not bound - BFont itself
// isn't bound anywhere in this package (a separate, larger future
// addition); per-range *color* styling below doesn't need one.
void* eb_haiku_textview_create(float left, float top, float right, float bottom,
                                const char* name);
void eb_haiku_textview_set_text(void* view, const char* text);
// Borrowed from the real BTextView's own long-lived storage - no heap
// allocation, no matching free needed (same convention as
// eb_haiku_stringview_get_text above).
const char* eb_haiku_textview_get_text(void* view);
int eb_haiku_textview_text_length(void* view);
void eb_haiku_textview_set_word_wrap(void* view, int wrap);
void eb_haiku_textview_make_editable(void* view, int editable);
void eb_haiku_textview_select(void* view, int start, int end);
// IMPORTANT, confirmed by direct reproduction: real BTextView defaults
// to IsStylable() = false, in which case SetFontAndColor's own color
// change is NOT scoped to [start, end) at all - it silently applies to
// the ENTIRE text instead. Call this with `stylable` != 0 before ever
// calling eb_haiku_textview_set_color, or per-range coloring will
// silently misbehave.
void eb_haiku_textview_set_stylable(void* view, int stylable);
int eb_haiku_textview_is_stylable(void* view);
// Real per-character-range color styling - SetFontAndColor(start, end,
// font, mode, color) takes a required (non-defaulted) font parameter,
// but passing nullptr with mode=0 (no font-changing bits) is confirmed
// safe via direct reproduction and only touches color, matching this
// package's own decision not to bind BFont for this pass. Requires
// eb_haiku_textview_set_stylable(view, 1) first - see its own comment.
void eb_haiku_textview_set_color(void* view, int start, int end, unsigned char r,
                                  unsigned char g, unsigned char b, unsigned char a);
// Fills the real color in effect at `offset` (the start of a real
// run - matches whatever HTextViewSetColor's own range last set there).
void eb_haiku_textview_get_color(void* view, int offset, unsigned char* outR,
                                  unsigned char* outG, unsigned char* outB,
                                  unsigned char* outA);

// ---- View-level layout attachment + per-view size/alignment
// constraints. BSize (two floats) and BAlignment (two ints) are plain
// value structs in real Haiku - passed here as separate parameters,
// exactly like BRect, never needing their own opaque handle. Works on
// any view/control handle (BView already implements these directly -
// confirmed in View.h - not just something BLayoutItem adds).

void eb_haiku_view_set_layout(void* view, void* layout);
void eb_haiku_view_set_explicit_min_size(void* view, float width, float height);
void eb_haiku_view_set_explicit_max_size(void* view, float width, float height);
void eb_haiku_view_set_explicit_preferred_size(void* view, float width, float height);
void eb_haiku_view_set_explicit_size(void* view, float width, float height);
// horizontalAlign: H_ALIGN_LEFT/RIGHT/CENTER; verticalAlign:
// H_ALIGN_TOP/BOTTOM/MIDDLE (real Haiku enum values - see
// raw/haiku_shim_interface.bas's own constants).
void eb_haiku_view_set_explicit_alignment(void* view, int horizontalAlign, int verticalAlign);

// ---- BGroupLayout ----
// orientation: 0 = B_HORIZONTAL, 1 = B_VERTICAL (Haiku's own real enum
// values - see raw/haiku_shim_interface.bas's own constants).
void* eb_haiku_group_layout_create(unsigned int orientation, float spacing);
void eb_haiku_group_layout_set_orientation(void* layout, unsigned int orientation);
void eb_haiku_group_layout_set_spacing(void* layout, float spacing);
float eb_haiku_group_layout_item_weight(void* layout, int index);
void eb_haiku_group_layout_set_item_weight(void* layout, int index, float weight);

// ---- Generic BLayout operations - BGroupLayout/BGridLayout/
// BCardLayout all share this common base with a *virtual* AddView/
// AddItem, so one pair of functions correctly dispatches to whichever
// concrete layout is actually passed in, via ordinary C++ virtual
// dispatch (confirmed directly against Layout.h/GridLayout.h/
// CardLayout.h - no need for one near-duplicate AddView per type).
void eb_haiku_layout_add_view(void* layout, void* view);
void eb_haiku_layout_add_item(void* layout, void* item);
// SetInsets is on the shared BTwoDimensionalLayout base of Group *and*
// Grid specifically (not Card, which has no insets of its own).
void eb_haiku_two_dimensional_layout_set_insets(void* layout, float left, float top, float right,
                                                 float bottom);

// ---- BGridLayout ----
void* eb_haiku_grid_layout_create(float horizontalSpacing, float verticalSpacing);
void eb_haiku_grid_layout_add_view_at(void* layout, void* view, int column, int row,
                                       int columnCount, int rowCount);
void eb_haiku_grid_layout_set_spacing(void* layout, float horizontalSpacing,
                                       float verticalSpacing);
void eb_haiku_grid_layout_set_column_weight(void* layout, int column, float weight);
void eb_haiku_grid_layout_set_row_weight(void* layout, int row, float weight);
void eb_haiku_grid_layout_set_min_column_width(void* layout, int column, float width);
void eb_haiku_grid_layout_set_max_column_width(void* layout, int column, float width);
void eb_haiku_grid_layout_set_min_row_height(void* layout, int row, float height);
void eb_haiku_grid_layout_set_max_row_height(void* layout, int row, float height);

// ---- BCardLayout - shows exactly one child at a time (wizard pages,
// tabbed-without-tabs content). Add children via the generic
// eb_haiku_layout_add_view above. ----
void* eb_haiku_card_layout_create(void);
void eb_haiku_card_layout_set_visible_item(void* layout, int index);
int eb_haiku_card_layout_visible_index(void* layout);

// ---- BSplitView - a real BView subclass providing resizable split
// panes directly (not a BLayout - confirmed the public class is
// BSplitView; BSplitLayout is a private implementation detail, never
// meant to be used directly). ----
void* eb_haiku_split_view_create(unsigned int orientation, float spacing);
void eb_haiku_split_view_add_child(void* splitView, void* view, float weight);
void eb_haiku_split_view_set_collapsible(void* splitView, int collapsible);
void eb_haiku_split_view_set_insets(void* splitView, float left, float top, float right,
                                     float bottom);
void eb_haiku_split_view_set_splitter_size(void* splitView, float size);

// ---- BSpaceLayoutItem - real, commonly-used spacer items, added to
// any layout via the generic eb_haiku_layout_add_item above. ----
void* eb_haiku_space_layout_item_create_glue(void);
void* eb_haiku_space_layout_item_create_horizontal_strut(float width);
void* eb_haiku_space_layout_item_create_vertical_strut(float height);

// ---- BMenuBar/BMenu/BMenuItem (interface/{Menu,MenuBar,MenuItem}.h)
// - real window menus. BMenuBar : public BMenu : public BView (single
// inheritance throughout, confirmed) - a menu bar's own handle is
// already safe to pass anywhere a BMenu*/BView* is expected, including
// the existing eb_haiku_window_add_child (no separate "add menu bar to
// window" function needed at all). Once added to a menu/window, Haiku
// itself owns and destroys menus/items automatically - matching the
// existing stock-controls convention (no destroy functions here,
// exactly like eb_haiku_button_create/friends have none).
void* eb_haiku_menu_bar_create(const char* name);
void* eb_haiku_menu_create(const char* name);
// A leaf item - `message` is an eb_haiku_message_create result (shim.h).
void* eb_haiku_menu_item_create(const char* label, void* message);
// A submenu item - `message` may be NULL (a pure submenu, no message
// of its own).
void* eb_haiku_menu_item_create_submenu(void* submenu, void* message);
int eb_haiku_menu_add_item(void* menu, void* item);
// Also used to add a BMenu to a BMenuBar - same underlying AddItem
// overload, safe via the confirmed single-inheritance chain above.
int eb_haiku_menu_add_submenu(void* menu, void* submenu);
int eb_haiku_menu_add_separator_item(void* menu);
void eb_haiku_menu_item_set_enabled(void* item, int enabled);
void eb_haiku_menu_item_set_marked(void* item, int marked);
int eb_haiku_menu_item_is_marked(void* item);
// Same "not BInvoker::Invoke() directly" reasoning/fix as
// eb_haiku_button_invoke above (BMenuItem is a BInvoker too - the same
// documented crash risk applies) - manually sends the item's own
// message to its own established target via Messenger().
void eb_haiku_menu_item_invoke_via_messenger(void* item);

// Radio-mode grouping - once on, marking one item automatically
// unmarks its siblings, entirely handled internally by real Haiku (no
// new per-item logic needed here).
void eb_haiku_menu_set_radio_mode(void* menu, int on);
int eb_haiku_menu_is_radio_mode(void* menu);
void eb_haiku_menu_set_label_from_marked(void* menu, int on);

// ---- ShimHandler - a small, reusable per-object callback target,
// added for the eb-gui universal cross-toolkit GUI API (see
// eb-gui-haiku). Real Haiku's own per-object callback story is thin:
// BMenuItem/BMessageRunner (and BControl's own invocation) all deliver
// via a BMessage sent to a *target* BHandler, which defaults to the
// window itself - fine for this package's own existing
// HWindowSetMessageReceivedCallback (one shared dispatch point), but
// eb-gui's contract needs a genuinely PER-ACTION/PER-TIMER callback
// (unlike GTK4's GSimpleAction "activate" signal or Qt6's
// QAction::triggered, which are real per-object signals Haiku has no
// equivalent of). Rather than a fragile global `what`-code dispatch
// table, each GuiAction/GuiTimer gets its OWN ShimHandler instance,
// added to the owning window's own BLooper (BWindow::AddHandler - a
// real, ordinary BLooper method, not a new subclass), and set as the
// BMenuItem's/BMessageRunner's own invocation target - so this single
// class's MessageReceived (which fires unconditionally on ANY message,
// since one instance is always dedicated to exactly one thing) is the
// only new virtual-method-forwarding subclass this addition needs.
typedef void (*EbHaikuVoidCallback)(void* userData);

void* eb_haiku_handler_create(void);
void eb_haiku_handler_set_callback(void* handler, EbHaikuVoidCallback cb, void* userData);
// Attaches `handler` to `window`'s own BLooper - required before the
// handler can be used as a real invocation target (BMessenger/SetTarget
// both need the handler to already have an associated BLooper).
void eb_haiku_window_add_handler(void* window, void* handler);
// BMenuItem inherits BInvoker - redirects its own invocation message
// to `handler` instead of the window it happens to be attached to.
void eb_haiku_menu_item_set_target(void* item, void* handler);
// Same for BButton (also a real BInvoker, via BControl) - a SEPARATE
// function rather than one generic void*-to-BInvoker* cast, on purpose:
// static_cast-ing an erased void* to a non-first base of a multiply-
// inherited class needs the compiler to know the pointer's real
// concrete type at the cast site to apply the correct offset (the same
// real bug class this package hit once before with BFile) - each
// concrete type here gets its own function precisely so that cast is
// always safe.
void eb_haiku_button_set_target(void* button, void* handler);

// ---- ShimTimer (BMessageRunner) - Haiku's own periodic-message
// primitive doesn't match eb-gui's Start/Stop/SetSingleShot/IsActive
// shape any more directly than GLib's g_timeout_add did for eb-gtk4's
// own GtkTimer (a real BMessageRunner is effectively one-shot-lifecycle
// - this recreates it on every Start() rather than assuming it can be
// restarted in place). `handler` must already be attached to a window
// via eb_haiku_window_add_handler (above) before being passed here.
void* eb_haiku_timer_create(void* handler);
void eb_haiku_timer_set_interval(void* timer, long long microseconds);
void eb_haiku_timer_set_single_shot(void* timer, int singleShot);
void eb_haiku_timer_start(void* timer);
void eb_haiku_timer_stop(void* timer);
int eb_haiku_timer_is_active(void* timer);
void eb_haiku_timer_destroy(void* timer);

// ---- BPopUpMenu - IS-A BMenu (like BMenuBar already is), reuses the
// same opaque handle everywhere a BMenu* is expected (add items via
// the existing eb_haiku_menu_add_item/add_submenu/add_separator_item
// above). IMPORTANT, confirmed by direct reproduction: real interactive
// item *selection* needs a human mouse click - not triggerable over
// SSH (the same real limitation as BPrintJob::ConfigJob) - Go() itself
// is safe to call (returns promptly with async=true), but this
// package's own tests can't drive a real selection headlessly.
void* eb_haiku_popup_menu_create(const char* name);
// Returns the picked BMenuItem* (0 if none/still open, e.g. with
// async=true).
void* eb_haiku_popup_menu_go(void* popup, float x, float y, int autoInvoke, int keepOpen,
                              int async);

// ---- BMenuField - a real BView combining a label + a BMenuBar-styled
// clickable field wrapping an existing BMenu. Once shown, Haiku itself
// owns/destroys both the field and the menu it was given - matching
// the existing stock-controls convention (no destroy function here).
void* eb_haiku_menu_field_create(float left, float top, float right, float bottom,
                                  const char* name, const char* label, void* menu);
// The BMenu this field wraps - useful to add items to it after
// creation (e.g. built up incrementally rather than fully upfront).
void* eb_haiku_menu_field_menu(void* menuField);

// ---- BPrintJob (interface/PrintJob.h) - real printing, via a real
// ShimPrintJob subclass (the only way to reach the virtual DrawView()
// from eBasic, same reason as ShimWindow/ShimView above).
//
// IMPORTANT, confirmed by direct reproduction: ConfigJob()/ConfigPage()
// show a real, interactive Page Setup/Print dialog and block until a
// human clicks through it - not triggerable over SSH (the same real
// limitation already documented for mouse clicks throughout this
// package), so this package's own tests/examples can't drive them
// headlessly. The rest of the real API (BeginJob/SpoolPage/CommitJob/
// CanContinue/PaperRect/PrintableRect/PrinterType/GetResolution) is
// still bound and real for interactive use.

typedef void (*EbHaikuPrintDrawViewCallback)(void* userData, void* view, float rectLeft,
                                              float rectTop, float rectRight, float rectBottom,
                                              float whereX, float whereY);

void* eb_haiku_print_job_create(const char* name);
void eb_haiku_print_job_set_draw_view_callback(void* job, EbHaikuPrintDrawViewCallback cb,
                                                void* userData);
void eb_haiku_print_job_begin_job(void* job);
void eb_haiku_print_job_commit_job(void* job);
// Shows a real, interactive dialog - see this section's own top comment.
int eb_haiku_print_job_config_job(void* job);
void eb_haiku_print_job_cancel_job(void* job);
// Shows a real, interactive dialog - see this section's own top comment.
int eb_haiku_print_job_config_page(void* job);
// Triggers a real DrawView() call via the registered callback above.
void eb_haiku_print_job_spool_page(void* job);
int eb_haiku_print_job_can_continue(void* job);
void eb_haiku_print_job_paper_rect(void* job, float* outLeft, float* outTop, float* outRight,
                                    float* outBottom);
void eb_haiku_print_job_printable_rect(void* job, float* outLeft, float* outTop, float* outRight,
                                        float* outBottom);
void eb_haiku_print_job_get_resolution(void* job, int* outXDPI, int* outYDPI);
// Returns a *borrowed* BMessage* (never free/HMessageFree it) - the
// job's own live settings archive, editable in place. SetSettings/
// IsSettingsMessageValid operate on a caller-owned HMessage instead.
// Returns NULL until a real ConfigJob/ConfigPage has established a
// real printer/page choice (confirmed by direct reproduction - not a
// bug, real Haiku behavior).
void* eb_haiku_print_job_settings(void* job);
// IMPORTANT, confirmed by direct reproduction: calling this with a
// message that isn't a real, validated settings archive (or without a
// real printer connection established) can HANG indefinitely - the
// same real "needs a live print_server round-trip" category as
// ConfigJob/ConfigPage's own interactive dialogs. Check
// IsSettingsMessageValid first and only call this with a message
// that originated from a real Settings()/ConfigJob call.
void eb_haiku_print_job_set_settings(void* job, void* archiveMessage);
int eb_haiku_print_job_is_settings_message_valid(void* job, void* archiveMessage);
int eb_haiku_print_job_first_page(void* job);
int eb_haiku_print_job_last_page(void* job);
int eb_haiku_print_job_printer_type(void* job);
void eb_haiku_print_job_destroy(void* job);

} // extern "C"
