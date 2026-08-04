' Raw FFI layer: eb-haiku's Translation Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_translation.h.
'
' IMPORTANT: every function here hangs indefinitely if called before
' any HApplication exists (confirmed by direct reproduction in a
' standalone C++ program with no eBasic involved) - see this package's
' own README "Threading" section. Always call HApplicationCreate first.

' Real Haiku file open-mode values (support/SupportDefs.h) - confirmed
' by compiling and printing each one on the real Haiku host, matching
' this package's own "verify, don't assume" discipline.
CONST H_READ_ONLY = 0
CONST H_WRITE_ONLY = 1
CONST H_READ_WRITE = 2
CONST H_CREATE_FILE = 512
CONST H_ERASE_FILE = 1024
CONST H_OPEN_AT_END = 2048

' Real Haiku color_space enum values (interface/GraphicsDefs.h) - NOT a
' plain sequential enum - confirmed on the real Haiku host.
CONST H_RGB32 = 8
CONST H_RGBA32 = 8200
CONST H_RGB24 = 3
CONST H_GRAY8 = 2
CONST H_CMAP8 = 4

' Real Haiku translation format constants (translation/TranslatorFormats.h)
' - FourCC-style, but NOT hand-derivable reliably (multichar-literal bit
' packing is compiler/platform behavior, not something to guess) -
' confirmed by compiling and printing each one on the real Haiku host;
' several of these differ from a naive hand computation.
CONST H_TRANSLATOR_BITMAP = 1651078259 ' 'bits'
CONST H_GIF_FORMAT = 1195984416        ' 'GIF '
CONST H_JPEG_FORMAT = 1246774599       ' 'JPEG'
CONST H_PNG_FORMAT = 1347307296        ' 'PNG '
CONST H_BMP_FORMAT = 1112363040        ' 'BMP '
CONST H_TIFF_FORMAT = 1414088262       ' 'TIFF'
CONST H_WEBP_FORMAT = 1466262096       ' 'WebP'

Extern "C" Lib "ebhaikushim"
    ' ---- BBitmap ----
    Declare Function eb_haiku_bitmap_create(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, BYVAL colorSpace AS UINTEGER, BYVAL flags AS UINTEGER) AS ANY PTR
    Declare Function eb_haiku_bitmap_init_check(BYVAL bitmap AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_bitmap_get_bounds(BYVAL bitmap AS ANY PTR, BYVAL outLeft AS ANY PTR, BYVAL outTop AS ANY PTR, BYVAL outRight AS ANY PTR, BYVAL outBottom AS ANY PTR)
    Declare Function eb_haiku_bitmap_color_space(BYVAL bitmap AS ANY PTR) AS UINTEGER
    Declare Sub eb_haiku_bitmap_destroy(BYVAL bitmap AS ANY PTR)

    ' ---- BFile ----
    Declare Function eb_haiku_file_create(BYVAL path AS ZSTRING, BYVAL openMode AS UINTEGER) AS ANY PTR
    Declare Function eb_haiku_file_init_check(BYVAL file AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_file_destroy(BYVAL file AS ANY PTR)

    ' ---- BTranslationUtils ----
    Declare Function eb_haiku_translation_utils_get_bitmap(BYVAL positionIOStream AS ANY PTR) AS ANY PTR

    ' ---- BTranslatorRoster ----
    Declare Function eb_haiku_translator_roster_default() AS ANY PTR
    Declare Function eb_haiku_translator_roster_translate(BYVAL roster AS ANY PTR, BYVAL sourceStream AS ANY PTR, BYVAL destinationStream AS ANY PTR, BYVAL wantOutType AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_translator_roster_identify(BYVAL roster AS ANY PTR, BYVAL sourceStream AS ANY PTR, BYVAL outType AS ANY PTR, BYVAL outMime AS ANY PTR, BYVAL mimeBufSize AS INTEGER, BYVAL outName AS ANY PTR, BYVAL nameBufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_translator_roster_add_translators(BYVAL roster AS ANY PTR, BYVAL loadPath AS ZSTRING) AS INTEGER

    ' ---- Translator introspection ----
    Declare Function eb_haiku_translator_roster_get_all_translators(BYVAL roster AS ANY PTR, BYVAL outIds AS ANY PTR, BYVAL idBufCount AS INTEGER) AS INTEGER
    Declare Function eb_haiku_translator_roster_get_translator_info(BYVAL roster AS ANY PTR, BYVAL translatorId AS UINTEGER, BYVAL outName AS ANY PTR, BYVAL nameBufSize AS INTEGER, BYVAL outInfo AS ANY PTR, BYVAL infoBufSize AS INTEGER, BYVAL outVersion AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_translator_roster_get_input_formats(BYVAL roster AS ANY PTR, BYVAL translatorId AS UINTEGER, BYVAL outTypes AS ANY PTR, BYVAL outMimeBuf AS ANY PTR, BYVAL mimeBufSize AS INTEGER, BYVAL formatBufCount AS INTEGER) AS INTEGER
    Declare Function eb_haiku_translator_roster_get_output_formats(BYVAL roster AS ANY PTR, BYVAL translatorId AS UINTEGER, BYVAL outTypes AS ANY PTR, BYVAL outMimeBuf AS ANY PTR, BYVAL mimeBufSize AS INTEGER, BYVAL formatBufCount AS INTEGER) AS INTEGER

    ' ---- BBitmapStream ----
    Declare Function eb_haiku_bitmap_stream_create(BYVAL bitmap AS ANY PTR) AS ANY PTR
    Declare Function eb_haiku_bitmap_stream_detach_bitmap(BYVAL stream AS ANY PTR) AS ANY PTR
    Declare Sub eb_haiku_bitmap_stream_destroy(BYVAL stream AS ANY PTR)
End Extern
