' Locale Kit - locale-aware date/number formatting and string sorting.

#include once "../src/lib.bas"

DIM dateFmt AS HDateFormat
dateFmt = HDateFormatCreate()

DIM buf(255) AS BYTE
DIM bufPtr AS ANY PTR
bufPtr = @buf(0)

DIM n AS INTEGER
n = HDateFormatFormat(dateFmt, 1700000000, H_SHORT_DATE_FORMAT, bufPtr, 256)
buf(n) = 0
DIM z AS ZSTRING
z = bufPtr
DIM s AS STRING
s = z
PRINT "date: ", s
CALL HDateFormatFree(dateFmt)

DIM numFmt AS HNumberFormat
numFmt = HNumberFormatCreate()
n = HNumberFormatFormatDouble(numFmt, 1234567.89, bufPtr, 256)
buf(n) = 0
z = bufPtr
s = z
PRINT "number: ", s
CALL HNumberFormatFree(numFmt)

DIM collator AS HCollator
collator = HCollatorCreate()
PRINT "compare(apple, banana) = ", HCollatorCompare(collator, "apple", "banana")
CALL HCollatorFree(collator)
