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

''' Triggers `item` exactly as a real click would - not implemented via
''' BInvoker::Invoke() itself, which crashes when called from outside
''' the window's own thread (the same documented risk as
''' HButtonInvoke, confirmed by direct reproduction); still a
''' legitimate way to programmatically drive a menu item, not just a
''' test-only hack.
SUB HMenuItemInvokeViaMessenger(BYVAL item AS HMenuItem)
    CALL eb_haiku_menu_item_invoke_via_messenger(item.handle)
END SUB
