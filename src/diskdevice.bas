' Idiomatic layer: Disk Device Kit - BDiskDeviceRoster/BDiskDevice/
' BPartition. Real classes live under headers/private/storage on real
' Haiku (not the public os/ tree every other Kit in this package
' uses) - a deliberate, documented exception (see
' native/shim_diskdevice.h's own top comment); the symbols themselves
' are in the already-linked libbe.so.
'
' IMPORTANT, confirmed by direct reproduction: BDiskDeviceRoster's own
' VisitEachMountablePartition (and presumably its Device/Partition
' siblings) does NOT reliably scope its enumeration to a childless
' `device` filter - it instead visited every real partition on this
' ENTIRE host, including the live boot volumes, and never returned
' (hung indefinitely). NOT bound here at all - a real, confirmed
' hazard. Enumerate via HDiskDeviceRosterGetNextDevice/RewindDevices
' (fill-in-place, matching HVolumeRosterGetNextVolume's own
' convention) plus HPartitionChildAt/CountChildren navigation instead -
' both confirmed safe.
'
' `BPartition` itself has a private ctor/dtor in real Haiku - there is
' deliberately no HPartitionFree function. HDiskDevice IS-A BPartition
' (single inheritance, no pointer-adjustment concern), so every
' HPartition* function below also works directly on an HDiskDevice's
' own handle - matching this package's own established base-type-reuse
' convention (e.g. Game Kit's shared HGameSound functions).
'
' Verify real Mount/Unmount ONLY against a loopback file registered via
' HDiskDeviceRosterRegisterFileDevice - NEVER a real physical/boot
' device (see tests/diskdevice_basics.bas for the safe pattern: `mkfs
' -t bfs` a small throwaway image file first).

#include once "raw/haiku_shim_diskdevice.bas"
#include once "path.bas"

TYPE HDiskDevice
    handle AS ANY PTR
END TYPE

FUNCTION HDiskDeviceCreate() AS HDiskDevice
    DIM d AS HDiskDevice
    d.handle = eb_haiku_disk_device_create()
    HDiskDeviceCreate = d
END FUNCTION

