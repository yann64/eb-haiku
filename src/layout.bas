' Idiomatic layer: Haiku's Layout Kit - BGroupLayout (row/column),
' BGridLayout (rows+columns, with spanning), BCardLayout (shows one
' child at a time), BSplitView (resizable panes - a real BView
' subclass, not a BLayout), and BSpaceLayoutItem (glue/struts).
'
' BGroupLayout/BGridLayout/BCardLayout all share Haiku's own real
' BLayout base with a *virtual* AddView/AddItem - HLayoutAddView/
' HLayoutAddItem below work uniformly on any of the three (via their
' own `.handle`), so there's no separate per-type AddView function.
'
' Not bound, deliberately: BLayoutBuilder (a pure templated C++
' convenience API with no stable ABI - it only ever calls the same
' methods this file already binds directly) and BGroupView/BGridView/
' BCardView (convenience BView-with-built-in-layout subclasses -
' already achievable in two calls via HViewCreate + HViewSetLayout).

#include once "raw/haiku_shim_interface.bas"

TYPE HGroupLayout
    handle AS ANY PTR
END TYPE

''' Creates a group layout - `orientation` is `H_HORIZONTAL` or
''' `H_VERTICAL`. Attach it to a window via `HWindowSetLayout`, or to an
''' ordinary view via `HViewSetLayout` (for a layout nested inside a
''' larger one), then add each child directly to the layout
''' (HLayoutAddView) instead of the window/view - a layout positions/
''' sizes its own children itself.
FUNCTION HGroupLayoutCreate(BYVAL layoutOrientation AS UINTEGER, BYVAL spacing AS SINGLE) AS HGroupLayout
    DIM l AS HGroupLayout
    l.handle = eb_haiku_group_layout_create(layoutOrientation, spacing)
    HGroupLayoutCreate = l
END FUNCTION

''' Adds `view` (any real BView handle - HView/HButton/HStringView/
''' HTextControl/HShimView, all via their own `.handle`) to the end of
''' the group. An alias for the generic HLayoutAddView below, kept for
''' the exact call shape earlier `eb-haiku` versions already used.
SUB HGroupLayoutAddView(BYVAL l AS HGroupLayout, BYVAL view AS ANY PTR)
    CALL eb_haiku_group_layout_add_view(l.handle, view)
END SUB

SUB HGroupLayoutSetOrientation(BYVAL l AS HGroupLayout, BYVAL layoutOrientation AS UINTEGER)
    CALL eb_haiku_group_layout_set_orientation(l.handle, layoutOrientation)
END SUB

SUB HGroupLayoutSetSpacing(BYVAL l AS HGroupLayout, BYVAL spacing AS SINGLE)
    CALL eb_haiku_group_layout_set_spacing(l.handle, spacing)
END SUB

''' How much of the group's own extra space `index`'s child claims,
''' relative to its siblings (0 = none, higher = more) - 0-based, in
''' the order each child was added.
FUNCTION HGroupLayoutItemWeight(BYVAL l AS HGroupLayout, BYVAL index AS INTEGER) AS SINGLE
    HGroupLayoutItemWeight = eb_haiku_group_layout_item_weight(l.handle, index)
END FUNCTION

SUB HGroupLayoutSetItemWeight(BYVAL l AS HGroupLayout, BYVAL index AS INTEGER, BYVAL weight AS SINGLE)
    CALL eb_haiku_group_layout_set_item_weight(l.handle, index, weight)
END SUB

' ---- Generic BLayout operations (BGroupLayout/BGridLayout/
' BCardLayout) - take a plain ANY PTR layout handle. ----

''' Adds `view` to any layout (Group/Grid/Card) via its own `.handle`.
SUB HLayoutAddView(BYVAL layout AS ANY PTR, BYVAL view AS ANY PTR)
    CALL eb_haiku_layout_add_view(layout, view)
END SUB

''' Adds a non-view layout item (e.g. one returned by
''' HSpaceLayoutItemCreateGlue) to any layout via its own `.handle`.
SUB HLayoutAddItem(BYVAL layout AS ANY PTR, BYVAL item AS ANY PTR)
    CALL eb_haiku_layout_add_item(layout, item)
END SUB

''' Sets the empty border around a Group or Grid layout's own children
''' (not applicable to Card, which has none of its own).
SUB HTwoDimensionalLayoutSetInsets(BYVAL layout AS ANY PTR, BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE)
    CALL eb_haiku_two_dimensional_layout_set_insets(layout, left, top, right, bottom)
END SUB

TYPE HGridLayout
    handle AS ANY PTR
END TYPE

''' Creates a grid layout (rows and columns) - attach via
''' HWindowSetLayout/HViewSetLayout, same as HGroupLayout.
FUNCTION HGridLayoutCreate(BYVAL horizontalSpacing AS SINGLE, BYVAL verticalSpacing AS SINGLE) AS HGridLayout
    DIM l AS HGridLayout
    l.handle = eb_haiku_grid_layout_create(horizontalSpacing, verticalSpacing)
    HGridLayoutCreate = l
END FUNCTION

''' Places `view` at a specific `column`/`row` (0-based), optionally
''' spanning more than one column/row. Use HLayoutAddView instead if you
''' just want the grid to place the next view in its own default
''' position.
SUB HGridLayoutAddViewAt(BYVAL l AS HGridLayout, BYVAL view AS ANY PTR, BYVAL column AS INTEGER, BYVAL row AS INTEGER, BYVAL columnCount AS INTEGER, BYVAL rowCount AS INTEGER)
    CALL eb_haiku_grid_layout_add_view_at(l.handle, view, column, row, columnCount, rowCount)
END SUB

