' Real stat info (permissions/owner/size/timestamps) and typed extended
' attributes (int32/int64/bool/double/raw) - the Storage Kit extensions
' beyond Phase 1's basic path/entry/directory/string-attribute surface.

#include once "../src/lib.bas"

CALL WriteFile("/boot/home/eb_haiku_metadata_example.txt", "hello")

DIM e AS HEntry
e = HEntryCreate("/boot/home/eb_haiku_metadata_example.txt")

PRINT "size=", HEntryGetSize(e)
PRINT "permissions=", HEntryGetPermissions(e)
PRINT "is symlink=", HEntryIsSymLink(e)

' A round-trip: set a known modification time, read it back.
CALL HEntrySetModificationTime(e, 1700000000)
PRINT "modification time=", HEntryGetModificationTime(e)

CALL HEntryFree(e)

' Typed attributes - the practically useful scalar subset beyond
' HNodeWriteAttrString/ReadAttrString (see attributes.bas).
DIM n AS HNode
n = HNodeCreate("/boot/home/eb_haiku_metadata_example.txt")

CALL HNodeWriteAttrInt32(n, "Rating", 5)
DIM rating AS INTEGER
IF HNodeReadAttrInt32(n, "Rating", rating) = 1 THEN
    PRINT "rating=", rating   ' 5
END IF

CALL HNodeWriteAttrBool(n, "Favorite", 1)
DIM favorite AS INTEGER
IF HNodeReadAttrBool(n, "Favorite", favorite) = 1 THEN
    PRINT "favorite=", favorite   ' 1
END IF

CALL HNodeWriteAttrDouble(n, "Score", 9.5)
DIM score AS DOUBLE
IF HNodeReadAttrDouble(n, "Score", score) = 1 THEN
    PRINT "score=", score   ' 9.5
END IF

' GetAttrInfo - introspect an attribute's real type/size before reading
' it (useful for attributes written by another real Haiku app).
DIM attrType AS UINTEGER
DIM attrSize AS LONGINT
IF HNodeGetAttrInfo(n, "Rating", attrType, attrSize) = 0 THEN
    PRINT "Rating attribute size=", attrSize, " bytes"   ' 4 bytes
END IF

CALL HNodeFree(n)

CALL Kill("/boot/home/eb_haiku_metadata_example.txt")
