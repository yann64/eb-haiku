' Idiomatic layer: BSymLink - real symlinks, a real POSIX-ish feature
' Haiku fully supports. Kept as its own separate opaque type rather
' than reusing HNode's functions (BSymLink IS-A BNode in real Haiku,
' but simplicity/consistency wins over DRY here). Creating a symlink is
' a BDirectory operation - see HDirectoryCreateSymLink in directory.bas.

#include once "raw/haiku_shim_storage.bas"

TYPE HSymLink
    handle AS ANY PTR
END TYPE

''' Opens an existing symlink at `path`.
FUNCTION HSymLinkCreate(path AS ZSTRING) AS HSymLink
    DIM s AS HSymLink
    s.handle = eb_haiku_symlink_create(path)
    HSymLinkCreate = s
END FUNCTION

FUNCTION HSymLinkInitCheck(BYVAL s AS HSymLink) AS INTEGER
    HSymLinkInitCheck = eb_haiku_symlink_init_check(s.handle)
END FUNCTION

''' Reads the symlink's own target path into `buf` (caller-supplied,
''' `bufSize` bytes) - real POSIX `readlink()` semantics, NOT
''' null-terminated automatically. Returns the number of bytes written,
''' or a negative status code.
'''
''' DIM buf(255) AS BYTE
''' DIM n AS INTEGER : n = HSymLinkReadLink(link, @buf(0), 256)
''' IF n >= 0 THEN buf(n) = 0 ' null-terminate before reading as ZSTRING
FUNCTION HSymLinkReadLink(BYVAL s AS HSymLink, BYVAL buf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HSymLinkReadLink = eb_haiku_symlink_read_link(s.handle, buf, bufSize)
END FUNCTION

FUNCTION HSymLinkIsAbsolute(BYVAL s AS HSymLink) AS INTEGER
    HSymLinkIsAbsolute = eb_haiku_symlink_is_absolute(s.handle)
END FUNCTION

''' Frees an HSymLink - call exactly once.
SUB HSymLinkFree(BYVAL s AS HSymLink)
    CALL eb_haiku_symlink_destroy(s.handle)
END SUB
