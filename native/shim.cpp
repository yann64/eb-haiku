#include "shim.h"

#include <AppDefs.h>
#include <Clipboard.h>
#include <Directory.h>
#include <Entry.h>
#include <Handler.h>
#include <Locker.h>
#include <Message.h>
#include <Messenger.h>
#include <Roster.h>
#include <Node.h>
#include <NodeInfo.h>
#include <Path.h>
#include <TypeConstants.h>
#include <Volume.h>
#include <app/Application.h>
#include <fs_attr.h>

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

// ---- BEntry / BStatable ----

int eb_haiku_entry_is_symlink(void* entry) {
    return static_cast<BEntry*>(entry)->IsSymLink() ? 1 : 0;
}

int eb_haiku_entry_get_permissions(void* entry, unsigned int* outPermissions) {
    mode_t mode;
    status_t rc = static_cast<BEntry*>(entry)->GetPermissions(&mode);
    *outPermissions = static_cast<unsigned int>(mode);
    return rc;
}

int eb_haiku_entry_set_permissions(void* entry, unsigned int permissions) {
    return static_cast<BEntry*>(entry)->SetPermissions(static_cast<mode_t>(permissions));
}

int eb_haiku_entry_get_owner(void* entry, unsigned int* outOwner) {
    uid_t owner;
    status_t rc = static_cast<BEntry*>(entry)->GetOwner(&owner);
    *outOwner = static_cast<unsigned int>(owner);
    return rc;
}

int eb_haiku_entry_set_owner(void* entry, unsigned int owner) {
    return static_cast<BEntry*>(entry)->SetOwner(static_cast<uid_t>(owner));
}

int eb_haiku_entry_get_group(void* entry, unsigned int* outGroup) {
    gid_t group;
    status_t rc = static_cast<BEntry*>(entry)->GetGroup(&group);
    *outGroup = static_cast<unsigned int>(group);
    return rc;
}

int eb_haiku_entry_set_group(void* entry, unsigned int group) {
    return static_cast<BEntry*>(entry)->SetGroup(static_cast<gid_t>(group));
}

int eb_haiku_entry_get_size(void* entry, long long* outSize) {
    off_t size;
    status_t rc = static_cast<BEntry*>(entry)->GetSize(&size);
    *outSize = static_cast<long long>(size);
    return rc;
}

int eb_haiku_entry_get_modification_time(void* entry, long long* outTime) {
    time_t t;
    status_t rc = static_cast<BEntry*>(entry)->GetModificationTime(&t);
    *outTime = static_cast<long long>(t);
    return rc;
}

int eb_haiku_entry_set_modification_time(void* entry, long long time) {
    return static_cast<BEntry*>(entry)->SetModificationTime(static_cast<time_t>(time));
}

int eb_haiku_entry_get_creation_time(void* entry, long long* outTime) {
    time_t t;
    status_t rc = static_cast<BEntry*>(entry)->GetCreationTime(&t);
    *outTime = static_cast<long long>(t);
    return rc;
}

int eb_haiku_entry_set_creation_time(void* entry, long long time) {
    return static_cast<BEntry*>(entry)->SetCreationTime(static_cast<time_t>(time));
}

int eb_haiku_entry_get_volume(void* entry, void* outVolume) {
    return static_cast<BEntry*>(entry)->GetVolume(static_cast<BVolume*>(outVolume));
}

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

// ---- BNode / BStatable ----

int eb_haiku_node_get_permissions(void* node, unsigned int* outPermissions) {
    mode_t mode;
    status_t rc = static_cast<BNode*>(node)->GetPermissions(&mode);
    *outPermissions = static_cast<unsigned int>(mode);
    return rc;
}

int eb_haiku_node_set_permissions(void* node, unsigned int permissions) {
    return static_cast<BNode*>(node)->SetPermissions(static_cast<mode_t>(permissions));
}

int eb_haiku_node_get_owner(void* node, unsigned int* outOwner) {
    uid_t owner;
    status_t rc = static_cast<BNode*>(node)->GetOwner(&owner);
    *outOwner = static_cast<unsigned int>(owner);
    return rc;
}

