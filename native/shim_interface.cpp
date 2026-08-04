#include "shim_interface.h"

#include <AppDefs.h>
#include <Alignment.h>
#include <Bitmap.h>
#include <Button.h>
#include <CardLayout.h>
#include <GridLayout.h>
#include <GroupLayout.h>
#include <Layout.h>
#include <LayoutItem.h>
#include <Looper.h>
#include <Menu.h>
#include <MenuBar.h>
#include <MenuItem.h>
#include <Message.h>
#include <Messenger.h>
#include <PrintJob.h>
#include <Size.h>
#include <SpaceLayoutItem.h>
#include <SplitView.h>
#include <StringView.h>
#include <TextControl.h>
#include <TwoDimensionalLayout.h>
#include <View.h>
#include <Window.h>

namespace {

/// The only way to reach BWindow's own virtual methods from eBasic at
/// all - eBasic's Extern mechanism can't override a foreign class's
/// virtuals directly, so this real C++ subclass forwards each one to a
/// stored callback (a plain function pointer + a caller-supplied
/// userData, exactly matching this package's own established
/// eb-gtk4-derived convention - see shim_interface.h's own top comment).
class ShimWindow : public BWindow {
public:
    ShimWindow(BRect frame, const char* title, unsigned int flags)
        : BWindow(frame, title, B_TITLED_WINDOW, flags) {}

    void SetMessageReceivedCallback(EbHaikuMessageReceivedCallback cb, void* userData) {
        fMessageCallback = cb;
        fMessageUserData = userData;
    }

    void SetQuitRequestedCallback(EbHaikuQuitRequestedCallback cb, void* userData) {
        fQuitCallback = cb;
        fQuitUserData = userData;
    }

    void SetFrameResizedCallback(EbHaikuFrameResizedCallback cb, void* userData) {
        fResizeCallback = cb;
        fResizeUserData = userData;
    }

    void MessageReceived(BMessage* message) override {
        if (fMessageCallback) {
            fMessageCallback(fMessageUserData, message);
        } else {
            BWindow::MessageReceived(message);
        }
    }

    bool QuitRequested() override {
        if (fQuitCallback) return fQuitCallback(fQuitUserData) != 0;
        return BWindow::QuitRequested();
    }

    void FrameResized(float newWidth, float newHeight) override {
        if (fResizeCallback) fResizeCallback(fResizeUserData, newWidth, newHeight);
        BWindow::FrameResized(newWidth, newHeight);
    }

private:
    EbHaikuMessageReceivedCallback fMessageCallback = nullptr;
    void* fMessageUserData = nullptr;
    EbHaikuQuitRequestedCallback fQuitCallback = nullptr;
    void* fQuitUserData = nullptr;
    EbHaikuFrameResizedCallback fResizeCallback = nullptr;
    void* fResizeUserData = nullptr;
};

/// Same forwarding pattern as ShimWindow (see its own top comment) -
/// the only way to reach BView's own virtual methods from eBasic.
class ShimView : public BView {
public:
    ShimView(BRect frame, const char* name, unsigned int resizingMode, unsigned int flags)
        : BView(frame, name, resizingMode, flags) {}

    void SetDrawCallback(EbHaikuDrawCallback cb, void* userData) {
        fDrawCallback = cb;
        fDrawUserData = userData;
    }
    void SetMouseDownCallback(EbHaikuMouseCallback cb, void* userData) {
        fMouseDownCallback = cb;
        fMouseDownUserData = userData;
    }
    void SetMouseUpCallback(EbHaikuMouseCallback cb, void* userData) {
        fMouseUpCallback = cb;
        fMouseUpUserData = userData;
    }
    void SetKeyDownCallback(EbHaikuKeyDownCallback cb, void* userData) {
        fKeyDownCallback = cb;
        fKeyDownUserData = userData;
    }

