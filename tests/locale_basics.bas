' Locale Kit: BDateFormat/BTimeFormat/BNumberFormat/BCollator. Verified
' against real, known values - a fixed timestamp formats to a sane,
' non-empty string (exact text depends on the host's own locale, not
' asserted literally), BCollator orders a small known word pair
' correctly, and BNumberFormat round-trips a known value's real digits.

#include once "../src/lib.bas"

DIM dateFmt AS HDateFormat
dateFmt = HDateFormatCreate()

DIM buf(255) AS BYTE
DIM bufPtr AS ANY PTR
bufPtr = @buf(0)

CONST KNOWN_TIME = 1700000000 ' 2023-11-14 22:13:20 UTC
DIM n AS INTEGER
n = HDateFormatFormat(dateFmt, KNOWN_TIME, H_SHORT_DATE_FORMAT, bufPtr, 256)
IF n <= 0 THEN
    PRINT "FAIL: HDateFormatFormat returned ", n
    CALL ExitProcess(1)
END IF
buf(n) = 0
DIM dateZ AS ZSTRING
dateZ = bufPtr
DIM dateStr AS STRING
dateStr = dateZ
PRINT "formatted date=", dateStr
' The formatted date should contain "23" (the year 2023, in whatever
' 2-or-4-digit form the host's own locale uses) - a loose, locale-
' independent sanity check rather than asserting exact separator style.
IF InStr(dateStr, "23") = 0 THEN
    PRINT "FAIL: formatted date does not look like it contains the year"
    CALL ExitProcess(1)
END IF
PRINT "date format ok"
CALL HDateFormatFree(dateFmt)

DIM timeFmt AS HTimeFormat
timeFmt = HTimeFormatCreate()
n = HTimeFormatFormat(timeFmt, KNOWN_TIME, H_SHORT_TIME_FORMAT, bufPtr, 256)
IF n <= 0 THEN
    PRINT "FAIL: HTimeFormatFormat returned ", n
    CALL ExitProcess(1)
END IF
buf(n) = 0
DIM timeZ AS ZSTRING
timeZ = bufPtr
DIM timeStr AS STRING
timeStr = timeZ
PRINT "formatted time=", timeStr
CALL HTimeFormatFree(timeFmt)
PRINT "time format ok"

DIM numFmt AS HNumberFormat
numFmt = HNumberFormatCreate()
n = HNumberFormatFormatDouble(numFmt, 12345.678, bufPtr, 256)
IF n <= 0 THEN
    PRINT "FAIL: HNumberFormatFormatDouble returned ", n
    CALL ExitProcess(1)
END IF
buf(n) = 0
DIM numZ AS ZSTRING
numZ = bufPtr
DIM numStr AS STRING
numStr = numZ
PRINT "formatted number=", numStr
' Real digit groups should appear regardless of thousands/decimal
' separator style.
IF InStr(numStr, "12") = 0 OR InStr(numStr, "345") = 0 THEN
    PRINT "FAIL: formatted number does not contain expected digit groups"
    CALL ExitProcess(1)
END IF
PRINT "number format ok"
CALL HNumberFormatFree(numFmt)

DIM collator AS HCollator
collator = HCollatorCreate()
IF HCollatorCompare(collator, "apple", "banana") >= 0 THEN
    PRINT "FAIL: apple should sort before banana"
    CALL ExitProcess(1)
END IF
IF HCollatorCompare(collator, "banana", "apple") <= 0 THEN
    PRINT "FAIL: banana should sort after apple"
    CALL ExitProcess(1)
END IF
IF HCollatorCompare(collator, "apple", "apple") <> 0 THEN
    PRINT "FAIL: a string should compare equal to itself"
    CALL ExitProcess(1)
END IF
CALL HCollatorFree(collator)
PRINT "collator ordering ok"

PRINT "locale basics test ok"
