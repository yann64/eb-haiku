' Storage Kit extensions step 4: BVolume + BVolumeRoster - iterate real
' mounted volumes, sanity-check the boot volume's capacity/free bytes,
' and confirm HEntryGetVolume ties an entry back to its own real volume.

#include once "../src/lib.bas"

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

PRINT "volume basics test ok"
