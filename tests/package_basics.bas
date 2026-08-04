' Package Kit basics: BPackageRoster - real installed packages, real
' repository paths, reboot-needed state. Verified against real
' installed packages (confirmed via a standalone C++ probe first: 726
' real packages on this host, including "haiku" itself).

#include once "../src/lib.bas"

DIM roster AS HPackageRoster
roster = HPackageRosterCreate()

DIM rebootNeeded AS INTEGER
rebootNeeded = HPackageRosterIsRebootNeeded(roster)
PRINT "reboot needed=", rebootNeeded

DIM cachePath AS HPath
cachePath = HPathCreateEmpty()
DIM rc AS INTEGER
rc = HPackageRosterGetCommonRepositoryCachePath(roster, cachePath)
IF rc <> 0 THEN
    PRINT "FAIL: HPackageRosterGetCommonRepositoryCachePath returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "common repository cache path=", HPathGet(cachePath)
CALL HPathFree(cachePath)

DIM infoSet AS HPackageInfoSet
infoSet = HPackageInfoSetCreate()
rc = HPackageRosterGetActivePackages(roster, H_PACKAGE_INSTALLATION_LOCATION_SYSTEM, infoSet)
IF rc <> 0 THEN
    PRINT "FAIL: HPackageRosterGetActivePackages returned ", rc
    CALL ExitProcess(1)
END IF

DIM count AS INTEGER
count = HPackageInfoSetCount(infoSet)
PRINT "active package count=", count
IF count <= 0 THEN
    PRINT "FAIL: expected a positive real package count"
    CALL ExitProcess(1)
END IF

DIM it AS HPackageInfoIterator
it = HPackageInfoIteratorCreate(infoSet)

DIM foundHaiku AS INTEGER
foundHaiku = 0
DIM seen AS INTEGER
seen = 0

DIM nameBuf(255) AS BYTE
DIM nameBufPtr AS ANY PTR
nameBufPtr = @nameBuf(0)
DIM verBuf(63) AS BYTE
DIM verBufPtr AS ANY PTR
verBufPtr = @verBuf(0)

DO WHILE HPackageInfoIteratorHasNext(it) <> 0
    DIM info AS ANY PTR
    info = HPackageInfoIteratorNext(it)

    DIM nameLen AS INTEGER
    nameLen = HPackageInfoName(info, nameBufPtr, 256)
    nameBuf(nameLen) = 0
    DIM nameZ AS ZSTRING
    nameZ = nameBufPtr
    DIM name AS STRING
    name = nameZ

    IF name = "haiku" THEN
        DIM verLen AS INTEGER
        verLen = HPackageInfoVersionString(info, verBufPtr, 64)
        verBuf(verLen) = 0
        DIM verZ AS ZSTRING
        verZ = verBufPtr
        DIM ver AS STRING
        ver = verZ
        PRINT "found haiku package, version=", ver
        foundHaiku = 1
    END IF

    seen = seen + 1
LOOP

CALL HPackageInfoIteratorFree(it)
CALL HPackageInfoSetFree(infoSet)
CALL HPackageRosterFree(roster)

IF seen <> count THEN
    PRINT "FAIL: iterated ", seen, " but CountInfos reported ", count
    CALL ExitProcess(1)
END IF
IF foundHaiku <> 1 THEN
    PRINT "FAIL: the real 'haiku' package should be among installed packages"
    CALL ExitProcess(1)
END IF

PRINT "package basics test ok"
