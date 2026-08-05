#include "shim_diskdevice.h"

#include <DiskDevice.h>
#include <DiskDeviceRoster.h>
#include <Partition.h>
#include <Path.h>
#include <String.h>

#include <cstring>

namespace {

int copyBStringToBuffer(const BString& s, char* outBuf, int bufSize) {
    int len = s.Length();
    int toCopy = len < bufSize ? len : bufSize;
    std::memcpy(outBuf, s.String(), static_cast<size_t>(toCopy));
    return len;
}

} // namespace

extern "C" {

// ---- BDiskDeviceRoster ----

void* eb_haiku_disk_device_roster_create(void) { return new BDiskDeviceRoster(); }

void eb_haiku_disk_device_roster_destroy(void* roster) {
    delete static_cast<BDiskDeviceRoster*>(roster);
}

int eb_haiku_disk_device_roster_get_next_device(void* roster, void* device) {
    return static_cast<BDiskDeviceRoster*>(roster)->GetNextDevice(
        static_cast<BDiskDevice*>(device));
}

int eb_haiku_disk_device_roster_rewind_devices(void* roster) {
    return static_cast<BDiskDeviceRoster*>(roster)->RewindDevices();
}

int eb_haiku_disk_device_roster_register_file_device(void* roster, const char* path) {
    return static_cast<BDiskDeviceRoster*>(roster)->RegisterFileDevice(path);
}

int eb_haiku_disk_device_roster_unregister_file_device(void* roster, const char* path) {
    return static_cast<BDiskDeviceRoster*>(roster)->UnregisterFileDevice(path);
}

int eb_haiku_disk_device_roster_get_device_with_id(void* roster, int id, void* device) {
    return static_cast<BDiskDeviceRoster*>(roster)->GetDeviceWithID(
        id, static_cast<BDiskDevice*>(device));
}

// ---- BDiskDevice ----

void* eb_haiku_disk_device_create(void) { return new BDiskDevice(); }

void eb_haiku_disk_device_destroy(void* device) { delete static_cast<BDiskDevice*>(device); }

int eb_haiku_disk_device_init_check(void* device) {
    return static_cast<BDiskDevice*>(device)->InitCheck();
}

int eb_haiku_disk_device_has_media(void* device) {
    return static_cast<BDiskDevice*>(device)->HasMedia() ? 1 : 0;
}

int eb_haiku_disk_device_is_removable_media(void* device) {
    return static_cast<BDiskDevice*>(device)->IsRemovableMedia() ? 1 : 0;
}

int eb_haiku_disk_device_is_read_only_media(void* device) {
    return static_cast<BDiskDevice*>(device)->IsReadOnlyMedia() ? 1 : 0;
}

int eb_haiku_disk_device_eject(void* device, int update) {
    return static_cast<BDiskDevice*>(device)->Eject(update != 0);
}

int eb_haiku_disk_device_get_path(void* device, void* outPath) {
    return static_cast<BDiskDevice*>(device)->GetPath(static_cast<BPath*>(outPath));
}

// ---- BPartition-level (shared) ----

int eb_haiku_partition_mount(void* partition, const char* mountPoint, unsigned int mountFlags,
                              const char* parameters) {
    const char* realMountPoint = (mountPoint && mountPoint[0] != '\0') ? mountPoint : nullptr;
    const char* realParameters = (parameters && parameters[0] != '\0') ? parameters : nullptr;
    return static_cast<BPartition*>(partition)->Mount(realMountPoint, mountFlags, realParameters);
}

int eb_haiku_partition_unmount(void* partition, unsigned int unmountFlags) {
    return static_cast<BPartition*>(partition)->Unmount(unmountFlags);
}

const char* eb_haiku_partition_name(void* partition) {
    return static_cast<BPartition*>(partition)->Name();
}

int eb_haiku_partition_content_name(void* partition, char* outBuf, int bufSize) {
    BString s = static_cast<BPartition*>(partition)->ContentName();
    return copyBStringToBuffer(s, outBuf, bufSize);
}

const char* eb_haiku_partition_type(void* partition) {
    return static_cast<BPartition*>(partition)->Type();
}

const char* eb_haiku_partition_content_type(void* partition) {
    return static_cast<BPartition*>(partition)->ContentType();
}

int eb_haiku_partition_id(void* partition) { return static_cast<BPartition*>(partition)->ID(); }

int eb_haiku_partition_is_mounted(void* partition) {
    return static_cast<BPartition*>(partition)->IsMounted() ? 1 : 0;
}

int eb_haiku_partition_is_read_only(void* partition) {
    return static_cast<BPartition*>(partition)->IsReadOnly() ? 1 : 0;
}

long long eb_haiku_partition_size(void* partition) {
    return static_cast<long long>(static_cast<BPartition*>(partition)->Size());
}

int eb_haiku_partition_get_mount_point(void* partition, void* outMountPoint) {
    return static_cast<BPartition*>(partition)->GetMountPoint(static_cast<BPath*>(outMountPoint));
}

int eb_haiku_partition_count_children(void* partition) {
    return static_cast<BPartition*>(partition)->CountChildren();
}

void* eb_haiku_partition_child_at(void* partition, int index) {
    return static_cast<BPartition*>(partition)->ChildAt(index);
}

} // extern "C"
