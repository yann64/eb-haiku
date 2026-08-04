' Idiomatic layer: BGroupLayout - arranges child views in a row/column
' instead of manual frame positioning.

#include once "raw/haiku_shim_interface.bas"

TYPE HGroupLayout
    handle AS ANY PTR
END TYPE

''' Creates a group layout - `orientation` is `H_HORIZONTAL` or
''' `H_VERTICAL`. Attach it to a window via `HWindowSetLayout`, then
''' add each child directly to the layout (HGroupLayoutAddView) instead
''' of the window (HWindowAddChild) - a layout positions/sizes its own
''' children itself.
FUNCTION HGroupLayoutCreate(BYVAL layoutOrientation AS UINTEGER, BYVAL spacing AS SINGLE) AS HGroupLayout
    DIM l AS HGroupLayout
    l.handle = eb_haiku_group_layout_create(layoutOrientation, spacing)
    HGroupLayoutCreate = l
END FUNCTION

''' Adds `view` (any real BView handle - HView/HButton/HStringView/
''' HTextControl/HShimView, all via their own `.handle`) to the end of
''' the group.
SUB HGroupLayoutAddView(BYVAL l AS HGroupLayout, BYVAL view AS ANY PTR)
    CALL eb_haiku_group_layout_add_view(l.handle, view)
END SUB
