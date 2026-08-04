' Idiomatic layer: BDirectory.

#include once "raw/haiku_shim.bas"
#include once "raw/haiku_shim_storage.bas"
#include once "entry.bas"

TYPE HDirectory
    handle AS ANY PTR
END TYPE

''' Opens a directory at `path`.
FUNCTION HDirectoryCreate(path AS ZSTRING) AS HDirectory
    DIM d AS HDirectory
    d.handle = eb_haiku_directory_create(path)
    HDirectoryCreate = d
END FUNCTION

FUNCTION HDirectoryInitCheck(BYVAL d AS HDirectory) AS INTEGER
    HDirectoryInitCheck = eb_haiku_directory_init_check(d.handle)
END FUNCTION

''' Fills `outEntry` (from HEntryCreateEmpty) with the directory's next
''' entry - returns a negative status code once iteration is exhausted
''' (check the return value, not HEntryExists, to detect the end).
''' Call HDirectoryRewind first if you need to iterate more than once.
'''
''' DIM d AS HDirectory : d = HDirectoryCreate("/boot/home")
''' DIM e AS HEntry : e = HEntryCreateEmpty()
''' DO WHILE HDirectoryGetNextEntry(d, e) >= 0
'''     PRINT HEntryName(e)
''' LOOP
FUNCTION HDirectoryGetNextEntry(BYVAL d AS HDirectory, BYVAL outEntry AS HEntry) AS INTEGER
    HDirectoryGetNextEntry = eb_haiku_directory_get_next_entry(d.handle, outEntry.handle, 0)
END FUNCTION

''' Resets iteration back to the first entry.
FUNCTION HDirectoryRewind(BYVAL d AS HDirectory) AS INTEGER
    HDirectoryRewind = eb_haiku_directory_rewind(d.handle)
END FUNCTION

''' The total number of entries in the directory (including "." and "..").
FUNCTION HDirectoryCountEntries(BYVAL d AS HDirectory) AS INTEGER
    HDirectoryCountEntries = eb_haiku_directory_count_entries(d.handle)
END FUNCTION

''' Creates a new subdirectory named `path` (relative to `d`, or
''' absolute) - returns a status code (0 = success).
FUNCTION HDirectoryCreateDirectory(BYVAL d AS HDirectory, path AS ZSTRING) AS INTEGER
    HDirectoryCreateDirectory = eb_haiku_directory_create_directory(d.handle, path)
END FUNCTION

''' Creates a real symlink at `path` (relative to `d`, or absolute)
''' pointing at `linkToPath` - returns a status code (0 = success). Open
''' the resulting symlink itself via HSymLinkCreate (symlink.bas) if you
''' need to read it back.
FUNCTION HDirectoryCreateSymLink(BYVAL d AS HDirectory, path AS ZSTRING, linkToPath AS ZSTRING) AS INTEGER
    HDirectoryCreateSymLink = eb_haiku_directory_create_symlink(d.handle, path, linkToPath)
END FUNCTION

''' Frees an HDirectory - call exactly once.
SUB HDirectoryFree(BYVAL d AS HDirectory)
    CALL eb_haiku_directory_destroy(d.handle)
END SUB
