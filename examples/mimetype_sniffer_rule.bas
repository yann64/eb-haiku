' BMimeType sniffer rules - validate a candidate rule, then register it
' for a throwaway MIME type.

#include once "../src/lib.bas"

DIM errBuf(511) AS BYTE
DIM errPtr AS ANY PTR
errPtr = @errBuf(0)
DIM rc AS INTEGER
rc = HMimeTypeCheckSnifferRule("1.0 [0:3] ('PNG')", errPtr, 512)
PRINT "CheckSnifferRule rc=", rc

DIM mt AS HMimeType
mt = HMimeTypeCreate("application/x-vnd.EbHaiku-SnifferRuleExample")
CALL HMimeTypeInstall(mt)
CALL HMimeTypeSetSnifferRule(mt, "1.0 [0:3] ('PNG')")

DIM ruleBuf(255) AS BYTE
DIM rulePtr AS ANY PTR
rulePtr = @ruleBuf(0)
DIM ruleLen AS INTEGER
ruleLen = HMimeTypeGetSnifferRule(mt, rulePtr, 256)
IF ruleLen >= 0 THEN
    ruleBuf(ruleLen) = 0
    DIM ruleZ AS ZSTRING
    ruleZ = rulePtr
    DIM ruleStr AS STRING
    ruleStr = ruleZ
    PRINT "sniffer rule=", ruleStr
END IF

CALL HMimeTypeDelete(mt)
CALL HMimeTypeFree(mt)
