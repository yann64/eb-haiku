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
// The inverse of Format() - parses `source` into a real BDate, whose
// plain int32 Year()/Month()/Day() fields are copied out directly
// (matching this shim's own plain-value-struct-as-separate-params
// convention, e.g. BRect elsewhere) rather than binding a whole new
// BDate handle type just for this. Returns a status_t (0 = success).
int eb_haiku_date_format_parse(void* fmt, const char* source, unsigned int style, int* outYear,
                                int* outMonth, int* outDay);
void eb_haiku_date_format_destroy(void* fmt);

void* eb_haiku_time_format_create(void);
int eb_haiku_time_format_format(void* fmt, long long time, unsigned int style, char* outBuf,
                                 int bufSize);
// Same convention as eb_haiku_date_format_parse, via BTime's own plain
// int32 Hour()/Minute()/Second(). Real BTime lives in `namespace
// BPrivate` inside DateTime.h, but that header itself is public and
// re-exports it via `using BPrivate::BTime;` at global scope - fully
// stable, ordinary public API despite the namespace name.
int eb_haiku_time_format_parse(void* fmt, const char* source, unsigned int style, int* outHour,
                                int* outMinute, int* outSecond);
void eb_haiku_time_format_destroy(void* fmt);

// ---- BNumberFormat (locale/NumberFormat.h) ----

void* eb_haiku_number_format_create(void);
int eb_haiku_number_format_format_double(void* fmt, double value, char* outBuf, int bufSize);
int eb_haiku_number_format_format_int32(void* fmt, int value, char* outBuf, int bufSize);
int eb_haiku_number_format_format_monetary(void* fmt, double value, char* outBuf, int bufSize);
int eb_haiku_number_format_format_percent(void* fmt, double value, char* outBuf, int bufSize);
int eb_haiku_number_format_set_precision(void* fmt, int precision);
// The inverse of FormatDouble() - no int32-specific overload exists in
// real Haiku, only into a double.
int eb_haiku_number_format_parse(void* fmt, const char* source, double* outValue);
void eb_haiku_number_format_destroy(void* fmt);

// ---- BCollator (locale/Collator.h) - locale-aware string comparison/
// sorting, a real gap eBasic's own plain string comparison operators
// don't fill. ----

void* eb_haiku_collator_create(void);
// Real three-way comparison (< 0 / 0 / > 0), matching C's strcmp
// convention.
int eb_haiku_collator_compare(void* collator, const char* s1, const char* s2);
void eb_haiku_collator_destroy(void* collator);

// ---- BCatalog (locale/Catalog.h) - real translation-catalog lookup.
// Only the runtime-facing surface is bound - GetString(key, context,
// comment); the entry_ref-based ctor/SetTo, GetData/GetSignature/
// GetLanguage/GetFingerprint are a reasonable follow-on, not needed
// for the "look up a key, real .catkeys data or not" scope here. Real
// and useful even with zero .catkeys data installed: GetString
// gracefully echoes `string` itself back as the real fallback when no
// catalog/translation is found (confirmed via header - this is the
// entire point of the real B_TRANSLATE macro convention). Building the
// .catkeys data itself is a separate, build-time tool pipeline
// (collectcatkeys/linkcatkeys) - not bound here, a runtime API only.
// Plain new/delete - BCatalog's own destructor is public and virtual,
// no ref-counting. ----

void* eb_haiku_catalog_create(void);
// `signature`/`language` follow this shim's own established
// NULL-via-empty-string convention (language "" means the real
// default: the current system locale).
void* eb_haiku_catalog_create_with_signature(const char* signature, const char* language);
// `context`/`comment` likewise "" for real NULL.
const char* eb_haiku_catalog_get_string(void* catalog, const char* str, const char* context,
                                         const char* comment);
int eb_haiku_catalog_set_to(void* catalog, const char* signature, const char* language);
int eb_haiku_catalog_init_check(void* catalog);
int eb_haiku_catalog_count_items(void* catalog);
void eb_haiku_catalog_destroy(void* catalog);

} // extern "C"
