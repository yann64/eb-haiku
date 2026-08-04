#include "shim_storage.h"

#include <Directory.h>
#include <Entry.h>
#include <Handler.h>
#include <Messenger.h>
#include <MimeType.h>
#include <Query.h>
#include <SymLink.h>
#include <Volume.h>
#include <VolumeRoster.h>

#include <cstring>

extern "C" {

// ---- BSymLink ----

void* eb_haiku_symlink_create(const char* path) { return new BSymLink(path); }

int eb_haiku_symlink_init_check(void* link) {
    return static_cast<BSymLink*>(link)->InitCheck();
}

int eb_haiku_symlink_read_link(void* link, char* buf, int bufSize) {
    return static_cast<int>(
        static_cast<BSymLink*>(link)->ReadLink(buf, static_cast<size_t>(bufSize)));
}

int eb_haiku_symlink_is_absolute(void* link) {
    return static_cast<BSymLink*>(link)->IsAbsolute() ? 1 : 0;
}

void eb_haiku_symlink_destroy(void* link) { delete static_cast<BSymLink*>(link); }

// ---- BDirectory::CreateSymLink ----

int eb_haiku_directory_create_symlink(void* dir, const char* path, const char* linkToPath) {
    return static_cast<BDirectory*>(dir)->CreateSymLink(path, linkToPath, nullptr);
}

// ---- BVolume ----

void* eb_haiku_volume_create_empty(void) { return new BVolume(); }

int eb_haiku_volume_init_check(void* volume) {
    return static_cast<BVolume*>(volume)->InitCheck();
}

unsigned int eb_haiku_volume_device(void* volume) {
    return static_cast<unsigned int>(static_cast<BVolume*>(volume)->Device());
}

int eb_haiku_volume_capacity(void* volume, long long* outCapacity) {
    *outCapacity = static_cast<long long>(static_cast<BVolume*>(volume)->Capacity());
    return B_OK;
}

int eb_haiku_volume_free_bytes(void* volume, long long* outFreeBytes) {
    *outFreeBytes = static_cast<long long>(static_cast<BVolume*>(volume)->FreeBytes());
    return B_OK;
}

int eb_haiku_volume_get_name(void* volume, char* outName) {
    return static_cast<BVolume*>(volume)->GetName(outName);
}

int eb_haiku_volume_is_read_only(void* volume) {
    return static_cast<BVolume*>(volume)->IsReadOnly() ? 1 : 0;
}

int eb_haiku_volume_is_removable(void* volume) {
    return static_cast<BVolume*>(volume)->IsRemovable() ? 1 : 0;
}

int eb_haiku_volume_is_persistent(void* volume) {
    return static_cast<BVolume*>(volume)->IsPersistent() ? 1 : 0;
}

int eb_haiku_volume_is_shared(void* volume) {
    return static_cast<BVolume*>(volume)->IsShared() ? 1 : 0;
}

int eb_haiku_volume_knows_mime(void* volume) {
    return static_cast<BVolume*>(volume)->KnowsMime() ? 1 : 0;
}

int eb_haiku_volume_knows_attr(void* volume) {
    return static_cast<BVolume*>(volume)->KnowsAttr() ? 1 : 0;
}

int eb_haiku_volume_knows_query(void* volume) {
    return static_cast<BVolume*>(volume)->KnowsQuery() ? 1 : 0;
}

void eb_haiku_volume_destroy(void* volume) { delete static_cast<BVolume*>(volume); }

// ---- BVolumeRoster ----

void* eb_haiku_volume_roster_create(void) { return new BVolumeRoster(); }

int eb_haiku_volume_roster_get_next_volume(void* roster, void* outVolume) {
    return static_cast<BVolumeRoster*>(roster)->GetNextVolume(static_cast<BVolume*>(outVolume));
}

void eb_haiku_volume_roster_rewind(void* roster) {
    static_cast<BVolumeRoster*>(roster)->Rewind();
}

int eb_haiku_volume_roster_get_boot_volume(void* roster, void* outVolume) {
    return static_cast<BVolumeRoster*>(roster)->GetBootVolume(static_cast<BVolume*>(outVolume));
}

int eb_haiku_volume_roster_start_watching(void* roster, void* watcher) {
    return static_cast<BVolumeRoster*>(roster)->StartWatching(
        BMessenger(static_cast<BHandler*>(watcher)));
}

void eb_haiku_volume_roster_stop_watching(void* roster) {
    static_cast<BVolumeRoster*>(roster)->StopWatching();
}

void eb_haiku_volume_roster_destroy(void* roster) { delete static_cast<BVolumeRoster*>(roster); }

// ---- BQuery ----

void* eb_haiku_query_create(void) { return new BQuery(); }

int eb_haiku_query_set_volume(void* query, void* volume) {
    return static_cast<BQuery*>(query)->SetVolume(static_cast<BVolume*>(volume));
}

int eb_haiku_query_set_predicate(void* query, const char* expression) {
    return static_cast<BQuery*>(query)->SetPredicate(expression);
}

int eb_haiku_query_fetch(void* query) { return static_cast<BQuery*>(query)->Fetch(); }

int eb_haiku_query_get_next_entry(void* query, void* outEntry) {
    return static_cast<BQuery*>(query)->GetNextEntry(static_cast<BEntry*>(outEntry), false);
}

int eb_haiku_query_rewind(void* query) { return static_cast<BQuery*>(query)->Rewind(); }

int eb_haiku_query_count_entries(void* query) {
    return static_cast<BQuery*>(query)->CountEntries();
}

int eb_haiku_query_set_target(void* query, void* watcher) {
    return static_cast<BQuery*>(query)->SetTarget(BMessenger(static_cast<BHandler*>(watcher)));
}

int eb_haiku_query_is_live(void* query) { return static_cast<BQuery*>(query)->IsLive() ? 1 : 0; }

void eb_haiku_query_destroy(void* query) { delete static_cast<BQuery*>(query); }

namespace {
int copyCStringToBuffer(const char* s, char* outBuf, int bufSize) {
    int len = static_cast<int>(std::strlen(s));
    int toCopy = len < bufSize ? len : bufSize;
    std::memcpy(outBuf, s, static_cast<size_t>(toCopy));
    return len;
}
} // namespace

// ---- BMimeType ----

void* eb_haiku_mime_type_create(const char* mimeType) { return new BMimeType(mimeType); }

int eb_haiku_mime_type_set_to(void* mime, const char* mimeType) {
    return static_cast<BMimeType*>(mime)->SetTo(mimeType);
}

int eb_haiku_mime_type_init_check(void* mime) {
    return static_cast<BMimeType*>(mime)->InitCheck();
}

int eb_haiku_mime_type_is_valid(void* mime) {
    return static_cast<BMimeType*>(mime)->IsValid() ? 1 : 0;
}

int eb_haiku_mime_type_is_installed(void* mime) {
    return static_cast<BMimeType*>(mime)->IsInstalled() ? 1 : 0;
}

int eb_haiku_mime_type_install(void* mime) { return static_cast<BMimeType*>(mime)->Install(); }

int eb_haiku_mime_type_delete(void* mime) { return static_cast<BMimeType*>(mime)->Delete(); }

const char* eb_haiku_mime_type_type(void* mime) {
    const char* result = static_cast<BMimeType*>(mime)->Type();
    return result ? result : "";
}

int eb_haiku_mime_type_get_short_description(void* mime, char* outBuf, int bufSize) {
    char local[1024] = {0};
    status_t rc = static_cast<BMimeType*>(mime)->GetShortDescription(local);
    if (rc != B_OK) return rc;
    return copyCStringToBuffer(local, outBuf, bufSize);
}

int eb_haiku_mime_type_set_short_description(void* mime, const char* description) {
    return static_cast<BMimeType*>(mime)->SetShortDescription(description);
}

int eb_haiku_mime_type_get_long_description(void* mime, char* outBuf, int bufSize) {
    char local[1024] = {0};
    status_t rc = static_cast<BMimeType*>(mime)->GetLongDescription(local);
    if (rc != B_OK) return rc;
    return copyCStringToBuffer(local, outBuf, bufSize);
}

int eb_haiku_mime_type_set_long_description(void* mime, const char* description) {
    return static_cast<BMimeType*>(mime)->SetLongDescription(description);
}

int eb_haiku_mime_type_get_preferred_app(void* mime, char* outBuf, int bufSize) {
    char local[1024] = {0};
    status_t rc = static_cast<BMimeType*>(mime)->GetPreferredApp(local);
    if (rc != B_OK) return rc;
    return copyCStringToBuffer(local, outBuf, bufSize);
}

int eb_haiku_mime_type_set_preferred_app(void* mime, const char* signature) {
    return static_cast<BMimeType*>(mime)->SetPreferredApp(signature);
}

int eb_haiku_mime_type_get_file_extensions(void* mime, void* outMessage) {
    return static_cast<BMimeType*>(mime)->GetFileExtensions(static_cast<BMessage*>(outMessage));
}

int eb_haiku_mime_type_set_file_extensions(void* mime, void* extensionsMessage) {
    return static_cast<BMimeType*>(mime)->SetFileExtensions(
        static_cast<const BMessage*>(extensionsMessage));
}

int eb_haiku_mime_type_get_supporting_apps(void* mime, void* outMessage) {
    return static_cast<BMimeType*>(mime)->GetSupportingApps(static_cast<BMessage*>(outMessage));
}

void eb_haiku_mime_type_destroy(void* mime) { delete static_cast<BMimeType*>(mime); }

int eb_haiku_mime_type_guess_mime_type(const char* path, void* outMime) {
    return BMimeType::GuessMimeType(path, static_cast<BMimeType*>(outMime));
}

int eb_haiku_mime_type_get_installed_types(void* outMessage) {
    return BMimeType::GetInstalledTypes(static_cast<BMessage*>(outMessage));
}

int eb_haiku_mime_type_get_installed_supertypes(void* outMessage) {
    return BMimeType::GetInstalledSupertypes(static_cast<BMessage*>(outMessage));
}

} // extern "C"
