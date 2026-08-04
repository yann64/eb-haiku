' Translation Kit step 4: BTranslatorRoster::Identify - format/MIME
' detection on a few real, differently-formatted files. The JPEG/BMP
' fixtures are produced by this test itself (via HGetBitmap +
' HBitmapStreamCreate + HTranslate - see translation_convert.bas) from
' the same real PNG artwork fixture used throughout these tests, so the
' test is self-contained and reproducible on a clean checkout.

#include once "../src/lib.bas"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-IdentifyTest")

DIM roster AS HTranslatorRoster
roster = HTranslatorRosterDefault()

SUB MakeFixture(BYVAL roster AS HTranslatorRoster, outPath AS ZSTRING, BYVAL wantOutType AS UINTEGER)
    DIM src AS HFile
    src = HFileCreate("/boot/system/data/artwork/HAIKU logo - white on blue - normal.png", H_READ_ONLY)
    IF HFileInitCheck(src) <> 0 THEN
        PRINT "FAIL: could not open source PNG fixture"
        CALL ExitProcess(1)
    END IF

    DIM decoded AS HBitmap
    decoded = HGetBitmap(src.handle)
    CALL HFileFree(src)
    IF decoded.handle = 0 THEN
        PRINT "FAIL: could not decode source PNG fixture"
        CALL ExitProcess(1)
    END IF

    DIM stream AS HBitmapStream
    stream = HBitmapStreamCreate(decoded)

    DIM dst AS HFile
    dst = HFileCreate(outPath, H_WRITE_ONLY OR H_CREATE_FILE OR H_ERASE_FILE)
    IF HFileInitCheck(dst) <> 0 THEN
        PRINT "FAIL: could not create fixture ", outPath
        CALL ExitProcess(1)
    END IF

    DIM rc AS INTEGER
    rc = HTranslate(roster, stream.handle, dst.handle, wantOutType)
    CALL HBitmapStreamFree(stream)
    CALL HFileFree(dst)
    IF rc <> 0 THEN
        PRINT "FAIL: could not create fixture ", outPath, " (rc=", rc, ")"
        CALL ExitProcess(1)
    END IF
END SUB

SUB CheckIdentify(BYVAL roster AS HTranslatorRoster, path AS ZSTRING, BYVAL expectedType AS UINTEGER, BYVAL expectedMime AS STRING)
    DIM f AS HFile
    f = HFileCreate(path, H_READ_ONLY)
    IF HFileInitCheck(f) <> 0 THEN
        PRINT "FAIL: could not open ", path
        CALL ExitProcess(1)
    END IF

    DIM mimeBuf(255) AS BYTE
    DIM nameBuf(255) AS BYTE
    DIM mimePtr AS ANY PTR
    DIM namePtr AS ANY PTR
    mimePtr = @mimeBuf(0)
    namePtr = @nameBuf(0)
    DIM outType AS UINTEGER
    DIM rc AS INTEGER
    rc = HIdentify(roster, f.handle, outType, mimePtr, 256, namePtr, 256)
    IF rc <> 0 THEN
        PRINT "FAIL: HIdentify returned ", rc, " for ", path
        CALL ExitProcess(1)
    END IF

    DIM mimeZ AS ZSTRING
    mimeZ = mimePtr
    DIM mime AS STRING
    mime = mimeZ

    PRINT path, " -> type=", outType, " mime=", mime

    IF outType <> expectedType THEN
        PRINT "FAIL: type mismatch for ", path
        CALL ExitProcess(1)
    END IF
    IF mime <> expectedMime THEN
        PRINT "FAIL: mime mismatch for ", path
        CALL ExitProcess(1)
    END IF

    CALL HFileFree(f)
END SUB

CALL MakeFixture(roster, "/tmp/eb_haiku_fixture.jpg", H_JPEG_FORMAT)
CALL MakeFixture(roster, "/tmp/eb_haiku_fixture.bmp", H_BMP_FORMAT)

CALL CheckIdentify(roster, "/boot/system/data/artwork/HAIKU logo - white on blue - normal.png", H_PNG_FORMAT, "image/png")
CALL CheckIdentify(roster, "/tmp/eb_haiku_fixture.jpg", H_JPEG_FORMAT, "image/jpeg")
' Note: Identify()'s own detected MIME for BMP is "image/x-bmp" - a
' real, different string from the BMP translator's registered *output*
' MIME ("image/bmp", per `translate --list`) - confirmed by running
' this test against a real file, not assumed.
CALL CheckIdentify(roster, "/tmp/eb_haiku_fixture.bmp", H_BMP_FORMAT, "image/x-bmp")

CALL HApplicationFree(app)

PRINT "identify test ok"
