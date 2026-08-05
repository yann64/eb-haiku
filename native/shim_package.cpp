#include "shim_package.h"

#include <Entry.h>
#include <Handler.h>
#include <Messenger.h>
#include <Path.h>
#include <package/PackageInfo.h>
#include <package/PackageInfoSet.h>
#include <package/PackageRoster.h>
#include <package/PackageVersion.h>

#include <cstring>

using namespace BPackageKit;

namespace {

int copyBStringToBuffer(const BString& s, char* outBuf, int bufSize) {
    int len = s.Length();
    int toCopy = len < bufSize ? len : bufSize;
    std::memcpy(outBuf, s.String(), static_cast<size_t>(toCopy));
    return len;
}

/// Same forwarding pattern as shim_interface.cpp's own ShimView/
/// ShimWindow (see their top comments) - the only way to reach
/// BRepositoryConfigVisitor's own virtual operator() from eBasic.
class ShimRepositoryConfigVisitor : public BRepositoryConfigVisitor {
public:
    ShimRepositoryConfigVisitor(EbHaikuRepoConfigVisitCallback cb, void* userData)
        : fCallback(cb), fUserData(userData) {}

    status_t operator()(const BEntry& entry) override {
        BPath path;
        if (fCallback && entry.GetPath(&path) == B_OK) {
            fCallback(fUserData, path.Path());
        }
        return B_OK;
    }

private:
    EbHaikuRepoConfigVisitCallback fCallback;
    void* fUserData;
};

} // namespace

extern "C" {

// ---- BPackageRoster ----

void* eb_haiku_package_roster_create(void) { return new BPackageRoster(); }

int eb_haiku_package_roster_is_reboot_needed(void* roster) {
    return static_cast<BPackageRoster*>(roster)->IsRebootNeeded() ? 1 : 0;
}

int eb_haiku_package_roster_get_common_repository_cache_path(void* roster, void* outPath) {
    return static_cast<BPackageRoster*>(roster)->GetCommonRepositoryCachePath(
        static_cast<BPath*>(outPath));
}

int eb_haiku_package_roster_get_user_repository_cache_path(void* roster, void* outPath) {
    return static_cast<BPackageRoster*>(roster)->GetUserRepositoryCachePath(
        static_cast<BPath*>(outPath));
}

int eb_haiku_package_roster_get_common_repository_config_path(void* roster, void* outPath) {
    return static_cast<BPackageRoster*>(roster)->GetCommonRepositoryConfigPath(
        static_cast<BPath*>(outPath));
}

int eb_haiku_package_roster_get_user_repository_config_path(void* roster, void* outPath) {
    return static_cast<BPackageRoster*>(roster)->GetUserRepositoryConfigPath(
        static_cast<BPath*>(outPath));
}

int eb_haiku_package_roster_get_active_packages(void* roster, unsigned int location,
                                                 void* infoSet) {
    return static_cast<BPackageRoster*>(roster)->GetActivePackages(
        static_cast<BPackageInstallationLocation>(location),
        *static_cast<BPackageInfoSet*>(infoSet));
}

int eb_haiku_package_roster_visit_common_repository_configs(void* roster, void* visitor) {
    return static_cast<BPackageRoster*>(roster)->VisitCommonRepositoryConfigs(
        *static_cast<ShimRepositoryConfigVisitor*>(visitor));
}

int eb_haiku_package_roster_visit_user_repository_configs(void* roster, void* visitor) {
    return static_cast<BPackageRoster*>(roster)->VisitUserRepositoryConfigs(
        *static_cast<ShimRepositoryConfigVisitor*>(visitor));
}

int eb_haiku_package_roster_start_watching(void* roster, void* watcher, unsigned int eventMask) {
    return static_cast<BPackageRoster*>(roster)->StartWatching(
        BMessenger(static_cast<BHandler*>(watcher)), eventMask);
}

int eb_haiku_package_roster_stop_watching(void* roster, void* watcher) {
    return static_cast<BPackageRoster*>(roster)->StopWatching(
        BMessenger(static_cast<BHandler*>(watcher)));
}

void eb_haiku_package_roster_destroy(void* roster) { delete static_cast<BPackageRoster*>(roster); }

void* eb_haiku_repo_config_visitor_create(EbHaikuRepoConfigVisitCallback cb, void* userData) {
    return new ShimRepositoryConfigVisitor(cb, userData);
}

void eb_haiku_repo_config_visitor_destroy(void* visitor) {
    delete static_cast<ShimRepositoryConfigVisitor*>(visitor);
}

// ---- BPackageInfoSet + Iterator ----

void* eb_haiku_package_info_set_create(void) { return new BPackageInfoSet(); }

unsigned int eb_haiku_package_info_set_count(void* infoSet) {
    return static_cast<BPackageInfoSet*>(infoSet)->CountInfos();
}

void eb_haiku_package_info_set_destroy(void* infoSet) {
    delete static_cast<BPackageInfoSet*>(infoSet);
}

void* eb_haiku_package_info_iterator_create(void* infoSet) {
    return new BPackageInfoSet::Iterator(static_cast<BPackageInfoSet*>(infoSet)->GetIterator());
}

int eb_haiku_package_info_iterator_has_next(void* iter) {
    return static_cast<BPackageInfoSet::Iterator*>(iter)->HasNext() ? 1 : 0;
}

void* eb_haiku_package_info_iterator_next(void* iter) {
    return const_cast<BPackageInfo*>(static_cast<BPackageInfoSet::Iterator*>(iter)->Next());
}

void eb_haiku_package_info_iterator_destroy(void* iter) {
    delete static_cast<BPackageInfoSet::Iterator*>(iter);
}

// ---- BPackageInfo ----

int eb_haiku_package_info_name(void* info, char* outBuf, int bufSize) {
    return copyBStringToBuffer(static_cast<BPackageInfo*>(info)->Name(), outBuf, bufSize);
}

int eb_haiku_package_info_version_string(void* info, char* outBuf, int bufSize) {
    return copyBStringToBuffer(static_cast<BPackageInfo*>(info)->Version().ToString(), outBuf,
                                bufSize);
}

} // extern "C"
