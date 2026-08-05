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

' ---- BMemoryIO/BMallocIO - both real BPositionIO subclasses, usable
' anywhere HFile already is (e.g. as HTranslatorRosterTranslate's own
' sourceStream/destinationStream). BMemoryIO wraps a caller-owned
' buffer (non-owning - you must keep it alive and free it yourself);
' BMallocIO self-manages its own growable buffer. ----

TYPE HMemoryIO
    handle AS ANY PTR
END TYPE

''' Wraps an existing, caller-owned buffer (e.g. `@someArray(0)`) as a
''' writable Translation-Kit-compatible stream - non-owning, the caller
''' must keep `ioData` alive and free it themselves.
FUNCTION HMemoryIOCreate(BYVAL ioData AS ANY PTR, BYVAL ioLength AS ULONGINT) AS HMemoryIO
    DIM m AS HMemoryIO
    m.handle = eb_haiku_memory_io_create(ioData, ioLength)
    HMemoryIOCreate = m
END FUNCTION

''' Same as HMemoryIOCreate, but read-only (real BMemoryIO(const
''' void*, size_t) overload) - use when `ioData` itself is read-only.
FUNCTION HMemoryIOCreateReadOnly(BYVAL ioData AS ANY PTR, BYVAL ioLength AS ULONGINT) AS HMemoryIO
    DIM m AS HMemoryIO
    m.handle = eb_haiku_memory_io_create_read_only(ioData, ioLength)
    HMemoryIOCreateReadOnly = m
END FUNCTION

''' Frees an HMemoryIO - call exactly once. Does NOT free the
''' underlying buffer you supplied to HMemoryIOCreate/CreateReadOnly.
SUB HMemoryIOFree(BYVAL m AS HMemoryIO)
    CALL eb_haiku_memory_io_destroy(m.handle)
END SUB

TYPE HMallocIO
    handle AS ANY PTR
END TYPE

''' A self-growing, Translation-Kit-compatible in-memory stream - no
''' caller-supplied buffer needed.
FUNCTION HMallocIOCreate() AS HMallocIO
    DIM m AS HMallocIO
    m.handle = eb_haiku_malloc_io_create()
    HMallocIOCreate = m
END FUNCTION

SUB HMallocIOSetBlockSize(BYVAL m AS HMallocIO, BYVAL blockSize AS ULONGINT)
    CALL eb_haiku_malloc_io_set_block_size(m.handle, blockSize)
END SUB

''' The real, current read-only pointer to this stream's own internal
''' buffer - valid only until the next write grows it.
FUNCTION HMallocIOBuffer(BYVAL m AS HMallocIO) AS ANY PTR
    HMallocIOBuffer = eb_haiku_malloc_io_buffer(m.handle)
END FUNCTION

FUNCTION HMallocIOBufferLength(BYVAL m AS HMallocIO) AS ULONGINT
    HMallocIOBufferLength = eb_haiku_malloc_io_buffer_length(m.handle)
END FUNCTION

''' Frees an HMallocIO - call exactly once.
SUB HMallocIOFree(BYVAL m AS HMallocIO)
    CALL eb_haiku_malloc_io_destroy(m.handle)
END SUB
