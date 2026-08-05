' Disk Device Kit: enumerate real system disk devices, and mount/
' unmount a safe throwaway loopback file device (never a real
' physical/boot device - see diskdevice.bas's own top comment).

#include once "../src/lib.bas"

DIM roster AS HDiskDeviceRoster
roster = HDiskDeviceRosterCreate()

DIM device AS HDiskDevice
device = HDiskDeviceCreate()
DIM count AS INTEGER
count = 0
DO WHILE HDiskDeviceRosterGetNextDevice(roster, device) = 0
    PRINT "device: ", HPartitionName(device.handle), " (", HPartitionContentType(device.handle), ")"
    count = count + 1
LOOP
PRINT "real device count=", count
CALL HDiskDeviceFree(device)

CONST IMAGE_PATH = "/boot/home/eb-haiku-diskdevice-example.img"
CALL Kill(IMAGE_PATH)
CALL Shell("dd if=/dev/zero of=" & IMAGE_PATH & " bs=1M count=10 2>/dev/null")
CALL Shell("mkfs -t bfs -q " & IMAGE_PATH & " ExampleVol 2>/dev/null")

DIM regId AS INTEGER
regId = HDiskDeviceRosterRegisterFileDevice(roster, IMAGE_PATH)

DIM loopDevice AS HDiskDevice
loopDevice = HDiskDeviceCreate()
CALL HDiskDeviceRosterGetDeviceWithId(roster, regId, loopDevice)

DIM rc AS INTEGER
rc = HPartitionMount(loopDevice.handle, "", 0, "")
IF rc = 0 THEN
    CALL HSnooze(300000)
    DIM mountPoint AS HPath
    mountPoint = HPathCreateEmpty()
    CALL HPartitionGetMountPoint(loopDevice.handle, mountPoint)
    PRINT "mounted loopback image at ", HPathGet(mountPoint)
    CALL HPathFree(mountPoint)
    CALL HPartitionUnmount(loopDevice.handle, 0)
END IF

CALL HDiskDeviceRosterUnregisterFileDevice(roster, IMAGE_PATH)
CALL HDiskDeviceFree(loopDevice)
CALL HDiskDeviceRosterFree(roster)
CALL Kill(IMAGE_PATH)
