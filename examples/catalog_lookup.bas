' BCatalog - real translation-catalog lookup. Works even with zero
' .catkeys data installed: GetString echoes the key itself back as the
' real, documented fallback.

#include once "../src/lib.bas"

DIM cat AS HCatalog
cat = HCatalogCreateWithSignature("application/x-vnd.EbHaiku-CatalogExample", "")

DIM greeting AS STRING
greeting = HCatalogGetString(cat, "Hello, world!", "", "")
PRINT greeting

DIM menuItem AS STRING
menuItem = HCatalogGetString(cat, "Open", "File menu item", "")
PRINT menuItem

CALL HCatalogFree(cat)
