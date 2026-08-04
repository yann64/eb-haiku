' Idiomatic layer: BMenuBar/BMenu/BMenuItem - real window menus. A menu
' bar IS a menu (real Haiku: BMenuBar : public BMenu : public BView,
' single inheritance throughout) - HMenuBarCreate returns a plain HMenu,
' reused directly wherever a menu handle is expected. IMPORTANT: a menu
' bar must be hosted in a real layout (HWindowSetLayout + a
' HGroupLayoutAddView call, as the first item), NOT a plain
' HWindowAddChild - see HMenuBarCreate's own doc comment below for why.
'
' Once a menu/item is added to its parent, Haiku itself owns and
' destroys it automatically - matching this package's own existing
' stock-controls convention (no HMenuFree/HMenuItemFree, exactly like
' HButtonCreate has no HButtonFree).
'
' IMPORTANT, confirmed by direct reproduction: constructing a new
' HMenu/HMenuItem (a real BView/BHandler) AFTER HApplicationFree has
' already destroyed the owning HApplication hangs indefinitely - the
' same "needs a live BApplication" gotcha family as Translation Kit's
' GetBitmap/BClipboard::Lock, but here needing one to still exist
' rather than merely have existed once. Do all menu/item construction
' before HApplicationFree, never after.

#include once "raw/haiku_shim_interface.bas"
#include once "message.bas"

TYPE HMenu
    handle AS ANY PTR
END TYPE

TYPE HMenuItem
    handle AS ANY PTR
END TYPE

