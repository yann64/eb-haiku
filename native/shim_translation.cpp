#include "shim_translation.h"

#include <Bitmap.h>
#include <BitmapStream.h>
#include <DataIO.h>
#include <File.h>
#include <TranslationUtils.h>
#include <TranslatorRoster.h>
#include <TranslatorFormats.h>

#include <cstring>

extern "C" {

// ---- BBitmap ----

void* eb_haiku_bitmap_create(float left, float top, float right, float bottom,
                              unsigned int colorSpace, unsigned int flags) {
    return new BBitmap(BRect(left, top, right, bottom), flags, static_cast<color_space>(colorSpace));
}

int eb_haiku_bitmap_init_check(void* bitmap) {
    return static_cast<BBitmap*>(bitmap)->InitCheck();
}

void eb_haiku_bitmap_get_bounds(void* bitmap, float* outLeft, float* outTop, float* outRight,
                                 float* outBottom) {
    BRect b = static_cast<BBitmap*>(bitmap)->Bounds();
    *outLeft = b.left;
    *outTop = b.top;
    *outRight = b.right;
    *outBottom = b.bottom;
}

unsigned int eb_haiku_bitmap_color_space(void* bitmap) {
    return static_cast<unsigned int>(static_cast<BBitmap*>(bitmap)->ColorSpace());
}

void eb_haiku_bitmap_destroy(void* bitmap) { delete static_cast<BBitmap*>(bitmap); }

// ---- BFile ----
//
// BFile : public BNode, public BPositionIO - BPositionIO is the SECOND
// base, at a nonzero offset within the complete object. The handle
// this shim hands out has to work both as a BFile* (InitCheck/destroy
// below) and as a BPositionIO* (every Translation Kit function that
// takes a "stream" - GetBitmap/Translate/Identify below all just
// static_cast<BPositionIO*> whatever void* they're given, with no way
// to know it started life as a BFile*).
//
// A static_cast straight from void* to BPositionIO* does NOT apply
// that offset - the compiler has no static type to adjust from, so it
// just reinterprets the bits as if BPositionIO sat at offset 0. The
// resulting pointer lands inside the BNode subobject instead, and any
// translator that actually calls Read/Seek through it (real installed
// ones do, e.g. WonderBrushTranslator's own BitsCheck) reads garbage
// and crashes (a real General Protection Fault, reproduced directly
// against this shim - not a hang, and not present when the identical
// BFile/GetBitmap calls are written inline with static types intact).
//
// Fix: store the *already-adjusted* BPositionIO* as the canonical
// handle (computed here, the one place BFile's real static type is
// known, so the compiler inserts the correct offset itself), and use
// dynamic_cast (RTTI - both classes are polymorphic) to recover BFile*
// for the two functions that need it. dynamic_cast correctly walks the
// real multiple-inheritance layout regardless of which base you start
// from, unlike static_cast from an untyped void*.

void* eb_haiku_file_create(const char* path, unsigned int openMode) {
    BFile* file = new BFile(path, openMode);
    return static_cast<BPositionIO*>(file);
}

int eb_haiku_file_init_check(void* file) {
    return dynamic_cast<BFile*>(static_cast<BPositionIO*>(file))->InitCheck();
}

void eb_haiku_file_destroy(void* file) { delete dynamic_cast<BFile*>(static_cast<BPositionIO*>(file)); }

// ---- BMemoryIO/BMallocIO ----

void* eb_haiku_memory_io_create(void* data, unsigned long length) {
    return new BMemoryIO(data, static_cast<size_t>(length));
}

void* eb_haiku_memory_io_create_read_only(const void* data, unsigned long length) {
    return new BMemoryIO(data, static_cast<size_t>(length));
}

void eb_haiku_memory_io_destroy(void* io) { delete static_cast<BMemoryIO*>(io); }

void* eb_haiku_malloc_io_create(void) { return new BMallocIO(); }

void eb_haiku_malloc_io_set_block_size(void* io, unsigned long blockSize) {
    static_cast<BMallocIO*>(io)->SetBlockSize(static_cast<size_t>(blockSize));
}

const void* eb_haiku_malloc_io_buffer(void* io) { return static_cast<BMallocIO*>(io)->Buffer(); }

unsigned long eb_haiku_malloc_io_buffer_length(void* io) {
    return static_cast<unsigned long>(static_cast<BMallocIO*>(io)->BufferLength());
}

void eb_haiku_malloc_io_destroy(void* io) { delete static_cast<BMallocIO*>(io); }

// ---- BTranslationUtils ----

void* eb_haiku_translation_utils_get_bitmap(void* positionIOStream) {
    return BTranslationUtils::GetBitmap(static_cast<BPositionIO*>(positionIOStream));
}

// ---- BTranslatorRoster ----

void* eb_haiku_translator_roster_default(void) { return BTranslatorRoster::Default(); }

int eb_haiku_translator_roster_translate(void* roster, void* sourceStream, void* destinationStream,
                                          unsigned int wantOutType) {
    return static_cast<BTranslatorRoster*>(roster)->Translate(
        static_cast<BPositionIO*>(sourceStream), nullptr, nullptr,
        static_cast<BPositionIO*>(destinationStream), wantOutType);
}

int eb_haiku_translator_roster_identify(void* roster, void* sourceStream, unsigned int* outType,
                                         char* outMime, int mimeBufSize, char* outName,
                                         int nameBufSize) {
    translator_info info;
    status_t rc = static_cast<BTranslatorRoster*>(roster)->Identify(
        static_cast<BPositionIO*>(sourceStream), nullptr, &info);
    if (rc != B_OK) {
        outMime[0] = '\0';
        outName[0] = '\0';
        return rc;
    }
    *outType = info.type;
    std::strncpy(outMime, info.MIME, static_cast<size_t>(mimeBufSize - 1));
    outMime[mimeBufSize - 1] = '\0';
    std::strncpy(outName, info.name, static_cast<size_t>(nameBufSize - 1));
    outName[nameBufSize - 1] = '\0';
    return B_OK;
}

int eb_haiku_translator_roster_add_translators(void* roster, const char* loadPath) {
    return static_cast<BTranslatorRoster*>(roster)->AddTranslators(loadPath);
}

// ---- Translator introspection ----

int eb_haiku_translator_roster_get_all_translators(void* roster, unsigned int* outIds,
                                                    int idBufCount) {
    translator_id* list = nullptr;
    int32 count = 0;
    status_t rc = static_cast<BTranslatorRoster*>(roster)->GetAllTranslators(&list, &count);
    if (rc != B_OK) return -1;
    int written = count < idBufCount ? count : idBufCount;
    for (int i = 0; i < written; i++) outIds[i] = static_cast<unsigned int>(list[i]);
    return count;
}

int eb_haiku_translator_roster_get_translator_info(void* roster, unsigned int translatorId,
                                                    char* outName, int nameBufSize, char* outInfo,
                                                    int infoBufSize, int* outVersion) {
    const char* name = nullptr;
    const char* info = nullptr;
    int32 version = 0;
    status_t rc = static_cast<BTranslatorRoster*>(roster)->GetTranslatorInfo(
        static_cast<translator_id>(translatorId), &name, &info, &version);
    if (rc != B_OK) {
        outName[0] = '\0';
        outInfo[0] = '\0';
        *outVersion = 0;
        return rc;
    }
    std::strncpy(outName, name ? name : "", static_cast<size_t>(nameBufSize - 1));
    outName[nameBufSize - 1] = '\0';
    std::strncpy(outInfo, info ? info : "", static_cast<size_t>(infoBufSize - 1));
    outInfo[infoBufSize - 1] = '\0';
    *outVersion = version;
    return B_OK;
}

int eb_haiku_translator_roster_get_input_formats(void* roster, unsigned int translatorId,
                                                  unsigned int* outTypes, char* outMimeBuf,
                                                  int mimeBufSize, int formatBufCount) {
    const translation_format* formats = nullptr;
    int32 count = 0;
    status_t rc = static_cast<BTranslatorRoster*>(roster)->GetInputFormats(
        static_cast<translator_id>(translatorId), &formats, &count);
    if (rc != B_OK) return -1;
    int written = count < formatBufCount ? count : formatBufCount;
    for (int i = 0; i < written; i++) {
        outTypes[i] = formats[i].type;
        char* slot = outMimeBuf + (static_cast<size_t>(i) * static_cast<size_t>(mimeBufSize));
        std::strncpy(slot, formats[i].MIME, static_cast<size_t>(mimeBufSize - 1));
        slot[mimeBufSize - 1] = '\0';
    }
    return count;
}

int eb_haiku_translator_roster_get_output_formats(void* roster, unsigned int translatorId,
                                                   unsigned int* outTypes, char* outMimeBuf,
                                                   int mimeBufSize, int formatBufCount) {
    const translation_format* formats = nullptr;
    int32 count = 0;
    status_t rc = static_cast<BTranslatorRoster*>(roster)->GetOutputFormats(
        static_cast<translator_id>(translatorId), &formats, &count);
    if (rc != B_OK) return -1;
    int written = count < formatBufCount ? count : formatBufCount;
    for (int i = 0; i < written; i++) {
        outTypes[i] = formats[i].type;
        char* slot = outMimeBuf + (static_cast<size_t>(i) * static_cast<size_t>(mimeBufSize));
        std::strncpy(slot, formats[i].MIME, static_cast<size_t>(mimeBufSize - 1));
        slot[mimeBufSize - 1] = '\0';
    }
    return count;
}

// ---- BBitmapStream ----

void* eb_haiku_bitmap_stream_create(void* bitmap) {
    return new BBitmapStream(static_cast<BBitmap*>(bitmap));
}

void* eb_haiku_bitmap_stream_detach_bitmap(void* stream) {
    BBitmap* bitmap = nullptr;
    static_cast<BBitmapStream*>(stream)->DetachBitmap(&bitmap);
    return bitmap;
}

void eb_haiku_bitmap_stream_destroy(void* stream) { delete static_cast<BBitmapStream*>(stream); }

} // extern "C"
