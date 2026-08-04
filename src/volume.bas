' Idiomatic layer: BVolume/BVolumeRoster - real mounted-volume/disk
' info (capacity, free space, name, read-only/removable/persistent
' flags). Also HEntryGetVolume/HNodeGetVolume (BStatable::GetVolume) -
' defined here rather than in entry.bas/node.bas since both need the
' HVolume type this file itself introduces.

#include once "raw/haiku_shim_storage.bas"
#include once "entry.bas"
#include once "node.bas"
#include once "watcher.bas"

TYPE HVolume
    handle AS ANY PTR
END TYPE

''' An unset volume - used as an out-parameter for
''' HVolumeRosterGetNextVolume/GetBootVolume, HEntryGetVolume, and
''' HNodeGetVolume.
FUNCTION HVolumeCreateEmpty() AS HVolume
    DIM v AS HVolume
    v.handle = eb_haiku_volume_create_empty()
    HVolumeCreateEmpty = v
END FUNCTION

FUNCTION HVolumeInitCheck(BYVAL v AS HVolume) AS INTEGER
    HVolumeInitCheck = eb_haiku_volume_init_check(v.handle)
END FUNCTION

''' The volume's own real device id - needed by HCreateIndex
''' (query.bas) to target fs_create_index at this specific volume.
FUNCTION HVolumeDevice(BYVAL v AS HVolume) AS UINTEGER
    HVolumeDevice = eb_haiku_volume_device(v.handle)
END FUNCTION

''' The volume's real total capacity, in bytes.
FUNCTION HVolumeCapacity(BYVAL v AS HVolume) AS LONGINT
    DIM cap AS LONGINT
    CALL eb_haiku_volume_capacity(v.handle, @cap)
    HVolumeCapacity = cap
END FUNCTION

''' The volume's real free space, in bytes.
FUNCTION HVolumeFreeBytes(BYVAL v AS HVolume) AS LONGINT
    DIM freeBytes AS LONGINT
    CALL eb_haiku_volume_free_bytes(v.handle, @freeBytes)
    HVolumeFreeBytes = freeBytes
END FUNCTION

''' Fills `outName` (caller-supplied, at least 256 bytes) with the
''' volume's real name. Returns a status code (0 = success).
'''
''' DIM buf(255) AS BYTE
''' CALL HVolumeGetName(v, @buf(0))
FUNCTION HVolumeGetName(BYVAL v AS HVolume, BYVAL outName AS ANY PTR) AS INTEGER
    HVolumeGetName = eb_haiku_volume_get_name(v.handle, outName)
END FUNCTION

FUNCTION HVolumeIsReadOnly(BYVAL v AS HVolume) AS INTEGER
    HVolumeIsReadOnly = eb_haiku_volume_is_read_only(v.handle)
END FUNCTION

FUNCTION HVolumeIsRemovable(BYVAL v AS HVolume) AS INTEGER
    HVolumeIsRemovable = eb_haiku_volume_is_removable(v.handle)
END FUNCTION

FUNCTION HVolumeIsPersistent(BYVAL v AS HVolume) AS INTEGER
    HVolumeIsPersistent = eb_haiku_volume_is_persistent(v.handle)
END FUNCTION

FUNCTION HVolumeIsShared(BYVAL v AS HVolume) AS INTEGER
    HVolumeIsShared = eb_haiku_volume_is_shared(v.handle)
END FUNCTION

FUNCTION HVolumeKnowsMime(BYVAL v AS HVolume) AS INTEGER
    HVolumeKnowsMime = eb_haiku_volume_knows_mime(v.handle)
END FUNCTION

FUNCTION HVolumeKnowsAttr(BYVAL v AS HVolume) AS INTEGER
    HVolumeKnowsAttr = eb_haiku_volume_knows_attr(v.handle)
END FUNCTION

FUNCTION HVolumeKnowsQuery(BYVAL v AS HVolume) AS INTEGER
    HVolumeKnowsQuery = eb_haiku_volume_knows_query(v.handle)
END FUNCTION

''' Frees an HVolume - call exactly once.
SUB HVolumeFree(BYVAL v AS HVolume)
    CALL eb_haiku_volume_destroy(v.handle)
END SUB

''' Fills `outVolume` with the volume this entry lives on. Returns a
''' status code (0 = success).
FUNCTION HEntryGetVolume(BYVAL e AS HEntry, BYVAL outVolume AS HVolume) AS INTEGER
    HEntryGetVolume = eb_haiku_entry_get_volume(e.handle, outVolume.handle)
END FUNCTION

''' Same as HEntryGetVolume, for an HNode.
FUNCTION HNodeGetVolume(BYVAL n AS HNode, BYVAL outVolume AS HVolume) AS INTEGER
    HNodeGetVolume = eb_haiku_node_get_volume(n.handle, outVolume.handle)
END FUNCTION

TYPE HVolumeRoster
    handle AS ANY PTR
END TYPE

FUNCTION HVolumeRosterCreate() AS HVolumeRoster
    DIM r AS HVolumeRoster
    r.handle = eb_haiku_volume_roster_create()
    HVolumeRosterCreate = r
END FUNCTION

''' Fills `outVolume` (from HVolumeCreateEmpty) with the next mounted
''' volume - returns a negative status code once iteration is
''' exhausted (matching HDirectoryGetNextEntry's own convention). Call
''' HVolumeRosterRewind first if you need to iterate more than once.
FUNCTION HVolumeRosterGetNextVolume(BYVAL r AS HVolumeRoster, BYVAL outVolume AS HVolume) AS INTEGER
    HVolumeRosterGetNextVolume = eb_haiku_volume_roster_get_next_volume(r.handle, outVolume.handle)
END FUNCTION

SUB HVolumeRosterRewind(BYVAL r AS HVolumeRoster)
    CALL eb_haiku_volume_roster_rewind(r.handle)
END SUB

''' Fills `outVolume` with the volume Haiku itself was booted from.
''' Returns a status code (0 = success).
FUNCTION HVolumeRosterGetBootVolume(BYVAL r AS HVolumeRoster, BYVAL outVolume AS HVolume) AS INTEGER
    HVolumeRosterGetBootVolume = eb_haiku_volume_roster_get_boot_volume(r.handle, outVolume.handle)
END FUNCTION

''' Makes `watcher` a real live target for mount/unmount notifications -
''' real H_NODE_MONITOR messages (see raw/haiku_shim_storage.bas's own
''' constants) are delivered to its own registered callback whenever a
''' volume is mounted/unmounted anywhere on the system, with an
''' "opcode" field of H_DEVICE_MOUNTED/H_DEVICE_UNMOUNTED and a "new
''' device" int32 field (the mounted volume's own dev_t). Returns a
''' status code (0 = success).
FUNCTION HVolumeRosterStartWatching(BYVAL r AS HVolumeRoster, BYVAL watcher AS HWatcher) AS INTEGER
    HVolumeRosterStartWatching = eb_haiku_volume_roster_start_watching(r.handle, watcher.handle)
END FUNCTION

SUB HVolumeRosterStopWatching(BYVAL r AS HVolumeRoster)
    CALL eb_haiku_volume_roster_stop_watching(r.handle)
END SUB

''' Frees an HVolumeRoster - call exactly once.
SUB HVolumeRosterFree(BYVAL r AS HVolumeRoster)
    CALL eb_haiku_volume_roster_destroy(r.handle)
END SUB
