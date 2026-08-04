' BPath basics: build a path, inspect it, find its parent.

#include once "../src/lib.bas"

DIM p AS HPath
p = HPathCreate("/boot/home/Documents")
CALL HPathAppend(p, "notes.txt")
PRINT HPathGet(p)     ' /boot/home/Documents/notes.txt
PRINT HPathLeaf(p)    ' notes.txt

DIM parent AS HPath
parent = HPathCreateEmpty()
CALL HPathGetParent(p, parent)
PRINT HPathGet(parent) ' /boot/home/Documents

CALL HPathFree(parent)
CALL HPathFree(p)
