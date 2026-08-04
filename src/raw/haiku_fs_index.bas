' Raw FFI layer: Haiku's own fs_create_index() (kernel/fs_index.h) - a
' real, plain extern "C" kernel function (like find_directory - see
' raw/haiku_find_directory.bas's own top comment), not a shim wrapper.
' BQuery predicates only ever match *indexed* attributes on BFS - an
' attribute with no index simply never matches, silently - so a real
' query demo needs this to create one first for whatever custom
' attribute it wants to search on.

Extern "C" Lib "root"
    Declare Function fs_create_index(BYVAL device AS UINTEGER, BYVAL name AS ZSTRING, BYVAL attrType AS UINTEGER, BYVAL flags AS UINTEGER) AS INTEGER
End Extern