''' A menu bar. IMPORTANT, confirmed by direct reproduction: this uses
''' `BMenuBar`'s own layout-kit-friendly constructor (no `BRect` frame
''' at all) - it renders at zero size and is invisible unless added to
''' a real layout (`HWindowSetLayout` + `HGroupLayoutAddView(layout,
''' menuBar.handle)`, as the first item, matching real Haiku's own
''' standard menu bar hosting pattern), NOT via a plain `HWindowAddChild`.
''' Fill it with top-level menus via HMenuAddSubmenu.
FUNCTION HMenuBarCreate(name AS ZSTRING) AS HMenu
    DIM m AS HMenu
    m.handle = eb_haiku_menu_bar_create(name)
    HMenuBarCreate = m
END FUNCTION

''' A plain menu (a top-level menu under a menu bar, or a submenu).
FUNCTION HMenuCreate(name AS ZSTRING) AS HMenu
    DIM m AS HMenu
    m.handle = eb_haiku_menu_create(name)
    HMenuCreate = m
END FUNCTION

''' A leaf menu item - `message` is delivered (via
''' HMenuItemInvokeViaMessenger, or a real click) to the item's own
''' established target, which defaults to the window it ends up
''' attached to.
FUNCTION HMenuItemCreate(label AS ZSTRING, BYVAL message AS HMessage) AS HMenuItem
    DIM i AS HMenuItem
    i.handle = eb_haiku_menu_item_create(label, message.handle)
    HMenuItemCreate = i
END FUNCTION

''' A submenu item - `submenu` opens when this item is selected.
FUNCTION HMenuItemCreateSubmenu(BYVAL submenu AS HMenu) AS HMenuItem
    DIM i AS HMenuItem
    i.handle = eb_haiku_menu_item_create_submenu(submenu.handle, 0)
    HMenuItemCreateSubmenu = i
END FUNCTION

''' Adds a leaf item to `menu`. Returns nonzero on success.
FUNCTION HMenuAddItem(BYVAL menu AS HMenu, BYVAL item AS HMenuItem) AS INTEGER
    HMenuAddItem = eb_haiku_menu_add_item(menu.handle, item.handle)
END FUNCTION

''' Adds `submenu` to `menu` (or to a menu bar - `menu` may be an
''' HMenuBarCreate result, since a menu bar IS a menu). Returns nonzero
''' on success.
FUNCTION HMenuAddSubmenu(BYVAL menu AS HMenu, BYVAL submenu AS HMenu) AS INTEGER
    HMenuAddSubmenu = eb_haiku_menu_add_submenu(menu.handle, submenu.handle)
END FUNCTION

''' Adds a visual separator line. Returns nonzero on success.
FUNCTION HMenuAddSeparatorItem(BYVAL menu AS HMenu) AS INTEGER
    HMenuAddSeparatorItem = eb_haiku_menu_add_separator_item(menu.handle)
END FUNCTION

SUB HMenuItemSetEnabled(BYVAL item AS HMenuItem, BYVAL enabled AS INTEGER)
    CALL eb_haiku_menu_item_set_enabled(item.handle, enabled)
END SUB

SUB HMenuItemSetMarked(BYVAL item AS HMenuItem, BYVAL marked AS INTEGER)
    CALL eb_haiku_menu_item_set_marked(item.handle, marked)
END SUB

FUNCTION HMenuItemIsMarked(BYVAL item AS HMenuItem) AS INTEGER
    HMenuItemIsMarked = eb_haiku_menu_item_is_marked(item.handle)
END FUNCTION

''' Triggers `item` exactly as a real click would - not implemented via
''' BInvoker::Invoke() itself, which crashes when called from outside
''' the window's own thread (the same documented risk as
''' HButtonInvoke, confirmed by direct reproduction); still a
''' legitimate way to programmatically drive a menu item, not just a
''' test-only hack.
SUB HMenuItemInvokeViaMessenger(BYVAL item AS HMenuItem)
    CALL eb_haiku_menu_item_invoke_via_messenger(item.handle)
END SUB

''' Turns radio-mode grouping on/off for `menu` - once on, real Haiku
''' automatically unmarks every sibling item when one is marked (via a
''' real click or HMenuItemSetMarked), entirely handled internally, no
''' extra bookkeeping needed on the eBasic side.
SUB HMenuSetRadioMode(BYVAL menu AS HMenu, BYVAL isOn AS INTEGER)
    CALL eb_haiku_menu_set_radio_mode(menu.handle, isOn)
END SUB

FUNCTION HMenuIsRadioMode(BYVAL menu AS HMenu) AS INTEGER
    HMenuIsRadioMode = eb_haiku_menu_is_radio_mode(menu.handle)
END FUNCTION

''' When on (radio mode only), the menu's own displayed label follows
''' whichever item is currently marked.
SUB HMenuSetLabelFromMarked(BYVAL menu AS HMenu, BYVAL isOn AS INTEGER)
    CALL eb_haiku_menu_set_label_from_marked(menu.handle, isOn)
END SUB

''' A context (right-click-style) menu - IS-A BMenu (like HMenuBarCreate's
''' own result), reuses the plain HMenu type directly: add items to it
''' via HMenuAddItem/AddSubmenu/AddSeparatorItem exactly like any other
''' menu, then show it via HPopUpMenuGo.
FUNCTION HPopUpMenuCreate(name AS ZSTRING) AS HMenu
    DIM m AS HMenu
    m.handle = eb_haiku_popup_menu_create(name)
    HPopUpMenuCreate = m
END FUNCTION

''' Shows `popup` at screen point (x, y). With `async` = 0 (the common
''' case), blocks the calling thread until the user picks an item or
''' dismisses the menu, returning the picked HMenuItem (a null handle if
''' dismissed). With `async` <> 0, returns immediately with a null
''' handle - the picked item (if any) is delivered as a real message to
''' its own established target instead, same as a menu bar item.
''' IMPORTANT, confirmed by direct reproduction: real interactive item
''' *selection* needs a human mouse click - not triggerable over SSH
''' (the same real limitation as HPrintJobConfigJob) - only `async` = 1
''' is safe to drive headlessly in an automated test.
FUNCTION HPopUpMenuGo(BYVAL popup AS HMenu, BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL autoInvoke AS INTEGER, BYVAL keepOpen AS INTEGER, BYVAL async AS INTEGER) AS HMenuItem
    DIM picked AS HMenuItem
    picked.handle = eb_haiku_popup_menu_go(popup.handle, x, y, autoInvoke, keepOpen, async)
    HPopUpMenuGo = picked
END FUNCTION

TYPE HMenuField
    handle AS ANY PTR
END TYPE

''' A labeled, clickable field wrapping an existing menu (build `menu`'s
''' own items first via HMenuAddItem/AddSubmenu, then pass it here).
FUNCTION HMenuFieldCreate(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, name AS ZSTRING, label AS ZSTRING, BYVAL menu AS HMenu) AS HMenuField
    DIM f AS HMenuField
    f.handle = eb_haiku_menu_field_create(left, top, right, bottom, name, label, menu.handle)
    HMenuFieldCreate = f
END FUNCTION

''' The HMenu this field wraps - add items to it after creation via the
''' usual HMenuAddItem/AddSubmenu/AddSeparatorItem.
FUNCTION HMenuFieldMenu(BYVAL f AS HMenuField) AS HMenu
    DIM m AS HMenu
    m.handle = eb_haiku_menu_field_menu(f.handle)
    HMenuFieldMenu = m
END FUNCTION
