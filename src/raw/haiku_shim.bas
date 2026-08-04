' Raw FFI layer: eb-haiku's own native shim (`ebhaikushim`) - see
' /home/yann64/git/cpp/eb-haiku/native/shim.h. Haiku's Kits (BPath/
' BEntry/BDirectory/BNode/BMessage/BApplication) are real C++ classes
' with no parallel C API at all (unlike GTK4/GLib, which eb-gtk4 binds
' directly) - eBasic's Extern mechanism only ever binds free functions,
' never a foreign class's constructor or methods, so this package's own
' native/ directory is a small, hand-written extern "C" shim exposing a
' flat, unmangled ABI. Every Haiku object lives behind an opaque `ANY
' PTR` handle - matching this project's own established handle pattern
' (see docs/reference/extern-interop.md) - constructed/destroyed only
' through this shim, never inspected directly.
'
' Every boolean-shaped result is a plain INTEGER (0/1, C convention) -
' not BOOLEAN (eBasic's own TRUE = -1 convention) - matching eb-cjson's
' own Is* functions for exactly the same reason: these are real C `int`
' return values from the shim, not eBasic BOOLEAN expressions.

' Real Haiku type_code constants (support/TypeConstants.h) - FourCC-
' style, NOT hand-derivable reliably (multichar-literal bit packing is
' compiler/platform behavior) - confirmed by compiling and printing
' each one on the real Haiku host, matching this package's own
' "verify, don't assume" discipline. Used to interpret
' eb_haiku_node_get_attr_info's own outType result.
CONST H_ATTR_TYPE_INT32 = 1280265799
CONST H_ATTR_TYPE_INT64 = 1280069191
CONST H_ATTR_TYPE_BOOL = 1112493900
CONST H_ATTR_TYPE_DOUBLE = 1145195589
CONST H_ATTR_TYPE_STRING = 1129534546
CONST H_ATTR_TYPE_RAW = 1380013908
' Also the real type Haiku's own clipboard convention uses for plain
' text (a "text/plain" field, see eb_haiku_clipboard_data's own
' comment) - confirmed the same way, not assumed.
CONST H_ATTR_TYPE_MIME = 1296649541

