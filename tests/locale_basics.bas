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

' HDateFormatParse - the inverse direction. Round-trip: parse the
' exact string Format just produced (locale/timezone-independent,
' rather than hardcoding an assumed calendar date).
DIM rc AS INTEGER
DIM parsedYear AS INTEGER
DIM parsedMonth AS INTEGER
DIM parsedDay AS INTEGER
rc = HDateFormatParse(dateFmt, dateStr, H_SHORT_DATE_FORMAT, parsedYear, parsedMonth, parsedDay)
IF rc <> 0 THEN
    PRINT "FAIL: HDateFormatParse returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "parsed date=", parsedYear, "-", parsedMonth, "-", parsedDay
IF parsedYear < 2000 OR parsedMonth < 1 OR parsedMonth > 12 OR parsedDay < 1 OR parsedDay > 31 THEN
    PRINT "FAIL: parsed date fields look implausible"
    CALL ExitProcess(1)
END IF
PRINT "date parse ok"
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

DIM timeFmt2 AS HTimeFormat
timeFmt2 = HTimeFormatCreate()
DIM parsedHour AS INTEGER
DIM parsedMinute AS INTEGER
DIM parsedSecond AS INTEGER
rc = HTimeFormatParse(timeFmt2, timeStr, H_SHORT_TIME_FORMAT, parsedHour, parsedMinute, parsedSecond)
IF rc <> 0 THEN
    PRINT "FAIL: HTimeFormatParse returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "parsed time=", parsedHour, ":", parsedMinute, ":", parsedSecond
IF parsedHour < 0 OR parsedHour > 23 OR parsedMinute < 0 OR parsedMinute > 59 THEN
    PRINT "FAIL: parsed time fields look implausible"
    CALL ExitProcess(1)
END IF
CALL HTimeFormatFree(timeFmt2)
PRINT "time parse ok"

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

DIM parsedValue AS DOUBLE
rc = HNumberFormatParse(numFmt, numStr, parsedValue)
IF rc <> 0 THEN
    PRINT "FAIL: HNumberFormatParse returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "parsed number=", parsedValue
IF parsedValue < 12345.0 OR parsedValue > 12346.0 THEN
    PRINT "FAIL: parsed number does not round-trip to the original value"
    CALL ExitProcess(1)
END IF
PRINT "number parse ok"
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
