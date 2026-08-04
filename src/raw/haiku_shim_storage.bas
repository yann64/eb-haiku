' Raw FFI layer: eb-haiku's Storage Kit extension shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_storage.h.

Extern "C" Lib "ebhaikushim"
    ' ---- BSymLink ----
    Declare Function eb_haiku_symlink_create(BYVAL path AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_symlink_init_check(BYVAL link AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_symlink_read_link(BYVAL link AS ANY PTR, BYVAL buf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_symlink_is_absolute(BYVAL link AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_symlink_destroy(BYVAL link AS ANY PTR)

    ' ---- BDirectory::CreateSymLink ----
    Declare Function eb_haiku_directory_create_symlink(BYVAL dir AS ANY PTR, BYVAL path AS ZSTRING, BYVAL linkToPath AS ZSTRING) AS INTEGER

    ' ---- BVolume ----
    Declare Function eb_haiku_volume_create_empty() AS ANY PTR
    Declare Function eb_haiku_volume_init_check(BYVAL volume AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_volume_device(BYVAL volume AS ANY PTR) AS UINTEGER
    Declare Function eb_haiku_volume_capacity(BYVAL volume AS ANY PTR, BYVAL outCapacity AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_volume_free_bytes(BYVAL volume AS ANY PTR, BYVAL outFreeBytes AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_volume_get_name(BYVAL volume AS ANY PTR, BYVAL outName AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_volume_is_read_only(BYVAL volume AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_volume_is_removable(BYVAL volume AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_volume_is_persistent(BYVAL volume AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_volume_is_shared(BYVAL volume AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_volume_knows_mime(BYVAL volume AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_volume_knows_attr(BYVAL volume AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_volume_knows_query(BYVAL volume AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_volume_destroy(BYVAL volume AS ANY PTR)

    ' ---- BVolumeRoster ----
    Declare Function eb_haiku_volume_roster_create() AS ANY PTR
    Declare Function eb_haiku_volume_roster_get_next_volume(BYVAL roster AS ANY PTR, BYVAL outVolume AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_volume_roster_rewind(BYVAL roster AS ANY PTR)
    Declare Function eb_haiku_volume_roster_get_boot_volume(BYVAL roster AS ANY PTR, BYVAL outVolume AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_volume_roster_destroy(BYVAL roster AS ANY PTR)

    ' ---- BQuery ----
    Declare Function eb_haiku_query_create() AS ANY PTR
    Declare Function eb_haiku_query_set_volume(BYVAL query AS ANY PTR, BYVAL volume AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_query_set_predicate(BYVAL query AS ANY PTR, BYVAL expression AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_query_fetch(BYVAL query AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_query_get_next_entry(BYVAL query AS ANY PTR, BYVAL outEntry AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_query_rewind(BYVAL query AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_query_count_entries(BYVAL query AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_query_destroy(BYVAL query AS ANY PTR)
End Extern