''' Frees an HDiskDevice - call exactly once. Any HPartition obtained
''' via HPartitionChildAt on this device becomes invalid too (it was
''' never separately owned - see this file's own top comment).
SUB HDiskDeviceFree(BYVAL d AS HDiskDevice)
    CALL eb_haiku_disk_device_destroy(d.handle)
END SUB

FUNCTION HDiskDeviceInitCheck(BYVAL d AS HDiskDevice) AS INTEGER
    HDiskDeviceInitCheck = eb_haiku_disk_device_init_check(d.handle)
END FUNCTION

FUNCTION HDiskDeviceHasMedia(BYVAL d AS HDiskDevice) AS INTEGER
    HDiskDeviceHasMedia = eb_haiku_disk_device_has_media(d.handle)
END FUNCTION

FUNCTION HDiskDeviceIsRemovableMedia(BYVAL d AS HDiskDevice) AS INTEGER
    HDiskDeviceIsRemovableMedia = eb_haiku_disk_device_is_removable_media(d.handle)
END FUNCTION

FUNCTION HDiskDeviceIsReadOnlyMedia(BYVAL d AS HDiskDevice) AS INTEGER
    HDiskDeviceIsReadOnlyMedia = eb_haiku_disk_device_is_read_only_media(d.handle)
END FUNCTION

FUNCTION HDiskDeviceEject(BYVAL d AS HDiskDevice, BYVAL updateFlag AS INTEGER) AS INTEGER
    HDiskDeviceEject = eb_haiku_disk_device_eject(d.handle, updateFlag)
END FUNCTION

''' Fills `outPath` (an existing HPathCreateEmpty result) with the
''' device's own real device-node path.
FUNCTION HDiskDeviceGetPath(BYVAL d AS HDiskDevice, BYVAL outPath AS HPath) AS INTEGER
    HDiskDeviceGetPath = eb_haiku_disk_device_get_path(d.handle, outPath.handle)
END FUNCTION

TYPE HDiskDeviceRoster
    handle AS ANY PTR
END TYPE

FUNCTION HDiskDeviceRosterCreate() AS HDiskDeviceRoster
    DIM r AS HDiskDeviceRoster
    r.handle = eb_haiku_disk_device_roster_create()
    HDiskDeviceRosterCreate = r
END FUNCTION

''' Frees an HDiskDeviceRoster - call exactly once.
SUB HDiskDeviceRosterFree(BYVAL r AS HDiskDeviceRoster)
    CALL eb_haiku_disk_device_roster_destroy(r.handle)
END SUB

''' Fills `device` (an existing HDiskDeviceCreate result) with the next
''' real system disk device. Returns a status code (0 = success); a
''' real negative status once every device has been enumerated.
FUNCTION HDiskDeviceRosterGetNextDevice(BYVAL r AS HDiskDeviceRoster, BYVAL device AS HDiskDevice) AS INTEGER
    HDiskDeviceRosterGetNextDevice = eb_haiku_disk_device_roster_get_next_device(r.handle, device.handle)
END FUNCTION

FUNCTION HDiskDeviceRosterRewindDevices(BYVAL r AS HDiskDeviceRoster) AS INTEGER
    HDiskDeviceRosterRewindDevices = eb_haiku_disk_device_roster_rewind_devices(r.handle)
END FUNCTION

''' Publishes the real file at `path` as a loopback block device - the
''' documented-safe way to get a real testable device without touching
''' physical/boot hardware. Returns a real partition_id (>= 0 on
''' success) - pass it to HDiskDeviceRosterGetDeviceWithId.
FUNCTION HDiskDeviceRosterRegisterFileDevice(BYVAL r AS HDiskDeviceRoster, path AS ZSTRING) AS INTEGER
    HDiskDeviceRosterRegisterFileDevice = eb_haiku_disk_device_roster_register_file_device(r.handle, path)
END FUNCTION

FUNCTION HDiskDeviceRosterUnregisterFileDevice(BYVAL r AS HDiskDeviceRoster, path AS ZSTRING) AS INTEGER
    HDiskDeviceRosterUnregisterFileDevice = eb_haiku_disk_device_roster_unregister_file_device(r.handle, path)
END FUNCTION

''' Fills `device` with the real device matching `forId` (e.g. from
''' HDiskDeviceRosterRegisterFileDevice's own return value). Returns a
''' status code (0 = success).
FUNCTION HDiskDeviceRosterGetDeviceWithId(BYVAL r AS HDiskDeviceRoster, BYVAL forId AS INTEGER, BYVAL device AS HDiskDevice) AS INTEGER
    HDiskDeviceRosterGetDeviceWithId = eb_haiku_disk_device_roster_get_device_with_id(r.handle, forId, device.handle)
END FUNCTION

' ---- BPartition-level - takes an HDiskDevice's own .handle directly,
' or an HPartition's own .handle from HPartitionChildAt (both work,
' see this file's own top comment) ----

TYPE HPartition
    handle AS ANY PTR
END TYPE

''' Mounts this partition. `mountPoint`/`parameters` may be "" for
''' real Haiku's own "pick automatically"/"none" default. Returns a
''' status code (0 = success).
FUNCTION HPartitionMount(BYVAL partitionHandle AS ANY PTR, mountPoint AS ZSTRING, BYVAL mountFlags AS UINTEGER, parameters AS ZSTRING) AS INTEGER
    HPartitionMount = eb_haiku_partition_mount(partitionHandle, mountPoint, mountFlags, parameters)
END FUNCTION

FUNCTION HPartitionUnmount(BYVAL partitionHandle AS ANY PTR, BYVAL unmountFlags AS UINTEGER) AS INTEGER
    HPartitionUnmount = eb_haiku_partition_unmount(partitionHandle, unmountFlags)
END FUNCTION

FUNCTION HPartitionName(BYVAL partitionHandle AS ANY PTR) AS ZSTRING
    HPartitionName = eb_haiku_partition_name(partitionHandle)
END FUNCTION

''' Fills `outBuf` (caller-supplied, `bufSize` bytes, NOT null-
''' terminated automatically) with the real content name. Returns the
''' real length in bytes (>= 0).
FUNCTION HPartitionContentName(BYVAL partitionHandle AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HPartitionContentName = eb_haiku_partition_content_name(partitionHandle, outBuf, bufSize)
END FUNCTION

FUNCTION HPartitionType(BYVAL partitionHandle AS ANY PTR) AS ZSTRING
    HPartitionType = eb_haiku_partition_type(partitionHandle)
END FUNCTION

FUNCTION HPartitionContentType(BYVAL partitionHandle AS ANY PTR) AS ZSTRING
    HPartitionContentType = eb_haiku_partition_content_type(partitionHandle)
END FUNCTION

FUNCTION HPartitionId(BYVAL partitionHandle AS ANY PTR) AS INTEGER
    HPartitionId = eb_haiku_partition_id(partitionHandle)
END FUNCTION

FUNCTION HPartitionIsMounted(BYVAL partitionHandle AS ANY PTR) AS INTEGER
    HPartitionIsMounted = eb_haiku_partition_is_mounted(partitionHandle)
END FUNCTION

FUNCTION HPartitionIsReadOnly(BYVAL partitionHandle AS ANY PTR) AS INTEGER
    HPartitionIsReadOnly = eb_haiku_partition_is_read_only(partitionHandle)
END FUNCTION

FUNCTION HPartitionSize(BYVAL partitionHandle AS ANY PTR) AS LONGINT
    HPartitionSize = eb_haiku_partition_size(partitionHandle)
END FUNCTION

''' Fills `outMountPoint` (an existing HPathCreateEmpty result) -
''' meaningful only if HPartitionIsMounted is true.
FUNCTION HPartitionGetMountPoint(BYVAL partitionHandle AS ANY PTR, BYVAL outMountPoint AS HPath) AS INTEGER
    HPartitionGetMountPoint = eb_haiku_partition_get_mount_point(partitionHandle, outMountPoint.handle)
END FUNCTION

FUNCTION HPartitionCountChildren(BYVAL partitionHandle AS ANY PTR) AS INTEGER
    HPartitionCountChildren = eb_haiku_partition_count_children(partitionHandle)
END FUNCTION

''' Returns the real child BPartition at `index` (0 ..
''' HPartitionCountChildren - 1) as an HPartition - owned by the
''' BDiskDevice tree, NOT the caller (no HPartitionFree exists -
''' real BPartition has a private destructor).
FUNCTION HPartitionChildAt(BYVAL partitionHandle AS ANY PTR, BYVAL index AS INTEGER) AS HPartition
    DIM p AS HPartition
    p.handle = eb_haiku_partition_child_at(partitionHandle, index)
    HPartitionChildAt = p
END FUNCTION
