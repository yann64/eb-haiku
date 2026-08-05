#include "shim_network.h"

#include <DatagramSocket.h>
#include <NetworkAddress.h>
#include <NetworkInterface.h>
#include <NetworkRoster.h>
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

// ---- BNetworkRoster/BNetworkInterface ----

void* eb_haiku_network_roster_default(void) { return &BNetworkRoster::Default(); }

int eb_haiku_network_roster_count_interfaces(void* roster) {
    return static_cast<int>(static_cast<BNetworkRoster*>(roster)->CountInterfaces());
}

int eb_haiku_network_roster_get_next_interface(void* roster, unsigned int* cookie,
                                                void* interface) {
    uint32 c = *cookie;
    status_t rc = static_cast<BNetworkRoster*>(roster)->GetNextInterface(
        &c, *static_cast<BNetworkInterface*>(interface));
    *cookie = c;
    return rc;
}

void* eb_haiku_network_interface_create(void) { return new BNetworkInterface(); }

void eb_haiku_network_interface_destroy(void* interface) {
    delete static_cast<BNetworkInterface*>(interface);
}

const char* eb_haiku_network_interface_name(void* interface) {
    return static_cast<BNetworkInterface*>(interface)->Name();
}

unsigned int eb_haiku_network_interface_flags(void* interface) {
    return static_cast<BNetworkInterface*>(interface)->Flags();
}

int eb_haiku_network_interface_has_link(void* interface) {
    return static_cast<BNetworkInterface*>(interface)->HasLink() ? 1 : 0;
}

int eb_haiku_network_interface_count_addresses(void* interface) {
    return static_cast<int>(static_cast<BNetworkInterface*>(interface)->CountAddresses());
}

void* eb_haiku_network_interface_address_create(void) { return new BNetworkInterfaceAddress(); }

void eb_haiku_network_interface_address_destroy(void* ifAddr) {
    delete static_cast<BNetworkInterfaceAddress*>(ifAddr);
}

int eb_haiku_network_interface_get_address_at(void* interface, int index, void* ifAddr) {
    return static_cast<BNetworkInterface*>(interface)->GetAddressAt(
        index, *static_cast<BNetworkInterfaceAddress*>(ifAddr));
}

void eb_haiku_network_interface_address_copy_address(void* ifAddr, void* outAddr) {
    *static_cast<BNetworkAddress*>(outAddr) =
        static_cast<BNetworkInterfaceAddress*>(ifAddr)->Address();
}

// ---- BNetworkInterface configuration ----

int eb_haiku_network_interface_set_flags(void* interface, unsigned int flags) {
    return static_cast<BNetworkInterface*>(interface)->SetFlags(flags);
}

int eb_haiku_network_interface_set_mtu(void* interface, unsigned int mtu) {
    return static_cast<BNetworkInterface*>(interface)->SetMTU(mtu);
}

int eb_haiku_network_interface_set_media(void* interface, int media) {
    return static_cast<BNetworkInterface*>(interface)->SetMedia(media);
}

int eb_haiku_network_interface_set_metric(void* interface, unsigned int metric) {
    return static_cast<BNetworkInterface*>(interface)->SetMetric(metric);
}

int eb_haiku_network_interface_add_address(void* interface, void* address) {
    return static_cast<BNetworkInterface*>(interface)->AddAddress(
        *static_cast<BNetworkAddress*>(address));
}

int eb_haiku_network_interface_remove_address(void* interface, void* address) {
    return static_cast<BNetworkInterface*>(interface)->RemoveAddress(
        *static_cast<BNetworkAddress*>(address));
}

int eb_haiku_network_interface_remove_address_at(void* interface, int index) {
    return static_cast<BNetworkInterface*>(interface)->RemoveAddressAt(index);
}

int eb_haiku_network_interface_add_default_route(void* interface, void* gatewayAddress) {
    return static_cast<BNetworkInterface*>(interface)->AddDefaultRoute(
        *static_cast<BNetworkAddress*>(gatewayAddress));
}

int eb_haiku_network_interface_remove_default_route(void* interface, int family) {
    return static_cast<BNetworkInterface*>(interface)->RemoveDefaultRoute(family);
}

int eb_haiku_network_interface_auto_configure(void* interface, int family) {
    return static_cast<BNetworkInterface*>(interface)->AutoConfigure(family);
}

} // extern "C"
