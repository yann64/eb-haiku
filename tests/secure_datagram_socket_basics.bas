' Network Kit: BSecureSocket (TLS) + BDatagramSocket (UDP). BSecureSocket
' verified via a real TLS handshake against a real HTTPS server (this
' Haiku VM has confirmed real internet access - see network_basics.bas's
' own DNS resolution test) - connect, send a manual GET request over the
' encrypted channel, confirm a real HTTP response comes back.
' BDatagramSocket verified via a real loopback round-trip using a second
' thread as the receiver, mirroring network_basics.bas's own real-
' listener precedent for TCP.

#include once "../src/lib.bas"

' ---- BSecureSocket: a real TLS handshake against a real HTTPS server ----

DIM addr AS HNetworkAddress
addr = HNetworkAddressCreateEmpty()
DIM rc AS INTEGER
rc = HNetworkAddressSetTo(addr, "example.com", 443)
IF rc <> 0 THEN
    PRINT "FAIL: HNetworkAddressSetTo(example.com:443) returned ", rc
    CALL ExitProcess(1)
END IF

DIM tls AS HSocket
tls = HSecureSocketCreate()
rc = HSocketConnect(tls, addr, 8000000) ' 8s - a real TLS handshake takes longer than plain TCP
IF rc <> 0 THEN
    PRINT "FAIL: HSocketConnect (TLS) returned ", rc
    CALL ExitProcess(1)
END IF
IF HSocketIsConnected(tls) <> 1 THEN
    PRINT "FAIL: HSocketIsConnected should be true after a successful TLS Connect"
    CALL ExitProcess(1)
END IF
PRINT "TLS handshake ok"

DIM HTTP_REQUEST AS STRING
HTTP_REQUEST = "GET / HTTP/1.1" & Chr(13) & Chr(10) & "Host: example.com" & Chr(13) & Chr(10) & "Connection: close" & Chr(13) & Chr(10) & Chr(13) & Chr(10)
DIM reqBuf(511) AS BYTE
DIM i AS INTEGER
FOR i = 1 TO Len(HTTP_REQUEST)
    reqBuf(i - 1) = Asc(Mid(HTTP_REQUEST, i, 1))
NEXT i
DIM reqBufPtr AS ANY PTR
reqBufPtr = @reqBuf(0)
DIM written AS INTEGER
written = HSocketWrite(tls, reqBufPtr, Len(HTTP_REQUEST))
IF written <> Len(HTTP_REQUEST) THEN
    PRINT "FAIL: HSocketWrite (TLS) wrote ", written, " of ", Len(HTTP_REQUEST), " bytes"
    CALL ExitProcess(1)
END IF

DIM respBuf(1023) AS BYTE
DIM respBufPtr AS ANY PTR
respBufPtr = @respBuf(0)
DIM n AS INTEGER
n = HSocketRead(tls, respBufPtr, 1024)
IF n <= 0 THEN
    PRINT "FAIL: HSocketRead (TLS) returned ", n
    CALL ExitProcess(1)
END IF
respBuf(n) = 0
DIM respZ AS ZSTRING
respZ = respBufPtr
DIM resp AS STRING
resp = respZ
PRINT "TLS response starts with=", Left(resp, 20)
IF Left(resp, 5) <> "HTTP/" THEN
    PRINT "FAIL: expected a real HTTP response over the encrypted channel"
    CALL ExitProcess(1)
END IF
PRINT "real encrypted HTTP response received ok"

CALL HSocketDisconnect(tls)
CALL HSocketFree(tls)
CALL HNetworkAddressFree(addr)

' ---- BDatagramSocket: a real loopback round-trip using a second thread
' as the receiver ----

CONST UDP_PORT = 8903
CONST UDP_MESSAGE = "hello from eb-haiku UDP"

DIM gReceivedText AS STRING
gReceivedText = ""

