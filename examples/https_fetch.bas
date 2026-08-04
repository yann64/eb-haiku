' BSecureSocket - a real TLS-encrypted TCP connection. Fetches the
' first part of a real HTTPS response by hand (a plain HTTP/1.1 request
' written directly over the encrypted channel - no high-level HTTP
' client is bound, see network.bas's own top comment on why).

#include once "../src/lib.bas"

DIM addr AS HNetworkAddress
addr = HNetworkAddressCreateEmpty()
CALL HNetworkAddressSetTo(addr, "example.com", 443)

DIM sock AS HSocket
sock = HSecureSocketCreate()
DIM rc AS INTEGER
rc = HSocketConnect(sock, addr, 8000000)
IF rc <> 0 THEN
    PRINT "FAIL: TLS connect returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "connected over TLS to example.com:443"

DIM request AS STRING
request = "GET / HTTP/1.1" & Chr(13) & Chr(10) & "Host: example.com" & Chr(13) & Chr(10) & "Connection: close" & Chr(13) & Chr(10) & Chr(13) & Chr(10)
DIM reqBuf(511) AS BYTE
DIM i AS INTEGER
FOR i = 1 TO Len(request)
    reqBuf(i - 1) = Asc(Mid(request, i, 1))
NEXT i
CALL HSocketWrite(sock, @reqBuf(0), Len(request))

DIM respBuf(2047) AS BYTE
DIM n AS INTEGER
n = HSocketRead(sock, @respBuf(0), 2048)
IF n > 0 THEN
    respBuf(n) = 0
    DIM respBufPtr AS ANY PTR
    respBufPtr = @respBuf(0)
    DIM respZ AS ZSTRING
    respZ = respBufPtr
    DIM resp AS STRING
    resp = respZ
    PRINT resp
END IF

CALL HSocketDisconnect(sock)
CALL HSocketFree(sock)
CALL HNetworkAddressFree(addr)
