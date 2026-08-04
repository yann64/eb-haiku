#include "shim_storage.h"

#include <Directory.h>
#include <Entry.h>
#include <Query.h>
#include <SymLink.h>
#include <Volume.h>
#include <VolumeRoster.h>

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

void eb_haiku_query_destroy(void* query) { delete static_cast<BQuery*>(query); }

} // extern "C"
