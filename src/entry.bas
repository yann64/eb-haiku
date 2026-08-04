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

' ---- BStatable (real stat info) - getters return the value directly
' (0/default on failure, matching HEntryName/HDirectoryCountEntries'
' own established convention); setters return a status code (0 =
' success), matching HEntryRemove/HEntryRename.

FUNCTION HEntryIsSymLink(BYVAL e AS HEntry) AS INTEGER
    HEntryIsSymLink = eb_haiku_entry_is_symlink(e.handle)
END FUNCTION

''' Real POSIX file permission bits (e.g. &O644).
FUNCTION HEntryGetPermissions(BYVAL e AS HEntry) AS UINTEGER
    DIM v AS UINTEGER
    CALL eb_haiku_entry_get_permissions(e.handle, @v)
    HEntryGetPermissions = v
END FUNCTION

FUNCTION HEntrySetPermissions(BYVAL e AS HEntry, BYVAL permissions AS UINTEGER) AS INTEGER
    HEntrySetPermissions = eb_haiku_entry_set_permissions(e.handle, permissions)
END FUNCTION

FUNCTION HEntryGetOwner(BYVAL e AS HEntry) AS UINTEGER
    DIM v AS UINTEGER
    CALL eb_haiku_entry_get_owner(e.handle, @v)
    HEntryGetOwner = v
END FUNCTION

FUNCTION HEntrySetOwner(BYVAL e AS HEntry, BYVAL owner AS UINTEGER) AS INTEGER
    HEntrySetOwner = eb_haiku_entry_set_owner(e.handle, owner)
END FUNCTION

FUNCTION HEntryGetGroup(BYVAL e AS HEntry) AS UINTEGER
    DIM v AS UINTEGER
    CALL eb_haiku_entry_get_group(e.handle, @v)
    HEntryGetGroup = v
END FUNCTION

FUNCTION HEntrySetGroup(BYVAL e AS HEntry, BYVAL group AS UINTEGER) AS INTEGER
    HEntrySetGroup = eb_haiku_entry_set_group(e.handle, group)
END FUNCTION

''' The real file size in bytes.
FUNCTION HEntryGetSize(BYVAL e AS HEntry) AS LONGINT
    DIM v AS LONGINT
    CALL eb_haiku_entry_get_size(e.handle, @v)
    HEntryGetSize = v
END FUNCTION

''' A Unix timestamp (seconds since 1970-01-01 UTC).
FUNCTION HEntryGetModificationTime(BYVAL e AS HEntry) AS LONGINT
    DIM v AS LONGINT
    CALL eb_haiku_entry_get_modification_time(e.handle, @v)
    HEntryGetModificationTime = v
END FUNCTION

FUNCTION HEntrySetModificationTime(BYVAL e AS HEntry, BYVAL time AS LONGINT) AS INTEGER
    HEntrySetModificationTime = eb_haiku_entry_set_modification_time(e.handle, time)
END FUNCTION

FUNCTION HEntryGetCreationTime(BYVAL e AS HEntry) AS LONGINT
    DIM v AS LONGINT
    CALL eb_haiku_entry_get_creation_time(e.handle, @v)
    HEntryGetCreationTime = v
END FUNCTION

FUNCTION HEntrySetCreationTime(BYVAL e AS HEntry, BYVAL time AS LONGINT) AS INTEGER
    HEntrySetCreationTime = eb_haiku_entry_set_creation_time(e.handle, time)
END FUNCTION
