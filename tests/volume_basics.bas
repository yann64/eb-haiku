' Storage Kit extensions step 4: BVolume + BVolumeRoster - iterate real
' mounted volumes, sanity-check the boot volume's capacity/free bytes,
' and confirm HEntryGetVolume ties an entry back to its own real volume.

#include once "../src/lib.bas"

' IMPORTANT, confirmed by direct reproduction (a standalone C++ probe):
' HVolumeGetIcon hangs indefinitely without a real HApplication existing
' first - a 4th confirmed occurrence of the "needs BApplication first"
' gotcha family (GetBitmap/BClipboard::Lock/BMimeType::GetIcon).
DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-VolumeBasicsTest")

DIM roster AS HVolumeRoster
roster = HVolumeRosterCreate()

DIM boot AS HVolume
boot = HVolumeCreateEmpty()
DIM rc AS INTEGER
rc = HVolumeRosterGetBootVolume(roster, boot)
IF rc <> 0 THEN
    PRINT "FAIL: HVolumeRosterGetBootVolume returned ", rc
    CALL ExitProcess(1)
END IF
IF HVolumeInitCheck(boot) <> 0 THEN
    PRINT "FAIL: HVolumeInitCheck on the boot volume"
    CALL ExitProcess(1)
END IF

DIM capacity AS LONGINT
capacity = HVolumeCapacity(boot)
IF capacity <= 0 THEN
    PRINT "FAIL: boot volume capacity should be positive, got ", capacity
    CALL ExitProcess(1)
END IF
PRINT "boot volume capacity=", capacity

DIM freeBytes AS LONGINT
freeBytes = HVolumeFreeBytes(boot)
IF freeBytes <= 0 OR freeBytes > capacity THEN
    PRINT "FAIL: boot volume free bytes should be positive and <= capacity, got ", freeBytes
    CALL ExitProcess(1)
END IF
PRINT "boot volume free bytes=", freeBytes

DIM nameBuf(255) AS BYTE
DIM namePtr AS ANY PTR
namePtr = @nameBuf(0)
rc = HVolumeGetName(boot, namePtr)
IF rc <> 0 THEN
    PRINT "FAIL: HVolumeGetName returned ", rc
    CALL ExitProcess(1)
END IF
DIM nameZ AS ZSTRING
nameZ = namePtr
DIM volName AS STRING
volName = nameZ
PRINT "boot volume name=", volName

IF HVolumeIsPersistent(boot) <> 1 THEN
    PRINT "FAIL: boot volume should be persistent"
    CALL ExitProcess(1)
END IF
PRINT "boot volume flags ok"

' GetIcon - real, read-only, safe against the real boot volume.
DIM bootIcon AS HBitmap
bootIcon = HBitmapCreate(0, 0, 31, 31, H_RGBA32, 0)
rc = HVolumeGetIcon(boot, bootIcon, H_LARGE_ICON)
IF rc = 0 THEN
    PRINT "got a real large icon for the boot volume ok"
ELSE
    PRINT "boot volume GetIcon returned ", rc, " (no custom icon set - not a failure)"
END IF
CALL HBitmapFree(bootIcon)

' Iterate every real mounted volume, counting them and confirming each
' one's own InitCheck passes.
DIM count AS INTEGER
count = 0
DIM v AS HVolume
v = HVolumeCreateEmpty()
DO WHILE HVolumeRosterGetNextVolume(roster, v) >= 0
    IF HVolumeInitCheck(v) <> 0 THEN
        PRINT "FAIL: a mounted volume's own InitCheck failed"
        CALL ExitProcess(1)
    END IF
    count = count + 1
LOOP
IF count <= 0 THEN
    PRINT "FAIL: expected at least one mounted volume"
    CALL ExitProcess(1)
END IF
PRINT "mounted volume count=", count
CALL HVolumeFree(v)

CALL HVolumeFree(boot)
CALL HVolumeRosterFree(roster)

' HEntryGetVolume - a real file's own volume should also pass InitCheck.
CONST TEST_FILE = "/boot/home/eb-haiku-volume-test.txt"
CALL WriteFile(TEST_FILE, "volume test")

DIM e AS HEntry
e = HEntryCreate(TEST_FILE)
DIM entryVolume AS HVolume
entryVolume = HVolumeCreateEmpty()
rc = HEntryGetVolume(e, entryVolume)
IF rc <> 0 THEN
    PRINT "FAIL: HEntryGetVolume returned ", rc
    CALL ExitProcess(1)
