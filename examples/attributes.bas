' Haiku's own extended file attributes - tag a file with arbitrary named
' metadata, independent of its byte content. No POSIX equivalent.

#include once "../src/lib.bas"

' A real file needs to exist before attributes can be attached to it -
' eBasic's own core File Library (WriteFile) handles plain file creation
' just fine; this package's own value-add is specifically the
' attributes, not byte-level file I/O.
CALL WriteFile("/boot/home/eb_haiku_example.txt", "hello")

DIM node AS HNode
node = HNodeCreate("/boot/home/eb_haiku_example.txt")

CALL HNodeWriteAttrString(node, "Author", "eBasic")
CALL HNodeWriteAttrString(node, "Status", "draft")

DIM raw AS ANY PTR
raw = HNodeReadAttrString(node, "Author")
IF raw <> 0 THEN
    DIM z AS ZSTRING
    z = raw
    DIM author AS STRING
    author = z
    PRINT author           ' eBasic
    CALL HFreeString(raw)
END IF

' Tag the file's MIME type too.
DIM info AS HNodeInfo
info = HNodeInfoCreate(node)
CALL HNodeInfoSetType(info, "text/plain")
raw = HNodeInfoGetType(info)
IF raw <> 0 THEN
    DIM z2 AS ZSTRING
    z2 = raw
    DIM mimeType AS STRING
    mimeType = z2
    PRINT mimeType          ' text/plain
    CALL HFreeString(raw)
END IF
CALL HNodeInfoFree(info)
CALL HNodeFree(node)

CALL Kill("/boot/home/eb_haiku_example.txt")