int eb_haiku_node_set_owner(void* node, unsigned int owner) {
    return static_cast<BNode*>(node)->SetOwner(static_cast<uid_t>(owner));
}

int eb_haiku_node_get_group(void* node, unsigned int* outGroup) {
    gid_t group;
    status_t rc = static_cast<BNode*>(node)->GetGroup(&group);
    *outGroup = static_cast<unsigned int>(group);
    return rc;
}

int eb_haiku_node_set_group(void* node, unsigned int group) {
    return static_cast<BNode*>(node)->SetGroup(static_cast<gid_t>(group));
}

int eb_haiku_node_get_size(void* node, long long* outSize) {
    off_t size;
    status_t rc = static_cast<BNode*>(node)->GetSize(&size);
    *outSize = static_cast<long long>(size);
    return rc;
}

int eb_haiku_node_get_modification_time(void* node, long long* outTime) {
    time_t t;
    status_t rc = static_cast<BNode*>(node)->GetModificationTime(&t);
    *outTime = static_cast<long long>(t);
    return rc;
}

int eb_haiku_node_set_modification_time(void* node, long long time) {
    return static_cast<BNode*>(node)->SetModificationTime(static_cast<time_t>(time));
}

int eb_haiku_node_get_creation_time(void* node, long long* outTime) {
    time_t t;
    status_t rc = static_cast<BNode*>(node)->GetCreationTime(&t);
    *outTime = static_cast<long long>(t);
    return rc;
}

int eb_haiku_node_set_creation_time(void* node, long long time) {
    return static_cast<BNode*>(node)->SetCreationTime(static_cast<time_t>(time));
}

int eb_haiku_node_get_volume(void* node, void* outVolume) {
    return static_cast<BNode*>(node)->GetVolume(static_cast<BVolume*>(outVolume));
}

// ---- BNode typed attributes ----

int eb_haiku_node_write_attr_int32(void* node, const char* name, int value) {
    int32 v = value;
    return static_cast<int>(static_cast<BNode*>(node)->WriteAttr(name, B_INT32_TYPE, 0, &v, sizeof(v)));
}

int eb_haiku_node_read_attr_int32(void* node, const char* name, int* outValue) {
    int32 v;
    ssize_t n = static_cast<BNode*>(node)->ReadAttr(name, B_INT32_TYPE, 0, &v, sizeof(v));
    if (n != sizeof(v)) return 0;
    *outValue = v;
    return 1;
}

int eb_haiku_node_write_attr_int64(void* node, const char* name, long long value) {
    int64 v = value;
    return static_cast<int>(static_cast<BNode*>(node)->WriteAttr(name, B_INT64_TYPE, 0, &v, sizeof(v)));
}

int eb_haiku_node_read_attr_int64(void* node, const char* name, long long* outValue) {
    int64 v;
    ssize_t n = static_cast<BNode*>(node)->ReadAttr(name, B_INT64_TYPE, 0, &v, sizeof(v));
    if (n != sizeof(v)) return 0;
    *outValue = v;
    return 1;
}

int eb_haiku_node_write_attr_bool(void* node, const char* name, int value) {
    bool v = value != 0;
    return static_cast<int>(static_cast<BNode*>(node)->WriteAttr(name, B_BOOL_TYPE, 0, &v, sizeof(v)));
}

int eb_haiku_node_read_attr_bool(void* node, const char* name, int* outValue) {
    bool v;
    ssize_t n = static_cast<BNode*>(node)->ReadAttr(name, B_BOOL_TYPE, 0, &v, sizeof(v));
    if (n != sizeof(v)) return 0;
    *outValue = v ? 1 : 0;
    return 1;
}

int eb_haiku_node_write_attr_double(void* node, const char* name, double value) {
    return static_cast<int>(
        static_cast<BNode*>(node)->WriteAttr(name, B_DOUBLE_TYPE, 0, &value, sizeof(value)));
}

