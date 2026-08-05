// eb-haiku native shim - Translation Kit (BTranslatorRoster/
// BTranslationUtils/BBitmap/BFile/BBitmapStream). See shim.h's own top
// comment for why a hand-written shim is needed at all.
//
// IMPORTANT: BTranslationUtils::GetBitmap (and, by extension, the rest
// of the Translation Kit - it goes through the same registrar/add-on
// system) hangs indefinitely if called before any BApplication exists
// - confirmed by direct reproduction in a standalone C++ program with
// no eBasic involved. Always call HApplicationCreate before any
// function in this file - see this package's own README "Threading"
// section, which documents this prominently (not a new burden for a
// real GUI/app program, which always needs one anyway, but a real trap
// for a program that only wants to use Translation Kit on its own).
//
// BBitmap/BFile here are deliberately minimal - just enough to drive
// Translation Kit's own API (load/save/inspect), not a general
// Interface Kit/Storage Kit expansion.
#pragma once

extern "C" {

// ---- BBitmap (minimal - hold/inspect/draw a loaded image) ----

void* eb_haiku_bitmap_create(float left, float top, float right, float bottom,
                              unsigned int colorSpace, unsigned int flags);
int eb_haiku_bitmap_init_check(void* bitmap);
// Writes the bitmap's own real bounds into the 4 out-params.
void eb_haiku_bitmap_get_bounds(void* bitmap, float* outLeft, float* outTop, float* outRight,
                                 float* outBottom);
unsigned int eb_haiku_bitmap_color_space(void* bitmap);
void eb_haiku_bitmap_destroy(void* bitmap);

// ---- BFile (minimal - drive Translation Kit's own I/O; a real
// BPositionIO, passed directly wherever the functions below need a
// stream) ----

void* eb_haiku_file_create(const char* path, unsigned int openMode);
int eb_haiku_file_init_check(void* file);
void eb_haiku_file_destroy(void* file);

// ---- BMemoryIO/BMallocIO (support/DataIO.h) - both real BPositionIO
// subclasses (single inheritance, no pointer-adjustment concern -
// unlike BFile's own MI case above), usable directly wherever the
// functions in this file already accept a BPositionIO*-shaped stream.
// BMemoryIO wraps a caller-owned buffer (non-owning); BMallocIO
// self-manages its own growable buffer. ----

// `data`/`length` describe an existing, caller-owned buffer this
// BMemoryIO wraps (non-owning - the caller must keep it alive and free
// it themselves) - writable.
void* eb_haiku_memory_io_create(void* data, unsigned long length);
// Read-only variant (real BMemoryIO(const void*, size_t) overload).
void* eb_haiku_memory_io_create_read_only(const void* data, unsigned long length);
void eb_haiku_memory_io_destroy(void* io);

void* eb_haiku_malloc_io_create(void);
void eb_haiku_malloc_io_set_block_size(void* io, unsigned long blockSize);
const void* eb_haiku_malloc_io_buffer(void* io);
unsigned long eb_haiku_malloc_io_buffer_length(void* io);
void eb_haiku_malloc_io_destroy(void* io);

// ---- BTranslationUtils ----

// NULL on failure (unsupported format, bad data, ...) - matching this
// package's own established null-on-failure convention throughout.
void* eb_haiku_translation_utils_get_bitmap(void* positionIOStream);

// ---- BTranslatorRoster ----

// The shared default roster - never destroyed by this package (it's
// owned by the Translation Kit itself, matching real Haiku's own
// intended usage - there is no eb_haiku_translator_roster_destroy).
void* eb_haiku_translator_roster_default(void);

// Auto-detects the source's own format (Haiku's own real "pass a null
// translator_info" idiom, confirmed working directly) and writes the
// result into a full BPositionIO destination stream. wantOutType is
// one of the H_*_FORMAT constants (or H_TRANSLATOR_BITMAP for the
// generic, uncompressed bitmap format).
int eb_haiku_translator_roster_translate(void* roster, void* sourceStream,
                                          void* destinationStream, unsigned int wantOutType);

// Identifies a stream's own format - writes the detected format's type
// code, MIME type, and human-readable name into the out-params (MIME/
// name buffers are caller-supplied, matching this package's own
// established out-buffer convention for borrowed/short strings).
// Returns a status code (0 = success).
int eb_haiku_translator_roster_identify(void* roster, void* sourceStream,
                                         unsigned int* outType, char* outMime, int mimeBufSize,
                                         char* outName, int nameBufSize);

// Loads a third-party translator add-on from a custom path (real
// installed translators are already found automatically - this is only
// for a translator that isn't in Haiku's own standard search path).
int eb_haiku_translator_roster_add_translators(void* roster, const char* loadPath);

// ---- Translator introspection ----

// Returns the real total number of installed translators (regardless
// of buffer size - call once with idBufCount 0 to just get the count),
// writing up to idBufCount of their real numeric IDs into outIds (each
// usable directly with the functions below) - returns -1 on failure.
int eb_haiku_translator_roster_get_all_translators(void* roster, unsigned int* outIds,
                                                    int idBufCount);
// Writes name/info/version into caller-supplied buffers/out-param.
int eb_haiku_translator_roster_get_translator_info(void* roster, unsigned int translatorId,
                                                    char* outName, int nameBufSize, char* outInfo,
                                                    int infoBufSize, int* outVersion);
// Returns the number of input/output formats a translator supports,
// writing each format's type code and MIME type into caller-supplied
// buffers (mimeBufSize applies to each individual MIME string slot).
int eb_haiku_translator_roster_get_input_formats(void* roster, unsigned int translatorId,
                                                  unsigned int* outTypes, char* outMimeBuf,
                                                  int mimeBufSize, int formatBufCount);
int eb_haiku_translator_roster_get_output_formats(void* roster, unsigned int translatorId,
                                                   unsigned int* outTypes, char* outMimeBuf,
                                                   int mimeBufSize, int formatBufCount);

// ---- BBitmapStream (wraps a BBitmap as a BPositionIO source, for
// saving via eb_haiku_translator_roster_translate) ----

// Takes ownership of `bitmap` - do not also call eb_haiku_bitmap_destroy
// on it; DetachBitmap (below) gives it back if needed.
void* eb_haiku_bitmap_stream_create(void* bitmap);
void* eb_haiku_bitmap_stream_detach_bitmap(void* stream);
void eb_haiku_bitmap_stream_destroy(void* stream);

} // extern "C"
