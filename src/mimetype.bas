' Idiomatic layer: BMimeType - the separate meta-mime database (icons,
' preferred-app registration, file-extension associations, the real
' installed-type registry), distinct from the per-file BNodeInfo type
' already bound in Phase 1 (node.bas). Sniffer-rule get/set/check are
' deliberately not bound - real added complexity (rule-syntax
' validation) for modest value.
'
' IMPORTANT, confirmed by direct reproduction: HMimeTypeGetIcon/SetIcon/
' GetIconForType/SetIconForType hang indefinitely without a real
' HApplication existing first - the same "needs BApplication first"
' gotcha family as Translation Kit's GetBitmap/BClipboard::Lock (see
' this package's own README). Every other function in this file works
' fine without one.

#include once "raw/haiku_shim_storage.bas"
#include once "message.bas"
#include once "bitmap.bas"

TYPE HMimeType
    handle AS ANY PTR
END TYPE

FUNCTION HMimeTypeCreate(mimeType AS ZSTRING) AS HMimeType
    DIM m AS HMimeType
    m.handle = eb_haiku_mime_type_create(mimeType)
    HMimeTypeCreate = m
END FUNCTION

FUNCTION HMimeTypeSetTo(BYVAL m AS HMimeType, mimeType AS ZSTRING) AS INTEGER
    HMimeTypeSetTo = eb_haiku_mime_type_set_to(m.handle, mimeType)
END FUNCTION

FUNCTION HMimeTypeInitCheck(BYVAL m AS HMimeType) AS INTEGER
    HMimeTypeInitCheck = eb_haiku_mime_type_init_check(m.handle)
END FUNCTION

FUNCTION HMimeTypeIsValid(BYVAL m AS HMimeType) AS INTEGER
    HMimeTypeIsValid = eb_haiku_mime_type_is_valid(m.handle)
END FUNCTION

