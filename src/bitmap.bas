' Idiomatic layer: BBitmap - minimal (hold/inspect/draw a loaded
' image, not full pixel-manipulation). The Translation Kit's own
' central currency: what HGetBitmap returns, what HBitmapStreamCreate
' wraps to save one.

#include once "raw/haiku_shim_translation.bas"

TYPE HBitmap
    handle AS ANY PTR
END TYPE

''' Creates an empty bitmap of the given bounds/color space - most
''' programs get an HBitmap from HGetBitmap (translation.bas) instead
''' of building one from scratch.
FUNCTION HBitmapCreate(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL colorSpace AS UINTEGER, BYVAL flags AS UINTEGER) AS HBitmap
    DIM b AS HBitmap
    b.handle = eb_haiku_bitmap_create(left, top, right, bottom, colorSpace, flags)
    HBitmapCreate = b
END FUNCTION

FUNCTION HBitmapInitCheck(BYVAL b AS HBitmap) AS INTEGER
    HBitmapInitCheck = eb_haiku_bitmap_init_check(b.handle)
END FUNCTION

''' Writes the bitmap's own real bounds into the 4 BYREF out-params.
SUB HBitmapGetBounds(BYVAL b AS HBitmap, BYREF outLeft AS SINGLE, BYREF outTop AS SINGLE, BYREF outRight AS SINGLE, BYREF outBottom AS SINGLE)
    DIM leftBuf(3) AS SINGLE
    CALL eb_haiku_bitmap_get_bounds(b.handle, @leftBuf(0), @leftBuf(1), @leftBuf(2), @leftBuf(3))
    outLeft = leftBuf(0)
    outTop = leftBuf(1)
    outRight = leftBuf(2)
    outBottom = leftBuf(3)
END SUB

FUNCTION HBitmapColorSpace(BYVAL b AS HBitmap) AS UINTEGER
    HBitmapColorSpace = eb_haiku_bitmap_color_space(b.handle)
END FUNCTION

''' Frees a bitmap - not needed for one wrapped by HBitmapStreamCreate
''' and never detached (the stream owns it) - see HBitmapStreamCreate's
''' own doc comment.
SUB HBitmapFree(BYVAL b AS HBitmap)
    CALL eb_haiku_bitmap_destroy(b.handle)
END SUB
