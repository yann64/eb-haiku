' Idiomatic layer: BQuery - Haiku's own live, attribute-based
' filesystem query mechanism, with no POSIX equivalent (real, indexed
' search over any file's extended attributes - see node.bas). Bound via
' the plain predicate-string API (HQuerySetPredicate), not the
' Push*/PushOp reverse-polish stack builder - identical expressiveness
' for a single string parameter, e.g. `HQuerySetPredicate(q, "TestInt32
' = 424242")`. Supports both a one-shot HQueryFetch + iterate AND a
' real live HQuerySetTarget path (via the HWatcher primitive below).

#include once "raw/haiku_shim_storage.bas"
#include once "raw/haiku_fs_index.bas"
#include once "entry.bas"
#include once "volume.bas"
#include once "watcher.bas"

''' Creates a real filesystem index for `name` on `device` (an
''' HVolume's own HVolumeDevice) - required before a query predicate on
''' a *custom* attribute (anything not already indexed by default, e.g.
''' via `lsindex`) can match anything at all: BFS query predicates only
''' ever match *indexed* attributes - an attribute with no index simply
''' never matches, silently. `attrType` is one of the H_ATTR_TYPE_*
''' constants (raw/haiku_shim.bas). Returns 0 on success, or a negative
''' status code (already-exists is a real, harmless, common case - most
''' callers can ignore a nonzero result here and proceed to query
''' anyway). Real Haiku's own built-in attributes (name/size/
''' modification time/MIME type, etc.) are already indexed - this is
''' only needed for a custom attribute your own program writes.
'''
''' CRITICAL, confirmed by direct reproduction (a real, silent BFS
''' behavior, not an eb-haiku limitation): indexing is NOT retroactive.
''' An attribute value already written *before* its index existed is
''' never picked up by that index, ever - only writes/updates that
''' happen *after* the index exists get indexed. Call HCreateIndex
''' before writing any attribute you'll later want to query on, not
''' just "sometime before the query" - see tests/query_basics.bas for
''' the correct real ordering.
FUNCTION HCreateIndex(BYVAL device AS UINTEGER, name AS ZSTRING, BYVAL attrType AS UINTEGER) AS INTEGER
    HCreateIndex = fs_create_index(device, name, attrType, 0)
END FUNCTION

TYPE HQuery
    handle AS ANY PTR
END TYPE

FUNCTION HQueryCreate() AS HQuery
    DIM q AS HQuery
    q.handle = eb_haiku_query_create()
    HQueryCreate = q
END FUNCTION

''' Restricts the query to `volume` (real Haiku queries always run
''' against exactly one volume) - required before HQueryFetch. Returns
''' a status code (0 = success).
FUNCTION HQuerySetVolume(BYVAL q AS HQuery, BYVAL volume AS HVolume) AS INTEGER
    HQuerySetVolume = eb_haiku_query_set_volume(q.handle, volume.handle)
END FUNCTION

''' Sets the query's own predicate expression, e.g.
''' `"TestInt32 = 424242"` or `"(Author == ""eBasic"") && (Rating >= 4)"`
''' - real Haiku query-predicate syntax over any attribute name.
''' Returns a status code (0 = success).
FUNCTION HQuerySetPredicate(BYVAL q AS HQuery, expression AS ZSTRING) AS INTEGER
    HQuerySetPredicate = eb_haiku_query_set_predicate(q.handle, expression)
END FUNCTION

''' Runs the query - call after HQuerySetVolume/HQuerySetPredicate,
''' before HQueryGetNextEntry. Returns a status code (0 = success).
FUNCTION HQueryFetch(BYVAL q AS HQuery) AS INTEGER
    HQueryFetch = eb_haiku_query_fetch(q.handle)
END FUNCTION

''' Fills `outEntry` (from HEntryCreateEmpty) with the next matching
''' entry - returns a negative status code once results are exhausted
''' (matching HDirectoryGetNextEntry's own convention).
'''
''' DIM q AS HQuery : q = HQueryCreate()
''' CALL HQuerySetVolume(q, vol)
''' CALL HQuerySetPredicate(q, "TestInt32 = 424242")
''' CALL HQueryFetch(q)
''' DIM e AS HEntry : e = HEntryCreateEmpty()
''' DO WHILE HQueryGetNextEntry(q, e) >= 0
'''     PRINT HEntryName(e)
''' LOOP
FUNCTION HQueryGetNextEntry(BYVAL q AS HQuery, BYVAL outEntry AS HEntry) AS INTEGER
    HQueryGetNextEntry = eb_haiku_query_get_next_entry(q.handle, outEntry.handle)
END FUNCTION

''' Resets iteration back to the first result.
FUNCTION HQueryRewind(BYVAL q AS HQuery) AS INTEGER
    HQueryRewind = eb_haiku_query_rewind(q.handle)
END FUNCTION

''' The total number of matching entries.
FUNCTION HQueryCountEntries(BYVAL q AS HQuery) AS INTEGER
    HQueryCountEntries = eb_haiku_query_count_entries(q.handle)
END FUNCTION

''' Marks this query as *live*: once HQueryFetch is called afterward
''' (still required - see below), real H_QUERY_UPDATE messages (see
''' raw/haiku_shim_storage.bas's own constants) are delivered to
''' `watcher`'s own registered callback as matching entries come and go,
''' in addition to the initial HQueryFetch/GetNextEntry results. Returns
''' a status code (0 = success).
'''
''' IMPORTANT, confirmed by direct reproduction (a standalone C++ probe,
''' before trusting this): HQuerySetTarget alone does NOT establish the
''' real live monitor, even though HQueryIsLive already reports true
''' immediately after it - HQueryFetch is what actually registers the
''' live watch with the kernel (as well as running the initial query),
''' so it must still be called, in this order: HQuerySetVolume ->
''' HQuerySetPredicate -> HQuerySetTarget -> HQueryFetch.
'''
''' DIM msg AS HMessage : msg.handle = messageHandle
''' IF HMessageWhat(msg) = H_QUERY_UPDATE THEN
'''     DIM opcode AS INTEGER : opcode = HMessageFindInt32(msg, "opcode")
'''     IF opcode = H_ENTRY_CREATED THEN ... (fields "device"/"directory"/"name")
FUNCTION HQuerySetTarget(BYVAL q AS HQuery, BYVAL watcher AS HWatcher) AS INTEGER
    HQuerySetTarget = eb_haiku_query_set_target(q.handle, watcher.handle)
END FUNCTION

''' Whether HQuerySetTarget has made this a real live query.
FUNCTION HQueryIsLive(BYVAL q AS HQuery) AS INTEGER
    HQueryIsLive = eb_haiku_query_is_live(q.handle)
END FUNCTION

''' Frees an HQuery - call exactly once.
SUB HQueryFree(BYVAL q AS HQuery)
    CALL eb_haiku_query_destroy(q.handle)
END SUB
