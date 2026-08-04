' Package Kit basics - list installed packages via BPackageRoster.

#include once "../src/lib.bas"

DIM roster AS HPackageRoster
roster = HPackageRosterCreate()

DIM infoSet AS HPackageInfoSet
infoSet = HPackageInfoSetCreate()
CALL HPackageRosterGetActivePackages(roster, H_PACKAGE_INSTALLATION_LOCATION_SYSTEM, infoSet)

PRINT "installed packages: ", HPackageInfoSetCount(infoSet)

DIM it AS HPackageInfoIterator
it = HPackageInfoIteratorCreate(infoSet)

DIM nameBuf(255) AS BYTE
DIM nameBufPtr AS ANY PTR
nameBufPtr = @nameBuf(0)
DIM verBuf(63) AS BYTE
DIM verBufPtr AS ANY PTR
verBufPtr = @verBuf(0)

DIM shown AS INTEGER
shown = 0
DO WHILE HPackageInfoIteratorHasNext(it) <> 0 AND shown < 10
    DIM info AS ANY PTR
    info = HPackageInfoIteratorNext(it)

    DIM nameLen AS INTEGER
    nameLen = HPackageInfoName(info, nameBufPtr, 256)
    nameBuf(nameLen) = 0
    DIM nameZ AS ZSTRING
    nameZ = nameBufPtr
    DIM name AS STRING
    name = nameZ

    DIM verLen AS INTEGER
    verLen = HPackageInfoVersionString(info, verBufPtr, 64)
    verBuf(verLen) = 0
    DIM verZ AS ZSTRING
    verZ = verBufPtr
    DIM ver AS STRING
    ver = verZ

    PRINT name, " ", ver
    shown = shown + 1
LOOP

CALL HPackageInfoIteratorFree(it)
CALL HPackageInfoSetFree(infoSet)
CALL HPackageRosterFree(roster)
