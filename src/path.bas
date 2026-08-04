' Idiomatic layer: BPath (Haiku's own path-manipulation type).
'
' HPath is an opaque handle over a real, heap-allocated BPath - every
' HPath must be freed exactly once via HPathFree.

#include once "raw/haiku_shim.bas"

TYPE HPath
    handle AS ANY PTR
END TYPE

''' Creates a path from a plain string.
FUNCTION HPathCreate(pathStr AS ZSTRING) AS HPath
    DIM p AS HPath
    p.handle = eb_haiku_path_create(pathStr)
    HPathCreate = p
END FUNCTION

''' Whether the path was successfully initialized (nonzero = success,
''' matching this shim's own plain-INTEGER/C convention throughout).
FUNCTION HPathInitCheck(BYVAL p AS HPath) AS INTEGER
    HPathInitCheck = eb_haiku_path_init_check(p.handle)
END FUNCTION

''' Appends `leaf` to the path in place - returns a status code (0 =
''' success).
FUNCTION HPathAppend(BYVAL p AS HPath, leaf AS ZSTRING) AS INTEGER
    HPathAppend = eb_haiku_path_append(p.handle, leaf)
END FUNCTION

''' The path's full text, borrowed from the HPath itself - valid until
''' HPathFree, never freed separately.
FUNCTION HPathGet(BYVAL p AS HPath) AS ZSTRING
    HPathGet = eb_haiku_path_get(p.handle)
END FUNCTION

''' The path's final component (e.g. "file.txt" for "/boot/home/file.txt").
FUNCTION HPathLeaf(BYVAL p AS HPath) AS ZSTRING
    HPathLeaf = eb_haiku_path_leaf(p.handle)
END FUNCTION

''' Fills `outParent` with `p`'s parent directory - `outParent` must
''' already be a valid HPath (from HPathCreate/HPathCreateEmpty).
''' Returns a status code (0 = success).
FUNCTION HPathGetParent(BYVAL p AS HPath, BYVAL outParent AS HPath) AS INTEGER
    HPathGetParent = eb_haiku_path_get_parent(p.handle, outParent.handle)
END FUNCTION

''' An empty path, ready to be filled in (e.g. via HPathGetParent's own
''' out-parameter, or HPathSetTo-style reuse).
FUNCTION HPathCreateEmpty() AS HPath
    DIM p AS HPath
    p.handle = eb_haiku_path_create_empty()
    HPathCreateEmpty = p
END FUNCTION

FUNCTION HPathIsAbsolute(BYVAL p AS HPath) AS INTEGER
    HPathIsAbsolute = eb_haiku_path_is_absolute(p.handle)
END FUNCTION

''' Frees an HPath - call exactly once.
SUB HPathFree(BYVAL p AS HPath)
    CALL eb_haiku_path_destroy(p.handle)
END SUB
