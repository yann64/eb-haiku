' Lists every entry directly inside /boot/home, noting which are
' directories.

#include once "../src/lib.bas"

DIM dir AS HDirectory
dir = HDirectoryCreate("/boot/home")

DIM entry AS HEntry
entry = HEntryCreateEmpty()

DO WHILE HDirectoryGetNextEntry(dir, entry) >= 0
    DIM nameZ AS ZSTRING
    nameZ = HEntryName(entry)
    DIM name AS STRING
    name = nameZ
    IF HEntryIsDirectory(entry) <> 0 THEN
        PRINT name & "/"
    ELSE
        PRINT name
    END IF
LOOP

CALL HEntryFree(entry)
CALL HDirectoryFree(dir)
