' Raw FFI layer: eb-haiku's Package Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_package.h. BPackageRoster
' basics only - not the full Solver/hpkg install/write machinery.

' Real BPackageInstallationLocation values (package/PackageDefs.h) - a
' plain sequential enum, confirmed via a compiled probe on the real
' Haiku host anyway, matching this package's own "verify, don't
' assume" discipline for every enum so far.
CONST H_PACKAGE_INSTALLATION_LOCATION_SYSTEM = 0
CONST H_PACKAGE_INSTALLATION_LOCATION_HOME = 1

Extern "C" Lib "ebhaikushim"
    ' ---- BPackageRoster ----
    Declare Function eb_haiku_package_roster_create() AS ANY PTR
    Declare Function eb_haiku_package_roster_is_reboot_needed(BYVAL roster AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_package_roster_get_common_repository_cache_path(BYVAL roster AS ANY PTR, BYVAL outPath AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_package_roster_get_user_repository_cache_path(BYVAL roster AS ANY PTR, BYVAL outPath AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_package_roster_get_common_repository_config_path(BYVAL roster AS ANY PTR, BYVAL outPath AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_package_roster_get_user_repository_config_path(BYVAL roster AS ANY PTR, BYVAL outPath AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_package_roster_get_active_packages(BYVAL roster AS ANY PTR, BYVAL location AS UINTEGER, BYVAL infoSet AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_package_roster_destroy(BYVAL roster AS ANY PTR)

    ' ---- BPackageInfoSet + Iterator ----
    Declare Function eb_haiku_package_info_set_create() AS ANY PTR
    Declare Function eb_haiku_package_info_set_count(BYVAL infoSet AS ANY PTR) AS UINTEGER
    Declare Sub eb_haiku_package_info_set_destroy(BYVAL infoSet AS ANY PTR)
    Declare Function eb_haiku_package_info_iterator_create(BYVAL infoSet AS ANY PTR) AS ANY PTR
    Declare Function eb_haiku_package_info_iterator_has_next(BYVAL iter AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_package_info_iterator_next(BYVAL iter AS ANY PTR) AS ANY PTR
    Declare Sub eb_haiku_package_info_iterator_destroy(BYVAL iter AS ANY PTR)

    ' ---- BPackageInfo ----
    Declare Function eb_haiku_package_info_name(BYVAL info AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_package_info_version_string(BYVAL info AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
End Extern
