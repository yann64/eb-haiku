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
// IMPORTANT: `watcher` is an eb_haiku_watcher_create result (shim.h) -
// needs a real BApplication to already exist (be_app), same as the
// watcher itself. Delivers real B_DEVICE_MOUNTED/B_DEVICE_UNMOUNTED
// messages (raw/haiku_shim_storage.bas's own H_DEVICE_* constants) to
// the watcher's own registered callback.
int eb_haiku_volume_roster_start_watching(void* roster, void* watcher);
void eb_haiku_volume_roster_stop_watching(void* roster);
void eb_haiku_volume_roster_destroy(void* roster);

// ---- BQuery (storage/Query.h) - Haiku's own live attribute-based
// filesystem query mechanism. Bound via the plain predicate-string API
// (SetPredicate) rather than the Push*/PushOp reverse-polish stack
// builder - identical expressiveness for a single string parameter.
// Both a one-shot Fetch()+iterate AND a real live SetTarget/IsLive path
// are bound (the live path via the new HWatcher primitive, shim.h).

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
// IMPORTANT: `watcher` is an eb_haiku_watcher_create result (shim.h).
// CONFIRMED BY DIRECT REPRODUCTION: this call alone does NOT establish
// the real live monitor (even though IsLive() reports true right
// after) - eb_haiku_query_fetch must still be called afterward, which
// is what actually registers the live watch with the kernel (as well
// as running the initial query). Once fetched, real B_QUERY_UPDATE
// messages (opcode field one of H_ENTRY_CREATED/REMOVED/MOVED - raw/
// haiku_shim_storage.bas's own constants) are delivered to the
// watcher's own registered callback as matching entries come and go.
int eb_haiku_query_set_target(void* query, void* watcher);
int eb_haiku_query_is_live(void* query);
void eb_haiku_query_destroy(void* query);

// ---- BMimeType (storage/MimeType.h) - the per-file BNodeInfo type is
// already covered (shim.h, Phase 1); this is the separate meta-mime
// database. Sniffer-rule get/set/check are deliberately not bound
// (real added complexity for modest value).

void* eb_haiku_mime_type_create(const char* mimeType);
int eb_haiku_mime_type_set_to(void* mime, const char* mimeType);
int eb_haiku_mime_type_init_check(void* mime);
int eb_haiku_mime_type_is_valid(void* mime);
int eb_haiku_mime_type_is_installed(void* mime);
int eb_haiku_mime_type_install(void* mime);
int eb_haiku_mime_type_delete(void* mime);
// Borrowed from the real BMimeType's own long-lived storage - no heap
// allocation, no matching free needed (same convention as
// eb_haiku_stringview_get_text).
const char* eb_haiku_mime_type_type(void* mime);
// Real GetShortDescription/GetLongDescription/GetPreferredApp take no
// buffer-size parameter of their own - the shim writes into a generous
// internal buffer first, then copies up to `bufSize` into `outBuf`
// (same truncation convention as this package's own copyBStringToBuffer
// helper elsewhere), returning the real full length (>= 0) or a
// negative status_t.
int eb_haiku_mime_type_get_short_description(void* mime, char* outBuf, int bufSize);
int eb_haiku_mime_type_set_short_description(void* mime, const char* description);
int eb_haiku_mime_type_get_long_description(void* mime, char* outBuf, int bufSize);
int eb_haiku_mime_type_set_long_description(void* mime, const char* description);
int eb_haiku_mime_type_get_preferred_app(void* mime, char* outBuf, int bufSize);
int eb_haiku_mime_type_set_preferred_app(void* mime, const char* signature);
// Fills `outMessage` (an existing eb_haiku_message_create result,
// shim.h) with a real repeated-string field ("extensions") - read it
// via eb_haiku_message_count_items/find_string_at (shim.h).
int eb_haiku_mime_type_get_file_extensions(void* mime, void* outMessage);
int eb_haiku_mime_type_set_file_extensions(void* mime, void* extensionsMessage);
// Fills `outMessage` with a real repeated-string field ("applications").
int eb_haiku_mime_type_get_supporting_apps(void* mime, void* outMessage);
// `icon`/`iconForType` are existing eb_haiku_bitmap_create results
// (shim_translation.h) - reuses the already-bound HBitmap type
// directly, no new plumbing. `size` is H_LARGE_ICON (32)/H_MINI_ICON
// (16) (raw/haiku_shim_storage.bas's own constants - real pixel
// dimensions this time, not FourCC-packed).
int eb_haiku_mime_type_get_icon(void* mime, void* icon, unsigned int size);
int eb_haiku_mime_type_set_icon(void* mime, void* icon, unsigned int size);
int eb_haiku_mime_type_get_icon_for_type(void* mime, const char* type, void* icon,
                                          unsigned int size);
int eb_haiku_mime_type_set_icon_for_type(void* mime, const char* type, void* icon,
                                          unsigned int size);
void eb_haiku_mime_type_destroy(void* mime);

// Static methods - `outMime`/`outMessage` are existing handles the
// caller already created (matching this package's own established
// fill-in-place convention, e.g. eb_haiku_volume_roster_get_next_volume).
int eb_haiku_mime_type_guess_mime_type(const char* path, void* outMime);
// Fills `outMessage` with a real repeated-string field ("types").
int eb_haiku_mime_type_get_installed_types(void* outMessage);
// IMPORTANT, confirmed by direct reproduction: the real field name
// here is "super_types", NOT "types" like the function above - a real
// inconsistency in Haiku's own API, not guessed.
int eb_haiku_mime_type_get_installed_supertypes(void* outMessage);

} // extern "C"