    void Draw(BRect updateRect) override {
        if (fDrawCallback) {
            fDrawCallback(fDrawUserData, updateRect.left, updateRect.top, updateRect.right,
                          updateRect.bottom);
        }
    }
    void MouseDown(BPoint where) override {
        if (fMouseDownCallback) fMouseDownCallback(fMouseDownUserData, where.x, where.y);
        else BView::MouseDown(where);
    }
    void MouseUp(BPoint where) override {
        if (fMouseUpCallback) fMouseUpCallback(fMouseUpUserData, where.x, where.y);
        else BView::MouseUp(where);
    }
    void KeyDown(const char* bytes, int32 numBytes) override {
        if (fKeyDownCallback) fKeyDownCallback(fKeyDownUserData, bytes, numBytes);
        else BView::KeyDown(bytes, numBytes);
    }

private:
    EbHaikuDrawCallback fDrawCallback = nullptr;
    void* fDrawUserData = nullptr;
    EbHaikuMouseCallback fMouseDownCallback = nullptr;
    void* fMouseDownUserData = nullptr;
    EbHaikuMouseCallback fMouseUpCallback = nullptr;
    void* fMouseUpUserData = nullptr;
    EbHaikuKeyDownCallback fKeyDownCallback = nullptr;
    void* fKeyDownUserData = nullptr;
};

/// Locks a BView's own window before touching it, matching real
/// Haiku's own threading requirement for BLooper-owned objects (a
/// window's own thread holds this lock implicitly while processing its
/// message loop - Draw/MessageReceived/etc. callbacks never need this
/// themselves - but code running on any *other* thread, like a plain
/// shim function called from eBasic's own main thread, must acquire it
/// explicitly first). `BLooper::Lock()` is safe to call even from the
/// looper's own thread (it's recursive), so this is always correct
/// regardless of which thread actually calls it - found the hard way:
/// BView::Invalidate() (called from outside the window's own thread,
/// with no lock held) crashed deep inside Haiku's own implementation,
/// confirmed via a standalone C++ reproduction with no eBasic involved
/// at all, exactly like BInvoker::Invoke()'s own cross-thread issue
/// (see eb_haiku_button_invoke's own comment).
class ViewAutolock {
public:
    explicit ViewAutolock(BView* view) : fLooper(view->Looper()) {
        fLocked = fLooper != nullptr && fLooper->Lock();
    }
    ~ViewAutolock() {
        if (fLocked) fLooper->Unlock();
    }

private:
    BLooper* fLooper;
    bool fLocked;
};

class ShimPrintJob : public BPrintJob {
public:
    explicit ShimPrintJob(const char* name) : BPrintJob(name) {}

    void SetDrawViewCallback(EbHaikuPrintDrawViewCallback cb, void* userData) {
        fDrawViewCallback = cb;
        fDrawViewUserData = userData;
    }

    void DrawView(BView* view, BRect rect, BPoint where) override {
        if (fDrawViewCallback) {
            fDrawViewCallback(fDrawViewUserData, view, rect.left, rect.top, rect.right,
                               rect.bottom, where.x, where.y);
        }
    }

private:
    EbHaikuPrintDrawViewCallback fDrawViewCallback = nullptr;
    void* fDrawViewUserData = nullptr;
};

} // namespace

