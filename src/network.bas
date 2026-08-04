' Idiomatic layer: BSocket/BNetworkAddress (real TCP networking) +
' BUrl (Support Kit's own URL-parsing value class, no I/O of its own -
' parse a URL, then HSocketConnect to its own HUrlHost/HUrlPort).
'
' TCP only - no UDP or TLS in this first pass. Real Haiku's high-level
' HTTP/URL-request API is private/unstable (confirmed on the real
' host - one class is literally declared inside a BPrivate namespace,
' the only libs are static/unversioned) and deliberately not bound.

#include once "raw/haiku_shim_network.bas"

TYPE HNetworkAddress
    handle AS ANY PTR
END TYPE

FUNCTION HNetworkAddressCreateEmpty() AS HNetworkAddress
    DIM a AS HNetworkAddress
    a.handle = eb_haiku_network_address_create_empty()
    HNetworkAddressCreateEmpty = a
END FUNCTION

''' Resolves `address` (a hostname or raw IP) + `port` - real DNS
''' resolution happens here for a hostname. Returns a status code (0 =
''' success).
FUNCTION HNetworkAddressSetTo(BYVAL a AS HNetworkAddress, address AS ZSTRING, BYVAL port AS UINTEGER) AS INTEGER
    HNetworkAddressSetTo = eb_haiku_network_address_set_to(a.handle, address, port)
END FUNCTION

FUNCTION HNetworkAddressInitCheck(BYVAL a AS HNetworkAddress) AS INTEGER
    HNetworkAddressInitCheck = eb_haiku_network_address_init_check(a.handle)
END FUNCTION

FUNCTION HNetworkAddressPort(BYVAL a AS HNetworkAddress) AS INTEGER
    HNetworkAddressPort = eb_haiku_network_address_port(a.handle)
END FUNCTION

''' Fills `outBuf` (caller-supplied, `bufSize` bytes) with the address's
''' own real "host:port"-shaped text form - NOT null-terminated
''' automatically, matching this package's own established buffer-out
''' convention. Returns the real length in bytes (>= 0).
FUNCTION HNetworkAddressToString(BYVAL a AS HNetworkAddress, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HNetworkAddressToString = eb_haiku_network_address_to_string(a.handle, outBuf, bufSize)
END FUNCTION

''' Frees an HNetworkAddress - call exactly once.
SUB HNetworkAddressFree(BYVAL a AS HNetworkAddress)
    CALL eb_haiku_network_address_destroy(a.handle)
END SUB

TYPE HSocket
    handle AS ANY PTR
END TYPE

FUNCTION HSocketCreate() AS HSocket
    DIM s AS HSocket
    s.handle = eb_haiku_socket_create()
    HSocketCreate = s
END FUNCTION

''' Connects to `addr` (an HNetworkAddressSetTo result), giving up
''' after `timeoutMicros` microseconds. Returns a status code (0 =
''' success).
FUNCTION HSocketConnect(BYVAL s AS HSocket, BYVAL addr AS HNetworkAddress, BYVAL timeoutMicros AS LONGINT) AS INTEGER
    HSocketConnect = eb_haiku_socket_connect(s.handle, addr.handle, timeoutMicros)
END FUNCTION

FUNCTION HSocketIsConnected(BYVAL s AS HSocket) AS INTEGER
    HSocketIsConnected = eb_haiku_socket_is_connected(s.handle)
END FUNCTION

''' Reads up to `size` bytes into `buffer` (a plain caller-owned byte
''' buffer, e.g. `@someArray(0)`). Returns bytes read (>= 0, 0 at
''' end-of-stream), or a negative status code.
FUNCTION HSocketRead(BYVAL s AS HSocket, BYVAL buffer AS ANY PTR, BYVAL size AS INTEGER) AS INTEGER
    HSocketRead = eb_haiku_socket_read(s.handle, buffer, size)
END FUNCTION

''' Writes `size` bytes from `buffer`. Returns bytes written (>= 0), or
''' a negative status code.
FUNCTION HSocketWrite(BYVAL s AS HSocket, BYVAL buffer AS ANY PTR, BYVAL size AS INTEGER) AS INTEGER
    HSocketWrite = eb_haiku_socket_write(s.handle, buffer, size)
END FUNCTION

SUB HSocketDisconnect(BYVAL s AS HSocket)
    CALL eb_haiku_socket_disconnect(s.handle)
END SUB

''' Frees an HSocket - call exactly once.
SUB HSocketFree(BYVAL s AS HSocket)
    CALL eb_haiku_socket_destroy(s.handle)
END SUB

''' A real TLS-capable socket - reuses the plain HSocket type entirely
''' (BSecureSocket IS-A BSocket, like HMenuBarCreate's own HMenu reuse)
''' - every other HSocket* function above (Connect/Read/Write/
''' IsConnected/Disconnect/Free) already dispatches correctly to the
''' real TLS implementation via ordinary C++ virtual dispatch. Connect
''' performs the real TLS handshake.
FUNCTION HSecureSocketCreate() AS HSocket
    DIM s AS HSocket
    s.handle = eb_haiku_secure_socket_create()
    HSecureSocketCreate = s
END FUNCTION

TYPE HDatagramSocket
    handle AS ANY PTR
END TYPE

''' A real UDP socket.
FUNCTION HDatagramSocketCreate() AS HDatagramSocket
    DIM s AS HDatagramSocket
    s.handle = eb_haiku_datagram_socket_create()
    HDatagramSocketCreate = s
END FUNCTION

''' Binds this socket to `addr` (its own real local address/port) -
''' required before HDatagramSocketReceiveFrom, AND before
''' HDatagramSocketSendTo (see that function's own doc comment - a real,
''' non-obvious requirement). Returns a status code (0 = success).
FUNCTION HDatagramSocketBind(BYVAL s AS HDatagramSocket, BYVAL addr AS HNetworkAddress, BYVAL reuseAddr AS INTEGER) AS INTEGER
    HDatagramSocketBind = eb_haiku_datagram_socket_bind(s.handle, addr.handle, reuseAddr)
END FUNCTION

''' Sends `size` bytes from `buffer` to `addr`. Returns bytes sent
''' (>= 0), or a negative status code.
'''
''' IMPORTANT, confirmed by direct reproduction: a freshly-created
''' HDatagramSocket has no real underlying file descriptor at all until
''' HDatagramSocketBind is called (real Haiku creates it lazily inside
''' Bind()/Connect(), not the constructor) - calling this on an unbound
''' socket fails with a real "Bad file descriptor" status. Call
''' HDatagramSocketBind first, even just to an ephemeral local
''' address/port (e.g. "0.0.0.0", port 0), before ever calling this.
FUNCTION HDatagramSocketSendTo(BYVAL s AS HDatagramSocket, BYVAL addr AS HNetworkAddress, BYVAL buffer AS ANY PTR, BYVAL size AS INTEGER) AS INTEGER
    HDatagramSocketSendTo = eb_haiku_datagram_socket_send_to(s.handle, addr.handle, buffer, size)
END FUNCTION

''' Blocks until a datagram arrives, filling `buffer` (up to
''' `bufferSize` bytes) and `outFromAddr` (an existing
''' HNetworkAddressCreateEmpty result) with the real sender's address.
''' Returns bytes received (>= 0), or a negative status code.
FUNCTION HDatagramSocketReceiveFrom(BYVAL s AS HDatagramSocket, BYVAL buffer AS ANY PTR, BYVAL bufferSize AS INTEGER, BYVAL outFromAddr AS HNetworkAddress) AS INTEGER
    HDatagramSocketReceiveFrom = eb_haiku_datagram_socket_receive_from(s.handle, buffer, bufferSize, outFromAddr.handle)
END FUNCTION

''' Frees an HDatagramSocket - call exactly once.
SUB HDatagramSocketFree(BYVAL s AS HDatagramSocket)
    CALL eb_haiku_datagram_socket_destroy(s.handle)
END SUB

TYPE HUrl
    handle AS ANY PTR
END TYPE

''' Parses `url` (e.g. "http://example.com:8080/path") into its own
''' fields - no I/O of its own, pair with HSocketConnect (via
''' HUrlHost/HUrlPort) to actually connect.
FUNCTION HUrlCreate(url AS ZSTRING) AS HUrl
    DIM u AS HUrl
    u.handle = eb_haiku_url_create(url)
    HUrlCreate = u
END FUNCTION

FUNCTION HUrlIsValid(BYVAL u AS HUrl) AS INTEGER
    HUrlIsValid = eb_haiku_url_is_valid(u.handle)
END FUNCTION

''' Each of HUrlProtocol/Host/Path fills `outBuf` (caller-supplied,
''' `bufSize` bytes, NOT null-terminated automatically) and returns the
''' real field's length in bytes (>= 0) - same buffer-out convention as
''' HNetworkAddressToString.
FUNCTION HUrlProtocol(BYVAL u AS HUrl, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HUrlProtocol = eb_haiku_url_protocol(u.handle, outBuf, bufSize)
END FUNCTION

FUNCTION HUrlHost(BYVAL u AS HUrl, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HUrlHost = eb_haiku_url_host(u.handle, outBuf, bufSize)
END FUNCTION

FUNCTION HUrlPath(BYVAL u AS HUrl, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HUrlPath = eb_haiku_url_path(u.handle, outBuf, bufSize)
END FUNCTION

FUNCTION HUrlPort(BYVAL u AS HUrl) AS INTEGER
    HUrlPort = eb_haiku_url_port(u.handle)
END FUNCTION

''' Frees an HUrl - call exactly once.
SUB HUrlFree(BYVAL u AS HUrl)
    CALL eb_haiku_url_destroy(u.handle)
END SUB
