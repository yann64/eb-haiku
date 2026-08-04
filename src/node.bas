' Idiomatic layer: BNode's extended file attributes, and BNodeInfo's
' MIME type - Haiku's own most distinctive filesystem feature, with no
' POSIX equivalent (every file can carry arbitrary named, typed
' metadata, independent of its actual byte content). Not overlapping
' with eBasic's own File Library (plain byte-level read/write) at all.

#include once "raw/haiku_shim.bas"

TYPE HNode
    handle AS ANY PTR
END TYPE

FUNCTION HNodeCreate(path AS ZSTRING) AS HNode
    DIM n AS HNode
    n.handle = eb_haiku_node_create(path)
    HNodeCreate = n
END FUNCTION

FUNCTION HNodeInitCheck(BYVAL n AS HNode) AS INTEGER
    HNodeInitCheck = eb_haiku_node_init_check(n.handle)
END FUNCTION

''' Writes `value` as a string-typed attribute named `name` on this
''' node's real file. Returns the number of bytes written (>= 0), or a
''' negative status code.
FUNCTION HNodeWriteAttrString(BYVAL n AS HNode, name AS ZSTRING, value AS ZSTRING) AS INTEGER
    HNodeWriteAttrString = eb_haiku_node_write_attr_string(n.handle, name, value)
END FUNCTION

''' Reads a string-typed attribute - a null ANY PTR if it doesn't exist.
''' Returns a freshly heap-allocated string, not a borrowed reference -
''' free the result via HFreeString once read. Not exported as STRING:
''' no top-level STRING-returning function can cross this package's own
''' `--lib` boundary (same restriction, and same fix, as `eb-cjson`'s
''' own `JsonStringify` - see that package's own README).
'''
''' DIM raw AS ANY PTR : raw = HNodeReadAttrString(n, "MyAttr")
''' IF raw <> 0 THEN
'''     DIM z AS ZSTRING : z = raw
'''     DIM s AS STRING : s = z
'''     CALL HFreeString(raw)
''' END IF
FUNCTION HNodeReadAttrString(BYVAL n AS HNode, name AS ZSTRING) AS ANY PTR
    HNodeReadAttrString = eb_haiku_node_read_attr_string(n.handle, name)
END FUNCTION

''' Removes an attribute - returns a status code (0 = success).
FUNCTION HNodeRemoveAttr(BYVAL n AS HNode, name AS ZSTRING) AS INTEGER
    HNodeRemoveAttr = eb_haiku_node_remove_attr(n.handle, name)
END FUNCTION

''' Resets attribute iteration back to the first attribute.
FUNCTION HNodeRewindAttrs(BYVAL n AS HNode) AS INTEGER
    HNodeRewindAttrs = eb_haiku_node_rewind_attrs(n.handle)
END FUNCTION

''' The next attribute's name - a null ANY PTR once iteration is
''' exhausted. Same ownership/bridging rules as HNodeReadAttrString
''' (see its own doc comment) - free each non-null result via
''' HFreeString.
'''
''' DIM n AS HNode : n = HNodeCreate("/boot/home/file.txt")
''' CALL HNodeRewindAttrs(n)
''' DIM raw AS ANY PTR
''' raw = HNodeGetNextAttrName(n)
''' DO WHILE raw <> 0
'''     DIM z AS ZSTRING : z = raw
'''     PRINT z
'''     CALL HFreeString(raw)
'''     raw = HNodeGetNextAttrName(n)
''' LOOP
FUNCTION HNodeGetNextAttrName(BYVAL n AS HNode) AS ANY PTR
    HNodeGetNextAttrName = eb_haiku_node_get_next_attr_name(n.handle)
END FUNCTION

''' Frees a string returned by HNodeReadAttrString, HNodeGetNextAttrName,
''' or HNodeInfoGetType.
SUB HFreeString(rawPtr AS ANY PTR)
    CALL eb_haiku_free_string(rawPtr)
END SUB

''' Frees an HNode - call exactly once.
SUB HNodeFree(BYVAL n AS HNode)
    CALL eb_haiku_node_destroy(n.handle)
END SUB

' ---- BStatable (real stat info) - same getter/setter convention as
' HEntry's own (see entry.bas) - getters return the value directly,
' setters return a status code.

FUNCTION HNodeGetPermissions(BYVAL n AS HNode) AS UINTEGER
    DIM v AS UINTEGER
    CALL eb_haiku_node_get_permissions(n.handle, @v)
    HNodeGetPermissions = v
END FUNCTION

FUNCTION HNodeSetPermissions(BYVAL n AS HNode, BYVAL permissions AS UINTEGER) AS INTEGER
    HNodeSetPermissions = eb_haiku_node_set_permissions(n.handle, permissions)
END FUNCTION

FUNCTION HNodeGetOwner(BYVAL n AS HNode) AS UINTEGER
    DIM v AS UINTEGER
    CALL eb_haiku_node_get_owner(n.handle, @v)
    HNodeGetOwner = v
END FUNCTION

FUNCTION HNodeSetOwner(BYVAL n AS HNode, BYVAL owner AS UINTEGER) AS INTEGER
    HNodeSetOwner = eb_haiku_node_set_owner(n.handle, owner)
END FUNCTION

FUNCTION HNodeGetGroup(BYVAL n AS HNode) AS UINTEGER
    DIM v AS UINTEGER
    CALL eb_haiku_node_get_group(n.handle, @v)
    HNodeGetGroup = v
END FUNCTION

FUNCTION HNodeSetGroup(BYVAL n AS HNode, BYVAL group AS UINTEGER) AS INTEGER
    HNodeSetGroup = eb_haiku_node_set_group(n.handle, group)
END FUNCTION

FUNCTION HNodeGetSize(BYVAL n AS HNode) AS LONGINT
    DIM v AS LONGINT
    CALL eb_haiku_node_get_size(n.handle, @v)
    HNodeGetSize = v
END FUNCTION

FUNCTION HNodeGetModificationTime(BYVAL n AS HNode) AS LONGINT
    DIM v AS LONGINT
    CALL eb_haiku_node_get_modification_time(n.handle, @v)
    HNodeGetModificationTime = v
END FUNCTION

FUNCTION HNodeSetModificationTime(BYVAL n AS HNode, BYVAL time AS LONGINT) AS INTEGER
    HNodeSetModificationTime = eb_haiku_node_set_modification_time(n.handle, time)
END FUNCTION

FUNCTION HNodeGetCreationTime(BYVAL n AS HNode) AS LONGINT
    DIM v AS LONGINT
    CALL eb_haiku_node_get_creation_time(n.handle, @v)
    HNodeGetCreationTime = v
END FUNCTION

FUNCTION HNodeSetCreationTime(BYVAL n AS HNode, BYVAL time AS LONGINT) AS INTEGER
    HNodeSetCreationTime = eb_haiku_node_set_creation_time(n.handle, time)
END FUNCTION

' ---- BNode typed attributes (beyond string, see HNodeWriteAttrString/
' HNodeReadAttrString above) - each Write* returns bytes written (>= 0)
' or a negative status code, matching HNodeWriteAttrString. Each Read*
' returns 1 (found, `outValue` filled) or 0 (absent/wrong type) -
' distinguishable from a valid zero value, unlike a bare sentinel.

FUNCTION HNodeWriteAttrInt32(BYVAL n AS HNode, name AS ZSTRING, BYVAL value AS INTEGER) AS INTEGER
    HNodeWriteAttrInt32 = eb_haiku_node_write_attr_int32(n.handle, name, value)
END FUNCTION

FUNCTION HNodeReadAttrInt32(BYVAL n AS HNode, name AS ZSTRING, BYREF outValue AS INTEGER) AS INTEGER
    DIM v AS INTEGER
    DIM found AS INTEGER
    found = eb_haiku_node_read_attr_int32(n.handle, name, @v)
    outValue = v
    HNodeReadAttrInt32 = found
END FUNCTION

FUNCTION HNodeWriteAttrInt64(BYVAL n AS HNode, name AS ZSTRING, BYVAL value AS LONGINT) AS INTEGER
    HNodeWriteAttrInt64 = eb_haiku_node_write_attr_int64(n.handle, name, value)
END FUNCTION

FUNCTION HNodeReadAttrInt64(BYVAL n AS HNode, name AS ZSTRING, BYREF outValue AS LONGINT) AS INTEGER
    DIM v AS LONGINT
    DIM found AS INTEGER
    found = eb_haiku_node_read_attr_int64(n.handle, name, @v)
    outValue = v
    HNodeReadAttrInt64 = found
END FUNCTION

FUNCTION HNodeWriteAttrBool(BYVAL n AS HNode, name AS ZSTRING, BYVAL value AS INTEGER) AS INTEGER
    HNodeWriteAttrBool = eb_haiku_node_write_attr_bool(n.handle, name, value)
END FUNCTION

FUNCTION HNodeReadAttrBool(BYVAL n AS HNode, name AS ZSTRING, BYREF outValue AS INTEGER) AS INTEGER
    DIM v AS INTEGER
    DIM found AS INTEGER
    found = eb_haiku_node_read_attr_bool(n.handle, name, @v)
    outValue = v
    HNodeReadAttrBool = found
END FUNCTION

FUNCTION HNodeWriteAttrDouble(BYVAL n AS HNode, name AS ZSTRING, BYVAL value AS DOUBLE) AS INTEGER
    HNodeWriteAttrDouble = eb_haiku_node_write_attr_double(n.handle, name, value)
END FUNCTION

FUNCTION HNodeReadAttrDouble(BYVAL n AS HNode, name AS ZSTRING, BYREF outValue AS DOUBLE) AS INTEGER
    DIM v AS DOUBLE
    DIM found AS INTEGER
    found = eb_haiku_node_read_attr_double(n.handle, name, @v)
    outValue = v
    HNodeReadAttrDouble = found
END FUNCTION

''' Low-level escape hatch (B_RAW_TYPE) for any attribute type not
''' covered by the typed variants above - `buffer`/`size` are a plain
''' caller-owned byte buffer (e.g. `@someArray(0)`), matching this
''' package's own established out-buffer convention. Returns bytes
''' written/read (>= 0), or a negative status code.
FUNCTION HNodeWriteAttrRaw(BYVAL n AS HNode, name AS ZSTRING, BYVAL buffer AS ANY PTR, BYVAL size AS INTEGER) AS INTEGER
    HNodeWriteAttrRaw = eb_haiku_node_write_attr_raw(n.handle, name, buffer, size)
END FUNCTION

FUNCTION HNodeReadAttrRaw(BYVAL n AS HNode, name AS ZSTRING, BYVAL buffer AS ANY PTR, BYVAL bufferSize AS INTEGER) AS INTEGER
    HNodeReadAttrRaw = eb_haiku_node_read_attr_raw(n.handle, name, buffer, bufferSize)
END FUNCTION

''' Fills `outType`/`outSize` with an existing attribute's own real
''' type_code (one of the H_ATTR_TYPE_* constants in
''' raw/haiku_shim.bas) and size in bytes - use before HNodeReadAttrRaw
''' on an attribute of unknown shape (e.g. written by another real
''' Haiku app). Returns a status code (0 = success).
FUNCTION HNodeGetAttrInfo(BYVAL n AS HNode, name AS ZSTRING, BYREF outType AS UINTEGER, BYREF outSize AS LONGINT) AS INTEGER
    DIM t AS UINTEGER
    DIM s AS LONGINT
    DIM rc AS INTEGER
    rc = eb_haiku_node_get_attr_info(n.handle, name, @t, @s)
    outType = t
    outSize = s
    HNodeGetAttrInfo = rc
