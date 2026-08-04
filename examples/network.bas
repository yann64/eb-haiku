' BUrl (parse a URL) + BSocket/BNetworkAddress (real TCP - connect to
' whatever host:port the URL names). TCP only - no HTTP client (real
' Haiku's own high-level HTTP API is private/unstable, see
' src/network.bas's own top comment).

#include once "../src/lib.bas"

DIM url AS HUrl
url = HUrlCreate("http://example.com:80/")

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

PRINT "host=", host
PRINT "port=", HUrlPort(url)
CALL HUrlFree(url)

DIM addr AS HNetworkAddress
addr = HNetworkAddressCreateEmpty()
DIM rc AS INTEGER
rc = HNetworkAddressSetTo(addr, host, 80) ' real DNS resolution happens here
IF rc <> 0 THEN
    PRINT "could not resolve ", host
    CALL ExitProcess(1)
END IF

DIM sock AS HSocket
sock = HSocketCreate()
rc = HSocketConnect(sock, addr, 5000000) ' 5 second timeout
IF rc = 0 THEN
    PRINT "connected to ", host
    CALL HSocketDisconnect(sock)
ELSE
    PRINT "could not connect (no network access?) - rc=", rc
END IF
CALL HSocketFree(sock)
CALL HNetworkAddressFree(addr)
