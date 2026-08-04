' Storage Kit extensions step 1+2: BStatable (permissions/owner/group/
' size/timestamps) on HEntry/HNode, and BNode typed attributes
' (int32/int64/bool/double/raw) + GetAttrInfo.

#include once "../src/lib.bas"

CONST TEST_FILE = "/boot/home/eb-haiku-stat-test.txt"

' Create a real file with known content via eBasic's own core File
' Library (plain byte-level I/O, unrelated to Storage Kit).
CALL WriteFile(TEST_FILE, "hello eb-haiku")

' ---- BStatable via HEntry ----

DIM e AS HEntry
e = HEntryCreate(TEST_FILE)
IF HEntryInitCheck(e) <> 0 THEN
    PRINT "FAIL: HEntryInitCheck on the real test file"
    CALL ExitProcess(1)
END IF

IF HEntryIsSymLink(e) <> 0 THEN
    PRINT "FAIL: a plain file should not be a symlink"
    CALL ExitProcess(1)
END IF

DIM size AS LONGINT
size = HEntryGetSize(e)
IF size <= 0 THEN
    PRINT "FAIL: HEntryGetSize should be positive, got ", size
    CALL ExitProcess(1)
END IF
PRINT "entry size=", size

DIM perms AS UINTEGER
perms = HEntryGetPermissions(e)
IF perms = 0 THEN
    PRINT "FAIL: HEntryGetPermissions returned 0"
    CALL ExitProcess(1)
END IF
PRINT "entry permissions=", perms

DIM rc AS INTEGER
rc = HEntrySetPermissions(e, perms)
IF rc <> 0 THEN
    PRINT "FAIL: HEntrySetPermissions returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "set permissions ok"

DIM owner AS UINTEGER
owner = HEntryGetOwner(e)
PRINT "entry owner=", owner

DIM grp AS UINTEGER
grp = HEntryGetGroup(e)
PRINT "entry group=", grp

' Modification-time round-trip: set a known, distinctive timestamp,
' read it back, confirm it matches exactly.
CONST KNOWN_TIME = 1000000000
rc = HEntrySetModificationTime(e, KNOWN_TIME)
IF rc <> 0 THEN
    PRINT "FAIL: HEntrySetModificationTime returned ", rc
    CALL ExitProcess(1)
END IF
DIM mtime AS LONGINT
mtime = HEntryGetModificationTime(e)
IF mtime <> KNOWN_TIME THEN
    PRINT "FAIL: modification time round-trip mismatch, got ", mtime
    CALL ExitProcess(1)
END IF
PRINT "modification time round-trip ok"

CALL HEntryFree(e)

' ---- BStatable via HNode (same file, different handle type) ----

DIM n AS HNode
n = HNodeCreate(TEST_FILE)
IF HNodeInitCheck(n) <> 0 THEN
    PRINT "FAIL: HNodeInitCheck on the real test file"
    CALL ExitProcess(1)
END IF

DIM nodeSize AS LONGINT
nodeSize = HNodeGetSize(n)
IF nodeSize <> size THEN
    PRINT "FAIL: HNodeGetSize should match HEntryGetSize, got ", nodeSize
    CALL ExitProcess(1)
END IF
PRINT "node/entry size agreement ok"

' ---- BNode typed attributes ----

rc = HNodeWriteAttrInt32(n, "TestInt32", 424242)
IF rc < 0 THEN
    PRINT "FAIL: HNodeWriteAttrInt32 returned ", rc
    CALL ExitProcess(1)
END IF
DIM i32 AS INTEGER
IF HNodeReadAttrInt32(n, "TestInt32", i32) <> 1 THEN
    PRINT "FAIL: HNodeReadAttrInt32 did not find the attribute"
    CALL ExitProcess(1)
END IF
IF i32 <> 424242 THEN
    PRINT "FAIL: int32 attribute round-trip mismatch, got ", i32
    CALL ExitProcess(1)
END IF
PRINT "int32 attribute round-trip ok"

rc = HNodeWriteAttrInt64(n, "TestInt64", 9000000000)
DIM i64 AS LONGINT
IF HNodeReadAttrInt64(n, "TestInt64", i64) <> 1 OR i64 <> 9000000000 THEN
    PRINT "FAIL: int64 attribute round-trip mismatch, got ", i64
    CALL ExitProcess(1)
END IF
PRINT "int64 attribute round-trip ok"

rc = HNodeWriteAttrBool(n, "TestBool", 1)
DIM b AS INTEGER
IF HNodeReadAttrBool(n, "TestBool", b) <> 1 OR b <> 1 THEN
    PRINT "FAIL: bool attribute round-trip mismatch, got ", b
    CALL ExitProcess(1)
END IF
PRINT "bool attribute round-trip ok"

rc = HNodeWriteAttrDouble(n, "TestDouble", 3.5)
DIM d AS DOUBLE
IF HNodeReadAttrDouble(n, "TestDouble", d) <> 1 OR d <> 3.5 THEN
    PRINT "FAIL: double attribute round-trip mismatch, got ", d
    CALL ExitProcess(1)
END IF
PRINT "double attribute round-trip ok"

' GetAttrInfo introspection - confirm the real type/size match what
' was written for the int32 attribute above.
DIM attrType AS UINTEGER
DIM attrSize AS LONGINT
rc = HNodeGetAttrInfo(n, "TestInt32", attrType, attrSize)
IF rc <> 0 THEN
    PRINT "FAIL: HNodeGetAttrInfo returned ", rc
    CALL ExitProcess(1)
END IF
IF attrType <> H_ATTR_TYPE_INT32 THEN
    PRINT "FAIL: GetAttrInfo type mismatch, got ", attrType
    CALL ExitProcess(1)
END IF
IF attrSize <> 4 THEN
    PRINT "FAIL: GetAttrInfo size mismatch, got ", attrSize
    CALL ExitProcess(1)
END IF
PRINT "GetAttrInfo introspection ok"

' Raw escape hatch round-trip.
DIM rawOut(7) AS BYTE
rawOut(0) = 1
rawOut(1) = 2
rawOut(2) = 3
rawOut(3) = 4
rc = HNodeWriteAttrRaw(n, "TestRaw", @rawOut(0), 4)
IF rc <> 4 THEN
    PRINT "FAIL: HNodeWriteAttrRaw returned ", rc
    CALL ExitProcess(1)
END IF
DIM rawIn(7) AS BYTE
rc = HNodeReadAttrRaw(n, "TestRaw", @rawIn(0), 8)
IF rc <> 4 THEN
    PRINT "FAIL: HNodeReadAttrRaw returned ", rc
    CALL ExitProcess(1)
END IF
IF rawIn(0) <> 1 OR rawIn(1) <> 2 OR rawIn(2) <> 3 OR rawIn(3) <> 4 THEN
    PRINT "FAIL: raw attribute round-trip mismatch"
    CALL ExitProcess(1)
END IF
PRINT "raw attribute round-trip ok"

CALL HNodeFree(n)

' Clean up the real test file.
DIM cleanup AS HEntry
cleanup = HEntryCreate(TEST_FILE)
CALL HEntryRemove(cleanup)
CALL HEntryFree(cleanup)

PRINT "stat/attrs basics test ok"