END IF
IF HVolumeInitCheck(entryVolume) <> 0 THEN
    PRINT "FAIL: HEntryGetVolume's own result failed InitCheck"
    CALL ExitProcess(1)
END IF
PRINT "HEntryGetVolume ok"

CALL HVolumeFree(entryVolume)
CALL HEntryRemove(e)
CALL HEntryFree(e)

' ---- HVolumeSetName - a real, functional rename, verified against a
' throwaway loopback BFS volume (never the real boot volume) ----

CONST IMAGE_PATH = "/boot/home/eb-haiku-volume-setname-test.img"
CALL Kill(IMAGE_PATH)
CALL Shell("dd if=/dev/zero of=" & IMAGE_PATH & " bs=1M count=10 2>/dev/null")
CALL Shell("mkfs -t bfs -q " & IMAGE_PATH & " EbHaikuSetNameTest 2>/dev/null")

DIM diskRoster AS HDiskDeviceRoster
diskRoster = HDiskDeviceRosterCreate()
DIM regId AS INTEGER
regId = HDiskDeviceRosterRegisterFileDevice(diskRoster, IMAGE_PATH)
IF regId < 0 THEN
    PRINT "FAIL: HDiskDeviceRosterRegisterFileDevice returned ", regId
    CALL ExitProcess(1)
END IF

DIM loopDevice AS HDiskDevice
loopDevice = HDiskDeviceCreate()
CALL HDiskDeviceRosterGetDeviceWithId(diskRoster, regId, loopDevice)
rc = HPartitionMount(loopDevice.handle, "", 0, "")
IF rc <> 0 THEN
    PRINT "FAIL: HPartitionMount returned ", rc
    CALL HDiskDeviceRosterUnregisterFileDevice(diskRoster, IMAGE_PATH)
    CALL ExitProcess(1)
END IF
CALL HSnooze(300000)

DIM loopMountPoint AS HPath
loopMountPoint = HPathCreateEmpty()
CALL HPartitionGetMountPoint(loopDevice.handle, loopMountPoint)

DIM mountEntry AS HEntry
mountEntry = HEntryCreate(HPathGet(loopMountPoint))
DIM loopVolume AS HVolume
loopVolume = HVolumeCreateEmpty()
rc = HEntryGetVolume(mountEntry, loopVolume)
IF rc <> 0 THEN
    PRINT "FAIL: HEntryGetVolume on the loopback mount point returned ", rc
    CALL HPartitionUnmount(loopDevice.handle, 0)
    CALL HDiskDeviceRosterUnregisterFileDevice(diskRoster, IMAGE_PATH)
    CALL ExitProcess(1)
END IF

rc = HVolumeSetName(loopVolume, "RenamedByEbHaiku")
PRINT "HVolumeSetName rc=", rc
IF rc <> 0 THEN
    PRINT "FAIL: HVolumeSetName returned ", rc
    CALL HPartitionUnmount(loopDevice.handle, 0)
    CALL HDiskDeviceRosterUnregisterFileDevice(diskRoster, IMAGE_PATH)
    CALL ExitProcess(1)
END IF

DIM renamedBuf(255) AS BYTE
DIM renamedPtr AS ANY PTR
renamedPtr = @renamedBuf(0)
CALL HVolumeGetName(loopVolume, renamedPtr)
DIM renamedZ AS ZSTRING
renamedZ = renamedPtr
DIM renamedName AS STRING
renamedName = renamedZ
PRINT "renamed volume name=", renamedName
IF renamedName <> "RenamedByEbHaiku" THEN
    PRINT "FAIL: expected the real volume name to reflect SetName"
    CALL HPartitionUnmount(loopDevice.handle, 0)
    CALL HDiskDeviceRosterUnregisterFileDevice(diskRoster, IMAGE_PATH)
    CALL ExitProcess(1)
END IF

CALL HVolumeFree(loopVolume)
CALL HPathFree(loopMountPoint)
CALL HEntryFree(mountEntry)
CALL HPartitionUnmount(loopDevice.handle, 0)
CALL HDiskDeviceRosterUnregisterFileDevice(diskRoster, IMAGE_PATH)
CALL HDiskDeviceFree(loopDevice)
CALL HDiskDeviceRosterFree(diskRoster)
CALL Kill(IMAGE_PATH)
PRINT "HVolumeSetName ok"

CALL HApplicationFree(app)

PRINT "volume basics test ok"
