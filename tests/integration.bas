' Full Phase 1 integration test - exercises BPath, BEntry, BDirectory,
' BNode (attributes), BNodeInfo (MIME type), and BMessage against real
' Haiku state. Not run via the normal cross-platform e2e harness (this
' package only builds/links on real Haiku, where libbe.so exists) - run
' by hand (or via this package's own verification script) over SSH to a
' real Haiku host.

#include once "../src/lib.bas"

' ---- BPath ----
DIM p AS HPath
p = HPathCreate("/boot/home/eb_haiku_test_dir")
PRINT HPathInitCheck(p)
PRINT HPathGet(p)
PRINT HPathLeaf(p)
CALL HPathAppend(p, "sub")
PRINT HPathGet(p)
PRINT HPathIsAbsolute(p)

DIM parent AS HPath
parent = HPathCreateEmpty()
CALL HPathGetParent(p, parent)
PRINT HPathGet(parent)
CALL HPathFree(parent)
CALL HPathFree(p)

' ---- BDirectory / BEntry ----
DIM testDirPath AS HPath
testDirPath = HPathCreate("/boot/home/eb_haiku_test_dir")
DIM homeDir AS HDirectory
homeDir = HDirectoryCreate("/boot/home")
CALL HDirectoryCreateDirectory(homeDir, "eb_haiku_test_dir")
CALL HDirectoryFree(homeDir)

DIM testDirEntry AS HEntry
testDirEntry = HEntryCreate("/boot/home/eb_haiku_test_dir")
PRINT HEntryExists(testDirEntry)
PRINT HEntryIsDirectory(testDirEntry)
PRINT HEntryIsFile(testDirEntry)
PRINT HEntryName(testDirEntry)
CALL HEntryFree(testDirEntry)
CALL HPathFree(testDirPath)

DIM testDir AS HDirectory
testDir = HDirectoryCreate("/boot/home/eb_haiku_test_dir")
CALL HDirectoryCreateDirectory(testDir, "child_a")
CALL HDirectoryCreateDirectory(testDir, "child_b")
PRINT HDirectoryCountEntries(testDir)

DIM iterEntry AS HEntry
iterEntry = HEntryCreateEmpty()
DIM foundCount AS INTEGER
foundCount = 0
DO WHILE HDirectoryGetNextEntry(testDir, iterEntry) >= 0
    foundCount = foundCount + 1
LOOP
PRINT foundCount
CALL HEntryFree(iterEntry)
CALL HDirectoryFree(testDir)

' ---- BNode (extended attributes) ----
DIM node AS HNode
node = HNodeCreate("/boot/home/eb_haiku_test_dir")
PRINT HNodeInitCheck(node)
PRINT HNodeWriteAttrString(node, "EbHaikuTestAttr", "hello attribute")

DIM raw AS ANY PTR
raw = HNodeReadAttrString(node, "EbHaikuTestAttr")
DIM attrValue AS STRING
IF raw <> 0 THEN
    DIM z AS ZSTRING
    z = raw
    attrValue = z
    CALL HFreeString(raw)
END IF
PRINT attrValue

raw = HNodeReadAttrString(node, "NoSuchAttr")
PRINT (raw = 0)

PRINT HNodeRemoveAttr(node, "EbHaikuTestAttr")
raw = HNodeReadAttrString(node, "EbHaikuTestAttr")
PRINT (raw = 0)

' ---- BNodeInfo (MIME type) ----
DIM info AS HNodeInfo
info = HNodeInfoCreate(node)
PRINT HNodeInfoSetType(info, "application/x-eb-haiku-test")
raw = HNodeInfoGetType(info)
DIM mimeType AS STRING
IF raw <> 0 THEN
    DIM z2 AS ZSTRING
    z2 = raw
    mimeType = z2
    CALL HFreeString(raw)
END IF
PRINT mimeType
CALL HNodeInfoFree(info)
CALL HNodeFree(node)

' ---- BMessage ----
DIM msg AS HMessage
msg = HMessageCreate(1234)
PRINT HMessageWhat(msg)
CALL HMessageAddString(msg, "name", "eBasic")
CALL HMessageAddInt32(msg, "count", 42)
CALL HMessageAddDouble(msg, "ratio", 3.5)
CALL HMessageAddBool(msg, "active", 1)
PRINT HMessageFindString(msg, "name")
PRINT HMessageFindInt32(msg, "count")
PRINT HMessageFindDouble(msg, "ratio")
PRINT HMessageFindBool(msg, "active")
PRINT HMessageFindString(msg, "no-such-key")
CALL HMessageFree(msg)

' ---- BApplication (lifecycle only - Run() blocks, so just construct/quit) ----
DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-IntegrationTest")
PRINT HApplicationInitCheck(app)
CALL HApplicationFree(app)

' ---- cleanup ----
DIM cleanupDir AS HDirectory
cleanupDir = HDirectoryCreate("/boot/home/eb_haiku_test_dir")
DIM cleanupEntry AS HEntry
cleanupEntry = HEntryCreateEmpty()
DO WHILE HDirectoryGetNextEntry(cleanupDir, cleanupEntry) >= 0
    DIM entryName AS STRING
    DIM entryNameZ AS ZSTRING
    entryNameZ = HEntryName(cleanupEntry)
    entryName = entryNameZ
    IF entryName <> "." AND entryName <> ".." THEN
        CALL HEntryRemove(cleanupEntry)
    END IF
LOOP
CALL HEntryFree(cleanupEntry)
CALL HDirectoryFree(cleanupDir)

DIM cleanupSelf AS HEntry
cleanupSelf = HEntryCreate("/boot/home/eb_haiku_test_dir")
CALL HEntryRemove(cleanupSelf)
CALL HEntryFree(cleanupSelf)

PRINT "eb-haiku integration test ok"