''' Whether this exact type is registered in the real, on-disk meta-mime
''' database (distinct from HMimeTypeIsValid, which only checks the
''' string's own syntax).
FUNCTION HMimeTypeIsInstalled(BYVAL m AS HMimeType) AS INTEGER
    HMimeTypeIsInstalled = eb_haiku_mime_type_is_installed(m.handle)
END FUNCTION

''' Registers this type in the real meta-mime database. Returns a
''' status code (0 = success).
FUNCTION HMimeTypeInstall(BYVAL m AS HMimeType) AS INTEGER
    HMimeTypeInstall = eb_haiku_mime_type_install(m.handle)
END FUNCTION

FUNCTION HMimeTypeDelete(BYVAL m AS HMimeType) AS INTEGER
    HMimeTypeDelete = eb_haiku_mime_type_delete(m.handle)
END FUNCTION

FUNCTION HMimeTypeType(BYVAL m AS HMimeType) AS ZSTRING
    HMimeTypeType = eb_haiku_mime_type_type(m.handle)
END FUNCTION

''' Fills `outBuf` (caller-supplied, `bufSize` bytes) with the real
''' short (one-line) description - NOT null-terminated automatically,
''' matching this package's own established buffer-out convention.
''' Returns the real full length (>= 0, may exceed `bufSize` - the
''' caller-visible portion is simply truncated), or a negative status
''' code if this type has none.
FUNCTION HMimeTypeGetShortDescription(BYVAL m AS HMimeType, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HMimeTypeGetShortDescription = eb_haiku_mime_type_get_short_description(m.handle, outBuf, bufSize)
END FUNCTION

FUNCTION HMimeTypeSetShortDescription(BYVAL m AS HMimeType, description AS ZSTRING) AS INTEGER
    HMimeTypeSetShortDescription = eb_haiku_mime_type_set_short_description(m.handle, description)
END FUNCTION

''' See HMimeTypeGetShortDescription's own doc comment for the calling
''' convention.
FUNCTION HMimeTypeGetLongDescription(BYVAL m AS HMimeType, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HMimeTypeGetLongDescription = eb_haiku_mime_type_get_long_description(m.handle, outBuf, bufSize)
END FUNCTION

FUNCTION HMimeTypeSetLongDescription(BYVAL m AS HMimeType, description AS ZSTRING) AS INTEGER
    HMimeTypeSetLongDescription = eb_haiku_mime_type_set_long_description(m.handle, description)
END FUNCTION

''' Fills `outBuf` with the real preferred application's own MIME
''' signature - see HMimeTypeGetShortDescription's own calling
''' convention.
FUNCTION HMimeTypeGetPreferredApp(BYVAL m AS HMimeType, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HMimeTypeGetPreferredApp = eb_haiku_mime_type_get_preferred_app(m.handle, outBuf, bufSize)
END FUNCTION

FUNCTION HMimeTypeSetPreferredApp(BYVAL m AS HMimeType, signature AS ZSTRING) AS INTEGER
    HMimeTypeSetPreferredApp = eb_haiku_mime_type_set_preferred_app(m.handle, signature)
END FUNCTION

''' Fills `outMessage` (an existing HMessageCreate result) with this
''' type's own real registered file extensions, as a repeated string
''' field named "extensions" - read via HMessageCountItems/
''' FindStringAt (message.bas). Returns a status code (0 = success).
FUNCTION HMimeTypeGetFileExtensions(BYVAL m AS HMimeType, BYVAL outMessage AS HMessage) AS INTEGER
    HMimeTypeGetFileExtensions = eb_haiku_mime_type_get_file_extensions(m.handle, outMessage.handle)
END FUNCTION

''' `extensionsMessage` must have the same "extensions" string-array
''' shape HMimeTypeGetFileExtensions above fills.
FUNCTION HMimeTypeSetFileExtensions(BYVAL m AS HMimeType, BYVAL extensionsMessage AS HMessage) AS INTEGER
    HMimeTypeSetFileExtensions = eb_haiku_mime_type_set_file_extensions(m.handle, extensionsMessage.handle)
END FUNCTION

''' Fills `outMessage` with the real signatures of apps registered as
''' "supporting" this type, as a repeated string field named
''' "applications" - read via HMessageCountItems/FindStringAt.
FUNCTION HMimeTypeGetSupportingApps(BYVAL m AS HMimeType, BYVAL outMessage AS HMessage) AS INTEGER
    HMimeTypeGetSupportingApps = eb_haiku_mime_type_get_supporting_apps(m.handle, outMessage.handle)
END FUNCTION

''' Fills `icon` (an existing HBitmapCreate result, sized/color-spaced
''' to match `size`) with this type's own real icon. `size` is
''' H_LARGE_ICON/H_MINI_ICON. Returns a status code (0 = success).
FUNCTION HMimeTypeGetIcon(BYVAL m AS HMimeType, BYVAL icon AS HBitmap, BYVAL size AS UINTEGER) AS INTEGER
    HMimeTypeGetIcon = eb_haiku_mime_type_get_icon(m.handle, icon.handle, size)
END FUNCTION

''' Registers `icon` as this type's own real icon.
FUNCTION HMimeTypeSetIcon(BYVAL m AS HMimeType, BYVAL icon AS HBitmap, BYVAL size AS UINTEGER) AS INTEGER
    HMimeTypeSetIcon = eb_haiku_mime_type_set_icon(m.handle, icon.handle, size)
END FUNCTION

''' Like HMimeTypeGetIcon, but for a specific file-extension `forType`
''' registered under this (super)type, rather than the type itself.
FUNCTION HMimeTypeGetIconForType(BYVAL m AS HMimeType, forType AS ZSTRING, BYVAL icon AS HBitmap, BYVAL size AS UINTEGER) AS INTEGER
    HMimeTypeGetIconForType = eb_haiku_mime_type_get_icon_for_type(m.handle, forType, icon.handle, size)
END FUNCTION

FUNCTION HMimeTypeSetIconForType(BYVAL m AS HMimeType, forType AS ZSTRING, BYVAL icon AS HBitmap, BYVAL size AS UINTEGER) AS INTEGER
    HMimeTypeSetIconForType = eb_haiku_mime_type_set_icon_for_type(m.handle, forType, icon.handle, size)
END FUNCTION

''' Fills `outBuf` (caller-supplied, `bufSize` bytes, NOT null-
''' terminated automatically) with this type's own real sniffer rule -
''' Haiku's own MIME-sniffing mini-language (e.g. "0.5 ('BEOS')"-style
''' patterns). Returns the real length in bytes (>= 0), or a negative
''' status code if this type has no sniffer rule set.
FUNCTION HMimeTypeGetSnifferRule(BYVAL m AS HMimeType, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HMimeTypeGetSnifferRule = eb_haiku_mime_type_get_sniffer_rule(m.handle, outBuf, bufSize)
END FUNCTION

FUNCTION HMimeTypeSetSnifferRule(BYVAL m AS HMimeType, rule AS ZSTRING) AS INTEGER
    HMimeTypeSetSnifferRule = eb_haiku_mime_type_set_sniffer_rule(m.handle, rule)
END FUNCTION

''' Validates a candidate sniffer rule string without needing any
''' HMimeType instance (a real static Haiku method) - on a real parse
''' error, fills `outErrBuf` (caller-supplied, `errBufSize` bytes, NOT
''' null-terminated automatically) with Haiku's own real error message.
''' Returns a status code (0 = valid rule).
FUNCTION HMimeTypeCheckSnifferRule(rule AS ZSTRING, BYVAL outErrBuf AS ANY PTR, BYVAL errBufSize AS INTEGER) AS INTEGER
    HMimeTypeCheckSnifferRule = eb_haiku_mime_type_check_sniffer_rule(rule, outErrBuf, errBufSize)
END FUNCTION

''' Frees an HMimeType - call exactly once.
SUB HMimeTypeFree(BYVAL m AS HMimeType)
    CALL eb_haiku_mime_type_destroy(m.handle)
END SUB

''' Fills `outMime` (an existing HMimeTypeCreate result) with the real
''' MIME type Haiku would guess for `path`, based on its own extension
''' (not content sniffing - real Haiku's own extension-only overload).
''' Returns a status code (0 = success).
FUNCTION HMimeTypeGuessMimeType(path AS ZSTRING, BYVAL outMime AS HMimeType) AS INTEGER
    HMimeTypeGuessMimeType = eb_haiku_mime_type_guess_mime_type(path, outMime.handle)
END FUNCTION

''' Fills `outMessage` with every real MIME type installed on this
''' system, as a repeated string field named "types" - read via
''' HMessageCountItems/FindStringAt.
FUNCTION HMimeTypeGetInstalledTypes(BYVAL outMessage AS HMessage) AS INTEGER
    HMimeTypeGetInstalledTypes = eb_haiku_mime_type_get_installed_types(outMessage.handle)
END FUNCTION

''' Like HMimeTypeGetInstalledTypes, but only real top-level supertypes
''' (e.g. "text", "image"). IMPORTANT, confirmed by direct
''' reproduction: the real field name here is "super_types", NOT
''' "types" like HMimeTypeGetInstalledTypes above - a real, easy-to-
''' assume-wrong inconsistency in Haiku's own API, not guessed.
FUNCTION HMimeTypeGetInstalledSupertypes(BYVAL outMessage AS HMessage) AS INTEGER
    HMimeTypeGetInstalledSupertypes = eb_haiku_mime_type_get_installed_supertypes(outMessage.handle)
END FUNCTION
