' Locale Kit: BCatalog - real translation-catalog lookup. This host has
' no real .catkeys data installed for a throwaway signature, so
' GetString is verified against its own real, documented fallback
' behavior: echoing the key itself back unchanged when no catalog data
' covers it - not an error, the entire point of the real B_TRANSLATE
' macro convention.

#include once "../src/lib.bas"

DIM cat AS HCatalog
cat = HCatalogCreateWithSignature("application/x-vnd.EbHaiku-CatalogBasicsTest", "")

' No real .catkeys data exists for this throwaway signature - InitCheck
' is expected to report a real, non-zero status (no catalog found),
' not asserted to succeed.
DIM checkRc AS INTEGER
checkRc = HCatalogInitCheck(cat)
PRINT "InitCheck rc=", checkRc

DIM countItems AS INTEGER
countItems = HCatalogCountItems(cat)
PRINT "CountItems=", countItems
IF countItems <> 0 THEN
    PRINT "FAIL: expected 0 real translated items for a throwaway signature"
    CALL ExitProcess(1)
END IF

DIM result AS STRING
result = HCatalogGetString(cat, "Hello, world!", "", "")
PRINT "GetString result=", result
IF result <> "Hello, world!" THEN
    PRINT "FAIL: expected the real fallback (the key itself unchanged)"
    CALL ExitProcess(1)
END IF
PRINT "GetString fallback ok"

DIM contextResult AS STRING
contextResult = HCatalogGetString(cat, "Open", "File menu item", "")
PRINT "GetString (with context) result=", contextResult
IF contextResult <> "Open" THEN
    PRINT "FAIL: expected the real fallback with a context argument too"
    CALL ExitProcess(1)
END IF

CALL HCatalogFree(cat)

PRINT "catalog basics test ok"
