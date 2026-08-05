' Raw FFI layer: eb-haiku's Disk Device Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_diskdevice.h.

Extern "C" Lib "ebhaikushim"
    ' ---- BDiskDeviceRoster ----
    Declare Function eb_haiku_disk_device_roster_create() AS ANY PTR
    Declare Sub eb_haiku_disk_device_roster_destroy(BYVAL roster AS ANY PTR)
    Declare Function eb_haiku_disk_device_roster_get_next_device(BYVAL roster AS ANY PTR, BYVAL deviceHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_disk_device_roster_rewind_devices(BYVAL roster AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_disk_device_roster_register_file_device(BYVAL roster AS ANY PTR, BYVAL path AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_disk_device_roster_unregister_file_device(BYVAL roster AS ANY PTR, BYVAL path AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_disk_device_roster_get_device_with_id(BYVAL roster AS ANY PTR, BYVAL forId AS INTEGER, BYVAL deviceHandle AS ANY PTR) AS INTEGER

    ' ---- BDiskDevice ----
    Declare Function eb_haiku_disk_device_create() AS ANY PTR
    Declare Sub eb_haiku_disk_device_destroy(BYVAL deviceHandle AS ANY PTR)
    Declare Function eb_haiku_disk_device_init_check(BYVAL deviceHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_disk_device_has_media(BYVAL deviceHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_disk_device_is_removable_media(BYVAL deviceHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_disk_device_is_read_only_media(BYVAL deviceHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_disk_device_eject(BYVAL deviceHandle AS ANY PTR, BYVAL updateFlag AS INTEGER) AS INTEGER
    Declare Function eb_haiku_disk_device_get_path(BYVAL deviceHandle AS ANY PTR, BYVAL outPath AS ANY PTR) AS INTEGER

    ' ---- BPartition-level (shared) ----
    Declare Function eb_haiku_partition_mount(BYVAL partitionHandle AS ANY PTR, BYVAL mountPoint AS ZSTRING, BYVAL mountFlags AS UINTEGER, BYVAL parameters AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_partition_unmount(BYVAL partitionHandle AS ANY PTR, BYVAL unmountFlags AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_partition_name(BYVAL partitionHandle AS ANY PTR) AS ZSTRING
    Declare Function eb_haiku_partition_content_name(BYVAL partitionHandle AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_partition_type(BYVAL partitionHandle AS ANY PTR) AS ZSTRING
    Declare Function eb_haiku_partition_content_type(BYVAL partitionHandle AS ANY PTR) AS ZSTRING
    Declare Function eb_haiku_partition_id(BYVAL partitionHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_partition_is_mounted(BYVAL partitionHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_partition_is_read_only(BYVAL partitionHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_partition_size(BYVAL partitionHandle AS ANY PTR) AS LONGINT
    Declare Function eb_haiku_partition_get_mount_point(BYVAL partitionHandle AS ANY PTR, BYVAL outMountPoint AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_partition_count_children(BYVAL partitionHandle AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_partition_child_at(BYVAL partitionHandle AS ANY PTR, BYVAL index AS INTEGER) AS ANY PTR
End Extern
