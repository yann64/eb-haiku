' Idiomatic layer: BCatalog - real translation-catalog lookup.
'
' Real and useful even with zero .catkeys data installed: GetString
' gracefully echoes the key itself back as the real fallback when no
' catalog/translation is found for it (confirmed via header - this is
' the entire point of the real B_TRANSLATE macro convention every
' Haiku app uses). Building the .catkeys data itself is a separate,
' build-time tool pipeline (collectcatkeys/linkcatkeys) - deliberately
' not bound here; this is a runtime lookup API only.
'
' Plain new/delete - BCatalog's own destructor is public and virtual,
' no ref-counting. Only the runtime-facing surface is bound
' (GetString/SetTo/InitCheck/CountItems) - the entry_ref-based
' constructor/SetTo and GetData/GetSignature/GetLanguage/GetFingerprint
' are a reasonable follow-on, not needed for this scope.

#include once "raw/haiku_shim_locale.bas"

TYPE HCatalog
    handle AS ANY PTR
END TYPE

FUNCTION HCatalogCreate() AS HCatalog
    DIM c AS HCatalog
    c.handle = eb_haiku_catalog_create()
    HCatalogCreate = c
END FUNCTION

''' `language` may be "" for the real default (the current system
''' locale).
FUNCTION HCatalogCreateWithSignature(signature AS ZSTRING, language AS ZSTRING) AS HCatalog
    DIM c AS HCatalog
    c.handle = eb_haiku_catalog_create_with_signature(signature, language)
    HCatalogCreateWithSignature = c
END FUNCTION

''' Looks up `str` in the real catalog - `context`/`comment` may be ""
''' for real NULL. Returns the real translated string if one exists,
''' or `str` itself unchanged as the real, documented fallback (not an
''' error) if no catalog data covers this key.
FUNCTION HCatalogGetString(BYVAL c AS HCatalog, str AS ZSTRING, context AS ZSTRING, comment AS ZSTRING) AS ZSTRING
    HCatalogGetString = eb_haiku_catalog_get_string(c.handle, str, context, comment)
END FUNCTION

FUNCTION HCatalogSetTo(BYVAL c AS HCatalog, signature AS ZSTRING, language AS ZSTRING) AS INTEGER
    HCatalogSetTo = eb_haiku_catalog_set_to(c.handle, signature, language)
END FUNCTION

FUNCTION HCatalogInitCheck(BYVAL c AS HCatalog) AS INTEGER
    HCatalogInitCheck = eb_haiku_catalog_init_check(c.handle)
END FUNCTION

''' The real number of translated entries actually loaded (0 if no
''' catalog data was found for this signature/language).
FUNCTION HCatalogCountItems(BYVAL c AS HCatalog) AS INTEGER
    HCatalogCountItems = eb_haiku_catalog_count_items(c.handle)
END FUNCTION

''' Frees an HCatalog - call exactly once.
SUB HCatalogFree(BYVAL c AS HCatalog)
    CALL eb_haiku_catalog_destroy(c.handle)
END SUB
