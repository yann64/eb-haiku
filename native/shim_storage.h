// eb-haiku native shim - Storage Kit extensions (BSymLink, BVolume/
// BVolumeRoster, BQuery) not covered by shim.h's own Phase 1 surface
// (BPath/BEntry/BDirectory/BNode/BNodeInfo). See shim.h's own top
// comment for why a hand-written shim is needed at all.
#pragma once

extern "C" {

// ---- BSymLink (storage/SymLink.h) - kept as its own separate opaque
// type rather than reusing BNode's functions (BSymLink IS-A BNode, but
// simplicity/consistency wins over DRY here).

void* eb_haiku_symlink_create(const char* path);
int eb_haiku_symlink_init_check(void* link);
// Real ssize_t/POSIX readlink() semantics - writes into `buf` (caller-
// supplied, `bufSize` bytes), NOT null-terminated automatically.
// Returns the number of bytes written, or a negative status_t.
int eb_haiku_symlink_read_link(void* link, char* buf, int bufSize);
int eb_haiku_symlink_is_absolute(void* link);
void eb_haiku_symlink_destroy(void* link);

// ---- BDirectory::CreateSymLink (storage/Directory.h) - creating a
// symlink is a BDirectory operation, not a BSymLink one.
int eb_haiku_directory_create_symlink(void* dir, const char* path, const char* linkToPath);

// ---- BVolume (storage/Volume.h) ----

// An unset volume - use as an out-param for
// eb_haiku_volume_roster_get_next_volume/get_boot_volume, or
// eb_haiku_entry_get_volume/eb_haiku_node_get_volume (shim.h).
void* eb_haiku_volume_create_empty(void);
int eb_haiku_volume_init_check(void* volume);
// dev_t (real 4-byte type) - the volume's own device id, needed to
// target fs_create_index (raw/haiku_fs_index.bas - a real, plain
// extern "C" kernel function, not a shim wrapper) at the right volume.
unsigned int eb_haiku_volume_device(void* volume);
// off_t (real 8-byte type) - see this package's own out-param
// convention throughout (BStatable's own get_size/get_*_time above).
int eb_haiku_volume_capacity(void* volume, long long* outCapacity);
int eb_haiku_volume_free_bytes(void* volume, long long* outFreeBytes);
// Fills `outName` (caller-supplied, at least 256 bytes - matching real
// Haiku's own B_FILE_NAME_LENGTH) with the volume's real name. Returns
// a status_t (0 = success).
int eb_haiku_volume_get_name(void* volume, char* outName);
int eb_haiku_volume_is_read_only(void* volume);
int eb_haiku_volume_is_removable(void* volume);
int eb_haiku_volume_is_persistent(void* volume);
int eb_haiku_volume_is_shared(void* volume);
int eb_haiku_volume_knows_mime(void* volume);
int eb_haiku_volume_knows_attr(void* volume);
int eb_haiku_volume_knows_query(void* volume);
void eb_haiku_volume_destroy(void* volume);

// ---- BVolumeRoster (storage/VolumeRoster.h) ----

void* eb_haiku_volume_roster_create(void);
// Fills `outVolume` (from eb_haiku_volume_create_empty) with the next
// mounted volume - returns a negative status_t once iteration is
// exhausted (matching eb_haiku_directory_get_next_entry's own
// convention).
int eb_haiku_volume_roster_get_next_volume(void* roster, void* outVolume);
void eb_haiku_volume_roster_rewind(void* roster);
int eb_haiku_volume_roster_get_boot_volume(void* roster, void* outVolume);
void eb_haiku_volume_roster_destroy(void* roster);

// ---- BQuery (storage/Query.h) - Haiku's own live attribute-based
// filesystem query mechanism. Bound via the plain predicate-string API
// (SetPredicate) rather than the Push*/PushOp reverse-polish stack
// builder - identical expressiveness for a single string parameter.
// Not "live" (SetTarget/IsLive) - a one-shot Fetch()+iterate.

void* eb_haiku_query_create(void);
int eb_haiku_query_set_volume(void* query, void* volume);
int eb_haiku_query_set_predicate(void* query, const char* expression);
int eb_haiku_query_fetch(void* query);
// Fills `outEntry` (from eb_haiku_entry_create_empty, shim.h) with the
// next matching entry - returns a negative status_t once results are
// exhausted (matching eb_haiku_directory_get_next_entry's own
// convention - both are real BEntryList implementations).
int eb_haiku_query_get_next_entry(void* query, void* outEntry);
int eb_haiku_query_rewind(void* query);
int eb_haiku_query_count_entries(void* query);
void eb_haiku_query_destroy(void* query);

} // extern "C"
