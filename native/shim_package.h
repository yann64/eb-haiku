// eb-haiku native shim - Package Kit basics (BPackageRoster - query
// installed packages, repo paths, reboot-needed state). See shim.h's
// own top comment for why a hand-written shim is needed at all. Links
// against libpackage.so (confirmed real, present on the host via `ls
// /boot/system/lib/`).
//
// Deliberately just BPackageRoster + read-only package info - not the
// full Solver/hpkg install/write machinery (package-manager-authoring
// territory, far outside a scripting binding's useful scope).
#pragma once

extern "C" {

// ---- BPackageRoster ----

void* eb_haiku_package_roster_create(void);
int eb_haiku_package_roster_is_reboot_needed(void* roster);
// Each fills `outPath` (an eb_haiku_path_create_empty result, shim.h -
// this reuses the existing BPath binding directly, no new plumbing).
// Returns a status_t (0 = success).
int eb_haiku_package_roster_get_common_repository_cache_path(void* roster, void* outPath);
int eb_haiku_package_roster_get_user_repository_cache_path(void* roster, void* outPath);
int eb_haiku_package_roster_get_common_repository_config_path(void* roster, void* outPath);
int eb_haiku_package_roster_get_user_repository_config_path(void* roster, void* outPath);
// `location` is H_PACKAGE_INSTALLATION_LOCATION_SYSTEM/HOME (real
// values confirmed via probe - a plain sequential enum, not guessed).
// Fills `infoSet` (an eb_haiku_package_info_set_create result).
// Returns a status_t (0 = success).
int eb_haiku_package_roster_get_active_packages(void* roster, unsigned int location,
                                                 void* infoSet);
void eb_haiku_package_roster_destroy(void* roster);

// ---- BPackageInfoSet + Iterator ----

void* eb_haiku_package_info_set_create(void);
unsigned int eb_haiku_package_info_set_count(void* infoSet);
void eb_haiku_package_info_set_destroy(void* infoSet);

void* eb_haiku_package_info_iterator_create(void* infoSet);
int eb_haiku_package_info_iterator_has_next(void* iter);
// Returns a borrowed `const BPackageInfo*` - valid only as long as the
// owning `infoSet` itself is alive; not separately freed.
void* eb_haiku_package_info_iterator_next(void* iter);
void eb_haiku_package_info_iterator_destroy(void* iter);

// ---- BPackageInfo (borrowed handles from the iterator above) ----

// Both real BString-returning methods, copied into the caller's own
// buffer - same convention as shim_network.cpp's own
// copyBStringToBuffer helper. Returns the real length in bytes (>= 0).
int eb_haiku_package_info_name(void* info, char* outBuf, int bufSize);
int eb_haiku_package_info_version_string(void* info, char* outBuf, int bufSize);

} // extern "C"
