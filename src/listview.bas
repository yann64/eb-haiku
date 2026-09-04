' Idiomatic layer: BListView + BStringItem. Real BListView has no
' BInvoker/target+message mechanism for per-selection-change
' notification (confirmed against a real, hardware-verified sibling
' FreeBASIC Haiku binding - only SetInvocationMessage exists, firing on
' double-click/Enter, not every selection change) - the only way to
' observe every change is the protected virtual SelectionChanged()
' hook, so this package's own ShimListView subclass overrides it and
' forwards to a plain callback, the same "no other way to reach a
' virtual from eBasic" reasoning as HWindow/HView's own callbacks.
' Add to a window/view via HWindowAddChild/HViewAddChild, passing
' `.handle` directly - a real BView under the hood.

#include once "raw/haiku_shim_interface.bas"

TYPE HListView
    handle AS ANY PTR
END TYPE

''' Creates a new, empty list view. `multipleSelection` = 0 for
''' single-selection (the common case), nonzero for multiple.
FUNCTION HListViewCreate(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, name AS ZSTRING, BYVAL multipleSelection AS INTEGER) AS HListView
    DIM lv AS HListView
    lv.handle = eb_haiku_listview_create(left, top, right, bottom, name, multipleSelection)
    HListViewCreate = lv
END FUNCTION

''' Fires on EVERY selection change (not just double-click/Enter,
''' unlike real BListView's own SetInvocationMessage) - see this file's
''' own top comment for why this needed a real virtual-forwarding
''' subclass rather than the usual target/message mechanism.
SUB HListViewSetSelectionChangedCallback(BYVAL lv AS HListView, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    CALL eb_haiku_listview_set_selection_changed_callback(lv.handle, cb, userData)
END SUB

''' Appends `item` (an `HStringItem`'s own `.handle`, or any other
''' `BListItem`-derived handle) - the list view now owns it.
SUB HListViewAddItem(BYVAL lv AS HListView, BYVAL item AS ANY PTR)
    CALL eb_haiku_listview_add_item(lv.handle, item)
END SUB

SUB HListViewMakeEmpty(BYVAL lv AS HListView)
    CALL eb_haiku_listview_make_empty(lv.handle)
END SUB

FUNCTION HListViewCountItems(BYVAL lv AS HListView) AS INTEGER
    HListViewCountItems = eb_haiku_listview_count_items(lv.handle)
END FUNCTION

''' -1 if nothing selected (real BListView::CurrentSelection default).
FUNCTION HListViewCurrentSelection(BYVAL lv AS HListView) AS INTEGER
    HListViewCurrentSelection = eb_haiku_listview_current_selection(lv.handle)
END FUNCTION

SUB HListViewSelect(BYVAL lv AS HListView, BYVAL index AS INTEGER)
    CALL eb_haiku_listview_select(lv.handle, index)
END SUB

TYPE HStringItem
    handle AS ANY PTR
END TYPE

FUNCTION HStringItemCreate(text AS ZSTRING) AS HStringItem
    DIM item AS HStringItem
    item.handle = eb_haiku_stringitem_create(text)
    HStringItemCreate = item
END FUNCTION

''' Borrowed from the real BStringItem's own long-lived storage - no
''' heap allocation, no matching free needed.
FUNCTION HStringItemGetText(BYVAL item AS HStringItem) AS ZSTRING
    HStringItemGetText = eb_haiku_stringitem_get_text(item.handle)
END FUNCTION
