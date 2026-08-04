' Idiomatic layer: BTranslationUtils/BTranslatorRoster/BBitmapStream -
' Haiku's own system for converting between data formats, most commonly
' images (PNG/JPEG/BMP/GIF/TIFF/WebP/...), backed by 20+ real installed
' translator add-ons.
'
' IMPORTANT: every function here hangs indefinitely if called before
' any HApplication exists (confirmed by direct reproduction in a
' standalone C++ program with no eBasic involved) - see this package's
' own README "Threading" section. Always call HApplicationCreate first
' - not a new burden for a real GUI/app program, which always needs one
' anyway, but a real trap if you only want to use Translation Kit.

#include once "raw/haiku_shim_translation.bas"
#include once "bitmap.bas"
#include once "file.bas"

''' Loads any supported image format from `stream` (an HFile's own
''' `.handle`, opened H_READ_ONLY) into a new HBitmap - `.handle` is 0
''' on failure (unsupported format, corrupt data, ...).
FUNCTION HGetBitmap(BYVAL stream AS ANY PTR) AS HBitmap
    DIM b AS HBitmap
    b.handle = eb_haiku_translation_utils_get_bitmap(stream)
    HGetBitmap = b
END FUNCTION

TYPE HTranslatorRoster
    handle AS ANY PTR
END TYPE

''' The shared default roster - never freed by this package (Haiku's
''' own Translation Kit owns it).
FUNCTION HTranslatorRosterDefault() AS HTranslatorRoster
    DIM r AS HTranslatorRoster
    r.handle = eb_haiku_translator_roster_default()
    HTranslatorRosterDefault = r
END FUNCTION

''' Auto-detects `source`'s own format and converts it, writing the
''' result to `destination` (both an HFile's own `.handle`, or an
''' HBitmapStream's own `.handle`) as `wantOutType` (one of the
''' H_*_FORMAT constants, or H_TRANSLATOR_BITMAP for the generic,
''' uncompressed bitmap format). Returns a status code (0 = success).
'''
''' Real Haiku behavior, confirmed by direct reproduction: most
''' translators only declare their own compressed format (e.g. 'JPEG')
''' and H_TRANSLATOR_BITMAP ('bits', the generic uncompressed format)
''' as inputs - NOT other compressed formats directly. Going straight
''' from one compressed file format to a *different* one in a single
''' HTranslate call typically fails with B_NO_TRANSLATOR. Convert in
''' two hops instead: HGetBitmap the source, then HBitmapStreamCreate
''' the result and HTranslate *that* ('bits') to the real target format
''' - see tests/translation_convert.bas for a full working example.
''' This matches how Haiku's own `translate` command-line tool works
''' internally.
FUNCTION HTranslate(BYVAL roster AS HTranslatorRoster, BYVAL source AS ANY PTR, BYVAL destination AS ANY PTR, BYVAL wantOutType AS UINTEGER) AS INTEGER
    HTranslate = eb_haiku_translator_roster_translate(roster.handle, source, destination, wantOutType)
END FUNCTION

