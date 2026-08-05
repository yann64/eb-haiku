' BVolume::GetIcon/SetName - fetch the boot volume's own real icon,
' and rename a throwaway loopback volume (never the real boot volume).

#include once "../src/lib.bas"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-VolumeIconRenameExample")

DIM roster AS HVolumeRoster
roster = HVolumeRosterCreate()
DIM boot AS HVolume
boot = HVolumeCreateEmpty()
CALL HVolumeRosterGetBootVolume(roster, boot)

DIM icon AS HBitmap
icon = HBitmapCreate(0, 0, 31, 31, H_RGBA32, 0)
DIM rc AS INTEGER
rc = HVolumeGetIcon(boot, icon, H_LARGE_ICON)
IF rc = 0 THEN
    PRINT "fetched the real boot volume icon ok"
END IF
CALL HBitmapFree(icon)
CALL HVolumeFree(boot)

CONST IMAGE_PATH = "/boot/home/eb-haiku-volume-rename-example.img"
CALL Kill(IMAGE_PATH)
CALL Shell("dd if=/dev/zero of=" & IMAGE_PATH & " bs=1M count=10 2>/dev/null")
CALL Shell("mkfs -t bfs -q " & IMAGE_PATH & " ExampleVol 2>/dev/null")

DIM diskRoster AS HDiskDeviceRoster
diskRoster = HDiskDeviceRosterCreate()
DIM regId AS INTEGER
regId = HDiskDeviceRosterRegisterFileDevice(diskRoster, IMAGE_PATH)
DIM device AS HDiskDevice
device = HDiskDeviceCreate()
CALL HDiskDeviceRosterGetDeviceWithId(diskRoster, regId, device)
CALL HPartitionMount(device.handle, "", 0, "")
CALL HSnooze(300000)

DIM mountPoint AS HPath
mountPoint = HPathCreateEmpty()
CALL HPartitionGetMountPoint(device.handle, mountPoint)

DIM mountEntry AS HEntry
mountEntry = HEntryCreate(HPathGet(mountPoint))
DIM loopVolume AS HVolume
loopVolume = HVolumeCreateEmpty()
CALL HEntryGetVolume(mountEntry, loopVolume)

rc = HVolumeSetName(loopVolume, "RenamedByEbHaiku")
PRINT "HVolumeSetName rc=", rc

CALL HVolumeFree(loopVolume)
CALL HEntryFree(mountEntry)
CALL HPathFree(mountPoint)
CALL HPartitionUnmount(device.handle, 0)
CALL HDiskDeviceRosterUnregisterFileDevice(diskRoster, IMAGE_PATH)
CALL HDiskDeviceFree(device)
CALL HDiskDeviceRosterFree(diskRoster)
CALL HVolumeRosterFree(roster)
CALL Kill(IMAGE_PATH)
CALL HApplicationFree(app)
