' Idiomatic layer: BPackageRoster - query installed packages, real
' repository cache/config paths, reboot-needed state. Deliberately just
' this - not the full Solver/hpkg install/write machinery (package-
' manager-authoring territory, far outside a scripting binding's
' useful scope).

#include once "raw/haiku_shim_package.bas"
#include once "path.bas"
#include once "watcher.bas"

TYPE HPackageRoster
    handle AS ANY PTR
END TYPE

TYPE HPackageInfoSet
    handle AS ANY PTR
END TYPE

FUNCTION HPackageRosterCreate() AS HPackageRoster
    DIM r AS HPackageRoster
    r.handle = eb_haiku_package_roster_create()
    HPackageRosterCreate = r
END FUNCTION

FUNCTION HPackageRosterIsRebootNeeded(BYVAL r AS HPackageRoster) AS INTEGER
    HPackageRosterIsRebootNeeded = eb_haiku_package_roster_is_reboot_needed(r.handle)
END FUNCTION

''' Each fills `outPath` (an HPathCreateEmpty result, path.bas) with a
''' real repository cache/config directory. Returns a status code (0 =
''' success).
FUNCTION HPackageRosterGetCommonRepositoryCachePath(BYVAL r AS HPackageRoster, BYVAL outPath AS HPath) AS INTEGER
    HPackageRosterGetCommonRepositoryCachePath = eb_haiku_package_roster_get_common_repository_cache_path(r.handle, outPath.handle)
END FUNCTION

FUNCTION HPackageRosterGetUserRepositoryCachePath(BYVAL r AS HPackageRoster, BYVAL outPath AS HPath) AS INTEGER
    HPackageRosterGetUserRepositoryCachePath = eb_haiku_package_roster_get_user_repository_cache_path(r.handle, outPath.handle)
END FUNCTION

FUNCTION HPackageRosterGetCommonRepositoryConfigPath(BYVAL r AS HPackageRoster, BYVAL outPath AS HPath) AS INTEGER
    HPackageRosterGetCommonRepositoryConfigPath = eb_haiku_package_roster_get_common_repository_config_path(r.handle, outPath.handle)
END FUNCTION

FUNCTION HPackageRosterGetUserRepositoryConfigPath(BYVAL r AS HPackageRoster, BYVAL outPath AS HPath) AS INTEGER
    HPackageRosterGetUserRepositoryConfigPath = eb_haiku_package_roster_get_user_repository_config_path(r.handle, outPath.handle)
END FUNCTION

''' Fills `infoSet` (an HPackageInfoSetCreate result) with every
''' currently-active package at `location`
''' (H_PACKAGE_INSTALLATION_LOCATION_SYSTEM/HOME). Returns a status
''' code (0 = success).
FUNCTION HPackageRosterGetActivePackages(BYVAL r AS HPackageRoster, BYVAL location AS UINTEGER, BYVAL infoSet AS HPackageInfoSet) AS INTEGER
    HPackageRosterGetActivePackages = eb_haiku_package_roster_get_active_packages(r.handle, location, infoSet.handle)
END FUNCTION

''' Visits each real repository config file under the common (system-
''' wide) install location - `visitor` is an HRepositoryConfigVisitorCreate
''' result. Returns a status code (0 = success).
FUNCTION HPackageRosterVisitCommonRepositoryConfigs(BYVAL r AS HPackageRoster, BYVAL visitor AS ANY PTR) AS INTEGER
    HPackageRosterVisitCommonRepositoryConfigs = eb_haiku_package_roster_visit_common_repository_configs(r.handle, visitor)
END FUNCTION

''' Same as HPackageRosterVisitCommonRepositoryConfigs, for the
''' per-user install location.
FUNCTION HPackageRosterVisitUserRepositoryConfigs(BYVAL r AS HPackageRoster, BYVAL visitor AS ANY PTR) AS INTEGER
    HPackageRosterVisitUserRepositoryConfigs = eb_haiku_package_roster_visit_user_repository_configs(r.handle, visitor)
END FUNCTION

''' Makes `watcher` a real live target for package installation/
''' removal notifications - `eventMask` is
''' H_WATCH_PACKAGE_INSTALLATION_LOCATIONS. Returns a status code (0 =
''' success).
FUNCTION HPackageRosterStartWatching(BYVAL r AS HPackageRoster, BYVAL watcher AS HWatcher, BYVAL eventMask AS UINTEGER) AS INTEGER
    HPackageRosterStartWatching = eb_haiku_package_roster_start_watching(r.handle, watcher.handle, eventMask)
END FUNCTION

FUNCTION HPackageRosterStopWatching(BYVAL r AS HPackageRoster, BYVAL watcher AS HWatcher) AS INTEGER
    HPackageRosterStopWatching = eb_haiku_package_roster_stop_watching(r.handle, watcher.handle)
END FUNCTION

SUB HPackageRosterFree(BYVAL r AS HPackageRoster)
    CALL eb_haiku_package_roster_destroy(r.handle)
END SUB

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, path AS ZSTRING) - called once per real repository config file
''' found by HPackageRosterVisitCommonRepositoryConfigs/
''' VisitUserRepositoryConfigs.
FUNCTION HRepositoryConfigVisitorCreate(cb AS ANY PTR, userData AS ANY PTR) AS ANY PTR
    HRepositoryConfigVisitorCreate = eb_haiku_repo_config_visitor_create(cb, userData)
