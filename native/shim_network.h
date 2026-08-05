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

// ---- BNetworkRoster/BNetworkInterface (net/NetworkRoster.h,
// NetworkInterface.h) - enumerate the local machine's own real network
// interfaces. Configuration (AddAddress/SetMTU/routes/persistent
// wireless networks) deliberately not bound - diagnostics/enumeration
// only, matching what was actually asked for. ----

// A shared, never-destroyed singleton (&BNetworkRoster::Default(), like
// be_roster/be_clipboard elsewhere in this shim) - do not destroy.
void* eb_haiku_network_roster_default(void);
int eb_haiku_network_roster_count_interfaces(void* roster);
// `cookie` is caller-owned (start at 0, do not reuse across a fresh
// enumeration), `interface` an existing
// eb_haiku_network_interface_create result, filled in place. Returns a
// status_t (0 = success, a real negative status once the real
// enumeration is exhausted - confirmed via probe, not guessed).
int eb_haiku_network_roster_get_next_interface(void* roster, unsigned int* cookie, void* interface);

void* eb_haiku_network_interface_create(void);
void eb_haiku_network_interface_destroy(void* interface);
// BNetworkInterface::Name() returns a pointer into the object's own
// fixed-size internal buffer (not a BString) - safe to return directly
// as long as `interface` itself stays alive, matching
// eb_haiku_path_get's own established convention.
const char* eb_haiku_network_interface_name(void* interface);
unsigned int eb_haiku_network_interface_flags(void* interface);
int eb_haiku_network_interface_has_link(void* interface);
int eb_haiku_network_interface_count_addresses(void* interface);

void* eb_haiku_network_interface_address_create(void);
void eb_haiku_network_interface_address_destroy(void* ifAddr);
// Fills `ifAddr` (an existing eb_haiku_network_interface_address_create
// result) with the interface's `index`'th address. Returns a status_t
// (0 = success).
int eb_haiku_network_interface_get_address_at(void* interface, int index, void* ifAddr);
// Copies ifAddr's own real BNetworkAddress& (Address()) into `outAddr`
// (an existing eb_haiku_network_address_create_empty result) - reuses
// the existing HNetworkAddress type entirely rather than exposing a
// third address-shaped handle.
void eb_haiku_network_interface_address_copy_address(void* ifAddr, void* outAddr);

// ---- BNetworkInterface configuration (write side). SAFETY: only ever
// verified against the loopback interface on this project's own real
// development host - never a live NIC an active SSH session might
// depend on. Only the simple, BNetworkAddress-based overloads of
// AddAddress/RemoveAddress are bound (reusing the existing
// HNetworkAddress type) - the fuller BNetworkInterfaceAddress-based
// overloads (with mask/broadcast) and AddRoute/RemoveRoute's own
// BNetworkRoute-based overloads (raw sockaddr manipulation) are a
// reasonable follow-on, not bound here - disproportionate new surface
// for this pass. AddDefaultRoute/RemoveDefaultRoute/AutoConfigure need
// no new type at all. ----

int eb_haiku_network_interface_set_flags(void* interface, unsigned int flags);
int eb_haiku_network_interface_set_mtu(void* interface, unsigned int mtu);
int eb_haiku_network_interface_set_media(void* interface, int media);
int eb_haiku_network_interface_set_metric(void* interface, unsigned int metric);
// `address` is an existing eb_haiku_network_address_create_empty
// result (the simple BNetworkAddress overload, not the fuller
// BNetworkInterfaceAddress one).
int eb_haiku_network_interface_add_address(void* interface, void* address);
int eb_haiku_network_interface_remove_address(void* interface, void* address);
int eb_haiku_network_interface_remove_address_at(void* interface, int index);
int eb_haiku_network_interface_add_default_route(void* interface, void* gatewayAddress);
int eb_haiku_network_interface_remove_default_route(void* interface, int family);
int eb_haiku_network_interface_auto_configure(void* interface, int family);

} // extern "C"
