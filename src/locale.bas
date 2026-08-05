' Idiomatic layer: BDateFormat/BTimeFormat/BNumberFormat/BCollator -
' locale-aware formatting and string comparison/sorting, ICU-backed.
' No-arg constructors already resolve to the system's own default
' locale internally - no separate locale object needed for this first
' pass (confirmed working directly, no HApplication needed either).

#include once "raw/haiku_shim_locale.bas"

TYPE HDateFormat
    handle AS ANY PTR
END TYPE

FUNCTION HDateFormatCreate() AS HDateFormat
    DIM f AS HDateFormat
    f.handle = eb_haiku_date_format_create()
    HDateFormatCreate = f
END FUNCTION

''' Formats `time` (a Unix timestamp) into `outBuf` (caller-supplied,
''' `bufSize` bytes) using the given H_*_DATE_FORMAT style, in the
''' system's own default locale. NOT null-terminated automatically,
''' matching this package's own established buffer-out convention.
''' Returns the real length in bytes (>= 0), or a negative status code.
FUNCTION HDateFormatFormat(BYVAL f AS HDateFormat, BYVAL time AS LONGINT, BYVAL style AS UINTEGER, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HDateFormatFormat = eb_haiku_date_format_format(f.handle, time, style, outBuf, bufSize)
END FUNCTION

''' The inverse of HDateFormatFormat - parses `source` (in the given
''' H_*_DATE_FORMAT style, system default locale) into `outYear`/
''' `outMonth`/`outDay` (BYREF). Returns a status code (0 = success).
FUNCTION HDateFormatParse(BYVAL f AS HDateFormat, source AS ZSTRING, BYVAL style AS UINTEGER, BYREF outYear AS INTEGER, BYREF outMonth AS INTEGER, BYREF outDay AS INTEGER) AS INTEGER
    DIM y AS INTEGER
    DIM m AS INTEGER
    DIM d AS INTEGER
    HDateFormatParse = eb_haiku_date_format_parse(f.handle, source, style, @y, @m, @d)
    outYear = y
    outMonth = m
    outDay = d
END FUNCTION

''' Frees an HDateFormat - call exactly once.
SUB HDateFormatFree(BYVAL f AS HDateFormat)
    CALL eb_haiku_date_format_destroy(f.handle)
END SUB

TYPE HTimeFormat
    handle AS ANY PTR
END TYPE

FUNCTION HTimeFormatCreate() AS HTimeFormat
    DIM f AS HTimeFormat
    f.handle = eb_haiku_time_format_create()
    HTimeFormatCreate = f
END FUNCTION

''' Same shape as HDateFormatFormat, for time-of-day formatting.
FUNCTION HTimeFormatFormat(BYVAL f AS HTimeFormat, BYVAL time AS LONGINT, BYVAL style AS UINTEGER, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HTimeFormatFormat = eb_haiku_time_format_format(f.handle, time, style, outBuf, bufSize)
END FUNCTION

''' The inverse of HTimeFormatFormat - parses `source` into `outHour`/
''' `outMinute`/`outSecond` (BYREF). Returns a status code (0 = success).
FUNCTION HTimeFormatParse(BYVAL f AS HTimeFormat, source AS ZSTRING, BYVAL style AS UINTEGER, BYREF outHour AS INTEGER, BYREF outMinute AS INTEGER, BYREF outSecond AS INTEGER) AS INTEGER
    DIM h AS INTEGER
    DIM mi AS INTEGER
    DIM s AS INTEGER
    HTimeFormatParse = eb_haiku_time_format_parse(f.handle, source, style, @h, @mi, @s)
    outHour = h
    outMinute = mi
    outSecond = s
END FUNCTION

SUB HTimeFormatFree(BYVAL f AS HTimeFormat)
    CALL eb_haiku_time_format_destroy(f.handle)
END SUB

TYPE HNumberFormat
    handle AS ANY PTR
END TYPE

FUNCTION HNumberFormatCreate() AS HNumberFormat
    DIM f AS HNumberFormat
    f.handle = eb_haiku_number_format_create()
    HNumberFormatCreate = f
END FUNCTION

''' Formats `value` into `outBuf` using the system's own default
''' locale's own number formatting conventions (thousands/decimal
''' separators). Same buffer-out convention as HDateFormatFormat.
FUNCTION HNumberFormatFormatDouble(BYVAL f AS HNumberFormat, BYVAL value AS DOUBLE, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HNumberFormatFormatDouble = eb_haiku_number_format_format_double(f.handle, value, outBuf, bufSize)
END FUNCTION

FUNCTION HNumberFormatFormatInt32(BYVAL f AS HNumberFormat, BYVAL value AS INTEGER, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HNumberFormatFormatInt32 = eb_haiku_number_format_format_int32(f.handle, value, outBuf, bufSize)
END FUNCTION

''' Formats `value` as a locale-appropriate currency amount.
FUNCTION HNumberFormatFormatMonetary(BYVAL f AS HNumberFormat, BYVAL value AS DOUBLE, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HNumberFormatFormatMonetary = eb_haiku_number_format_format_monetary(f.handle, value, outBuf, bufSize)
END FUNCTION

''' Formats `value` (e.g. 0.5) as a locale-appropriate percentage
''' (e.g. "50%").
FUNCTION HNumberFormatFormatPercent(BYVAL f AS HNumberFormat, BYVAL value AS DOUBLE, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HNumberFormatFormatPercent = eb_haiku_number_format_format_percent(f.handle, value, outBuf, bufSize)
END FUNCTION

FUNCTION HNumberFormatSetPrecision(BYVAL f AS HNumberFormat, BYVAL precision AS INTEGER) AS INTEGER
    HNumberFormatSetPrecision = eb_haiku_number_format_set_precision(f.handle, precision)
END FUNCTION

''' The inverse of HNumberFormatFormatDouble - parses `source` (using
''' the system's own default locale's number conventions) into
''' `outValue` (BYREF). Real Haiku has no int32-specific Parse overload
''' - only into a double. Returns a status code (0 = success).
FUNCTION HNumberFormatParse(BYVAL f AS HNumberFormat, source AS ZSTRING, BYREF outValue AS DOUBLE) AS INTEGER
    DIM v AS DOUBLE
    HNumberFormatParse = eb_haiku_number_format_parse(f.handle, source, @v)
    outValue = v
END FUNCTION

SUB HNumberFormatFree(BYVAL f AS HNumberFormat)
    CALL eb_haiku_number_format_destroy(f.handle)
END SUB

TYPE HCollator
    handle AS ANY PTR
END TYPE

FUNCTION HCollatorCreate() AS HCollator
    DIM c AS HCollator
    c.handle = eb_haiku_collator_create()
    HCollatorCreate = c
END FUNCTION

''' Locale-aware three-way string comparison (< 0 / 0 / > 0, matching
''' C's strcmp convention) - a real gap eBasic's own plain string
''' comparison operators don't fill (accent/case/locale-correct
''' ordering, not byte-value ordering).
FUNCTION HCollatorCompare(BYVAL c AS HCollator, s1 AS ZSTRING, s2 AS ZSTRING) AS INTEGER
    HCollatorCompare = eb_haiku_collator_compare(c.handle, s1, s2)
END FUNCTION

SUB HCollatorFree(BYVAL c AS HCollator)
    CALL eb_haiku_collator_destroy(c.handle)
END SUB
