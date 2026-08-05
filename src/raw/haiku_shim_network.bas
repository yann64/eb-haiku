' Raw FFI layer: eb-haiku's Network Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_network.h. TCP only
' (BSocket) + BUrl (Support Kit's own URL-parsing value class). Real
' Haiku's high-level HTTP/URL-request API is private/unstable - not
' bound here, see shim_network.h's own top comment.

' Real address-family values (posix/sys/socket.h) - needed by
' BNetworkInterface's own family-based route functions.
CONST H_AF_INET = 1
CONST H_AF_INET6 = 5

Extern "C" Lib "ebhaikushim"
    ' ---- BNetworkAddress ----
    Declare Function eb_haiku_network_address_create_empty() AS ANY PTR
    Declare Function eb_haiku_network_address_set_to(BYVAL addr AS ANY PTR, BYVAL address AS ZSTRING, BYVAL port AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_network_address_init_check(BYVAL addr AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_network_address_port(BYVAL addr AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_network_address_to_string(BYVAL addr AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Sub eb_haiku_network_address_destroy(BYVAL addr AS ANY PTR)

    ' ---- BSocket (TCP only) ----
    Declare Function eb_haiku_socket_create() AS ANY PTR
    Declare Function eb_haiku_socket_connect(BYVAL socket AS ANY PTR, BYVAL addr AS ANY PTR, BYVAL timeoutMicros AS LONGINT) AS INTEGER
    Declare Function eb_haiku_socket_is_connected(BYVAL socket AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_socket_read(BYVAL socket AS ANY PTR, BYVAL buffer AS ANY PTR, BYVAL size AS INTEGER) AS INTEGER
    Declare Function eb_haiku_socket_write(BYVAL socket AS ANY PTR, BYVAL buffer AS ANY PTR, BYVAL size AS INTEGER) AS INTEGER
    Declare Sub eb_haiku_socket_disconnect(BYVAL socket AS ANY PTR)
    Declare Sub eb_haiku_socket_destroy(BYVAL socket AS ANY PTR)

    ' ---- BSecureSocket (IS-A BSocket - reuses eb_haiku_socket_* above) ----
    Declare Function eb_haiku_secure_socket_create() AS ANY PTR

    ' ---- BDatagramSocket (UDP) ----
    Declare Function eb_haiku_datagram_socket_create() AS ANY PTR
    Declare Function eb_haiku_datagram_socket_bind(BYVAL socket AS ANY PTR, BYVAL addr AS ANY PTR, BYVAL reuseAddr AS INTEGER) AS INTEGER
    Declare Function eb_haiku_datagram_socket_send_to(BYVAL socket AS ANY PTR, BYVAL addr AS ANY PTR, BYVAL buffer AS ANY PTR, BYVAL size AS INTEGER) AS INTEGER
    Declare Function eb_haiku_datagram_socket_receive_from(BYVAL socket AS ANY PTR, BYVAL buffer AS ANY PTR, BYVAL bufferSize AS INTEGER, BYVAL outFromAddr AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_datagram_socket_destroy(BYVAL socket AS ANY PTR)

    ' ---- BUrl ----
    Declare Function eb_haiku_url_create(BYVAL url AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_url_is_valid(BYVAL url AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_url_protocol(BYVAL url AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_url_host(BYVAL url AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_url_path(BYVAL url AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_url_port(BYVAL url AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_url_destroy(BYVAL url AS ANY PTR)

    ' ---- BNetworkRoster/BNetworkInterface ----
    Declare Function eb_haiku_network_roster_default() AS ANY PTR
    Declare Function eb_haiku_network_roster_count_interfaces(BYVAL roster AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_network_roster_get_next_interface(BYVAL roster AS ANY PTR, BYVAL cookie AS ANY PTR, BYVAL interface AS ANY PTR) AS INTEGER

    Declare Function eb_haiku_network_interface_create() AS ANY PTR
    Declare Sub eb_haiku_network_interface_destroy(BYVAL interface AS ANY PTR)
    Declare Function eb_haiku_network_interface_name(BYVAL interface AS ANY PTR) AS ZSTRING
    Declare Function eb_haiku_network_interface_flags(BYVAL interface AS ANY PTR) AS UINTEGER
    Declare Function eb_haiku_network_interface_has_link(BYVAL interface AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_network_interface_count_addresses(BYVAL interface AS ANY PTR) AS INTEGER

    Declare Function eb_haiku_network_interface_address_create() AS ANY PTR
    Declare Sub eb_haiku_network_interface_address_destroy(BYVAL ifAddr AS ANY PTR)
    Declare Function eb_haiku_network_interface_get_address_at(BYVAL interface AS ANY PTR, BYVAL index AS INTEGER, BYVAL ifAddr AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_network_interface_address_copy_address(BYVAL ifAddr AS ANY PTR, BYVAL outAddr AS ANY PTR)

    ' ---- BNetworkInterface configuration ----
    Declare Function eb_haiku_network_interface_set_flags(BYVAL interface AS ANY PTR, BYVAL flags AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_network_interface_set_mtu(BYVAL interface AS ANY PTR, BYVAL mtu AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_network_interface_set_media(BYVAL interface AS ANY PTR, BYVAL media AS INTEGER) AS INTEGER
    Declare Function eb_haiku_network_interface_set_metric(BYVAL interface AS ANY PTR, BYVAL metric AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_network_interface_add_address(BYVAL interface AS ANY PTR, BYVAL address AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_network_interface_remove_address(BYVAL interface AS ANY PTR, BYVAL address AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_network_interface_remove_address_at(BYVAL interface AS ANY PTR, BYVAL index AS INTEGER) AS INTEGER
    Declare Function eb_haiku_network_interface_add_default_route(BYVAL interface AS ANY PTR, BYVAL gatewayAddress AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_network_interface_remove_default_route(BYVAL interface AS ANY PTR, BYVAL family AS INTEGER) AS INTEGER
    Declare Function eb_haiku_network_interface_auto_configure(BYVAL interface AS ANY PTR, BYVAL family AS INTEGER) AS INTEGER
End Extern
