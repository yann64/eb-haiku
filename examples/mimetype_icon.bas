' BMimeType icon get/set - fetch a real system-installed icon (text/
' plain's own large icon) and register a custom icon for a throwaway
' MIME type. Needs a real HApplication to exist first - GetIcon/SetIcon
' hang indefinitely otherwise (see src/mimetype.bas's own top comment,
' the same "needs BApplication first" gotcha as GetBitmap/BClipboard).

#include once "../src/lib.bas"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-MimeIconExample")

DIM textPlain AS HMimeType
textPlain = HMimeTypeCreate("text/plain")

DIM icon AS HBitmap
icon = HBitmapCreate(0, 0, 31, 31, H_RGBA32, 0)
DIM rc AS INTEGER
rc = HMimeTypeGetIcon(textPlain, icon, H_LARGE_ICON)
IF rc = 0 THEN
    PRINT "fetched text/plain's real large icon ok"
END IF
CALL HBitmapFree(icon)
CALL HMimeTypeFree(textPlain)

CONST CUSTOM_TYPE = "application/x-vnd.EbHaiku-IconExampleType"
DIM custom AS HMimeType
custom = HMimeTypeCreate(CUSTOM_TYPE)
CALL HMimeTypeDelete(custom) ' start clean if a prior run left it installed
custom = HMimeTypeCreate(CUSTOM_TYPE)
CALL HMimeTypeInstall(custom)

DIM customIcon AS HBitmap
customIcon = HBitmapCreate(0, 0, 15, 15, H_RGBA32, 0)
rc = HMimeTypeSetIcon(custom, customIcon, H_MINI_ICON)
IF rc = 0 THEN
    PRINT "registered a real custom mini icon for ", CUSTOM_TYPE, " ok"
END IF
CALL HBitmapFree(customIcon)

CALL HMimeTypeDelete(custom) ' clean up
CALL HMimeTypeFree(custom)

CALL HApplicationFree(app)
