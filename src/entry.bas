' Idiomatic layer: BEntry (a reference to a file/directory/symlink by
' location - existence and identity, not an open file handle).

#include once "raw/haiku_shim.bas"
#include once "path.bas"

TYPE HEntry
    handle AS ANY PTR
END TYPE

''' Creates an entry referring to `path` (which need not exist yet).
FUNCTION HEntryCreate(path AS ZSTRING) AS HEntry
    DIM e AS HEntry
    e.handle = eb_haiku_entry_create(path, 0)
    HEntryCreate = e
END FUNCTION

''' An entry with no location set yet - used as an out-parameter for
''' HDirectoryGetNextEntry (see directory.bas).
FUNCTION HEntryCreateEmpty() AS HEntry
    DIM e AS HEntry
    e.handle = eb_haiku_entry_create_empty()
    HEntryCreateEmpty = e
END FUNCTION

FUNCTION HEntryInitCheck(BYVAL e AS HEntry) AS INTEGER
    HEntryInitCheck = eb_haiku_entry_init_check(e.handle)
END FUNCTION

FUNCTION HEntryExists(BYVAL e AS HEntry) AS INTEGER
    HEntryExists = eb_haiku_entry_exists(e.handle)
END FUNCTION

FUNCTION HEntryIsDirectory(BYVAL e AS HEntry) AS INTEGER
    HEntryIsDirectory = eb_haiku_entry_is_directory(e.handle)
END FUNCTION

FUNCTION HEntryIsFile(BYVAL e AS HEntry) AS INTEGER
    HEntryIsFile = eb_haiku_entry_is_file(e.handle)
END FUNCTION

''' The entry's own leaf name (not its full path) - borrowed, valid
''' until HEntryFree.
FUNCTION HEntryName(BYVAL e AS HEntry) AS ZSTRING
    HEntryName = eb_haiku_entry_name(e.handle)
END FUNCTION

''' Fills `outPath` (an already-valid HPath) with this entry's full
''' path. Returns a status code (0 = success).
FUNCTION HEntryGetPath(BYVAL e AS HEntry, BYVAL outPath AS HPath) AS INTEGER
    HEntryGetPath = eb_haiku_entry_get_path(e.handle, outPath.handle)
END FUNCTION

''' Deletes the real file/directory/symlink this entry refers to.
''' Returns a status code (0 = success).
FUNCTION HEntryRemove(BYVAL e AS HEntry) AS INTEGER
    HEntryRemove = eb_haiku_entry_remove(e.handle)
END FUNCTION

''' Renames/moves the real entry to `newPath`. Returns a status code.
FUNCTION HEntryRename(BYVAL e AS HEntry, newPath AS ZSTRING) AS INTEGER
    HEntryRename = eb_haiku_entry_rename(e.handle, newPath, 0)
END FUNCTION

''' Frees an HEntry - call exactly once.
SUB HEntryFree(BYVAL e AS HEntry)
    CALL eb_haiku_entry_destroy(e.handle)
END SUB