''' Identifies `source`'s own real format - `outMime`/`outName` are
''' filled in (see the example below); returns a status code (0 =
''' success, matching every other Kit in this package).
'''
''' DIM mimeBuf(255) AS BYTE
''' DIM nameBuf(255) AS BYTE
''' DIM outType AS UINTEGER
''' DIM rc AS INTEGER
''' rc = HIdentify(roster, file.handle, outType, @mimeBuf(0), 256, @nameBuf(0), 256)
''' DIM mimeZ AS ZSTRING : mimeZ = @mimeBuf(0)
''' DIM mime AS STRING : mime = mimeZ
FUNCTION HIdentify(BYVAL roster AS HTranslatorRoster, BYVAL source AS ANY PTR, BYREF outType AS UINTEGER, BYVAL outMime AS ANY PTR, BYVAL mimeBufSize AS INTEGER, BYVAL outName AS ANY PTR, BYVAL nameBufSize AS INTEGER) AS INTEGER
    DIM typeBuf(0) AS UINTEGER
    DIM rc AS INTEGER
    rc = eb_haiku_translator_roster_identify(roster.handle, source, @typeBuf(0), outMime, mimeBufSize, outName, nameBufSize)
    outType = typeBuf(0)
    HIdentify = rc
END FUNCTION

''' Loads a third-party translator add-on from a custom path - real,
''' already-installed translators are found automatically; this is only
''' for one that isn't in Haiku's own standard search path. Returns a
''' status code (0 = success).
FUNCTION HAddTranslators(BYVAL roster AS HTranslatorRoster, loadPath AS ZSTRING) AS INTEGER
    HAddTranslators = eb_haiku_translator_roster_add_translators(roster.handle, loadPath)
END FUNCTION

''' The real total number of installed translators - pass `outIds`
''' (e.g. `DIM ids(63) AS UINTEGER : @ids(0)`) sized generously; each
''' written ID is usable directly with HTranslatorInfo/HInputFormats/
''' HOutputFormats below.
FUNCTION HGetAllTranslators(BYVAL roster AS HTranslatorRoster, BYVAL outIds AS ANY PTR, BYVAL idBufCount AS INTEGER) AS INTEGER
    HGetAllTranslators = eb_haiku_translator_roster_get_all_translators(roster.handle, outIds, idBufCount)
END FUNCTION

''' Fills in `outName`/`outInfo`/`outVersion` for `translatorId` (one of
''' HGetAllTranslators's own results). Returns a status code.
FUNCTION HTranslatorInfo(BYVAL roster AS HTranslatorRoster, BYVAL translatorId AS UINTEGER, BYVAL outName AS ANY PTR, BYVAL nameBufSize AS INTEGER, BYVAL outInfo AS ANY PTR, BYVAL infoBufSize AS INTEGER, BYREF outVersion AS INTEGER) AS INTEGER
    DIM versionBuf(0) AS INTEGER
    DIM rc AS INTEGER
    rc = eb_haiku_translator_roster_get_translator_info(roster.handle, translatorId, outName, nameBufSize, outInfo, infoBufSize, @versionBuf(0))
    outVersion = versionBuf(0)
    HTranslatorInfo = rc
END FUNCTION

''' The number of input formats `translatorId` supports, filling
''' `outTypes` (an array of UINTEGER, one per format) and `outMimeBuf`
''' (a flat byte buffer, `mimeBufSize` bytes per format slot) - both
''' sized for at least `formatBufCount` entries.
FUNCTION HInputFormats(BYVAL roster AS HTranslatorRoster, BYVAL translatorId AS UINTEGER, BYVAL outTypes AS ANY PTR, BYVAL outMimeBuf AS ANY PTR, BYVAL mimeBufSize AS INTEGER, BYVAL formatBufCount AS INTEGER) AS INTEGER
    HInputFormats = eb_haiku_translator_roster_get_input_formats(roster.handle, translatorId, outTypes, outMimeBuf, mimeBufSize, formatBufCount)
END FUNCTION

''' Same shape as HInputFormats, for the formats `translatorId` can
''' produce as output.
FUNCTION HOutputFormats(BYVAL roster AS HTranslatorRoster, BYVAL translatorId AS UINTEGER, BYVAL outTypes AS ANY PTR, BYVAL outMimeBuf AS ANY PTR, BYVAL mimeBufSize AS INTEGER, BYVAL formatBufCount AS INTEGER) AS INTEGER
    HOutputFormats = eb_haiku_translator_roster_get_output_formats(roster.handle, translatorId, outTypes, outMimeBuf, mimeBufSize, formatBufCount)
END FUNCTION

TYPE HBitmapStream
    handle AS ANY PTR
END TYPE

''' Wraps `bitmap` as a stream HTranslate can write into (the "save
''' this bitmap as PNG/JPEG/..." direction) - takes ownership of
''' `bitmap`; do not also call HBitmapFree on it (HBitmapStreamDetach
''' below gives it back if you need it again afterward).
FUNCTION HBitmapStreamCreate(BYVAL bitmap AS HBitmap) AS HBitmapStream
    DIM s AS HBitmapStream
    s.handle = eb_haiku_bitmap_stream_create(bitmap.handle)
    HBitmapStreamCreate = s
END FUNCTION

''' Reclaims ownership of the wrapped bitmap - call HBitmapFree on the
''' result yourself afterward.
FUNCTION HBitmapStreamDetachBitmap(BYVAL s AS HBitmapStream) AS HBitmap
    DIM b AS HBitmap
    b.handle = eb_haiku_bitmap_stream_detach_bitmap(s.handle)
    HBitmapStreamDetachBitmap = b
END FUNCTION

''' Frees the stream - if the wrapped bitmap was never detached, this
''' frees it too.
SUB HBitmapStreamFree(BYVAL s AS HBitmapStream)
    CALL eb_haiku_bitmap_stream_destroy(s.handle)
END SUB
