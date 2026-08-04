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
