' Idiomatic layer: BFile - minimal, just enough to drive Translation
' Kit's own I/O (a real BPositionIO, passed directly wherever the
' Translation Kit functions need a stream). Not a general Storage Kit
' file-I/O expansion - eBasic's own core File Library already covers
' plain byte-level read/write; this exists specifically because
' BTranslatorRoster::Translate/BTranslationUtils::GetBitmap need a real
' BPositionIO-shaped handle to read from/write to.

#include once "raw/haiku_shim_translation.bas"

TYPE HFile
    handle AS ANY PTR
END TYPE

''' Opens a file for Translation Kit I/O - `openMode` is `H_READ_ONLY`
''' to load, or `H_WRITE_ONLY OR H_CREATE_FILE OR H_ERASE_FILE` to
''' create/overwrite one to save into (eBasic's own `OR` is a real
''' bitwise operator on `INTEGER` operands, matching C's `|` here).
FUNCTION HFileCreate(path AS ZSTRING, BYVAL openMode AS UINTEGER) AS HFile
    DIM f AS HFile
    f.handle = eb_haiku_file_create(path, openMode)
    HFileCreate = f
END FUNCTION

FUNCTION HFileInitCheck(BYVAL f AS HFile) AS INTEGER
    HFileInitCheck = eb_haiku_file_init_check(f.handle)
END FUNCTION

''' Frees a file - call exactly once, once you're done reading/writing
''' through it.
SUB HFileFree(BYVAL f AS HFile)
    CALL eb_haiku_file_destroy(f.handle)
END SUB
