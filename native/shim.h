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

// ---- BApplication (app/Application.h) - lifecycle only, no subclass ----
void* eb_haiku_application_create(const char* signature);
int eb_haiku_application_init_check(void* app);
// Blocks the calling thread running the app's message loop until
// eb_haiku_application_quit is called (from another thread) - matching
// real BApplication::Run()'s own documented blocking behavior.
int eb_haiku_application_run(void* app);
void eb_haiku_application_quit(void* app);
void eb_haiku_application_destroy(void* app);

} // extern "C"