END FUNCTION

TYPE HNodeInfo
    handle AS ANY PTR
END TYPE

''' Wraps `n` for MIME-type access - does not take ownership of `n`
''' (free `n` separately, after this HNodeInfo, via HNodeFree).
FUNCTION HNodeInfoCreate(BYVAL n AS HNode) AS HNodeInfo
    DIM info AS HNodeInfo
    info.handle = eb_haiku_nodeinfo_create(n.handle)
    HNodeInfoCreate = info
END FUNCTION

''' The node's MIME type - a null ANY PTR if none is set. Same
''' ownership/bridging rules as HNodeReadAttrString (see its own doc
''' comment) - free a non-null result via HFreeString.
FUNCTION HNodeInfoGetType(BYVAL info AS HNodeInfo) AS ANY PTR
    HNodeInfoGetType = eb_haiku_nodeinfo_get_type(info.handle)
END FUNCTION

''' Sets the node's MIME type - returns a status code (0 = success).
FUNCTION HNodeInfoSetType(BYVAL info AS HNodeInfo, mimeType AS ZSTRING) AS INTEGER
    HNodeInfoSetType = eb_haiku_nodeinfo_set_type(info.handle, mimeType)
END FUNCTION

''' Frees an HNodeInfo - call exactly once. Does not free the underlying
''' HNode (see HNodeInfoCreate's own doc comment).
SUB HNodeInfoFree(BYVAL info AS HNodeInfo)
    CALL eb_haiku_nodeinfo_destroy(info.handle)
END SUB
