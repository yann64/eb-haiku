' Disk Device Kit: BDiskDeviceRoster/BDiskDevice/BPartition. Verified
' entirely against a throwaway loopback file device (created via `dd` +
' `mkfs -t bfs`, registered via HDiskDeviceRosterRegisterFileDevice) -
' NEVER any real physical/boot device.
'
' IMPORTANT, confirmed by direct reproduction: BDiskDeviceRoster's own
' VisitEachMountablePartition does NOT reliably scope its enumeration
' to a childless `device` filter - it visited every real partition on
' the ENTIRE host (including the live boot volumes) and never
' returned. Deliberately not called anywhere in this package - see
' diskdevice.bas's own top comment. This test only uses
' GetNextDevice/RewindDevices and direct ChildAt/CountChildren
' navigation, both confirmed safe.

#include once "../src/lib.bas"

CONST TEST_IMAGE_PATH = "/boot/home/eb-haiku-diskdevice-test.img"

CALL Kill(TEST_IMAGE_PATH)
CALL Shell("dd if=/dev/zero of=" & TEST_IMAGE_PATH & " bs=1M count=10 2>/dev/null")
CALL Shell("mkfs -t bfs -q " & TEST_IMAGE_PATH & " EbHaikuTestVol 2>/dev/null")

DIM roster AS HDiskDeviceRoster
roster = HDiskDeviceRosterCreate()

DIM regId AS INTEGER
regId = HDiskDeviceRosterRegisterFileDevice(roster, TEST_IMAGE_PATH)
PRINT "RegisterFileDevice returned partition_id=", regId
IF regId < 0 THEN
    PRINT "FAIL: HDiskDeviceRosterRegisterFileDevice returned ", regId
    CALL ExitProcess(1)
END IF

DIM device AS HDiskDevice
device = HDiskDeviceCreate()
DIM rc AS INTEGER
rc = HDiskDeviceRosterGetDeviceWithId(roster, regId, device)
IF rc <> 0 THEN
    PRINT "FAIL: HDiskDeviceRosterGetDeviceWithId returned ", rc
    CALL HDiskDeviceRosterUnregisterFileDevice(roster, TEST_IMAGE_PATH)
    CALL ExitProcess(1)
END IF

PRINT "HasMedia=", HDiskDeviceHasMedia(device), " IsRemovableMedia=", HDiskDeviceIsRemovableMedia(device)
PRINT "ContentType=", HPartitionContentType(device.handle)
PRINT "CountChildren=", HPartitionCountChildren(device.handle)

' This raw loopback image has no partition map of its own (CountChildren
' = 0) - the device itself IS the mountable BFS partition, matching the
' real, confirmed behavior seen in a standalone C++ probe before writing
' this test. Mount/unmount the device itself directly - no visitor/
' enumeration needed.
IF HPartitionCountChildren(device.handle) <> 0 THEN
    PRINT "FAIL: expected a raw, unpartitioned loopback image (0 children)"
    CALL HDiskDeviceRosterUnregisterFileDevice(roster, TEST_IMAGE_PATH)
    CALL ExitProcess(1)
END IF

rc = HPartitionMount(device.handle, "", 0, "")
PRINT "Mount rc=", rc
IF rc <> 0 THEN
    PRINT "FAIL: HPartitionMount returned ", rc
    CALL HDiskDeviceRosterUnregisterFileDevice(roster, TEST_IMAGE_PATH)
    CALL ExitProcess(1)
END IF

IF HPartitionIsMounted(device.handle) <> 1 THEN
    PRINT "FAIL: expected IsMounted to be true after a successful Mount"
    CALL HPartitionUnmount(device.handle, 0)
    CALL HDiskDeviceRosterUnregisterFileDevice(roster, TEST_IMAGE_PATH)
    CALL ExitProcess(1)
END IF

DIM mountPoint AS HPath
mountPoint = HPathCreateEmpty()
CALL HPartitionGetMountPoint(device.handle, mountPoint)
PRINT "mounted at ", HPathGet(mountPoint)
CALL HPathFree(mountPoint)

rc = HPartitionUnmount(device.handle, 0)
PRINT "Unmount rc=", rc
IF rc <> 0 THEN
    PRINT "FAIL: HPartitionUnmount returned ", rc
    CALL HDiskDeviceRosterUnregisterFileDevice(roster, TEST_IMAGE_PATH)
    CALL ExitProcess(1)
END IF

' ---- GetNextDevice/RewindDevices - safe, real enumeration ----

DIM enumDevice AS HDiskDevice
enumDevice = HDiskDeviceCreate()
DIM deviceCount AS INTEGER
deviceCount = 0
DO WHILE HDiskDeviceRosterGetNextDevice(roster, enumDevice) = 0
    deviceCount = deviceCount + 1
LOOP
PRINT "real device count=", deviceCount
IF deviceCount < 1 THEN
    PRINT "FAIL: expected at least one real disk device (our own registered loopback image)"
    CALL HDiskDeviceRosterUnregisterFileDevice(roster, TEST_IMAGE_PATH)
    CALL ExitProcess(1)
END IF
CALL HDiskDeviceFree(enumDevice)

rc = HDiskDeviceRosterUnregisterFileDevice(roster, TEST_IMAGE_PATH)
PRINT "UnregisterFileDevice rc=", rc
IF rc <> 0 THEN
    PRINT "FAIL: HDiskDeviceRosterUnregisterFileDevice returned ", rc
    CALL ExitProcess(1)
END IF

CALL HDiskDeviceFree(device)
CALL HDiskDeviceRosterFree(roster)
CALL Kill(TEST_IMAGE_PATH)

PRINT "diskdevice basics test ok"
