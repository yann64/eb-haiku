' BMessage - Haiku's fundamental structured data-interchange type.

#include once "../src/lib.bas"

DIM msg AS HMessage
msg = HMessageCreate(1234)

CALL HMessageAddString(msg, "greeting", "hello from eBasic")
CALL HMessageAddInt32(msg, "answer", 42)

PRINT HMessageFindString(msg, "greeting")  ' hello from eBasic
PRINT HMessageFindInt32(msg, "answer")     ' 42
PRINT HMessageFindString(msg, "missing")   ' (empty)

CALL HMessageFree(msg)
