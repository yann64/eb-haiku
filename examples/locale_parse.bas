' Locale Kit Parse methods - the inverse of Format: parse a locale-
' formatted date/time/number string back into its own real fields.

#include once "../src/lib.bas"

DIM dateFmt AS HDateFormat
dateFmt = HDateFormatCreate()

DIM buf(255) AS BYTE
DIM bufPtr AS ANY PTR
bufPtr = @buf(0)
DIM n AS INTEGER
n = HDateFormatFormat(dateFmt, 1700000000, H_SHORT_DATE_FORMAT, bufPtr, 256)
buf(n) = 0
DIM dateZ AS ZSTRING
dateZ = bufPtr
DIM dateStr AS STRING
dateStr = dateZ
PRINT "formatted date=", dateStr

DIM parsedYear AS INTEGER
DIM parsedMonth AS INTEGER
DIM parsedDay AS INTEGER
DIM rc AS INTEGER
rc = HDateFormatParse(dateFmt, dateStr, H_SHORT_DATE_FORMAT, parsedYear, parsedMonth, parsedDay)
IF rc = 0 THEN
    PRINT "parsed date=", parsedYear, "-", parsedMonth, "-", parsedDay
END IF
CALL HDateFormatFree(dateFmt)

DIM numFmt AS HNumberFormat
numFmt = HNumberFormatCreate()
DIM value AS DOUBLE
rc = HNumberFormatParse(numFmt, "12345.678", value)
IF rc = 0 THEN
    PRINT "parsed number=", value
END IF
CALL HNumberFormatFree(numFmt)
