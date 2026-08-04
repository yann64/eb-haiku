' Translation Kit step 5: translator introspection
' (GetAllTranslators/GetTranslatorInfo/GetInputFormats/GetOutputFormats)
' + AddTranslators - verified by listing the real installed translators
' and spot-checking that the PNG translator reports an "image/png"
' output format among its own real, installed formats.

#include once "../src/lib.bas"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-IntrospectionTest")

DIM roster AS HTranslatorRoster
roster = HTranslatorRosterDefault()

DIM ids(63) AS UINTEGER
DIM count AS INTEGER
count = HGetAllTranslators(roster, @ids(0), 64)
IF count <= 0 THEN
    PRINT "FAIL: HGetAllTranslators returned ", count
    CALL ExitProcess(1)
END IF
PRINT "installed translator count=", count

DIM foundPng AS INTEGER
foundPng = 0

DIM i AS INTEGER
FOR i = 0 TO count - 1
    IF i >= 64 THEN
        EXIT FOR
    END IF

    DIM nameBuf(255) AS BYTE
    DIM infoBuf(255) AS BYTE
    DIM namePtr AS ANY PTR
    DIM infoPtr AS ANY PTR
    namePtr = @nameBuf(0)
    infoPtr = @infoBuf(0)
    DIM version AS INTEGER
    DIM rc AS INTEGER
    rc = HTranslatorInfo(roster, ids(i), namePtr, 256, infoPtr, 256, version)
    IF rc <> 0 THEN
        PRINT "FAIL: HTranslatorInfo returned ", rc
        CALL ExitProcess(1)
    END IF

    DIM nameZ AS ZSTRING
    nameZ = namePtr
    DIM name AS STRING
    name = nameZ

    IF InStr(name, "PNG") > 0 THEN
        DIM outTypes(15) AS UINTEGER
        DIM mimeBuf(15 * 256 - 1) AS BYTE
        DIM mimeBase AS BYTE PTR
        mimeBase = @mimeBuf(0)
        DIM outCount AS INTEGER
        outCount = HOutputFormats(roster, ids(i), @outTypes(0), mimeBase, 256, 16)
        IF outCount <= 0 THEN
            PRINT "FAIL: HOutputFormats returned ", outCount, " for ", name
            CALL ExitProcess(1)
        END IF

        DIM foundPngMime AS INTEGER
        foundPngMime = 0
        DIM j AS INTEGER
        FOR j = 0 TO outCount - 1
            IF j >= 16 THEN
                EXIT FOR
            END IF
            DIM slotPtr AS BYTE PTR
            slotPtr = mimeBase + (j * 256)
            DIM slotAny AS ANY PTR
            slotAny = slotPtr
            DIM slotZ AS ZSTRING
            slotZ = slotAny
            DIM slotMime AS STRING
            slotMime = slotZ
            IF slotMime = "image/png" THEN
                foundPngMime = 1
            END IF
        NEXT j

        IF foundPngMime = 1 THEN
            foundPng = 1
        END IF
    END IF
NEXT i

IF foundPng = 0 THEN
    PRINT "FAIL: no installed translator reported an image/png output format"
    CALL ExitProcess(1)
END IF
PRINT "png translator introspection ok"

' AddTranslators - point it at the real, already-populated installed
' translators directory. Should succeed (idempotent - adding translators
' that are already loaded is not an error).
DIM addRc AS INTEGER
addRc = HAddTranslators(roster, "/boot/system/add-ons/Translators")
IF addRc <> 0 THEN
    PRINT "FAIL: HAddTranslators returned ", addRc
    CALL ExitProcess(1)
END IF
PRINT "add translators ok"

CALL HApplicationFree(app)

PRINT "introspection test ok"
