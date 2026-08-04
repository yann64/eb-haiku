' Idiomatic layer: BMessage - Haiku's fundamental structured
' data-interchange type, used throughout the system (and the foundation
' any future GUI/messaging work would build on).

#include once "raw/haiku_shim.bas"
#include once "path.bas"

TYPE HMessage
    handle AS ANY PTR
END TYPE

''' Creates a message with the given `what` constant (an arbitrary
''' 4-byte code identifying the message's meaning - Haiku convention is
''' a 4-character literal like `'HELO'`, but any UINTEGER works).
FUNCTION HMessageCreate(BYVAL what AS UINTEGER) AS HMessage
    DIM m AS HMessage
    m.handle = eb_haiku_message_create(what)
    HMessageCreate = m
END FUNCTION

FUNCTION HMessageWhat(BYVAL m AS HMessage) AS UINTEGER
    HMessageWhat = eb_haiku_message_what(m.handle)
END FUNCTION

FUNCTION HMessageAddString(BYVAL m AS HMessage, name AS ZSTRING, value AS ZSTRING) AS INTEGER
    HMessageAddString = eb_haiku_message_add_string(m.handle, name, value)
END FUNCTION

FUNCTION HMessageAddInt32(BYVAL m AS HMessage, name AS ZSTRING, BYVAL value AS INTEGER) AS INTEGER
    HMessageAddInt32 = eb_haiku_message_add_int32(m.handle, name, value)
END FUNCTION

FUNCTION HMessageAddDouble(BYVAL m AS HMessage, name AS ZSTRING, BYVAL value AS DOUBLE) AS INTEGER
    HMessageAddDouble = eb_haiku_message_add_double(m.handle, name, value)
END FUNCTION

FUNCTION HMessageAddBool(BYVAL m AS HMessage, name AS ZSTRING, BYVAL value AS INTEGER) AS INTEGER
    HMessageAddBool = eb_haiku_message_add_bool(m.handle, name, value)
END FUNCTION

''' "" if `name` isn't present.
FUNCTION HMessageFindString(BYVAL m AS HMessage, name AS ZSTRING) AS ZSTRING
    HMessageFindString = eb_haiku_message_find_string(m.handle, name)
END FUNCTION

FUNCTION HMessageFindInt32(BYVAL m AS HMessage, name AS ZSTRING) AS INTEGER
    HMessageFindInt32 = eb_haiku_message_find_int32(m.handle, name)
END FUNCTION

FUNCTION HMessageFindDouble(BYVAL m AS HMessage, name AS ZSTRING) AS DOUBLE
    HMessageFindDouble = eb_haiku_message_find_double(m.handle, name)
END FUNCTION

FUNCTION HMessageFindBool(BYVAL m AS HMessage, name AS ZSTRING) AS INTEGER
    HMessageFindBool = eb_haiku_message_find_bool(m.handle, name)
END FUNCTION

''' Generic raw-data field - `msgType` is one of the H_ATTR_TYPE_*
''' constants (raw/haiku_shim.bas), `buffer`/`size` a plain caller-owned
''' byte buffer (e.g. `@someArray(0)`). This is how real Haiku's own
''' clipboard text convention works (H_ATTR_TYPE_MIME, field name
''' "text/plain" - see clipboard.bas's own HClipboardSetText/GetText,
''' which already do this correctly). Returns a status code (0 =
''' success).
FUNCTION HMessageAddData(BYVAL m AS HMessage, name AS ZSTRING, BYVAL msgType AS UINTEGER, BYVAL buffer AS ANY PTR, BYVAL size AS INTEGER) AS INTEGER
    HMessageAddData = eb_haiku_message_add_data(m.handle, name, msgType, buffer, size)
END FUNCTION

''' Returns the field's real byte size (>= 0) with `buffer` filled, or
''' a negative status code if absent/wrong type.
FUNCTION HMessageFindData(BYVAL m AS HMessage, name AS ZSTRING, BYVAL msgType AS UINTEGER, BYVAL buffer AS ANY PTR, BYVAL bufferSize AS INTEGER) AS INTEGER
    HMessageFindData = eb_haiku_message_find_data(m.handle, name, msgType, buffer, bufferSize)
END FUNCTION

''' Real BMessage fields support multiple values under one name (an
''' array field, e.g. BMimeType's own GetInstalledTypes/
''' GetFileExtensions, or BRoster's GetRecentDocuments/Folders/Apps).
''' Returns the real item count (>= 0), or a negative status code if
''' `name` isn't present at all. `msgType` is one of the H_ATTR_TYPE_*
''' constants (raw/haiku_shim.bas) - currently unused by the real
''' implementation (BMessage::GetInfo reports a field's own real type
''' regardless), kept for a future type-checked variant.
FUNCTION HMessageCountItems(BYVAL m AS HMessage, name AS ZSTRING, BYVAL msgType AS UINTEGER) AS INTEGER
    HMessageCountItems = eb_haiku_message_count_items(m.handle, name, msgType)
END FUNCTION

''' The `index`-th string value under `name` (see HMessageCountItems) -
''' "" if `name`/`index` isn't present.
FUNCTION HMessageFindStringAt(BYVAL m AS HMessage, name AS ZSTRING, BYVAL index AS INTEGER) AS ZSTRING
    HMessageFindStringAt = eb_haiku_message_find_string_at(m.handle, name, index)
END FUNCTION

''' Fills `outPath` (from HPathCreateEmpty) with the `index`-th
''' entry_ref value under `name` - the real field shape BRoster's own
''' GetRecentDocuments/Folders/Apps use (field name "refs"). Returns a
''' status code (0 = success).
FUNCTION HMessageFindRefAt(BYVAL m AS HMessage, name AS ZSTRING, BYVAL index AS INTEGER, BYVAL outPath AS HPath) AS INTEGER
    HMessageFindRefAt = eb_haiku_message_find_ref_at(m.handle, name, index, outPath.handle)
END FUNCTION

''' Frees an HMessage - call exactly once.
SUB HMessageFree(BYVAL m AS HMessage)
    CALL eb_haiku_message_destroy(m.handle)
END SUB