int eb_haiku_node_read_attr_double(void* node, const char* name, double* outValue) {
    double v;
    ssize_t n = static_cast<BNode*>(node)->ReadAttr(name, B_DOUBLE_TYPE, 0, &v, sizeof(v));
    if (n != sizeof(v)) return 0;
    *outValue = v;
    return 1;
}

int eb_haiku_node_write_attr_raw(void* node, const char* name, const void* buffer, int size) {
    return static_cast<int>(
        static_cast<BNode*>(node)->WriteAttr(name, B_RAW_TYPE, 0, buffer, static_cast<size_t>(size)));
}

int eb_haiku_node_read_attr_raw(void* node, const char* name, void* buffer, int bufferSize) {
    return static_cast<int>(static_cast<BNode*>(node)->ReadAttr(name, B_RAW_TYPE, 0, buffer,
                                                                  static_cast<size_t>(bufferSize)));
}

int eb_haiku_node_get_attr_info(void* node, const char* name, unsigned int* outType,
                                 long long* outSize) {
    attr_info info;
    status_t rc = static_cast<BNode*>(node)->GetAttrInfo(name, &info);
    if (rc != B_OK) return rc;
    *outType = info.type;
    *outSize = static_cast<long long>(info.size);
    return rc;
}

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

int eb_haiku_message_add_data(void* msg, const char* name, unsigned int type, const void* buffer,
                               int size) {
    return static_cast<BMessage*>(msg)->AddData(name, static_cast<type_code>(type), buffer,
                                                 static_cast<ssize_t>(size));
}

int eb_haiku_message_find_data(void* msg, const char* name, unsigned int type, void* buffer,
                                int bufferSize) {
    const void* data = nullptr;
    ssize_t numBytes = 0;
    status_t rc = static_cast<BMessage*>(msg)->FindData(name, static_cast<type_code>(type), &data,
                                                          &numBytes);
    if (rc != B_OK) return rc;
    ssize_t toCopy = numBytes < bufferSize ? numBytes : bufferSize;
    std::memcpy(buffer, data, static_cast<size_t>(toCopy));
    return static_cast<int>(numBytes);
}

int eb_haiku_message_count_items(void* msg, const char* name, unsigned int type) {
    (void)type;
    type_code typeFound = 0;
    int32 count = 0;
    status_t rc = static_cast<BMessage*>(msg)->GetInfo(name, &typeFound, &count);
    if (rc != B_OK) return rc;
    return count;
}

const char* eb_haiku_message_find_string_at(void* msg, const char* name, int index) {
    const char* result = nullptr;
    status_t rc = static_cast<BMessage*>(msg)->FindString(name, index, &result);
    return (rc == B_OK && result) ? result : "";
}

int eb_haiku_message_find_ref_at(void* msg, const char* name, int index, void* outPath) {
    entry_ref ref;
    status_t rc = static_cast<BMessage*>(msg)->FindRef(name, index, &ref);
    if (rc != B_OK) return rc;
    return static_cast<BPath*>(outPath)->SetTo(&ref);
}

int eb_haiku_message_was_dropped(void* msg) {
    return static_cast<BMessage*>(msg)->WasDropped() ? 1 : 0;
}

void eb_haiku_message_drop_point(void* msg, float* outX, float* outY) {
    BPoint p = static_cast<BMessage*>(msg)->DropPoint();
    *outX = p.x;
    *outY = p.y;
}

// ---- BLocker ----

void* eb_haiku_locker_create(void) { return new BLocker(); }

int eb_haiku_locker_lock(void* locker) { return static_cast<BLocker*>(locker)->Lock() ? 1 : 0; }

int eb_haiku_locker_lock_with_timeout(void* locker, long long timeoutMicros) {
    return static_cast<BLocker*>(locker)->LockWithTimeout(static_cast<bigtime_t>(timeoutMicros));
}

void eb_haiku_locker_unlock(void* locker) { static_cast<BLocker*>(locker)->Unlock(); }

int eb_haiku_locker_is_locked(void* locker) {
    return static_cast<BLocker*>(locker)->IsLocked() ? 1 : 0;
}

