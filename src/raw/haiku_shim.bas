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

    ' ---- BApplication (lifecycle only, no subclass) ----
    Declare Function eb_haiku_application_create(BYVAL signature AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_application_init_check(BYVAL app AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_application_run(BYVAL app AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_application_quit(BYVAL app AS ANY PTR)
    Declare Sub eb_haiku_application_destroy(BYVAL app AS ANY PTR)
End Extern
