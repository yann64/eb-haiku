' Storage Kit extensions step 5: BQuery - the compelling demo. Writes a
' distinctive int32 attribute on two real test files (and a different
' value on a third, as a negative control), then runs a real query
' predicate matching it, confirming exactly the two expected files come
' back and nothing else.
'
' IMPORTANT, confirmed by direct reproduction (a standalone C++ probe
' hit the identical silent failure before this was understood, and
' Haiku's own `query`/`addattr` command-line tools confirmed it's a
' real BFS behavior, not a binding bug): a query predicate only ever
' matches *indexed* attributes, AND indexing is NOT retroactive - an
' attribute value written *before* its index existed is never picked
' up by that index, silently (no error anywhere). The index must exist
' *before* the attribute is ever written for a query to find it later.
' HCreateIndex is therefore called here first, before any attribute
' writes - not just "somewhere before the query."

#include once "../src/lib.bas"

CONST DIR_PATH = "/boot/home/eb-haiku-query-test"
CONST MATCH_VALUE = 555555

DIM d AS HDirectory
DIM rc AS INTEGER
rc = MkDir(DIR_PATH)
d = HDirectoryCreate(DIR_PATH)
IF HDirectoryInitCheck(d) <> 0 THEN
    PRINT "FAIL: could not open the test directory"
    CALL ExitProcess(1)
END IF

' The query needs its own volume - get it from the directory itself.
DIM dirEntry AS HEntry
dirEntry = HEntryCreate(DIR_PATH)
DIM vol AS HVolume
vol = HVolumeCreateEmpty()
rc = HEntryGetVolume(dirEntry, vol)
IF rc <> 0 THEN
    PRINT "FAIL: HEntryGetVolume returned ", rc
    CALL ExitProcess(1)
END IF
CALL HEntryFree(dirEntry)

' Create the index BEFORE writing any attributes - see this file's own
' top comment. A nonzero result here (e.g. the index already exists
' from a prior run) is not fatal - proceed regardless.
CALL HCreateIndex(HVolumeDevice(vol), "EbHaikuQueryTest", H_ATTR_TYPE_INT32)

CALL WriteFile(DIR_PATH & "/match_a.txt", "a")
CALL WriteFile(DIR_PATH & "/match_b.txt", "b")
CALL WriteFile(DIR_PATH & "/no_match.txt", "c")

DIM na AS HNode
na = HNodeCreate(DIR_PATH & "/match_a.txt")
CALL HNodeWriteAttrInt32(na, "EbHaikuQueryTest", MATCH_VALUE)
CALL HNodeFree(na)

DIM nb AS HNode
nb = HNodeCreate(DIR_PATH & "/match_b.txt")
CALL HNodeWriteAttrInt32(nb, "EbHaikuQueryTest", MATCH_VALUE)
CALL HNodeFree(nb)

DIM nc AS HNode
nc = HNodeCreate(DIR_PATH & "/no_match.txt")
CALL HNodeWriteAttrInt32(nc, "EbHaikuQueryTest", 111111)
CALL HNodeFree(nc)

DIM q AS HQuery
q = HQueryCreate()
rc = HQuerySetVolume(q, vol)
IF rc <> 0 THEN
    PRINT "FAIL: HQuerySetVolume returned ", rc
    CALL ExitProcess(1)
END IF

rc = HQuerySetPredicate(q, "EbHaikuQueryTest = " & Str(MATCH_VALUE))
IF rc <> 0 THEN
    PRINT "FAIL: HQuerySetPredicate returned ", rc
    CALL ExitProcess(1)
END IF

rc = HQueryFetch(q)
IF rc <> 0 THEN
    PRINT "FAIL: HQueryFetch returned ", rc
    CALL ExitProcess(1)
END IF

DIM matchCount AS INTEGER
DIM sawA AS INTEGER
DIM sawB AS INTEGER
DIM sawNoMatch AS INTEGER
matchCount = 0
sawA = 0
sawB = 0
sawNoMatch = 0

DIM e AS HEntry
e = HEntryCreateEmpty()
DO WHILE HQueryGetNextEntry(q, e) >= 0
    DIM entryName AS STRING
    entryName = HEntryName(e)
    PRINT "matched: ", entryName
    matchCount = matchCount + 1
    IF entryName = "match_a.txt" THEN
        sawA = 1
    END IF
    IF entryName = "match_b.txt" THEN
        sawB = 1
    END IF
    IF entryName = "no_match.txt" THEN
        sawNoMatch = 1
    END IF
LOOP
CALL HEntryFree(e)

IF matchCount <> 2 THEN
    PRINT "FAIL: expected exactly 2 matches, got ", matchCount
    CALL ExitProcess(1)
END IF
IF sawA <> 1 OR sawB <> 1 THEN
    PRINT "FAIL: expected both match_a.txt and match_b.txt in the results"
    CALL ExitProcess(1)
END IF
IF sawNoMatch <> 0 THEN
    PRINT "FAIL: no_match.txt should not have matched (negative control)"
    CALL ExitProcess(1)
END IF
PRINT "query results ok"

CALL HQueryFree(q)
CALL HVolumeFree(vol)
CALL HDirectoryFree(d)

' Clean up.
CALL Kill(DIR_PATH & "/match_a.txt")
CALL Kill(DIR_PATH & "/match_b.txt")
CALL Kill(DIR_PATH & "/no_match.txt")
CALL RmDir(DIR_PATH)

PRINT "query basics test ok"
