' Raw FFI layer: eb-haiku's Network Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_network.h. TCP only
' (BSocket) + BUrl (Support Kit's own URL-parsing value class). Real
' Haiku's high-level HTTP/URL-request API is private/unstable - not
' bound here, see shim_network.h's own top comment.

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

    ' ---- BUrl ----
    Declare Function eb_haiku_url_create(BYVAL url AS ZSTRING) AS ANY PTR
    Declare Function eb_haiku_url_is_valid(BYVAL url AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_url_protocol(BYVAL url AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_url_host(BYVAL url AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_url_path(BYVAL url AS ANY PTR, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Function eb_haiku_url_port(BYVAL url AS ANY PTR) AS INTEGER
    Declare Sub eb_haiku_url_destroy(BYVAL url AS ANY PTR)
End Extern
