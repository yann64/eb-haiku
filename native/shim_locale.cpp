#include "shim_locale.h"

#include <Catalog.h>
#include <Collator.h>
#include <DateFormat.h>
#include <DateTime.h>
#include <NumberFormat.h>
#include <String.h>
#include <TimeFormat.h>

namespace {
const char* nullIfEmpty(const char* s) { return (s && s[0] != '\0') ? s : nullptr; }
} // namespace

extern "C" {

// ---- BDateFormat ----

void* eb_haiku_date_format_create(void) { return new BDateFormat(); }

int eb_haiku_date_format_format(void* fmt, long long time, unsigned int style, char* outBuf,
                                 int bufSize) {
    return static_cast<int>(static_cast<BDateFormat*>(fmt)->Format(
        outBuf, static_cast<size_t>(bufSize), static_cast<time_t>(time),
        static_cast<BDateFormatStyle>(style)));
}

int eb_haiku_date_format_parse(void* fmt, const char* source, unsigned int style, int* outYear,
                                int* outMonth, int* outDay) {
    BDate date;
    status_t rc = static_cast<BDateFormat*>(fmt)->Parse(BString(source),
                                                          static_cast<BDateFormatStyle>(style),
                                                          date);
    if (rc != B_OK) return rc;
    *outYear = date.Year();
    *outMonth = date.Month();
    *outDay = date.Day();
    return B_OK;
}

void eb_haiku_date_format_destroy(void* fmt) { delete static_cast<BDateFormat*>(fmt); }

// ---- BTimeFormat ----

void* eb_haiku_time_format_create(void) { return new BTimeFormat(); }

int eb_haiku_time_format_format(void* fmt, long long time, unsigned int style, char* outBuf,
                                 int bufSize) {
    return static_cast<int>(static_cast<BTimeFormat*>(fmt)->Format(
        outBuf, static_cast<size_t>(bufSize), static_cast<time_t>(time),
        static_cast<BTimeFormatStyle>(style)));
}

int eb_haiku_time_format_parse(void* fmt, const char* source, unsigned int style, int* outHour,
                                int* outMinute, int* outSecond) {
    BTime time;
    status_t rc = static_cast<BTimeFormat*>(fmt)->Parse(BString(source),
                                                          static_cast<BTimeFormatStyle>(style),
                                                          time);
    if (rc != B_OK) return rc;
    *outHour = time.Hour();
    *outMinute = time.Minute();
    *outSecond = time.Second();
    return B_OK;
}

void eb_haiku_time_format_destroy(void* fmt) { delete static_cast<BTimeFormat*>(fmt); }

// ---- BNumberFormat ----

void* eb_haiku_number_format_create(void) { return new BNumberFormat(); }

int eb_haiku_number_format_format_double(void* fmt, double value, char* outBuf, int bufSize) {
    return static_cast<int>(
        static_cast<BNumberFormat*>(fmt)->Format(outBuf, static_cast<size_t>(bufSize), value));
}

int eb_haiku_number_format_format_int32(void* fmt, int value, char* outBuf, int bufSize) {
    return static_cast<int>(static_cast<BNumberFormat*>(fmt)->Format(
        outBuf, static_cast<size_t>(bufSize), static_cast<int32>(value)));
}

int eb_haiku_number_format_format_monetary(void* fmt, double value, char* outBuf, int bufSize) {
    return static_cast<int>(static_cast<BNumberFormat*>(fmt)->FormatMonetary(
        outBuf, static_cast<size_t>(bufSize), value));
}

int eb_haiku_number_format_format_percent(void* fmt, double value, char* outBuf, int bufSize) {
    return static_cast<int>(static_cast<BNumberFormat*>(fmt)->FormatPercent(
        outBuf, static_cast<size_t>(bufSize), value));
}

int eb_haiku_number_format_set_precision(void* fmt, int precision) {
    return static_cast<BNumberFormat*>(fmt)->SetPrecision(precision);
}

int eb_haiku_number_format_parse(void* fmt, const char* source, double* outValue) {
    return static_cast<BNumberFormat*>(fmt)->Parse(BString(source), *outValue);
}

void eb_haiku_number_format_destroy(void* fmt) { delete static_cast<BNumberFormat*>(fmt); }

// ---- BCollator ----

void* eb_haiku_collator_create(void) { return new BCollator(); }

int eb_haiku_collator_compare(void* collator, const char* s1, const char* s2) {
    return static_cast<BCollator*>(collator)->Compare(s1, s2);
}

void eb_haiku_collator_destroy(void* collator) { delete static_cast<BCollator*>(collator); }

// ---- BCatalog ----

void* eb_haiku_catalog_create(void) { return new BCatalog(); }

void* eb_haiku_catalog_create_with_signature(const char* signature, const char* language) {
    return new BCatalog(signature, nullIfEmpty(language));
}

const char* eb_haiku_catalog_get_string(void* catalog, const char* str, const char* context,
                                         const char* comment) {
    return static_cast<BCatalog*>(catalog)->GetString(str, nullIfEmpty(context),
                                                        nullIfEmpty(comment));
}

int eb_haiku_catalog_set_to(void* catalog, const char* signature, const char* language) {
    return static_cast<BCatalog*>(catalog)->SetTo(signature, nullIfEmpty(language));
}

int eb_haiku_catalog_init_check(void* catalog) {
    return static_cast<BCatalog*>(catalog)->InitCheck();
}

int eb_haiku_catalog_count_items(void* catalog) {
    return static_cast<BCatalog*>(catalog)->CountItems();
}

void eb_haiku_catalog_destroy(void* catalog) { delete static_cast<BCatalog*>(catalog); }

} // extern "C"