int eb_haiku_locker_count_locks(void* locker) {
    return static_cast<BLocker*>(locker)->CountLocks();
}

void eb_haiku_locker_destroy(void* locker) { delete static_cast<BLocker*>(locker); }

namespace {
class ShimHandler : public BHandler {
public:
    ShimHandler() : BHandler("eb_haiku_watcher") {}

    void SetMessageReceivedCallback(EbHaikuWatcherMessageCallback cb, void* userData) {
        fCallback = cb;
        fUserData = userData;
    }

    void MessageReceived(BMessage* message) override {
        if (fCallback) {
            fCallback(fUserData, message);
        } else {
            BHandler::MessageReceived(message);
        }
    }

private:
    EbHaikuWatcherMessageCallback fCallback = nullptr;
    void* fUserData = nullptr;
};
} // namespace

// ---- HWatcher ----

void* eb_haiku_watcher_create(void) {
    ShimHandler* handler = new ShimHandler();
    be_app->AddHandler(handler);
    return handler;
}

void eb_haiku_watcher_set_message_received_callback(void* watcher,
                                                      EbHaikuWatcherMessageCallback cb,
                                                      void* userData) {
    static_cast<ShimHandler*>(watcher)->SetMessageReceivedCallback(cb, userData);
}

void eb_haiku_watcher_destroy(void* watcher) {
    ShimHandler* handler = static_cast<ShimHandler*>(watcher);
    be_app->RemoveHandler(handler);
    delete handler;
}

// ---- BRoster ----

void* eb_haiku_roster_default(void) { return const_cast<BRoster*>(be_roster); }

int eb_haiku_roster_is_running(void* roster, const char* signature) {
    return static_cast<BRoster*>(roster)->IsRunning(signature) ? 1 : 0;
}

int eb_haiku_roster_team_for(void* roster, const char* signature) {
    return static_cast<BRoster*>(roster)->TeamFor(signature);
}

int eb_haiku_roster_launch(void* roster, const char* signature, int* outTeam) {
    team_id team;
    status_t rc = static_cast<BRoster*>(roster)->Launch(signature, static_cast<BMessage*>(nullptr),
                                                          &team);
    *outTeam = team;
    return rc;
}

int eb_haiku_roster_activate_app(void* roster, int team) {
    return static_cast<BRoster*>(roster)->ActivateApp(static_cast<team_id>(team));
}

int eb_haiku_roster_broadcast(void* roster, void* message) {
    return static_cast<BRoster*>(roster)->Broadcast(static_cast<BMessage*>(message));
}

namespace {
int fillAppInfoOut(const app_info& info, int* outThread, unsigned int* outFlags, void* outPath) {
    *outThread = info.thread;
    *outFlags = info.flags;
    return static_cast<BPath*>(outPath)->SetTo(&info.ref);
}
} // namespace

int eb_haiku_roster_get_app_info(void* roster, const char* signature, int* outTeam,
                                  int* outThread, unsigned int* outFlags, void* outPath) {
    app_info info;
    status_t rc = static_cast<BRoster*>(roster)->GetAppInfo(signature, &info);
    if (rc != B_OK) return rc;
    *outTeam = info.team;
    return fillAppInfoOut(info, outThread, outFlags, outPath);
}

int eb_haiku_roster_get_running_app_info(void* roster, int team, int* outThread,
                                          unsigned int* outFlags, void* outPath,
                                          char* outSignature, int sigBufSize) {
    app_info info;
    status_t rc = static_cast<BRoster*>(roster)->GetRunningAppInfo(static_cast<team_id>(team),
                                                                     &info);
    if (rc != B_OK) return rc;
    int pathRc = fillAppInfoOut(info, outThread, outFlags, outPath);
    if (pathRc != B_OK) return pathRc;
    int sigLen = static_cast<int>(std::strlen(info.signature));
    int toCopy = sigLen < sigBufSize ? sigLen : sigBufSize;
    std::memcpy(outSignature, info.signature, static_cast<size_t>(toCopy));
    return B_OK;
}