Extern "C" Lib "ebhaikushim"
    ' ---- BPath ----
    Declare Function eb_haiku_path_create(BYVAL pathStr AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_path_create_empty() AS ANY PTR
    Declare Function eb_haiku_path_append(BYVAL path AS ANY PTR, BYVAL leaf AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_path_get(BYVAL path AS ANY PTR) AS ZSTRING
    Declare Function eb_haiku_path_leaf(BYVAL path AS ANY PTR) AS ZSTRING
    Declare Function eb_haiku_path_get_parent(BYVAL path AS ANY PTR, BYVAL outParentPath AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_path_is_absolute(BYVAL path AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_path_init_check(BYVAL path AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_path_destroy(BYVAL path AS ANY PTR)

    ' ---- BEntry ----
    Declare Function eb_haiku_entry_create(BYVAL path AS ZSTRING, BYVAL traverse AS INTEGER) AS ANY PTR
    Declare Function eb_haiku_entry_create_empty() AS ANY PTR
    Declare Function eb_haiku_entry_init_check(BYVAL entry AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_exists(BYVAL entry AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_is_directory(BYVAL entry AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_is_file(BYVAL entry AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_name(BYVAL entry AS ANY PTR) AS ZSTRING
    Declare Function eb_haiku_entry_get_path(BYVAL entry AS ANY PTR, BYVAL outPath AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_remove(BYVAL entry AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_rename(BYVAL entry AS ANY PTR, BYVAL newPath AS ZSTRING, BYVAL clobber AS INTEGER) AS INTEGER
    Declare Sub eb_haiku_entry_destroy(BYVAL entry AS ANY PTR)

    ' ---- BEntry / BStatable (real stat info) ----
    Declare Function eb_haiku_entry_is_symlink(BYVAL entry AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_get_permissions(BYVAL entry AS ANY PTR, BYVAL outPermissions AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_set_permissions(BYVAL entry AS ANY PTR, BYVAL permissions AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_entry_get_owner(BYVAL entry AS ANY PTR, BYVAL outOwner AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_set_owner(BYVAL entry AS ANY PTR, BYVAL owner AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_entry_get_group(BYVAL entry AS ANY PTR, BYVAL outGroup AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_set_group(BYVAL entry AS ANY PTR, BYVAL group AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_entry_get_size(BYVAL entry AS ANY PTR, BYVAL outSize AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_get_modification_time(BYVAL entry AS ANY PTR, BYVAL outTime AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_set_modification_time(BYVAL entry AS ANY PTR, BYVAL time AS LONGINT) AS INTEGER
    Declare Function eb_haiku_entry_get_creation_time(BYVAL entry AS ANY PTR, BYVAL outTime AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_entry_set_creation_time(BYVAL entry AS ANY PTR, BYVAL time AS LONGINT) AS INTEGER
    Declare Function eb_haiku_entry_get_volume(BYVAL entry AS ANY PTR, BYVAL outVolume AS ANY PTR) AS INTEGER

    ' ---- BDirectory ----
    Declare Function eb_haiku_directory_create(BYVAL path AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_directory_init_check(BYVAL dir AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_directory_get_next_entry(BYVAL dir AS ANY PTR, BYVAL outEntry AS ANY PTR, BYVAL traverse AS INTEGER) AS INTEGER
    Declare Function eb_haiku_directory_rewind(BYVAL dir AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_directory_count_entries(BYVAL dir AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_directory_create_directory(BYVAL dir AS ANY PTR, BYVAL path AS ZSTRING) AS INTEGER
    Declare Sub eb_haiku_directory_destroy(BYVAL dir AS ANY PTR)

    ' ---- BNode (extended attributes) ----
    Declare Function eb_haiku_node_create(BYVAL path AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_node_init_check(BYVAL node AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_node_write_attr_string(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING, BYVAL value AS ZSTRING) AS INTEGER
    ' Returns a newly heap-allocated string (free via
    ' eb_haiku_free_string), or a null ANY PTR if the attribute is
    ' absent - not a caller-supplied buffer, since no top-level STRING-
    ' returning function can cross this package's own --lib boundary,
    ' and a pointer into a local buffer would dangle immediately anyway.
    Declare Function eb_haiku_node_read_attr_string(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_node_remove_attr(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_node_get_next_attr_name(BYVAL node AS ANY PTR) AS ANY PTR
    Declare Function eb_haiku_node_rewind_attrs(BYVAL node AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_node_destroy(BYVAL node AS ANY PTR)

    ' ---- BNode / BStatable (real stat info) ----
    Declare Function eb_haiku_node_get_permissions(BYVAL node AS ANY PTR, BYVAL outPermissions AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_node_set_permissions(BYVAL node AS ANY PTR, BYVAL permissions AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_node_get_owner(BYVAL node AS ANY PTR, BYVAL outOwner AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_node_set_owner(BYVAL node AS ANY PTR, BYVAL owner AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_node_get_group(BYVAL node AS ANY PTR, BYVAL outGroup AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_node_set_group(BYVAL node AS ANY PTR, BYVAL group AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_node_get_size(BYVAL node AS ANY PTR, BYVAL outSize AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_node_get_modification_time(BYVAL node AS ANY PTR, BYVAL outTime AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_node_set_modification_time(BYVAL node AS ANY PTR, BYVAL time AS LONGINT) AS INTEGER
    Declare Function eb_haiku_node_get_creation_time(BYVAL node AS ANY PTR, BYVAL outTime AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_node_set_creation_time(BYVAL node AS ANY PTR, BYVAL time AS LONGINT) AS INTEGER
    Declare Function eb_haiku_node_get_volume(BYVAL node AS ANY PTR, BYVAL outVolume AS ANY PTR) AS INTEGER

    ' ---- BNode typed attributes (beyond B_STRING_TYPE) ----
    Declare Function eb_haiku_node_write_attr_int32(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING, BYVAL value AS INTEGER) AS INTEGER
    Declare Function eb_haiku_node_read_attr_int32(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING, BYVAL outValue AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_node_write_attr_int64(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING, BYVAL value AS LONGINT) AS INTEGER
    Declare Function eb_haiku_node_read_attr_int64(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING, BYVAL outValue AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_node_write_attr_bool(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING, BYVAL value AS INTEGER) AS INTEGER
    Declare Function eb_haiku_node_read_attr_bool(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING, BYVAL outValue AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_node_write_attr_double(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING, BYVAL value AS DOUBLE) AS INTEGER
    Declare Function eb_haiku_node_read_attr_double(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING, BYVAL outValue AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_node_write_attr_raw(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING, BYVAL buffer AS ANY PTR, BYVAL size AS INTEGER) AS INTEGER
    Declare Function eb_haiku_node_read_attr_raw(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING, BYVAL buffer AS ANY PTR, BYVAL bufferSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_node_get_attr_info(BYVAL node AS ANY PTR, BYVAL name AS ZSTRING, BYVAL outType AS ANY PTR, BYVAL outSize AS ANY PTR) AS INTEGER

    ' ---- BNodeInfo (MIME type) ----
    Declare Function eb_haiku_nodeinfo_create(BYVAL node AS ANY PTR) AS ANY PTR
    Declare Function eb_haiku_nodeinfo_get_type(BYVAL nodeInfo AS ANY PTR) AS ANY PTR
    Declare Function eb_haiku_nodeinfo_set_type(BYVAL nodeInfo AS ANY PTR, BYVAL mimeType AS ZSTRING) AS INTEGER
    Declare Sub eb_haiku_nodeinfo_destroy(BYVAL nodeInfo AS ANY PTR)

    Declare Sub eb_haiku_free_string(BYVAL s AS ANY PTR)

    ' ---- BMessage ----
    Declare Function eb_haiku_message_create(BYVAL what AS UINTEGER) AS ANY PTR
    Declare Sub eb_haiku_message_destroy(BYVAL msg AS ANY PTR)
    Declare Function eb_haiku_message_what(BYVAL msg AS ANY PTR) AS UINTEGER
    Declare Function eb_haiku_message_add_string(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING, BYVAL value AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_message_add_int32(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING, BYVAL value AS INTEGER) AS INTEGER
    Declare Function eb_haiku_message_add_double(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING, BYVAL value AS DOUBLE) AS INTEGER
    Declare Function eb_haiku_message_add_bool(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING, BYVAL value AS INTEGER) AS INTEGER
    Declare Function eb_haiku_message_find_string(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING) AS ZSTRING
    Declare Function eb_haiku_message_find_int32(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_message_find_double(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING) AS DOUBLE
    Declare Function eb_haiku_message_find_bool(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_message_add_data(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING, BYVAL msgType AS UINTEGER, BYVAL buffer AS ANY PTR, BYVAL size AS INTEGER) AS INTEGER
    Declare Function eb_haiku_message_find_data(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING, BYVAL msgType AS UINTEGER, BYVAL buffer AS ANY PTR, BYVAL bufferSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_message_count_items(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING, BYVAL msgType AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_message_find_string_at(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING, BYVAL index AS INTEGER) AS ZSTRING
    Declare Function eb_haiku_message_find_ref_at(BYVAL msg AS ANY PTR, BYVAL name AS ZSTRING, BYVAL index AS INTEGER, BYVAL outPath AS ANY PTR) AS INTEGER

    ' ---- BLocker ----
    Declare Function eb_haiku_locker_create() AS ANY PTR
    Declare Function eb_haiku_locker_lock(BYVAL locker AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_locker_lock_with_timeout(BYVAL locker AS ANY PTR, BYVAL timeoutMicros AS LONGINT) AS INTEGER
    Declare Sub eb_haiku_locker_unlock(BYVAL locker AS ANY PTR)
    Declare Function eb_haiku_locker_is_locked(BYVAL locker AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_locker_count_locks(BYVAL locker AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_locker_destroy(BYVAL locker AS ANY PTR)

    ' ---- BRoster ----
    Declare Function eb_haiku_roster_default() AS ANY PTR
    Declare Function eb_haiku_roster_is_running(BYVAL roster AS ANY PTR, BYVAL signature AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_roster_team_for(BYVAL roster AS ANY PTR, BYVAL signature AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_roster_launch(BYVAL roster AS ANY PTR, BYVAL signature AS ZSTRING, BYVAL outTeam AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_roster_activate_app(BYVAL roster AS ANY PTR, BYVAL team AS INTEGER) AS INTEGER
    Declare Function eb_haiku_roster_broadcast(BYVAL roster AS ANY PTR, BYVAL message AS ANY PTR) AS INTEGER

    ' ---- BClipboard ----
    Declare Function eb_haiku_clipboard_default() AS ANY PTR
    Declare Function eb_haiku_clipboard_create(BYVAL name AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_clipboard_lock(BYVAL clipboard AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_clipboard_unlock(BYVAL clipboard AS ANY PTR)
    Declare Function eb_haiku_clipboard_clear(BYVAL clipboard AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_clipboard_commit(BYVAL clipboard AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_clipboard_revert(BYVAL clipboard AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_clipboard_data(BYVAL clipboard AS ANY PTR) AS ANY PTR
    Declare Sub eb_haiku_clipboard_destroy(BYVAL clipboard AS ANY PTR)
    Declare Function eb_haiku_clipboard_set_text(BYVAL clipboard AS ANY PTR, BYVAL text AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_clipboard_get_text(BYVAL clipboard AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER

    ' ---- BApplication (lifecycle only, no subclass) ----
    Declare Function eb_haiku_application_create(BYVAL signature AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_application_init_check(BYVAL app AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_application_run(BYVAL app AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_application_quit(BYVAL app AS ANY PTR)
    Declare Sub eb_haiku_application_destroy(BYVAL app AS ANY PTR)
End Extern
