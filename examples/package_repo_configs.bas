' Package Kit - visit every real repository config file, and start (and
' immediately stop) watching for real package installation/removal
' notifications.

#include once "../src/lib.bas"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-PackageRepoConfigsExample")

DIM roster AS HPackageRoster
roster = HPackageRosterCreate()

SUB OnRepoConfigVisited(userData AS ANY PTR, path AS ZSTRING)
    PRINT "repo config: ", path
END SUB

DIM visitor AS ANY PTR
visitor = HRepositoryConfigVisitorCreate(@OnRepoConfigVisited, 0)
CALL HPackageRosterVisitCommonRepositoryConfigs(roster, visitor)
CALL HRepositoryConfigVisitorFree(visitor)

DIM watcher AS HWatcher
watcher = HWatcherCreate()
CALL HPackageRosterStartWatching(roster, watcher, H_WATCH_PACKAGE_INSTALLATION_LOCATIONS)
PRINT "watching for real package installation/removal events"
CALL HPackageRosterStopWatching(roster, watcher)
CALL HWatcherFree(watcher)

CALL HPackageRosterFree(roster)
CALL HApplicationFree(app)