int eb_haiku_roster_find_app(void* roster, const char* mimeType, void* outPath) {
    entry_ref appRef;
    status_t rc = static_cast<BRoster*>(roster)->FindApp(mimeType, &appRef);
    if (rc != B_OK) return rc;
    return static_cast<BPath*>(outPath)->SetTo(&appRef);
}

namespace {
// eBasic's ZSTRING can't represent NULL - an empty string means "no
// filter" at this package's own idiomatic layer, translated here to
// the real optional NULL these Haiku functions expect.
const char* nullIfEmpty(const char* s) { return (s && s[0] != '\0') ? s : nullptr; }
} // namespace

void eb_haiku_roster_get_recent_documents(void* roster, void* outMessage, int maxCount,
                                           const char* fileType, const char* signature) {
    static_cast<BRoster*>(roster)->GetRecentDocuments(
        static_cast<BMessage*>(outMessage), maxCount, nullIfEmpty(fileType),
        nullIfEmpty(signature));
}

void eb_haiku_roster_get_recent_folders(void* roster, void* outMessage, int maxCount,
                                         const char* signature) {
    static_cast<BRoster*>(roster)->GetRecentFolders(static_cast<BMessage*>(outMessage), maxCount,
                                                      nullIfEmpty(signature));
}

void eb_haiku_roster_get_recent_apps(void* roster, void* outMessage, int maxCount) {
    static_cast<BRoster*>(roster)->GetRecentApps(static_cast<BMessage*>(outMessage), maxCount);
}

int eb_haiku_roster_start_watching(void* roster, void* watcher, unsigned int eventMask) {
    return static_cast<BRoster*>(roster)->StartWatching(
        BMessenger(static_cast<BHandler*>(watcher)), eventMask);
}

int eb_haiku_roster_stop_watching(void* roster, void* watcher) {
    return static_cast<BRoster*>(roster)->StopWatching(
        BMessenger(static_cast<BHandler*>(watcher)));
}

namespace {
bool refForPath(const char* path, entry_ref* outRef) {
    BEntry entry(path);
    return entry.InitCheck() == B_OK && entry.GetRef(outRef) == B_OK;
}
} // namespace

int eb_haiku_roster_is_running_for_path(void* roster, const char* path) {
    entry_ref ref;
    if (!refForPath(path, &ref)) return 0;
    return static_cast<BRoster*>(roster)->IsRunning(&ref) ? 1 : 0;
}

int eb_haiku_roster_team_for_path(void* roster, const char* path) {
    entry_ref ref;
    if (!refForPath(path, &ref)) return B_ENTRY_NOT_FOUND;
    return static_cast<BRoster*>(roster)->TeamFor(&ref);
}

int eb_haiku_roster_get_app_info_for_path(void* roster, const char* path, int* outTeam,
                                           int* outThread, unsigned int* outFlags,
                                           void* outPath) {
    entry_ref ref;
    if (!refForPath(path, &ref)) return B_ENTRY_NOT_FOUND;
    app_info info;
    status_t rc = static_cast<BRoster*>(roster)->GetAppInfo(&ref, &info);
    if (rc != B_OK) return rc;
    *outTeam = info.team;
    return fillAppInfoOut(info, outThread, outFlags, outPath);
}

int eb_haiku_roster_find_app_for_path(void* roster, const char* path, void* outPath) {
    entry_ref ref;
    if (!refForPath(path, &ref)) return B_ENTRY_NOT_FOUND;
    entry_ref appRef;
    status_t rc = static_cast<BRoster*>(roster)->FindApp(&ref, &appRef);
    if (rc != B_OK) return rc;
    return static_cast<BPath*>(outPath)->SetTo(&appRef);
}

// ---- BClipboard ----

void* eb_haiku_clipboard_default(void) { return be_clipboard; }

void* eb_haiku_clipboard_create(const char* name) { return new BClipboard(name); }

int eb_haiku_clipboard_lock(void* clipboard) {
    return static_cast<BClipboard*>(clipboard)->Lock() ? 1 : 0;
}

void eb_haiku_clipboard_unlock(void* clipboard) { static_cast<BClipboard*>(clipboard)->Unlock(); }