END FUNCTION

''' Frees an HRepositoryConfigVisitorCreate result - call exactly once.
SUB HRepositoryConfigVisitorFree(BYVAL visitor AS ANY PTR)
    CALL eb_haiku_repo_config_visitor_destroy(visitor)
END SUB

FUNCTION HPackageInfoSetCreate() AS HPackageInfoSet
    DIM s AS HPackageInfoSet
    s.handle = eb_haiku_package_info_set_create()
    HPackageInfoSetCreate = s
END FUNCTION

FUNCTION HPackageInfoSetCount(BYVAL s AS HPackageInfoSet) AS UINTEGER
    HPackageInfoSetCount = eb_haiku_package_info_set_count(s.handle)
END FUNCTION

SUB HPackageInfoSetFree(BYVAL s AS HPackageInfoSet)
    CALL eb_haiku_package_info_set_destroy(s.handle)
END SUB

TYPE HPackageInfoIterator
    handle AS ANY PTR
END TYPE

FUNCTION HPackageInfoIteratorCreate(BYVAL s AS HPackageInfoSet) AS HPackageInfoIterator
    DIM it AS HPackageInfoIterator
    it.handle = eb_haiku_package_info_iterator_create(s.handle)
    HPackageInfoIteratorCreate = it
END FUNCTION

FUNCTION HPackageInfoIteratorHasNext(BYVAL it AS HPackageInfoIterator) AS INTEGER
    HPackageInfoIteratorHasNext = eb_haiku_package_info_iterator_has_next(it.handle)
END FUNCTION

''' The next package's own info handle - borrowed from the owning
''' HPackageInfoSet, valid only as long as it's alive; not separately
''' freed. Use with HPackageInfoName/HPackageInfoVersionString.
'''
''' DIM s AS HPackageInfoSet : s = HPackageInfoSetCreate()
''' CALL HPackageRosterGetActivePackages(roster, H_PACKAGE_INSTALLATION_LOCATION_SYSTEM, s)
''' DIM it AS HPackageInfoIterator : it = HPackageInfoIteratorCreate(s)
''' DO WHILE HPackageInfoIteratorHasNext(it) <> 0
'''     DIM info AS ANY PTR : info = HPackageInfoIteratorNext(it)
'''     ' ... HPackageInfoName(info, ...) / HPackageInfoVersionString(info, ...)
''' LOOP
''' CALL HPackageInfoIteratorFree(it)
''' CALL HPackageInfoSetFree(s)
FUNCTION HPackageInfoIteratorNext(BYVAL it AS HPackageInfoIterator) AS ANY PTR
    HPackageInfoIteratorNext = eb_haiku_package_info_iterator_next(it.handle)
END FUNCTION

SUB HPackageInfoIteratorFree(BYVAL it AS HPackageInfoIterator)
    CALL eb_haiku_package_info_iterator_destroy(it.handle)
END SUB

''' Fills `outBuf` (caller-supplied, NOT null-terminated automatically)
''' with a package's own real name. `info` is an
''' HPackageInfoIteratorNext result. Returns the real length in bytes
''' (>= 0).
FUNCTION HPackageInfoName(BYVAL info AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HPackageInfoName = eb_haiku_package_info_name(info, outBuf, bufSize)
END FUNCTION

''' Same shape as HPackageInfoName, for the package's own real version
''' string (e.g. "1.2-3").
FUNCTION HPackageInfoVersionString(BYVAL info AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HPackageInfoVersionString = eb_haiku_package_info_version_string(info, outBuf, bufSize)
END FUNCTION