SUB HGridLayoutSetSpacing(BYVAL l AS HGridLayout, BYVAL horizontalSpacing AS SINGLE, BYVAL verticalSpacing AS SINGLE)
    CALL eb_haiku_grid_layout_set_spacing(l.handle, horizontalSpacing, verticalSpacing)
END SUB

SUB HGridLayoutSetColumnWeight(BYVAL l AS HGridLayout, BYVAL column AS INTEGER, BYVAL weight AS SINGLE)
    CALL eb_haiku_grid_layout_set_column_weight(l.handle, column, weight)
END SUB

SUB HGridLayoutSetRowWeight(BYVAL l AS HGridLayout, BYVAL row AS INTEGER, BYVAL weight AS SINGLE)
    CALL eb_haiku_grid_layout_set_row_weight(l.handle, row, weight)
END SUB

SUB HGridLayoutSetMinColumnWidth(BYVAL l AS HGridLayout, BYVAL column AS INTEGER, BYVAL width AS SINGLE)
    CALL eb_haiku_grid_layout_set_min_column_width(l.handle, column, width)
END SUB

SUB HGridLayoutSetMaxColumnWidth(BYVAL l AS HGridLayout, BYVAL column AS INTEGER, BYVAL width AS SINGLE)
    CALL eb_haiku_grid_layout_set_max_column_width(l.handle, column, width)
END SUB

SUB HGridLayoutSetMinRowHeight(BYVAL l AS HGridLayout, BYVAL row AS INTEGER, BYVAL height AS SINGLE)
    CALL eb_haiku_grid_layout_set_min_row_height(l.handle, row, height)
END SUB

SUB HGridLayoutSetMaxRowHeight(BYVAL l AS HGridLayout, BYVAL row AS INTEGER, BYVAL height AS SINGLE)
    CALL eb_haiku_grid_layout_set_max_row_height(l.handle, row, height)
END SUB

TYPE HCardLayout
    handle AS ANY PTR
END TYPE

''' Creates a card layout - shows exactly one child at a time (wizard
''' pages, tabbed-without-tabs content). Add children via HLayoutAddView
''' (they're indexed 0-based in the order added); switch which one is
''' shown via HCardLayoutSetVisibleItem.
FUNCTION HCardLayoutCreate() AS HCardLayout
    DIM l AS HCardLayout
    l.handle = eb_haiku_card_layout_create()
    HCardLayoutCreate = l
END FUNCTION

SUB HCardLayoutSetVisibleItem(BYVAL l AS HCardLayout, BYVAL index AS INTEGER)
    CALL eb_haiku_card_layout_set_visible_item(l.handle, index)
END SUB

FUNCTION HCardLayoutVisibleIndex(BYVAL l AS HCardLayout) AS INTEGER
    HCardLayoutVisibleIndex = eb_haiku_card_layout_visible_index(l.handle)
END FUNCTION

TYPE HSplitView
    handle AS ANY PTR
END TYPE

''' Creates a split view (resizable panes with a draggable splitter
''' between them) - a real BView, not a BLayout - add it to a window/
''' view/layout via HWindowAddChild/HViewAddChild/HLayoutAddView, same
''' as any other view.
FUNCTION HSplitViewCreate(BYVAL splitOrientation AS UINTEGER, BYVAL spacing AS SINGLE) AS HSplitView
    DIM s AS HSplitView
    s.handle = eb_haiku_split_view_create(splitOrientation, spacing)
    HSplitViewCreate = s
END FUNCTION

''' Adds `view` as the next pane - `weight` controls how much of the
''' extra space it claims relative to its sibling panes (same meaning
''' as HGroupLayoutSetItemWeight).
SUB HSplitViewAddChild(BYVAL s AS HSplitView, BYVAL view AS ANY PTR, BYVAL weight AS SINGLE)
    CALL eb_haiku_split_view_add_child(s.handle, view, weight)
END SUB

''' Whether a pane can be dragged all the way to zero width/height
''' (collapsed) - nonzero = collapsible.
SUB HSplitViewSetCollapsible(BYVAL s AS HSplitView, BYVAL collapsible AS INTEGER)
    CALL eb_haiku_split_view_set_collapsible(s.handle, collapsible)
END SUB

SUB HSplitViewSetInsets(BYVAL s AS HSplitView, BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE)
    CALL eb_haiku_split_view_set_insets(s.handle, left, top, right, bottom)
END SUB

''' The thickness (in pixels) of the draggable splitter itself.
SUB HSplitViewSetSplitterSize(BYVAL s AS HSplitView, BYVAL size AS SINGLE)
    CALL eb_haiku_split_view_set_splitter_size(s.handle, size)
END SUB

' ---- BSpaceLayoutItem - real, commonly-used spacer items. Each
' returns a plain ANY PTR (a BLayoutItem*, not a BView - it has no view
' of its own to wrap in a TYPE) - add it to any layout via
' HLayoutAddItem.

''' Flexible empty space that expands to fill whatever room is left -
''' e.g. between two buttons in a horizontal HGroupLayout, to push one
''' to each end.
FUNCTION HSpaceLayoutItemCreateGlue() AS ANY PTR
    HSpaceLayoutItemCreateGlue = eb_haiku_space_layout_item_create_glue()
END FUNCTION

''' A fixed-width empty space.
FUNCTION HSpaceLayoutItemCreateHorizontalStrut(BYVAL width AS SINGLE) AS ANY PTR
    HSpaceLayoutItemCreateHorizontalStrut = eb_haiku_space_layout_item_create_horizontal_strut(width)
END FUNCTION

''' A fixed-height empty space.
FUNCTION HSpaceLayoutItemCreateVerticalStrut(BYVAL height AS SINGLE) AS ANY PTR
    HSpaceLayoutItemCreateVerticalStrut = eb_haiku_space_layout_item_create_vertical_strut(height)
END FUNCTION