int eb_haiku_clipboard_clear(void* clipboard) {
    return static_cast<BClipboard*>(clipboard)->Clear();
}

int eb_haiku_clipboard_commit(void* clipboard) {
    return static_cast<BClipboard*>(clipboard)->Commit();
}

int eb_haiku_clipboard_revert(void* clipboard) {
    return static_cast<BClipboard*>(clipboard)->Revert();
}

void* eb_haiku_clipboard_data(void* clipboard) {
    return static_cast<BClipboard*>(clipboard)->Data();
}

void eb_haiku_clipboard_destroy(void* clipboard) { delete static_cast<BClipboard*>(clipboard); }

int eb_haiku_clipboard_set_text(void* clipboard, const char* text) {
    BClipboard* cb = static_cast<BClipboard*>(clipboard);
    if (!cb->Lock()) return B_ERROR;
    cb->Clear();
    BMessage* data = cb->Data();
    status_t rc = data->AddData("text/plain", B_MIME_TYPE, text, static_cast<ssize_t>(std::strlen(text)));
    if (rc == B_OK) rc = cb->Commit();
    cb->Unlock();
    return rc;
}

int eb_haiku_clipboard_get_text(void* clipboard, char* outBuf, int bufSize) {
    BClipboard* cb = static_cast<BClipboard*>(clipboard);
    if (!cb->Lock()) return B_ERROR;
    const void* data = nullptr;
    ssize_t numBytes = 0;
    status_t rc = cb->Data()->FindData("text/plain", B_MIME_TYPE, &data, &numBytes);
    if (rc == B_OK) {
        ssize_t toCopy = numBytes < bufSize ? numBytes : bufSize;
        std::memcpy(outBuf, data, static_cast<size_t>(toCopy));
    }
    cb->Unlock();
    return rc == B_OK ? static_cast<int>(numBytes) : rc;
}

int eb_haiku_clipboard_start_watching(void* clipboard, void* watcher) {
    return static_cast<BClipboard*>(clipboard)->StartWatching(
        BMessenger(static_cast<BHandler*>(watcher)));
}

int eb_haiku_clipboard_stop_watching(void* clipboard, void* watcher) {
    return static_cast<BClipboard*>(clipboard)->StopWatching(
        BMessenger(static_cast<BHandler*>(watcher)));
}

// ---- BApplication ----

void* eb_haiku_application_create(const char* signature) { return new BApplication(signature); }

int eb_haiku_application_init_check(void* app) {
    return static_cast<BApplication*>(app)->InitCheck();
}

int eb_haiku_application_run(void* app) {
    return static_cast<int>(static_cast<BApplication*>(app)->Run());
}

void eb_haiku_application_quit(void* app) {
    // IMPORTANT, confirmed by direct reproduction: calling Quit()
    // directly from a thread other than the one that called Run()
    // fails ("you must Lock the application object before calling
    // Quit()") - the same cross-thread hazard already documented for
    // BInvoker::Invoke()/BView::Invalidate() elsewhere in this shim.
    // Post a real B_QUIT_REQUESTED message instead (same fix as
    // eb_haiku_window_close above) - safe to call from any thread,
    // which is the whole point of this function (this package's own
    // doc comment already says "typically from another thread").
    BMessenger(static_cast<BApplication*>(app)).SendMessage(B_QUIT_REQUESTED);
}
void eb_haiku_application_destroy(void* app) { delete static_cast<BApplication*>(app); }

void eb_haiku_application_add_handler(void* app, void* handler) {
    // Same reasoning as shim_interface.cpp's own WindowAutolock use for
    // eb_haiku_window_add_handler - confirmed necessary there by direct
    // reproduction (hung indefinitely without it, called post-Run) -
    // BApplication is a real BLooper, so the identical cross-thread
    // mutation hazard applies here.
    BApplication* application = static_cast<BApplication*>(app);
    bool locked = application->Lock();
    application->AddHandler(static_cast<BHandler*>(handler));
    if (locked) application->Unlock();
}

} // extern "C"
