// eb-haiku native shim - Disk Device Kit (BDiskDeviceRoster/
// BDiskDevice/BPartition). A deliberate, documented exception to this
// project's "public os/ headers only" precedent: the real classes
// live under headers/private/storage (confirmed live-compilable with
// extra -I flags added in CMakeLists.txt - the symbols themselves are
// in the already-linked libbe.so, same as every other Kit here).
//
// BDiskDevice : public BPartition (single inheritance, no pointer-
// adjustment concern - unlike BFile's own multiple-inheritance case
// elsewhere in this shim) - so the shared "partition-level" functions
// below (eb_haiku_partition_*) work correctly on either a real
// BDiskDevice's own handle OR a BPartition* obtained via
// eb_haiku_partition_child_at, via a plain static_cast<BPartition*>.
//
// IMPORTANT, confirmed by direct reproduction: BDiskDeviceRoster's own
// VisitEachMountablePartition (and presumably VisitEachPartition/
// VisitEachDevice) does NOT reliably scope its enumeration to the
// `device` filter argument when that device has no partition map of
// its own (CountChildren() == 0, e.g. a raw, unpartitioned loopback
// image registered via RegisterFileDevice) - it instead visited every
// real partition on the ENTIRE host, including the live boot volumes,
// and the call never returned (hung indefinitely) on this development
// host. NOT bound here at all - deliberately avoided as a real,
// confirmed hazard, not merely "not requested." Enumeration instead
// uses only GetNextDevice/RewindDevices (confirmed safe - matches
// BVolumeRoster::GetNextVolume's own fill-in-place convention) plus
// direct ChildAt/CountChildren navigation on a BDiskDevice already
// fetched by ID/enumeration - both real, safe, scoped operations.
//
// `BPartition` itself has a private ctor/dtor in real Haiku - never
// caller-owned, never destroyed by this shim (see
// eb_haiku_partition_child_at's own doc comment).
#pragma once

extern "C" {

// ---- BDiskDeviceRoster ----

void* eb_haiku_disk_device_roster_create(void);
void eb_haiku_disk_device_roster_destroy(void* roster);

// Fills `device` (an existing eb_haiku_disk_device_create result) with
// the next real system disk device. Returns a status_t (0 = success,
// a real negative status once enumeration is exhausted).
int eb_haiku_disk_device_roster_get_next_device(void* roster, void* device);
int eb_haiku_disk_device_roster_rewind_devices(void* roster);

// Publishes `path` as a real loopback block device
// (/dev/disk/virtual/files/<id>/raw) - the documented-safe way to get
// a real testable device without touching physical/boot hardware.
// Returns a real partition_id (>= 0 on success).
int eb_haiku_disk_device_roster_register_file_device(void* roster, const char* path);
int eb_haiku_disk_device_roster_unregister_file_device(void* roster, const char* path);

// Fills `device` with the real device matching `id` (e.g. from
// eb_haiku_disk_device_roster_register_file_device's own return
// value). Returns a status_t (0 = success).
int eb_haiku_disk_device_roster_get_device_with_id(void* roster, int id, void* device);

// ---- BDiskDevice (public ctor/dtor - plain new/delete) ----

void* eb_haiku_disk_device_create(void);
void eb_haiku_disk_device_destroy(void* device);

int eb_haiku_disk_device_init_check(void* device);
int eb_haiku_disk_device_has_media(void* device);
int eb_haiku_disk_device_is_removable_media(void* device);
int eb_haiku_disk_device_is_read_only_media(void* device);
int eb_haiku_disk_device_eject(void* device, int update);
// Fills outPath (an existing HPathCreateEmpty result). Returns a
// status_t (0 = success).
int eb_haiku_disk_device_get_path(void* device, void* outPath);

// ---- BPartition-level (shared - works on a BDiskDevice's own handle
// OR a BPartition* from eb_haiku_partition_child_at) ----

// `mountPoint` may be NULL (real Haiku's own "pick one automatically"
// default) - pass an empty string from the idiomatic layer to mean
// that, matching this shim's own NULL-via-empty-string convention
// elsewhere (e.g. BRoster::GetRecentDocuments's fileType/signature).
int eb_haiku_partition_mount(void* partition, const char* mountPoint, unsigned int mountFlags,
                              const char* parameters);
int eb_haiku_partition_unmount(void* partition, unsigned int unmountFlags);
const char* eb_haiku_partition_name(void* partition);
// ContentName() returns a real BString - copied into the caller's
// buffer, matching this shim's own established "no BString at the ABI
// boundary" convention. Returns the real length in bytes (>= 0,
// truncated to fit bufSize).
int eb_haiku_partition_content_name(void* partition, char* outBuf, int bufSize);
const char* eb_haiku_partition_type(void* partition);
const char* eb_haiku_partition_content_type(void* partition);
int eb_haiku_partition_id(void* partition);
int eb_haiku_partition_is_mounted(void* partition);
int eb_haiku_partition_is_read_only(void* partition);
long long eb_haiku_partition_size(void* partition);
// Fills outMountPoint (an existing HPathCreateEmpty result). Returns
// a status_t (0 = success) - meaningful only if IsMounted().
int eb_haiku_partition_get_mount_point(void* partition, void* outMountPoint);
int eb_haiku_partition_count_children(void* partition);
// Returned BPartition* is owned by the BDiskDevice tree, not the
// caller - NEVER free/delete it (real Haiku's own BPartition has a
// private destructor anyway, enforcing this at compile time inside
// the shim itself - there is deliberately no
// eb_haiku_partition_destroy function).
void* eb_haiku_partition_child_at(void* partition, int index);

} // extern "C"
