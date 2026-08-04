#include "shim_network.h"

#include <DatagramSocket.h>
#include <NetworkAddress.h>
#include <SecureSocket.h>
#include <Socket.h>
#include <Url.h>

#include <cstring>

namespace {

// Shared helper: copies a real BString's own content into a
// caller-supplied buffer, truncating to fit - matching this shim's own
// established "no BString exposed at the ABI boundary" convention.
int copyBStringToBuffer(const BString& s, char* outBuf, int bufSize) {
    int len = s.Length();
    int toCopy = len < bufSize ? len : bufSize;
    std::memcpy(outBuf, s.String(), static_cast<size_t>(toCopy));
    return len;
}

} // namespace

extern "C" {

// ---- BNetworkAddress ----

void* eb_haiku_network_address_create_empty(void) { return new BNetworkAddress(); }

int eb_haiku_network_address_set_to(void* addr, const char* address, unsigned int port) {
    return static_cast<BNetworkAddress*>(addr)->SetTo(address, static_cast<uint16>(port));
}

int eb_haiku_network_address_init_check(void* addr) {
    return static_cast<BNetworkAddress*>(addr)->InitCheck();
}

int eb_haiku_network_address_port(void* addr) {
    return static_cast<BNetworkAddress*>(addr)->Port();
}

int eb_haiku_network_address_to_string(void* addr, char* outBuf, int bufSize) {
    BString s = static_cast<BNetworkAddress*>(addr)->ToString();
    return copyBStringToBuffer(s, outBuf, bufSize);
}

void eb_haiku_network_address_destroy(void* addr) { delete static_cast<BNetworkAddress*>(addr); }

// ---- BSocket ----

void* eb_haiku_socket_create(void) { return new BSocket(); }

int eb_haiku_socket_connect(void* socket, void* addr, long long timeoutMicros) {
    return static_cast<BSocket*>(socket)->Connect(*static_cast<BNetworkAddress*>(addr),
                                                    static_cast<bigtime_t>(timeoutMicros));
}

int eb_haiku_socket_is_connected(void* socket) {
    return static_cast<BSocket*>(socket)->IsConnected() ? 1 : 0;
}

int eb_haiku_socket_read(void* socket, void* buffer, int size) {
    return static_cast<int>(static_cast<BSocket*>(socket)->Read(buffer, static_cast<size_t>(size)));
}

int eb_haiku_socket_write(void* socket, const void* buffer, int size) {
    return static_cast<int>(
        static_cast<BSocket*>(socket)->Write(buffer, static_cast<size_t>(size)));
}

void eb_haiku_socket_disconnect(void* socket) { static_cast<BSocket*>(socket)->Disconnect(); }

void eb_haiku_socket_destroy(void* socket) { delete static_cast<BSocket*>(socket); }

// ---- BSecureSocket ----

void* eb_haiku_secure_socket_create(void) { return new BSecureSocket(); }

// ---- BDatagramSocket ----

void* eb_haiku_datagram_socket_create(void) { return new BDatagramSocket(); }

int eb_haiku_datagram_socket_bind(void* socket, void* addr, int reuseAddr) {
    return static_cast<BDatagramSocket*>(socket)->Bind(*static_cast<BNetworkAddress*>(addr),
                                                         reuseAddr != 0);
}

int eb_haiku_datagram_socket_send_to(void* socket, void* addr, const void* buffer, int size) {
    return static_cast<int>(static_cast<BDatagramSocket*>(socket)->SendTo(
        *static_cast<BNetworkAddress*>(addr), buffer, static_cast<size_t>(size)));
}

int eb_haiku_datagram_socket_receive_from(void* socket, void* buffer, int bufferSize,
                                           void* outFromAddr) {
    return static_cast<int>(static_cast<BDatagramSocket*>(socket)->ReceiveFrom(
        buffer, static_cast<size_t>(bufferSize), *static_cast<BNetworkAddress*>(outFromAddr)));
}

void eb_haiku_datagram_socket_destroy(void* socket) {
    delete static_cast<BDatagramSocket*>(socket);
}

// ---- BUrl ----

void* eb_haiku_url_create(const char* url) { return new BUrl(url, true); }

int eb_haiku_url_is_valid(void* url) { return static_cast<BUrl*>(url)->IsValid() ? 1 : 0; }

int eb_haiku_url_protocol(void* url, char* outBuf, int bufSize) {
    return copyBStringToBuffer(static_cast<BUrl*>(url)->Protocol(), outBuf, bufSize);
}

int eb_haiku_url_host(void* url, char* outBuf, int bufSize) {
    return copyBStringToBuffer(static_cast<BUrl*>(url)->Host(), outBuf, bufSize);
}

int eb_haiku_url_path(void* url, char* outBuf, int bufSize) {
    return copyBStringToBuffer(static_cast<BUrl*>(url)->Path(), outBuf, bufSize);
}

int eb_haiku_url_port(void* url) { return static_cast<BUrl*>(url)->Port(); }

void eb_haiku_url_destroy(void* url) { delete static_cast<BUrl*>(url); }

} // extern "C"
