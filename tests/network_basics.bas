' Network Kit: BSocket/BNetworkAddress (real TCP) + BUrl. Self-
' contained (no external network dependency): a throwaway local `nc`
' listener is started via Shell() for each direction (write and read),
' matching real Haiku's own available tooling - confirmed present via
' `which nc` on the real host before writing this test.

#include once "../src/lib.bas"

' ---- BNetworkAddress: real DNS resolution against "localhost" ----

DIM addr AS HNetworkAddress
addr = HNetworkAddressCreateEmpty()
DIM rc AS INTEGER
rc = HNetworkAddressSetTo(addr, "localhost", 12345)
IF rc <> 0 THEN
    PRINT "FAIL: HNetworkAddressSetTo(localhost) returned ", rc
    CALL ExitProcess(1)
END IF
IF HNetworkAddressInitCheck(addr) <> 0 THEN
    PRINT "FAIL: HNetworkAddressInitCheck after resolving localhost"
    CALL ExitProcess(1)
END IF
IF HNetworkAddressPort(addr) <> 12345 THEN
    PRINT "FAIL: HNetworkAddressPort mismatch"
    CALL ExitProcess(1)
END IF
DIM addrBuf(255) AS BYTE
DIM addrBufPtr AS ANY PTR
addrBufPtr = @addrBuf(0)
DIM addrLen AS INTEGER
addrLen = HNetworkAddressToString(addr, addrBufPtr, 256)
addrBuf(addrLen) = 0
DIM addrZ AS ZSTRING
addrZ = addrBufPtr
PRINT "resolved localhost=", addrZ
CALL HNetworkAddressFree(addr)
PRINT "DNS resolution ok"

' ---- BSocket: write path - send real data to a throwaway nc listener ----

CONST WRITE_PORT = 8901
CONST WRITE_OUT_FILE = "/boot/home/eb-haiku-net-write-test.txt"
CONST WRITE_TEXT = "hello from eb-haiku BSocket"

CALL Kill(WRITE_OUT_FILE)
CALL Shell("nc -l -p " & Str(WRITE_PORT) & " > " & WRITE_OUT_FILE & " &")
CALL Sleep(500) ' let nc start listening

DIM writeAddr AS HNetworkAddress
writeAddr = HNetworkAddressCreateEmpty()
CALL HNetworkAddressSetTo(writeAddr, "127.0.0.1", WRITE_PORT)

DIM writeSock AS HSocket
writeSock = HSocketCreate()
rc = HSocketConnect(writeSock, writeAddr, 3000000)
IF rc <> 0 THEN
    PRINT "FAIL: HSocketConnect (write path) returned ", rc
    CALL ExitProcess(1)
END IF
IF HSocketIsConnected(writeSock) <> 1 THEN
    PRINT "FAIL: HSocketIsConnected should be true after a successful Connect"
    CALL ExitProcess(1)
END IF

DIM writeBuf(255) AS BYTE
DIM i AS INTEGER
FOR i = 1 TO Len(WRITE_TEXT)
    writeBuf(i - 1) = Asc(Mid(WRITE_TEXT, i, 1))
NEXT i
DIM writeBufPtr AS ANY PTR
writeBufPtr = @writeBuf(0)
DIM written AS INTEGER
written = HSocketWrite(writeSock, writeBufPtr, Len(WRITE_TEXT))
IF written <> Len(WRITE_TEXT) THEN
    PRINT "FAIL: HSocketWrite wrote ", written, " of ", Len(WRITE_TEXT), " bytes"
    CALL ExitProcess(1)
END IF
CALL HSocketDisconnect(writeSock)
CALL HSocketFree(writeSock)
CALL HNetworkAddressFree(writeAddr)

CALL Sleep(500) ' let nc flush and exit

DIM readOk AS INTEGER
DIM received AS STRING
received = ReadFile(WRITE_OUT_FILE, readOk)
IF readOk = 0 THEN
    PRINT "FAIL: could not read back what nc received"
    CALL ExitProcess(1)
END IF
PRINT "nc received=", received
IF received <> WRITE_TEXT THEN
    PRINT "FAIL: write-path round-trip mismatch"
    CALL ExitProcess(1)