FUNCTION UdpReceiverThreadFunc(data AS ANY PTR) AS INTEGER
    DIM bindAddr AS HNetworkAddress
    bindAddr = HNetworkAddressCreateEmpty()
    CALL HNetworkAddressSetTo(bindAddr, "127.0.0.1", UDP_PORT)

    DIM recvSock AS HDatagramSocket
    recvSock = HDatagramSocketCreate()
    DIM bindRc AS INTEGER
    bindRc = HDatagramSocketBind(recvSock, bindAddr, 1)
    IF bindRc <> 0 THEN
        PRINT "FAIL: HDatagramSocketBind returned ", bindRc
        CALL ExitProcess(1)
    END IF

    DIM fromAddr AS HNetworkAddress
    fromAddr = HNetworkAddressCreateEmpty()
    DIM rbuf(255) AS BYTE
    DIM rbufPtr AS ANY PTR
    rbufPtr = @rbuf(0)
    DIM rn AS INTEGER
    rn = HDatagramSocketReceiveFrom(recvSock, rbufPtr, 256, fromAddr)
    IF rn > 0 THEN
        rbuf(rn) = 0
        DIM rz AS ZSTRING
        rz = rbufPtr
        gReceivedText = rz
    END IF

    CALL HDatagramSocketFree(recvSock)
    CALL HNetworkAddressFree(bindAddr)
    CALL HNetworkAddressFree(fromAddr)
    UdpReceiverThreadFunc = 0
END FUNCTION

DIM t AS INTEGER
t = HSpawnThread(@UdpReceiverThreadFunc, "eb-haiku-udp-receiver", H_NORMAL_PRIORITY, 0)
CALL HResumeThread(t)

CALL HSnooze(300000) ' 300ms - let the receiver bind first

DIM destAddr AS HNetworkAddress
destAddr = HNetworkAddressCreateEmpty()
CALL HNetworkAddressSetTo(destAddr, "127.0.0.1", UDP_PORT)

DIM sendSock AS HDatagramSocket
sendSock = HDatagramSocketCreate()
' IMPORTANT, confirmed by direct reproduction: a freshly-created socket
' has no real file descriptor until Bind() - even the sender must bind
' (to an ephemeral local address/port here) before SendTo works - see
' HDatagramSocketSendTo's own doc comment.
DIM ephemeralAddr AS HNetworkAddress
ephemeralAddr = HNetworkAddressCreateEmpty()
CALL HNetworkAddressSetTo(ephemeralAddr, "0.0.0.0", 0)
DIM senderBindRc AS INTEGER
senderBindRc = HDatagramSocketBind(sendSock, ephemeralAddr, 1)
IF senderBindRc <> 0 THEN
    PRINT "FAIL: sender HDatagramSocketBind returned ", senderBindRc
    CALL ExitProcess(1)
END IF
CALL HNetworkAddressFree(ephemeralAddr)
DIM sbuf(255) AS BYTE
FOR i = 1 TO Len(UDP_MESSAGE)
    sbuf(i - 1) = Asc(Mid(UDP_MESSAGE, i, 1))
NEXT i
DIM sbufPtr AS ANY PTR
sbufPtr = @sbuf(0)
DIM sent AS INTEGER
sent = HDatagramSocketSendTo(sendSock, destAddr, sbufPtr, Len(UDP_MESSAGE))
IF sent <> Len(UDP_MESSAGE) THEN
    PRINT "FAIL: HDatagramSocketSendTo sent ", sent, " of ", Len(UDP_MESSAGE), " bytes"
    CALL ExitProcess(1)
END IF
CALL HDatagramSocketFree(sendSock)
CALL HNetworkAddressFree(destAddr)

DIM rv AS INTEGER
CALL HWaitForThread(t, rv)

PRINT "UDP received=", gReceivedText
IF gReceivedText <> UDP_MESSAGE THEN
    PRINT "FAIL: UDP round-trip mismatch"
    CALL ExitProcess(1)
END IF
PRINT "UDP loopback round-trip ok"

PRINT "secure/datagram socket basics test ok"