extern "C" {

void* eb_haiku_window_create(float left, float top, float right, float bottom,
                              const char* title, unsigned int flags) {
    return new ShimWindow(BRect(left, top, right, bottom), title, flags);
}

void eb_haiku_window_set_message_received_callback(void* window,
                                                     EbHaikuMessageReceivedCallback cb,
                                                     void* userData) {
    static_cast<ShimWindow*>(window)->SetMessageReceivedCallback(cb, userData);
}

void eb_haiku_window_set_quit_requested_callback(void* window, EbHaikuQuitRequestedCallback cb,
                                                  void* userData) {
    static_cast<ShimWindow*>(window)->SetQuitRequestedCallback(cb, userData);
}

void eb_haiku_window_set_frame_resized_callback(void* window, EbHaikuFrameResizedCallback cb,
                                                 void* userData) {
    static_cast<ShimWindow*>(window)->SetFrameResizedCallback(cb, userData);
}

void eb_haiku_window_show(void* window) { static_cast<BWindow*>(window)->Show(); }
void eb_haiku_window_hide(void* window) { static_cast<BWindow*>(window)->Hide(); }

void eb_haiku_window_add_child(void* window, void* view) {
    static_cast<BWindow*>(window)->AddChild(static_cast<BView*>(view));
}

void eb_haiku_window_set_layout(void* window, void* layout) {
    static_cast<BWindow*>(window)->SetLayout(static_cast<BLayout*>(layout));
}

void eb_haiku_window_close(void* window) {
    BMessenger(static_cast<BWindow*>(window)).SendMessage(B_QUIT_REQUESTED);
}

void* eb_haiku_view_create(float left, float top, float right, float bottom, const char* name,
                            unsigned int resizingMode, unsigned int flags) {
    return new BView(BRect(left, top, right, bottom), name, resizingMode, flags);
}

void eb_haiku_view_add_child(void* view, void* child) {
    static_cast<BView*>(view)->AddChild(static_cast<BView*>(child));
}

void eb_haiku_view_destroy(void* view) { delete static_cast<BView*>(view); }

void eb_haiku_view_set_layout(void* view, void* layout) {
    static_cast<BView*>(view)->SetLayout(static_cast<BLayout*>(layout));
}

void eb_haiku_view_set_explicit_min_size(void* view, float width, float height) {
    static_cast<BView*>(view)->SetExplicitMinSize(BSize(width, height));
}

void eb_haiku_view_set_explicit_max_size(void* view, float width, float height) {
    static_cast<BView*>(view)->SetExplicitMaxSize(BSize(width, height));
}

void eb_haiku_view_set_explicit_preferred_size(void* view, float width, float height) {
    static_cast<BView*>(view)->SetExplicitPreferredSize(BSize(width, height));
}

void eb_haiku_view_set_explicit_size(void* view, float width, float height) {
    static_cast<BView*>(view)->SetExplicitSize(BSize(width, height));
}

void eb_haiku_view_set_explicit_alignment(void* view, int horizontalAlign, int verticalAlign) {
    static_cast<BView*>(view)->SetExplicitAlignment(
        BAlignment(static_cast<alignment>(horizontalAlign),
                   static_cast<vertical_alignment>(verticalAlign)));
}

void* eb_haiku_button_create(float left, float top, float right, float bottom, const char* name,
                              const char* label, unsigned int what) {
    return new BButton(BRect(left, top, right, bottom), name, label, new BMessage(what));
}

void eb_haiku_button_invoke(void* button) {
    // Not BInvoker::Invoke() directly - confirmed by direct
    // reproduction in a standalone C++ program (no eBasic involved at
    // all) that calling it here hangs/crashes deep inside Haiku's own
    // implementation. This manually does what Invoke() is documented
    // to do (send the control's own message to its own established
    // target) - confirmed working via the same standalone reproduction
    // - sidestepping whatever Invoke()'s own internal issue is.
    BButton* btn = static_cast<BButton*>(button);
    BMessage* msg = btn->Message();
    if (msg) btn->Messenger().SendMessage(msg);
}

void* eb_haiku_stringview_create(float left, float top, float right, float bottom,
                                  const char* name, const char* text) {
    return new BStringView(BRect(left, top, right, bottom), name, text);
}

void eb_haiku_stringview_set_text(void* view, const char* text) {
    static_cast<BStringView*>(view)->SetText(text);
}

const char* eb_haiku_stringview_get_text(void* view) {
    return static_cast<BStringView*>(view)->Text();
}

void* eb_haiku_textcontrol_create(float left, float top, float right, float bottom,
                                   const char* name, const char* label, const char* initialText,
                                   unsigned int what) {
    return new BTextControl(BRect(left, top, right, bottom), name, label, initialText,
                             new BMessage(what));
}

void eb_haiku_textcontrol_set_text(void* view, const char* text) {
    static_cast<BTextControl*>(view)->SetText(text);
}

const char* eb_haiku_textcontrol_get_text(void* view) {
    return static_cast<BTextControl*>(view)->Text();
}

void* eb_haiku_group_layout_create(unsigned int orientation, float spacing) {
    return new BGroupLayout(static_cast<::orientation>(orientation), spacing);
}

void eb_haiku_group_layout_add_view(void* layout, void* view) {
    static_cast<BGroupLayout*>(layout)->AddView(static_cast<BView*>(view));
}

void eb_haiku_group_layout_set_orientation(void* layout, unsigned int orientation) {
    static_cast<BGroupLayout*>(layout)->SetOrientation(static_cast<::orientation>(orientation));
}

void eb_haiku_group_layout_set_spacing(void* layout, float spacing) {
    static_cast<BGroupLayout*>(layout)->SetSpacing(spacing);
}

float eb_haiku_group_layout_item_weight(void* layout, int index) {
    return static_cast<BGroupLayout*>(layout)->ItemWeight(index);
}

void eb_haiku_group_layout_set_item_weight(void* layout, int index, float weight) {
    static_cast<BGroupLayout*>(layout)->SetItemWeight(index, weight);
}

void eb_haiku_layout_add_view(void* layout, void* view) {
    static_cast<BLayout*>(layout)->AddView(static_cast<BView*>(view));
}

void eb_haiku_layout_add_item(void* layout, void* item) {
    static_cast<BLayout*>(layout)->AddItem(static_cast<BLayoutItem*>(item));
}

void eb_haiku_two_dimensional_layout_set_insets(void* layout, float left, float top, float right,
                                                 float bottom) {
    static_cast<BTwoDimensionalLayout*>(layout)->SetInsets(left, top, right, bottom);
}

void* eb_haiku_grid_layout_create(float horizontalSpacing, float verticalSpacing) {
    return new BGridLayout(horizontalSpacing, verticalSpacing);
}

void eb_haiku_grid_layout_add_view_at(void* layout, void* view, int column, int row,
                                       int columnCount, int rowCount) {
    static_cast<BGridLayout*>(layout)->AddView(static_cast<BView*>(view), column, row,
                                                columnCount, rowCount);
}

void eb_haiku_grid_layout_set_spacing(void* layout, float horizontalSpacing,
                                       float verticalSpacing) {
    static_cast<BGridLayout*>(layout)->SetSpacing(horizontalSpacing, verticalSpacing);
}

void eb_haiku_grid_layout_set_column_weight(void* layout, int column, float weight) {
    static_cast<BGridLayout*>(layout)->SetColumnWeight(column, weight);
}

void eb_haiku_grid_layout_set_row_weight(void* layout, int row, float weight) {
    static_cast<BGridLayout*>(layout)->SetRowWeight(row, weight);
}

void eb_haiku_grid_layout_set_min_column_width(void* layout, int column, float width) {
    static_cast<BGridLayout*>(layout)->SetMinColumnWidth(column, width);
}

void eb_haiku_grid_layout_set_max_column_width(void* layout, int column, float width) {
    static_cast<BGridLayout*>(layout)->SetMaxColumnWidth(column, width);
}

void eb_haiku_grid_layout_set_min_row_height(void* layout, int row, float height) {
    static_cast<BGridLayout*>(layout)->SetMinRowHeight(row, height);
}

void eb_haiku_grid_layout_set_max_row_height(void* layout, int row, float height) {
    static_cast<BGridLayout*>(layout)->SetMaxRowHeight(row, height);
}

void* eb_haiku_card_layout_create(void) { return new BCardLayout(); }

void eb_haiku_card_layout_set_visible_item(void* layout, int index) {
    static_cast<BCardLayout*>(layout)->SetVisibleItem(index);
}

int eb_haiku_card_layout_visible_index(void* layout) {
    return static_cast<BCardLayout*>(layout)->VisibleIndex();
}

void* eb_haiku_split_view_create(unsigned int orientation, float spacing) {
    return new BSplitView(static_cast<::orientation>(orientation), spacing);
}

void eb_haiku_split_view_add_child(void* splitView, void* view, float weight) {
    static_cast<BSplitView*>(splitView)->AddChild(static_cast<BView*>(view), weight);
}

void eb_haiku_split_view_set_collapsible(void* splitView, int collapsible) {
    static_cast<BSplitView*>(splitView)->SetCollapsible(collapsible != 0);
}

void eb_haiku_split_view_set_insets(void* splitView, float left, float top, float right,
                                     float bottom) {
    static_cast<BSplitView*>(splitView)->SetInsets(left, top, right, bottom);
}

void eb_haiku_split_view_set_splitter_size(void* splitView, float size) {
    static_cast<BSplitView*>(splitView)->SetSplitterSize(size);
}

void* eb_haiku_space_layout_item_create_glue(void) { return BSpaceLayoutItem::CreateGlue(); }

void* eb_haiku_space_layout_item_create_horizontal_strut(float width) {
    return BSpaceLayoutItem::CreateHorizontalStrut(width);
}

void* eb_haiku_space_layout_item_create_vertical_strut(float height) {
    return BSpaceLayoutItem::CreateVerticalStrut(height);
}

void* eb_haiku_shim_view_create(float left, float top, float right, float bottom,
                                 const char* name, unsigned int resizingMode,
                                 unsigned int flags) {
    return new ShimView(BRect(left, top, right, bottom), name, resizingMode, flags);
}

void eb_haiku_shim_view_set_draw_callback(void* view, EbHaikuDrawCallback cb, void* userData) {
    static_cast<ShimView*>(view)->SetDrawCallback(cb, userData);
}

void eb_haiku_shim_view_set_mouse_down_callback(void* view, EbHaikuMouseCallback cb,
                                                 void* userData) {
    static_cast<ShimView*>(view)->SetMouseDownCallback(cb, userData);
}

void eb_haiku_shim_view_set_mouse_up_callback(void* view, EbHaikuMouseCallback cb,
                                               void* userData) {
    static_cast<ShimView*>(view)->SetMouseUpCallback(cb, userData);
}

void eb_haiku_shim_view_set_key_down_callback(void* view, EbHaikuKeyDownCallback cb,
                                               void* userData) {
    static_cast<ShimView*>(view)->SetKeyDownCallback(cb, userData);
}

void eb_haiku_shim_view_invalidate(void* view) {
    BView* v = static_cast<BView*>(view);
    ViewAutolock lock(v);
    v->Invalidate();
}

void eb_haiku_view_set_high_color(void* view, unsigned char r, unsigned char g,
                                   unsigned char b) {
    static_cast<BView*>(view)->SetHighColor(r, g, b);
}

void eb_haiku_view_fill_rect(void* view, float left, float top, float right, float bottom) {
    static_cast<BView*>(view)->FillRect(BRect(left, top, right, bottom));
}

void eb_haiku_view_stroke_rect(void* view, float left, float top, float right, float bottom) {
    static_cast<BView*>(view)->StrokeRect(BRect(left, top, right, bottom));
}

void eb_haiku_view_stroke_line(void* view, float x1, float y1, float x2, float y2) {
    static_cast<BView*>(view)->StrokeLine(BPoint(x1, y1), BPoint(x2, y2));
}

void eb_haiku_view_draw_string(void* view, const char* text, float x, float y) {
    static_cast<BView*>(view)->DrawString(text, BPoint(x, y));
}

void eb_haiku_view_draw_bitmap(void* view, void* bitmap, float x, float y) {
    static_cast<BView*>(view)->DrawBitmap(static_cast<BBitmap*>(bitmap), BPoint(x, y));
}

// ---- BMenuBar/BMenu/BMenuItem ----

void* eb_haiku_menu_bar_create(const char* name) { return new BMenuBar(name); }

void* eb_haiku_menu_create(const char* name) { return new BMenu(name); }

void* eb_haiku_menu_item_create(const char* label, void* message) {
    return new BMenuItem(label, static_cast<BMessage*>(message));
}

void* eb_haiku_menu_item_create_submenu(void* submenu, void* message) {
    return new BMenuItem(static_cast<BMenu*>(submenu), static_cast<BMessage*>(message));
}

int eb_haiku_menu_add_item(void* menu, void* item) {
    return static_cast<BMenu*>(menu)->AddItem(static_cast<BMenuItem*>(item)) ? 1 : 0;
}

int eb_haiku_menu_add_submenu(void* menu, void* submenu) {
    return static_cast<BMenu*>(menu)->AddItem(static_cast<BMenu*>(submenu)) ? 1 : 0;
}

int eb_haiku_menu_add_separator_item(void* menu) {
    return static_cast<BMenu*>(menu)->AddSeparatorItem() ? 1 : 0;
}

void eb_haiku_menu_item_set_enabled(void* item, int enabled) {
    static_cast<BMenuItem*>(item)->SetEnabled(enabled != 0);
}

void eb_haiku_menu_item_set_marked(void* item, int marked) {
    static_cast<BMenuItem*>(item)->SetMarked(marked != 0);
}

void eb_haiku_menu_item_invoke_via_messenger(void* item) {
    // Same reasoning/fix as eb_haiku_button_invoke above - BMenuItem is
    // a BInvoker too, and calling Invoke() directly hit the same
    // documented crash risk (confirmed by direct reproduction).
    BMenuItem* menuItem = static_cast<BMenuItem*>(item);
    BMessage* msg = menuItem->Message();
    if (msg) menuItem->Messenger().SendMessage(msg);
}

// ---- BPrintJob ----

void* eb_haiku_print_job_create(const char* name) { return new ShimPrintJob(name); }

void eb_haiku_print_job_set_draw_view_callback(void* job, EbHaikuPrintDrawViewCallback cb,
                                                void* userData) {
    static_cast<ShimPrintJob*>(job)->SetDrawViewCallback(cb, userData);
}

void eb_haiku_print_job_begin_job(void* job) { static_cast<ShimPrintJob*>(job)->BeginJob(); }

void eb_haiku_print_job_commit_job(void* job) { static_cast<ShimPrintJob*>(job)->CommitJob(); }

int eb_haiku_print_job_config_job(void* job) { return static_cast<ShimPrintJob*>(job)->ConfigJob(); }

void eb_haiku_print_job_cancel_job(void* job) { static_cast<ShimPrintJob*>(job)->CancelJob(); }

int eb_haiku_print_job_config_page(void* job) {
    return static_cast<ShimPrintJob*>(job)->ConfigPage();
}

void eb_haiku_print_job_spool_page(void* job) { static_cast<ShimPrintJob*>(job)->SpoolPage(); }

int eb_haiku_print_job_can_continue(void* job) {
    return static_cast<ShimPrintJob*>(job)->CanContinue() ? 1 : 0;
}

void eb_haiku_print_job_paper_rect(void* job, float* outLeft, float* outTop, float* outRight,
                                    float* outBottom) {
    BRect r = static_cast<ShimPrintJob*>(job)->PaperRect();
    *outLeft = r.left;
    *outTop = r.top;
    *outRight = r.right;
    *outBottom = r.bottom;
}

void eb_haiku_print_job_printable_rect(void* job, float* outLeft, float* outTop, float* outRight,
                                        float* outBottom) {
    BRect r = static_cast<ShimPrintJob*>(job)->PrintableRect();
    *outLeft = r.left;
    *outTop = r.top;
    *outRight = r.right;
    *outBottom = r.bottom;
}

void eb_haiku_print_job_get_resolution(void* job, int* outXDPI, int* outYDPI) {
    int32 x = 0, y = 0;
    static_cast<ShimPrintJob*>(job)->GetResolution(&x, &y);
    *outXDPI = x;
    *outYDPI = y;
}

int eb_haiku_print_job_first_page(void* job) { return static_cast<ShimPrintJob*>(job)->FirstPage(); }

int eb_haiku_print_job_last_page(void* job) { return static_cast<ShimPrintJob*>(job)->LastPage(); }

int eb_haiku_print_job_printer_type(void* job) {
    return static_cast<ShimPrintJob*>(job)->PrinterType();
}

void eb_haiku_print_job_destroy(void* job) { delete static_cast<ShimPrintJob*>(job); }

} // extern "C"