END IF
CALL Kill(WRITE_OUT_FILE)
PRINT "socket write path ok"

' ---- BSocket: read path - receive real data from a throwaway nc sender ----

CONST READ_PORT = 8902
CONST READ_TEXT = "hello from nc"

CALL Shell("(echo '" & READ_TEXT & "' | nc -l -p " & Str(READ_PORT) & ") &")
CALL Sleep(500) ' let nc start listening

DIM readAddr AS HNetworkAddress
readAddr = HNetworkAddressCreateEmpty()
CALL HNetworkAddressSetTo(readAddr, "127.0.0.1", READ_PORT)

DIM readSock AS HSocket
readSock = HSocketCreate()
rc = HSocketConnect(readSock, readAddr, 3000000)
IF rc <> 0 THEN
    PRINT "FAIL: HSocketConnect (read path) returned ", rc
    CALL ExitProcess(1)
END IF

CALL Sleep(300) ' let nc's own echo pipe deliver its data

DIM readBuf(255) AS BYTE
DIM readBufPtr AS ANY PTR
readBufPtr = @readBuf(0)
DIM n AS INTEGER
n = HSocketRead(readSock, readBufPtr, 256)
IF n <= 0 THEN
    PRINT "FAIL: HSocketRead returned ", n
    CALL ExitProcess(1)
END IF
readBuf(n) = 0
DIM readZ AS ZSTRING
readZ = readBufPtr
DIM readText AS STRING
readText = readZ
PRINT "socket received=", readText

CALL HSocketDisconnect(readSock)
CALL HSocketFree(readSock)
CALL HNetworkAddressFree(readAddr)

IF InStr(readText, READ_TEXT) = 0 THEN
    PRINT "FAIL: read-path content mismatch"
    CALL ExitProcess(1)
END IF
PRINT "socket read path ok"

' ---- BUrl: parse round-trip on a real URL string ----

DIM url AS HUrl
url = HUrlCreate("http://example.com:8080/some/path")
IF HUrlIsValid(url) <> 1 THEN
    PRINT "FAIL: a well-formed URL should be valid"
    CALL ExitProcess(1)
END IF

DIM protoBuf(63) AS BYTE
DIM protoBufPtr AS ANY PTR
protoBufPtr = @protoBuf(0)
DIM protoLen AS INTEGER
protoLen = HUrlProtocol(url, protoBufPtr, 64)
protoBuf(protoLen) = 0
DIM protoZ AS ZSTRING
protoZ = protoBufPtr
DIM proto AS STRING
proto = protoZ

DIM hostBuf(255) AS BYTE
DIM hostBufPtr AS ANY PTR
hostBufPtr = @hostBuf(0)
DIM hostLen AS INTEGER
hostLen = HUrlHost(url, hostBufPtr, 256)
hostBuf(hostLen) = 0
DIM hostZ AS ZSTRING
hostZ = hostBufPtr
DIM host AS STRING
host = hostZ

DIM pathBuf(255) AS BYTE
DIM pathBufPtr AS ANY PTR
pathBufPtr = @pathBuf(0)
DIM pathLen AS INTEGER
pathLen = HUrlPath(url, pathBufPtr, 256)
pathBuf(pathLen) = 0
DIM pathZ AS ZSTRING
pathZ = pathBufPtr
DIM path AS STRING
path = pathZ

PRINT "url protocol=", proto
PRINT "url host=", host
PRINT "url port=", HUrlPort(url)
PRINT "url path=", path

IF proto <> "http" THEN
    PRINT "FAIL: protocol mismatch"
    CALL ExitProcess(1)
END IF
IF host <> "example.com" THEN
    PRINT "FAIL: host mismatch"
    CALL ExitProcess(1)
END IF
IF HUrlPort(url) <> 8080 THEN
    PRINT "FAIL: port mismatch"
    CALL ExitProcess(1)
END IF
IF path <> "/some/path" THEN
    PRINT "FAIL: path mismatch"
    CALL ExitProcess(1)
END IF
PRINT "URL parse round-trip ok"

CALL HUrlFree(url)

PRINT "network basics test ok"
