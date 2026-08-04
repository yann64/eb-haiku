' Idiomatic layer: BAppFileInfo - real executable metadata (signature,
' app flags, supported types), IS-A BNodeInfo (single inheritance,
' already bound in Phase 1 - node.bas). Reuses the existing HFile type
' (file.bas, Translation Kit) as its own I/O target.
'
' Icon get/set (a cheap, obvious follow-on via the same HBitmap-reuse
' pattern as BMimeType's own, see mimetype.bas), GetCatalogEntry/
' SetCatalogEntry (ties into the still-out-of-scope BCatalog), and
' BResources (a separate, larger class for embedded resource *data*,
' not metadata) are deliberately not bound.

#include once "raw/haiku_shim_storage.bas"
#include once "file.bas"
#include once "message.bas"

TYPE HAppFileInfo
    handle AS ANY PTR
END TYPE

FUNCTION HAppFileInfoCreate() AS HAppFileInfo
    DIM i AS HAppFileInfo
    i.handle = eb_haiku_app_file_info_create()
    HAppFileInfoCreate = i
END FUNCTION

''' Points this HAppFileInfo at an already-open HFile (file.bas) -
''' required before any other function below. Returns a status code
''' (0 = success).
FUNCTION HAppFileInfoSetTo(BYVAL i AS HAppFileInfo, BYVAL f AS HFile) AS INTEGER
    HAppFileInfoSetTo = eb_haiku_app_file_info_set_to(i.handle, f.handle)
END FUNCTION

''' Fills `outBuf` (caller-supplied, `bufSize` bytes) with the real
''' executable's own registered MIME signature - NOT null-terminated
''' automatically, matching this package's own established buffer-out
''' convention. Returns the real full length (>= 0), or a negative
''' status code if none is set.
FUNCTION HAppFileInfoGetSignature(BYVAL i AS HAppFileInfo, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HAppFileInfoGetSignature = eb_haiku_app_file_info_get_signature(i.handle, outBuf, bufSize)
END FUNCTION

FUNCTION HAppFileInfoSetSignature(BYVAL i AS HAppFileInfo, signature AS ZSTRING) AS INTEGER
    HAppFileInfoSetSignature = eb_haiku_app_file_info_set_signature(i.handle, signature)
END FUNCTION

''' Fills `outFlags` with the real app flags (H_SINGLE_LAUNCH/
''' H_MULTIPLE_LAUNCH/H_EXCLUSIVE_LAUNCH/H_BACKGROUND_APP/H_ARGV_ONLY -
''' raw/haiku_shim.bas's own constants). Returns a status code (0 =
''' success).
FUNCTION HAppFileInfoGetAppFlags(BYVAL i AS HAppFileInfo, BYREF outFlags AS UINTEGER) AS INTEGER
    DIM flags AS UINTEGER
    DIM rc AS INTEGER
    rc = eb_haiku_app_file_info_get_app_flags(i.handle, @flags)
    outFlags = flags
    HAppFileInfoGetAppFlags = rc
END FUNCTION

FUNCTION HAppFileInfoSetAppFlags(BYVAL i AS HAppFileInfo, BYVAL flags AS UINTEGER) AS INTEGER
    HAppFileInfoSetAppFlags = eb_haiku_app_file_info_set_app_flags(i.handle, flags)
END FUNCTION

FUNCTION HAppFileInfoRemoveAppFlags(BYVAL i AS HAppFileInfo) AS INTEGER
    HAppFileInfoRemoveAppFlags = eb_haiku_app_file_info_remove_app_flags(i.handle)
END FUNCTION

''' Fills `outMessage` (an existing HMessageCreate result) with the
''' real MIME types this executable declares support for, as a
''' repeated string field named "types" - read via
''' HMessageCountItems/FindStringAt (message.bas). Returns a status
''' code (0 = success).
FUNCTION HAppFileInfoGetSupportedTypes(BYVAL i AS HAppFileInfo, BYVAL outMessage AS HMessage) AS INTEGER
    HAppFileInfoGetSupportedTypes = eb_haiku_app_file_info_get_supported_types(i.handle, outMessage.handle)
END FUNCTION

''' `typesMessage` must have the same "types" string-array shape
''' HAppFileInfoGetSupportedTypes above fills.
FUNCTION HAppFileInfoSetSupportedTypes(BYVAL i AS HAppFileInfo, BYVAL typesMessage AS HMessage) AS INTEGER
    HAppFileInfoSetSupportedTypes = eb_haiku_app_file_info_set_supported_types(i.handle, typesMessage.handle)
END FUNCTION

FUNCTION HAppFileInfoIsSupportedType(BYVAL i AS HAppFileInfo, forType AS ZSTRING) AS INTEGER
    HAppFileInfoIsSupportedType = eb_haiku_app_file_info_is_supported_type(i.handle, forType)
END FUNCTION

''' Frees an HAppFileInfo - call exactly once.
SUB HAppFileInfoFree(BYVAL i AS HAppFileInfo)
    CALL eb_haiku_app_file_info_destroy(i.handle)
END SUB
