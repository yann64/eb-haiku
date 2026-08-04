' Storage Kit extensions step 3: BSymLink + BDirectory::CreateSymLink -
' create a real symlink, confirm HEntryIsSymLink is true on it, and
' read its target back via HSymLinkReadLink.

#include once "../src/lib.bas"

CONST TARGET_FILE = "/boot/home/eb-haiku-symlink-target.txt"
CONST LINK_PATH = "/boot/home/eb-haiku-symlink-link"

CALL WriteFile(TARGET_FILE, "symlink target")

DIM d AS HDirectory
d = HDirectoryCreate("/boot/home")
IF HDirectoryInitCheck(d) <> 0 THEN
    PRINT "FAIL: could not open /boot/home"
    CALL ExitProcess(1)
END IF

DIM rc AS INTEGER
rc = HDirectoryCreateSymLink(d, LINK_PATH, TARGET_FILE)
IF rc <> 0 THEN
    PRINT "FAIL: HDirectoryCreateSymLink returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "symlink created ok"
CALL HDirectoryFree(d)

' Confirm HEntryIsSymLink is true on the new link (and false on the
' real target file, from the earlier stat_attrs_basics.bas-style check).
DIM linkEntry AS HEntry
linkEntry = HEntryCreate(LINK_PATH)
IF HEntryInitCheck(linkEntry) <> 0 THEN
    PRINT "FAIL: could not open the symlink as an HEntry"
    CALL ExitProcess(1)
END IF
IF HEntryIsSymLink(linkEntry) <> 1 THEN
    PRINT "FAIL: HEntryIsSymLink should be true for a real symlink"
    CALL ExitProcess(1)
END IF
PRINT "HEntryIsSymLink ok"
CALL HEntryFree(linkEntry)

DIM targetEntry AS HEntry
targetEntry = HEntryCreate(TARGET_FILE)
IF HEntryIsSymLink(targetEntry) <> 0 THEN
    PRINT "FAIL: a plain file should not report as a symlink"
    CALL ExitProcess(1)
END IF
CALL HEntryFree(targetEntry)

' Read the symlink's own target back and confirm it matches.
DIM link AS HSymLink
link = HSymLinkCreate(LINK_PATH)
IF HSymLinkInitCheck(link) <> 0 THEN
    PRINT "FAIL: HSymLinkInitCheck on the real symlink"
    CALL ExitProcess(1)
END IF

DIM buf(511) AS BYTE
DIM bufPtr AS ANY PTR
bufPtr = @buf(0)
DIM n AS INTEGER
n = HSymLinkReadLink(link, bufPtr, 512)
IF n <= 0 THEN
    PRINT "FAIL: HSymLinkReadLink returned ", n
    CALL ExitProcess(1)
END IF
buf(n) = 0
DIM targetZ AS ZSTRING
targetZ = bufPtr
DIM target AS STRING
target = targetZ
PRINT "symlink target=", target
IF target <> TARGET_FILE THEN
    PRINT "FAIL: symlink target mismatch"
    CALL ExitProcess(1)
END IF
PRINT "ReadLink ok"

IF HSymLinkIsAbsolute(link) <> 1 THEN
    PRINT "FAIL: symlink target was written as an absolute path"
    CALL ExitProcess(1)
END IF
PRINT "IsAbsolute ok"

CALL HSymLinkFree(link)

' Clean up.
DIM cleanup1 AS HEntry
cleanup1 = HEntryCreate(LINK_PATH)
CALL HEntryRemove(cleanup1)
CALL HEntryFree(cleanup1)
DIM cleanup2 AS HEntry
cleanup2 = HEntryCreate(TARGET_FILE)
CALL HEntryRemove(cleanup2)
CALL HEntryFree(cleanup2)

PRINT "symlink basics test ok"
