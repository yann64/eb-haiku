// eb-haiku native shim - Phase 1 (Storage Kit, BMessage, BApplication
// lifecycle). Haiku's Kits have no C-level API at all (unlike GTK4/
// GLib, which eb-gtk4 binds directly), so eBasic's Extern mechanism -
// which only ever binds free functions, never a foreign class's
// constructor or methods - can't reach BPath/BEntry/BDirectory/BNode/
// BMessage/BApplication directly. This shim is real, hand-written C++:
// each function constructs/calls/destroys one real Haiku object behind
// an opaque `void*`, exposed here as a flat, unmangled `extern "C"` ABI.
//
// No subclassing, no virtual-method forwarding, no stored callbacks -
// that's Phase 2 (BWindow/BView), explicitly out of scope here.
#pragma once

#include <stddef.h>

extern "C" {

// ---- BPath (storage/Path.h) ----
void* eb_haiku_path_create(const char* pathStr);
void* eb_haiku_path_create_empty(void);
int eb_haiku_path_append(void* path, const char* leaf);
const char* eb_haiku_path_get(void* path);
const char* eb_haiku_path_leaf(void* path);
int eb_haiku_path_get_parent(void* path, void* outParentPath);
int eb_haiku_path_is_absolute(void* path);
int eb_haiku_path_init_check(void* path);
void eb_haiku_path_destroy(void* path);

// ---- BEntry (storage/Entry.h) ----
void* eb_haiku_entry_create(const char* path, int traverse);
void* eb_haiku_entry_create_empty(void);
int eb_haiku_entry_init_check(void* entry);
int eb_haiku_entry_exists(void* entry);
int eb_haiku_entry_is_directory(void* entry);
int eb_haiku_entry_is_file(void* entry);
const char* eb_haiku_entry_name(void* entry);
int eb_haiku_entry_get_path(void* entry, void* outPath);
int eb_haiku_entry_remove(void* entry);
int eb_haiku_entry_rename(void* entry, const char* newPath, int clobber);
void eb_haiku_entry_destroy(void* entry);

// ---- BEntry / BStatable (storage/Statable.h) - real stat info, bound
// per concrete type (not a generic BStatable*-accepting function) to
// avoid any multiple-inheritance pointer-adjustment risk - see this
// package's own README on the real MI bug found and fixed for BFile in
// the Translation Kit. Every getter returns a status_t (0 = success)
// and writes through an out-param; every setter takes the value
// directly. mode_t/uid_t/gid_t are real 4-byte types on Haiku
// (confirmed via a compiled probe, not assumed) - passed as
// `unsigned int`. off_t/time_t are real 8-byte types - passed as
// `long long`.
int eb_haiku_entry_is_symlink(void* entry);
int eb_haiku_entry_get_permissions(void* entry, unsigned int* outPermissions);
int eb_haiku_entry_set_permissions(void* entry, unsigned int permissions);
int eb_haiku_entry_get_owner(void* entry, unsigned int* outOwner);
int eb_haiku_entry_set_owner(void* entry, unsigned int owner);
int eb_haiku_entry_get_group(void* entry, unsigned int* outGroup);
int eb_haiku_entry_set_group(void* entry, unsigned int group);
int eb_haiku_entry_get_size(void* entry, long long* outSize);
int eb_haiku_entry_get_modification_time(void* entry, long long* outTime);
int eb_haiku_entry_set_modification_time(void* entry, long long time);
int eb_haiku_entry_get_creation_time(void* entry, long long* outTime);
int eb_haiku_entry_set_creation_time(void* entry, long long time);
// Fills `outVolume` (from eb_haiku_volume_create_empty, shim_storage.h)
// with the volume this entry lives on. Returns a status_t.
int eb_haiku_entry_get_volume(void* entry, void* outVolume);

// ---- BDirectory (storage/Directory.h) ----
void* eb_haiku_directory_create(const char* path);
int eb_haiku_directory_init_check(void* dir);
// Fills `outEntry` (a pre-created BEntry, see eb_haiku_entry_create with
// a null path) with the next entry; returns B_ENTRY_NOT_FOUND (a
// negative status_t) once iteration is exhausted.
int eb_haiku_directory_get_next_entry(void* dir, void* outEntry, int traverse);
int eb_haiku_directory_rewind(void* dir);
int eb_haiku_directory_count_entries(void* dir);
int eb_haiku_directory_create_directory(void* dir, const char* path);
void eb_haiku_directory_destroy(void* dir);

// ---- BNode (storage/Node.h) - Haiku's extended file attributes ----
void* eb_haiku_node_create(const char* path);
int eb_haiku_node_init_check(void* node);
// Returns the number of bytes written (>=0), or a negative status_t.
int eb_haiku_node_write_attr_string(void* node, const char* name, const char* value);
// Returns a newly heap-allocated, NUL-terminated copy of the attribute's
// value, or NULL if it doesn't exist - free the result via
// eb_haiku_free_string. A heap allocation (not a caller-supplied buffer)
// specifically so the idiomatic .bas layer can return it as a plain
// ANY PTR - no top-level STRING-returning function can cross an ebpm
// `--lib` package boundary yet (see this package's own README), and a
// pointer into a stack-local buffer would dangle the instant this
// function returned anyway.
char* eb_haiku_node_read_attr_string(void* node, const char* name);
int eb_haiku_node_remove_attr(void* node, const char* name);
// Returns a newly heap-allocated copy of the next attribute's name, or
// NULL once exhausted - free via eb_haiku_free_string. Call
// eb_haiku_node_rewind_attrs first.
char* eb_haiku_node_get_next_attr_name(void* node);
int eb_haiku_node_rewind_attrs(void* node);
void eb_haiku_node_destroy(void* node);

// ---- BNode / BStatable - same real stat surface as BEntry above (see
// its own comment - bound per concrete type, no generic BStatable*).
// No IsSymLink here - BNode doesn't need it, use HSymLink directly.
int eb_haiku_node_get_permissions(void* node, unsigned int* outPermissions);
int eb_haiku_node_set_permissions(void* node, unsigned int permissions);
int eb_haiku_node_get_owner(void* node, unsigned int* outOwner);
int eb_haiku_node_set_owner(void* node, unsigned int owner);
int eb_haiku_node_get_group(void* node, unsigned int* outGroup);
int eb_haiku_node_set_group(void* node, unsigned int group);
int eb_haiku_node_get_size(void* node, long long* outSize);
int eb_haiku_node_get_modification_time(void* node, long long* outTime);
int eb_haiku_node_set_modification_time(void* node, long long time);
int eb_haiku_node_get_creation_time(void* node, long long* outTime);
int eb_haiku_node_set_creation_time(void* node, long long time);
// Same as eb_haiku_entry_get_volume above.
int eb_haiku_node_get_volume(void* node, void* outVolume);

// ---- BNode typed attributes (storage/Node.h WriteAttr/ReadAttr,
// support/TypeConstants.h) - beyond the B_STRING_TYPE convenience pair
// above. Same "returns bytes written/read (>=0), or a negative
// status_t" convention as eb_haiku_node_write_attr_string.
int eb_haiku_node_write_attr_int32(void* node, const char* name, int value);
// Returns 0 (not found/wrong size) or 1, writing through outValue -
// distinguishable from a valid 0 value, unlike a bare sentinel return.
int eb_haiku_node_read_attr_int32(void* node, const char* name, int* outValue);
int eb_haiku_node_write_attr_int64(void* node, const char* name, long long value);
int eb_haiku_node_read_attr_int64(void* node, const char* name, long long* outValue);
int eb_haiku_node_write_attr_bool(void* node, const char* name, int value);
int eb_haiku_node_read_attr_bool(void* node, const char* name, int* outValue);
int eb_haiku_node_write_attr_double(void* node, const char* name, double value);
int eb_haiku_node_read_attr_double(void* node, const char* name, double* outValue);
// Raw escape hatch (B_RAW_TYPE) for anything not covered above -
// returns bytes written/read (>=0), or a negative status_t, exactly
// like the string/typed variants.
int eb_haiku_node_write_attr_raw(void* node, const char* name, const void* buffer, int size);
int eb_haiku_node_read_attr_raw(void* node, const char* name, void* buffer, int bufferSize);
// Fills outType/outSize with the real attribute's own type_code/size -
// returns a status_t (0 = success). Use before eb_haiku_node_read_attr_raw
// on an attribute of unknown type/size (e.g. written by another app).
int eb_haiku_node_get_attr_info(void* node, const char* name, unsigned int* outType,
                                 long long* outSize);

// ---- BNodeInfo (storage/NodeInfo.h) - MIME type only for Phase 1 ----
// Does not take ownership of `node` - the caller keeps its own
// eb_haiku_node_destroy responsibility.
void* eb_haiku_nodeinfo_create(void* node);
// NULL if no MIME type is set - free via eb_haiku_free_string (same
// reasoning as eb_haiku_node_read_attr_string above).
char* eb_haiku_nodeinfo_get_type(void* nodeInfo);
int eb_haiku_nodeinfo_set_type(void* nodeInfo, const char* mimeType);
void eb_haiku_nodeinfo_destroy(void* nodeInfo);

// Frees a string returned by eb_haiku_node_read_attr_string,
// eb_haiku_node_get_next_attr_name, or eb_haiku_nodeinfo_get_type.
void eb_haiku_free_string(void* s);

// ---- BMessage (app/Message.h) ----
void* eb_haiku_message_create(unsigned int what);
void eb_haiku_message_destroy(void* msg);
unsigned int eb_haiku_message_what(void* msg);
int eb_haiku_message_add_string(void* msg, const char* name, const char* value);
int eb_haiku_message_add_int32(void* msg, const char* name, int value);
int eb_haiku_message_add_double(void* msg, const char* name, double value);
int eb_haiku_message_add_bool(void* msg, const char* name, int value);
// Returns "" (an empty, non-null string) if `name` isn't present.
const char* eb_haiku_message_find_string(void* msg, const char* name);
int eb_haiku_message_find_int32(void* msg, const char* name);
double eb_haiku_message_find_double(void* msg, const char* name);
int eb_haiku_message_find_bool(void* msg, const char* name);
// Generic raw-data field (any type_code - see raw/haiku_shim.bas's own
// H_ATTR_TYPE_* constants), matching the existing typed-attribute raw
// escape hatch from Storage Kit. Returns a status_t (0 = success).
int eb_haiku_message_add_data(void* msg, const char* name, unsigned int type, const void* buffer,
                               int size);
// Returns the field's real byte size (>= 0) with `buffer` filled, or a
// negative status_t if absent/wrong type.
int eb_haiku_message_find_data(void* msg, const char* name, unsigned int type, void* buffer,
                                int bufferSize);

// Real BMessage fields support multiple values under one name (an
// array field) - GetInfo/FindString(name, index, ...) reach them.
// Returns the real item count (>= 0), or a negative status_t if `name`
// isn't present at all.
int eb_haiku_message_count_items(void* msg, const char* name, unsigned int type);
// Returns "" (an empty, non-null string) if `name`/`index` isn't
// present - same convention as eb_haiku_message_find_string above.
const char* eb_haiku_message_find_string_at(void* msg, const char* name, int index);
// entry_ref-flavored sibling of the above, for BRoster's own recent-
// document/folder/app lists (real Haiku fills a BMessage with a
// repeated "refs" field of this type) - fills `outPath` (an existing,
// real BPath* handle, e.g. from eb_haiku_path_create_empty) in place.
// Returns a status_t (0 = success).
int eb_haiku_message_find_ref_at(void* msg, const char* name, int index, void* outPath);

// Real drag-and-drop: a message delivered to a view's MessageReceived
// callback as the result of a real eb_haiku_view_drag_message drop is
// distinguished from an ordinary message via WasDropped(); DropPoint()
// gives the real screen location it was dropped at.
int eb_haiku_message_was_dropped(void* msg);
void eb_haiku_message_drop_point(void* msg, float* outX, float* outY);

// ---- BLocker (support/Locker.h) - a real mutex/locking primitive.
// bigtime_t (real 8-byte type, microseconds) confirmed via a compiled
// probe, not assumed.
void* eb_haiku_locker_create(void);
int eb_haiku_locker_lock(void* locker);
// Returns a status_t (0 = success, B_TIMED_OUT on timeout).
int eb_haiku_locker_lock_with_timeout(void* locker, long long timeoutMicros);
void eb_haiku_locker_unlock(void* locker);
int eb_haiku_locker_is_locked(void* locker);
int eb_haiku_locker_count_locks(void* locker);
void eb_haiku_locker_destroy(void* locker);

// ---- HWatcher (a small ShimHandler : public BHandler, AddHandler'd
// onto be_app) - the real, minimal way to become a live BMessenger
// target for BQuery::SetTarget/BVolumeRoster::StartWatching/
// BClipboard::StartWatching, none of which are reachable without one.
// Needs a real BApplication first (be_app must exist) - the same
// "needs BApplication" gotcha as GetBitmap/BClipboard::Lock. Delivered
// messages are forwarded to an eBasic callback exactly like
// eb_haiku_window_set_message_received_callback (shim_interface.h).
typedef void (*EbHaikuWatcherMessageCallback)(void* userData, void* messageHandle);
void* eb_haiku_watcher_create(void);
void eb_haiku_watcher_set_message_received_callback(void* watcher,
                                                      EbHaikuWatcherMessageCallback cb,
                                                      void* userData);
void eb_haiku_watcher_destroy(void* watcher);

// ---- BRoster (app/Roster.h) - the shared be_roster singleton, exposed
// the same way BTranslatorRoster::Default() already is. Never freed by
// this package (owned by the Application Kit itself).
void* eb_haiku_roster_default(void);
int eb_haiku_roster_is_running(void* roster, const char* signature);
// team_id (real 4-byte signed type) - 0/negative if not running.
int eb_haiku_roster_team_for(void* roster, const char* signature);
// Fills outTeam with the newly launched app's team_id. Returns a
// status_t (0 = success).
int eb_haiku_roster_launch(void* roster, const char* signature, int* outTeam);
int eb_haiku_roster_activate_app(void* roster, int team);
int eb_haiku_roster_broadcast(void* roster, void* message);
// Fills outTeam/outThread/outFlags and outPath (an existing BPath*
// handle, e.g. eb_haiku_path_create_empty - filled from the real
// app_info's own entry_ref, same "reuse BPath directly" convention as
// BPackageRoster's own repository-path functions). Returns a status_t
// (0 = success).
int eb_haiku_roster_get_app_info(void* roster, const char* signature, int* outTeam,
                                  int* outThread, unsigned int* outFlags, void* outPath);
// Like the above, but looked up by team_id instead of signature (real
// Haiku's own GetRunningAppInfo) - also fills outSignature (caller-
// supplied, bufSize bytes, NOT null-terminated automatically).
int eb_haiku_roster_get_running_app_info(void* roster, int team, int* outThread,
                                          unsigned int* outFlags, void* outPath,
                                          char* outSignature, int sigBufSize);
// Real FindApp(mimeType) overload - fills outPath with the preferred
// handler app's own real executable path.
int eb_haiku_roster_find_app(void* roster, const char* mimeType, void* outPath);
// Fills outMessage (an existing eb_haiku_message_create result) with a
// real repeated entry_ref field named "refs" - read via
// eb_haiku_message_count_items/find_ref_at (above).
void eb_haiku_roster_get_recent_documents(void* roster, void* outMessage, int maxCount,
                                           const char* fileType, const char* signature);
void eb_haiku_roster_get_recent_folders(void* roster, void* outMessage, int maxCount,
                                         const char* signature);
void eb_haiku_roster_get_recent_apps(void* roster, void* outMessage, int maxCount);
// `watcher` is an eb_haiku_watcher_create result (shim.h) - real
// B_SOME_APP_LAUNCHED/B_SOME_APP_QUIT messages (raw/haiku_shim.bas's
// own constants) are delivered to its own registered callback as apps
// launch/quit system-wide. `eventMask` is H_REQUEST_LAUNCHED/
// H_REQUEST_QUIT/H_REQUEST_ACTIVATED (combine with OR).
int eb_haiku_roster_start_watching(void* roster, void* watcher, unsigned int eventMask);
int eb_haiku_roster_stop_watching(void* roster, void* watcher);
// entry_ref-based overloads, taking a plain file path at this
// package's own idiomatic layer - the shim constructs the real
// entry_ref internally via BEntry(path).GetRef(&ref) (matching the
// established "don't expose a new type unless it's genuinely
// reusable" pattern already used for play_sound's own path-to-
// entry_ref conversion in Media Kit).
int eb_haiku_roster_is_running_for_path(void* roster, const char* path);
// team_id (real 4-byte signed type) - 0/negative if not running.
int eb_haiku_roster_team_for_path(void* roster, const char* path);
int eb_haiku_roster_get_app_info_for_path(void* roster, const char* path, int* outTeam,
                                           int* outThread, unsigned int* outFlags,
                                           void* outPath);
int eb_haiku_roster_find_app_for_path(void* roster, const char* path, void* outPath);

// ---- BClipboard (app/Clipboard.h) - the shared be_clipboard
// singleton, exposed the same way. Never freed by this package for the
// default one; eb_haiku_clipboard_create's own custom instances should
// still be destroyed once done.
void* eb_haiku_clipboard_default(void);
void* eb_haiku_clipboard_create(const char* name);
int eb_haiku_clipboard_lock(void* clipboard);
void eb_haiku_clipboard_unlock(void* clipboard);
int eb_haiku_clipboard_clear(void* clipboard);
int eb_haiku_clipboard_commit(void* clipboard);
int eb_haiku_clipboard_revert(void* clipboard);
// The clipboard's own payload BMessage - direct access for anything
// beyond plain text (a custom MIME type) via eb_haiku_message_add_data/
// find_data above.
void* eb_haiku_clipboard_data(void* clipboard);
void eb_haiku_clipboard_destroy(void* clipboard);

// Convenience helpers for the common case - handle the full Lock/
// Clear-or-read/write/Commit/Unlock sequence internally. Real Haiku's
// own plain-text convention (confirmed via the real `clipboard`
// command-line tool's own `-d`/debug dump, not assumed) is a raw
// B_MIME_TYPE field named "text/plain" - NOT AddString/FindString, a
// completely different field.
int eb_haiku_clipboard_set_text(void* clipboard, const char* text);
// Returns the real text length in bytes (>= 0) with outBuf filled (NOT
// null-terminated automatically), or a negative status_t if there's no
// plain text on the clipboard.
int eb_haiku_clipboard_get_text(void* clipboard, char* outBuf, int bufSize);
// `watcher` is an eb_haiku_watcher_create result (shim.h) - a real
// B_CLIPBOARD_CHANGED message (matching this package's own H_* NodeMonitor-
// style constant convention, see raw/haiku_shim.bas) is delivered to its
// own registered callback whenever the clipboard's own content changes.
int eb_haiku_clipboard_start_watching(void* clipboard, void* watcher);
int eb_haiku_clipboard_stop_watching(void* clipboard, void* watcher);

// ---- BApplication (app/Application.h) - lifecycle only, no subclass ----
void* eb_haiku_application_create(const char* signature);
int eb_haiku_application_init_check(void* app);
// Blocks the calling thread running the app's message loop until
// eb_haiku_application_quit is called (from another thread) - matching
// real BApplication::Run()'s own documented blocking behavior.
int eb_haiku_application_run(void* app);
// IMPORTANT, confirmed by direct reproduction: posts a real
// B_QUIT_REQUESTED message rather than calling Quit() directly (which
// fails with "you must Lock the application object" when called from
// a thread other than the one that called eb_haiku_application_run) -
// safe to call from any thread, the same fix as eb_haiku_window_close.
void eb_haiku_application_quit(void* app);
void eb_haiku_application_destroy(void* app);

} // extern "C"
