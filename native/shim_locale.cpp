#include "shim_locale.h"

#include <Collator.h>
#include <DateFormat.h>
#include <NumberFormat.h>
#include <TimeFormat.h>

extern "C" {

// ---- BDateFormat ----

void* eb_haiku_date_format_create(void) { return new BDateFormat(); }

int eb_haiku_date_format_format(void* fmt, long long time, unsigned int style, char* outBuf,
                                 int bufSize) {
    return static_cast<int>(static_cast<BDateFormat*>(fmt)->Format(
        outBuf, static_cast<size_t>(bufSize), static_cast<time_t>(time),
        static_cast<BDateFormatStyle>(style)));
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

void eb_haiku_number_format_destroy(void* fmt) { delete static_cast<BNumberFormat*>(fmt); }

// ---- BCollator ----

void* eb_haiku_collator_create(void) { return new BCollator(); }

int eb_haiku_collator_compare(void* collator, const char* s1, const char* s2) {
    return static_cast<BCollator*>(collator)->Compare(s1, s2);
}

void eb_haiku_collator_destroy(void* collator) { delete static_cast<BCollator*>(collator); }

} // extern "C"
