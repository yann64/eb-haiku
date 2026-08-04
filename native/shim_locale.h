// eb-haiku native shim - Locale Kit (BDateFormat/BTimeFormat/
// BNumberFormat/BCollator). See shim.h's own top comment for why a
// hand-written shim is needed at all.
//
// Real, compact, ICU-backed API living directly in libbe.so (confirmed
// via `nm` on the real host) - no new link dependency, unlike
// Translation/Network Kit. No-arg constructors already resolve to
// BLocale::Default() internally - no separate locale object exposed
// here for this first pass.
#pragma once

extern "C" {

// ---- BDateFormat/BTimeFormat (locale/DateFormat.h, TimeFormat.h) ----
// style: one of the H_*_DATE_FORMAT/H_*_TIME_FORMAT constants
// (raw/haiku_shim_locale.bas - real values confirmed via probe, a
// plain sequential enum 0-3 in the real header).

void* eb_haiku_date_format_create(void);
// Fills `outBuf` (caller-supplied, `bufSize` bytes) with the formatted
// date - real Haiku's own char*/maxSize overload, no BString involved
// at all. Returns the real length in bytes (>= 0), or a negative
// status_t.
int eb_haiku_date_format_format(void* fmt, long long time, unsigned int style, char* outBuf,
                                 int bufSize);
void eb_haiku_date_format_destroy(void* fmt);

void* eb_haiku_time_format_create(void);
int eb_haiku_time_format_format(void* fmt, long long time, unsigned int style, char* outBuf,
                                 int bufSize);
void eb_haiku_time_format_destroy(void* fmt);

// ---- BNumberFormat (locale/NumberFormat.h) ----

void* eb_haiku_number_format_create(void);
int eb_haiku_number_format_format_double(void* fmt, double value, char* outBuf, int bufSize);
int eb_haiku_number_format_format_int32(void* fmt, int value, char* outBuf, int bufSize);
int eb_haiku_number_format_format_monetary(void* fmt, double value, char* outBuf, int bufSize);
int eb_haiku_number_format_format_percent(void* fmt, double value, char* outBuf, int bufSize);
int eb_haiku_number_format_set_precision(void* fmt, int precision);
void eb_haiku_number_format_destroy(void* fmt);

// ---- BCollator (locale/Collator.h) - locale-aware string comparison/
// sorting, a real gap eBasic's own plain string comparison operators
// don't fill. ----

void* eb_haiku_collator_create(void);
// Real three-way comparison (< 0 / 0 / > 0), matching C's strcmp
// convention.
int eb_haiku_collator_compare(void* collator, const char* s1, const char* s2);
void eb_haiku_collator_destroy(void* collator);

} // extern "C"
