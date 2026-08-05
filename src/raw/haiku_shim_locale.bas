' Raw FFI layer: eb-haiku's Locale Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_locale.h.

' Real BDateFormatStyle/BTimeFormatStyle values (locale/
' FormattingConventions.h) - a plain sequential enum in the real
' header (0-3), confirmed via a compiled probe on the real Haiku host
' anyway, matching this package's own "verify, don't assume" discipline
' for every enum so far.
CONST H_FULL_DATE_FORMAT = 0
CONST H_LONG_DATE_FORMAT = 1
CONST H_MEDIUM_DATE_FORMAT = 2
CONST H_SHORT_DATE_FORMAT = 3
CONST H_FULL_TIME_FORMAT = 0
CONST H_LONG_TIME_FORMAT = 1
CONST H_MEDIUM_TIME_FORMAT = 2
CONST H_SHORT_TIME_FORMAT = 3

Extern "C" Lib "ebhaikushim"
    ' ---- BDateFormat ----
    Declare Function eb_haiku_date_format_create() AS ANY PTR
    Declare Function eb_haiku_date_format_format(BYVAL fmt AS ANY PTR, BYVAL time AS LONGINT, BYVAL style AS UINTEGER, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_date_format_parse(BYVAL fmt AS ANY PTR, BYVAL source AS ZSTRING, BYVAL style AS UINTEGER, BYVAL outYear AS ANY PTR, BYVAL outMonth AS ANY PTR, BYVAL outDay AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_date_format_destroy(BYVAL fmt AS ANY PTR)

    ' ---- BTimeFormat ----
    Declare Function eb_haiku_time_format_create() AS ANY PTR
    Declare Function eb_haiku_time_format_format(BYVAL fmt AS ANY PTR, BYVAL time AS LONGINT, BYVAL style AS UINTEGER, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_time_format_parse(BYVAL fmt AS ANY PTR, BYVAL source AS ZSTRING, BYVAL style AS UINTEGER, BYVAL outHour AS ANY PTR, BYVAL outMinute AS ANY PTR, BYVAL outSecond AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_time_format_destroy(BYVAL fmt AS ANY PTR)

    ' ---- BNumberFormat ----
    Declare Function eb_haiku_number_format_create() AS ANY PTR
    Declare Function eb_haiku_number_format_format_double(BYVAL fmt AS ANY PTR, BYVAL value AS DOUBLE, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_number_format_format_int32(BYVAL fmt AS ANY PTR, BYVAL value AS INTEGER, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_number_format_format_monetary(BYVAL fmt AS ANY PTR, BYVAL value AS DOUBLE, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_number_format_format_percent(BYVAL fmt AS ANY PTR, BYVAL value AS DOUBLE, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_number_format_set_precision(BYVAL fmt AS ANY PTR, BYVAL precision AS INTEGER) AS INTEGER
    Declare Function eb_haiku_number_format_parse(BYVAL fmt AS ANY PTR, BYVAL source AS ZSTRING, BYVAL outValue AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_number_format_destroy(BYVAL fmt AS ANY PTR)

    ' ---- BCollator ----
    Declare Function eb_haiku_collator_create() AS ANY PTR
    Declare Function eb_haiku_collator_compare(BYVAL collator AS ANY PTR, BYVAL s1 AS ZSTRING, BYVAL s2 AS ZSTRING) AS INTEGER
    Declare Sub eb_haiku_collator_destroy(BYVAL collator AS ANY PTR)

    ' ---- BCatalog ----
    Declare Function eb_haiku_catalog_create() AS ANY PTR
    Declare Function eb_haiku_catalog_create_with_signature(BYVAL signature AS ZSTRING, BYVAL language AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_catalog_get_string(BYVAL catalog AS ANY PTR, BYVAL str AS ZSTRING, BYVAL context AS ZSTRING, BYVAL comment AS ZSTRING) AS ZSTRING
    Declare Function eb_haiku_catalog_set_to(BYVAL catalog AS ANY PTR, BYVAL signature AS ZSTRING, BYVAL language AS ZSTRING) AS INTEGER
    Declare Function eb_haiku_catalog_init_check(BYVAL catalog AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_catalog_count_items(BYVAL catalog AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_catalog_destroy(BYVAL catalog AS ANY PTR)
End Extern
