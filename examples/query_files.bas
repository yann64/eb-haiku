' BQuery - Haiku's own live, attribute-based filesystem search, with no
' POSIX equivalent. Tags a couple of real files with a custom "Rating"
' attribute, then finds them by real query predicate.
'
' IMPORTANT: a query predicate only ever matches *indexed* attributes,
' and indexing is NOT retroactive - HCreateIndex must run before the
' attribute is ever written, not just before the query. See
' HCreateIndex's own doc comment in src/query.bas.

#include once "../src/lib.bas"

CONST DIR_PATH = "/boot/home/eb_haiku_query_example"

CALL MkDir(DIR_PATH)

DIM dirEntry AS HEntry
dirEntry = HEntryCreate(DIR_PATH)
DIM vol AS HVolume
vol = HVolumeCreateEmpty()
CALL HEntryGetVolume(dirEntry, vol)
CALL HEntryFree(dirEntry)

CALL HCreateIndex(HVolumeDevice(vol), "Rating", H_ATTR_TYPE_INT32)

CALL WriteFile(DIR_PATH & "/great.txt", "a great file")
CALL WriteFile(DIR_PATH & "/mediocre.txt", "a mediocre file")

DIM great AS HNode
great = HNodeCreate(DIR_PATH & "/great.txt")
CALL HNodeWriteAttrInt32(great, "Rating", 5)
CALL HNodeFree(great)

DIM mediocre AS HNode
mediocre = HNodeCreate(DIR_PATH & "/mediocre.txt")
CALL HNodeWriteAttrInt32(mediocre, "Rating", 2)
CALL HNodeFree(mediocre)

DIM q AS HQuery
q = HQueryCreate()
CALL HQuerySetVolume(q, vol)
CALL HQuerySetPredicate(q, "Rating >= 4")
CALL HQueryFetch(q)

DIM e AS HEntry
e = HEntryCreateEmpty()
DO WHILE HQueryGetNextEntry(q, e) >= 0
    PRINT HEntryName(e)   ' great.txt
LOOP
CALL HEntryFree(e)

CALL HQueryFree(q)
CALL HVolumeFree(vol)

CALL Kill(DIR_PATH & "/great.txt")
CALL Kill(DIR_PATH & "/mediocre.txt")
CALL RmDir(DIR_PATH)
