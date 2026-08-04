// eb-haiku native shim - Network Kit (BSocket/BNetworkAddress, real
// TCP networking) + BUrl (Support Kit, despite the name - a plain
// value class, no I/O of its own). See shim.h's own top comment for
// why a hand-written shim is needed at all.
//
// TCP only (BSocket) - no UDP (BDatagramSocket) or TLS (BSecureSocket)
// in this first pass. Real Haiku's own high-level HTTP/URL-request API
// (BUrlRequest/BHttpRequest/BUrlProtocolRoster) lives only under
// headers/private/netservices{,2}/ - one class is literally declared
// inside namespace BPrivate::Network, and the only libs are static,
// unversioned internals, not the stable libbnetapi.so this shim links
// against. Not a safely bindable target - deliberately not attempted.
#pragma once

extern "C" {

// ---- BNetworkAddress (net/NetworkAddress.h) ----

void* eb_haiku_network_address_create_empty(void);
// Real DNS resolution happens here if `address` isn't already a raw
// IP. Returns a status_t (0 = success).
int eb_haiku_network_address_set_to(void* addr, const char* address, unsigned int port);
int eb_haiku_network_address_init_check(void* addr);
int eb_haiku_network_address_port(void* addr);
// Fills `outBuf` (caller-supplied, `bufSize` bytes) with the address's
// own real "host:port"-shaped text form (BNetworkAddress::ToString,
// which returns a BString - not itself bound, see shim.h's own
// established avoidance of BString elsewhere - copied into the
// caller's buffer instead). Returns the real length in bytes (>= 0),
// truncated to fit `bufSize` if needed.
int eb_haiku_network_address_to_string(void* addr, char* outBuf, int bufSize);
void eb_haiku_network_address_destroy(void* addr);

// ---- BSocket (net/Socket.h, a BDataIO - TCP only) ----

void* eb_haiku_socket_create(void);
// bigtime_t (real 8-byte type, microseconds) - confirmed via the same
// compiled probe used for BLocker's own timeout parameter.
int eb_haiku_socket_connect(void* socket, void* addr, long long timeoutMicros);
int eb_haiku_socket_is_connected(void* socket);
// Real ssize_t Read/Write, matching this package's own established
// ANY-PTR-buffer-plus-size convention. Returns bytes read/written
// (>= 0), or a negative status_t.
int eb_haiku_socket_read(void* socket, void* buffer, int size);
int eb_haiku_socket_write(void* socket, const void* buffer, int size);
void eb_haiku_socket_disconnect(void* socket);
void eb_haiku_socket_destroy(void* socket);

// ---- BSecureSocket (net/SecureSocket.h) - IS-A BSocket (single
// inheritance, confirmed), so the existing eb_haiku_socket_connect/
// read/write/is_connected/disconnect/destroy functions above already
// operate correctly on a BSecureSocket* via ordinary C++ virtual
// dispatch (TLS handled internally by the real override) - only the
// constructor differs. Certificate-verification-failure handling uses
// real Haiku's own default policy (no shim subclass/override).
void* eb_haiku_secure_socket_create(void);

// ---- BDatagramSocket (net/DatagramSocket.h) - UDP, a BSocket sibling
// (BAbstractSocket), not a subclass - its own separate functions.
void* eb_haiku_datagram_socket_create(void);
// Real Bind() confusingly names its own local-address parameter
// "peer" - it's the address THIS socket binds to, not a remote peer.
int eb_haiku_datagram_socket_bind(void* socket, void* addr, int reuseAddr);
int eb_haiku_datagram_socket_send_to(void* socket, void* addr, const void* buffer, int size);
// Fills outFromAddr (an existing eb_haiku_network_address_create_empty
// result) with the real sender's address. Returns bytes received
// (>= 0), or a negative status_t.
int eb_haiku_datagram_socket_receive_from(void* socket, void* buffer, int bufferSize,
                                           void* outFromAddr);
void eb_haiku_datagram_socket_destroy(void* socket);

// ---- BUrl (support/Url.h - a plain value class, no I/O) ----

void* eb_haiku_url_create(const char* url);
int eb_haiku_url_is_valid(void* url);
// Each returns the real field's length in bytes (>= 0, truncated to
// fit `bufSize`), filling `outBuf` - same convention as
// eb_haiku_network_address_to_string above (all real BString-returning
// methods, not itself bound).
int eb_haiku_url_protocol(void* url, char* outBuf, int bufSize);
int eb_haiku_url_host(void* url, char* outBuf, int bufSize);
int eb_haiku_url_path(void* url, char* outBuf, int bufSize);
int eb_haiku_url_port(void* url);
void eb_haiku_url_destroy(void* url);

} // extern "C"
