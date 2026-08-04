#include "shim.h"

#include <Directory.h>
#include <Entry.h>
#include <Message.h>
#include <Node.h>
#include <NodeInfo.h>
#include <Path.h>
#include <TypeConstants.h>
#include <app/Application.h>

#include <cstring>

extern "C" {

// ---- BPath ----

void* eb_haiku_path_create(const char* pathStr) { return new BPath(pathStr); }
void* eb_haiku_path_create_empty(void) { return new BPath(); }

int eb_haiku_path_append(void* path, const char* leaf) {
    return static_cast<BPath*>(path)->Append(leaf);
}

const char* eb_haiku_path_get(void* path) { return static_cast<BPath*>(path)->Path(); }
const char* eb_haiku_path_leaf(void* path) { return static_cast<BPath*>(path)->Leaf(); }

int eb_haiku_path_get_parent(void* path, void* outParentPath) {
    return static_cast<BPath*>(path)->GetParent(static_cast<BPath*>(outParentPath));
}

int eb_haiku_path_is_absolute(void* path) {
    return static_cast<BPath*>(path)->IsAbsolute() ? 1 : 0;
}

int eb_haiku_path_init_check(void* path) { return static_cast<BPath*>(path)->InitCheck(); }
void eb_haiku_path_destroy(void* path) { delete static_cast<BPath*>(path); }

// ---- BEntry ----

void* eb_haiku_entry_create(const char* path, int traverse) {
    return new BEntry(path, traverse != 0);
}

void* eb_haiku_entry_create_empty(void) { return new BEntry(); }

int eb_haiku_entry_init_check(void* entry) { return static_cast<BEntry*>(entry)->InitCheck(); }
int eb_haiku_entry_exists(void* entry) { return static_cast<BEntry*>(entry)->Exists() ? 1 : 0; }

int eb_haiku_entry_is_directory(void* entry) {
    return static_cast<BEntry*>(entry)->IsDirectory() ? 1 : 0;
}

int eb_haiku_entry_is_file(void* entry) {
    return static_cast<BEntry*>(entry)->IsFile() ? 1 : 0;
}

const char* eb_haiku_entry_name(void* entry) { return static_cast<BEntry*>(entry)->Name(); }

int eb_haiku_entry_get_path(void* entry, void* outPath) {
    return static_cast<BEntry*>(entry)->GetPath(static_cast<BPath*>(outPath));
}

int eb_haiku_entry_remove(void* entry) { return static_cast<BEntry*>(entry)->Remove(); }

int eb_haiku_entry_rename(void* entry, const char* newPath, int clobber) {
    return static_cast<BEntry*>(entry)->Rename(newPath, clobber != 0);
}

void eb_haiku_entry_destroy(void* entry) { delete static_cast<BEntry*>(entry); }

// ---- BDirectory ----

void* eb_haiku_directory_create(const char* path) { return new BDirectory(path); }

int eb_haiku_directory_init_check(void* dir) {
    return static_cast<BDirectory*>(dir)->InitCheck();
}

int eb_haiku_directory_get_next_entry(void* dir, void* outEntry, int traverse) {
    return static_cast<BDirectory*>(dir)->GetNextEntry(static_cast<BEntry*>(outEntry),
                                                         traverse != 0);
}

int eb_haiku_directory_rewind(void* dir) { return static_cast<BDirectory*>(dir)->Rewind(); }

int eb_haiku_directory_count_entries(void* dir) {
    return static_cast<BDirectory*>(dir)->CountEntries();
}

int eb_haiku_directory_create_directory(void* dir, const char* path) {
    return static_cast<BDirectory*>(dir)->CreateDirectory(path, nullptr);
}

void eb_haiku_directory_destroy(void* dir) { delete static_cast<BDirectory*>(dir); }

// ---- BNode ----

void* eb_haiku_node_create(const char* path) { return new BNode(path); }
int eb_haiku_node_init_check(void* node) { return static_cast<BNode*>(node)->InitCheck(); }

int eb_haiku_node_write_attr_string(void* node, const char* name, const char* value) {
    return static_cast<int>(static_cast<BNode*>(node)->WriteAttr(
        name, B_STRING_TYPE, 0, value, std::strlen(value) + 1));
}

char* eb_haiku_node_read_attr_string(void* node, const char* name) {
    // A fixed, generous buffer - Phase 1 targets short attribute values
    // (names, tags, small metadata), not arbitrarily large blobs.
    char stackBuf[4096];
    ssize_t n = static_cast<BNode*>(node)->ReadAttr(name, B_STRING_TYPE, 0, stackBuf,
                                                     sizeof(stackBuf) - 1);
    if (n < 0) return nullptr;
    stackBuf[n] = '\0';
    char* result = new char[static_cast<size_t>(n) + 1];
    std::memcpy(result, stackBuf, static_cast<size_t>(n) + 1);
    return result;
}

int eb_haiku_node_remove_attr(void* node, const char* name) {
    return static_cast<BNode*>(node)->RemoveAttr(name);
}

char* eb_haiku_node_get_next_attr_name(void* node) {
    // GetNextAttrName always writes into a buffer of at least
    // B_ATTR_NAME_LENGTH (255) + 1 bytes internally - this stack buffer
    // matches that real Haiku constant.
    char stackBuf[256];
    if (static_cast<BNode*>(node)->GetNextAttrName(stackBuf) != B_OK) return nullptr;
    size_t len = std::strlen(stackBuf);
    char* result = new char[len + 1];
    std::memcpy(result, stackBuf, len + 1);
    return result;
}

int eb_haiku_node_rewind_attrs(void* node) { return static_cast<BNode*>(node)->RewindAttrs(); }
void eb_haiku_node_destroy(void* node) { delete static_cast<BNode*>(node); }

// ---- BNodeInfo ----

void* eb_haiku_nodeinfo_create(void* node) { return new BNodeInfo(static_cast<BNode*>(node)); }

char* eb_haiku_nodeinfo_get_type(void* nodeInfo) {
    // GetType always writes up to B_MIME_TYPE_LENGTH (255) + 1 bytes
    // internally - this stack buffer matches that real Haiku constant.
    char stackBuf[256];
    if (static_cast<BNodeInfo*>(nodeInfo)->GetType(stackBuf) != B_OK) return nullptr;
    size_t len = std::strlen(stackBuf);
    char* result = new char[len + 1];
    std::memcpy(result, stackBuf, len + 1);
    return result;
}

void eb_haiku_free_string(void* s) { delete[] static_cast<char*>(s); }

int eb_haiku_nodeinfo_set_type(void* nodeInfo, const char* mimeType) {
    return static_cast<BNodeInfo*>(nodeInfo)->SetType(mimeType);
}

void eb_haiku_nodeinfo_destroy(void* nodeInfo) { delete static_cast<BNodeInfo*>(nodeInfo); }

// ---- BMessage ----

void* eb_haiku_message_create(unsigned int what) { return new BMessage(what); }
void eb_haiku_message_destroy(void* msg) { delete static_cast<BMessage*>(msg); }
unsigned int eb_haiku_message_what(void* msg) { return static_cast<BMessage*>(msg)->what; }

int eb_haiku_message_add_string(void* msg, const char* name, const char* value) {
    return static_cast<BMessage*>(msg)->AddString(name, value);
}

int eb_haiku_message_add_int32(void* msg, const char* name, int value) {
    return static_cast<BMessage*>(msg)->AddInt32(name, value);
}

int eb_haiku_message_add_double(void* msg, const char* name, double value) {
    return static_cast<BMessage*>(msg)->AddDouble(name, value);
}

int eb_haiku_message_add_bool(void* msg, const char* name, int value) {
    return static_cast<BMessage*>(msg)->AddBool(name, value != 0);
}

const char* eb_haiku_message_find_string(void* msg, const char* name) {
    const char* result = static_cast<BMessage*>(msg)->FindString(name);
    return result ? result : "";
}

int eb_haiku_message_find_int32(void* msg, const char* name) {
    return static_cast<BMessage*>(msg)->FindInt32(name);
}

double eb_haiku_message_find_double(void* msg, const char* name) {
    return static_cast<BMessage*>(msg)->FindDouble(name);
}

int eb_haiku_message_find_bool(void* msg, const char* name) {
    return static_cast<BMessage*>(msg)->FindBool(name) ? 1 : 0;
}

// ---- BApplication ----

void* eb_haiku_application_create(const char* signature) { return new BApplication(signature); }

int eb_haiku_application_init_check(void* app) {
    return static_cast<BApplication*>(app)->InitCheck();
}

int eb_haiku_application_run(void* app) {
    return static_cast<int>(static_cast<BApplication*>(app)->Run());
}

void eb_haiku_application_quit(void* app) { static_cast<BApplication*>(app)->Quit(); }
void eb_haiku_application_destroy(void* app) { delete static_cast<BApplication*>(app); }

} // extern "C"
