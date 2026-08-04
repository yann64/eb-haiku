' Idiomatic layer: BNetworkRoster/BNetworkInterface - enumerate the
' local machine's own real network interfaces (name, flags, link
' state, addresses). Diagnostics/enumeration only - configuration
' (AddAddress/SetMTU/routes/persistent wireless networks) deliberately
' not bound, matching what was actually asked for.

#include once "raw/haiku_shim_network.bas"
#include once "network.bas"

TYPE HNetworkRoster
    handle AS ANY PTR
END TYPE

''' The one, shared, system-wide roster - never freed by this package
''' (owned by the Network Kit itself, like HRosterDefault's own
''' be_roster convention).
FUNCTION HNetworkRosterDefault() AS HNetworkRoster
    DIM r AS HNetworkRoster
    r.handle = eb_haiku_network_roster_default()
    HNetworkRosterDefault = r
END FUNCTION

FUNCTION HNetworkRosterCountInterfaces(BYVAL r AS HNetworkRoster) AS INTEGER
    HNetworkRosterCountInterfaces = eb_haiku_network_roster_count_interfaces(r.handle)
END FUNCTION

TYPE HNetworkInterface
    handle AS ANY PTR
END TYPE

''' Creates an empty interface handle - pass to
''' HNetworkRosterGetNextInterface (repeatedly, reusing the same handle)
''' to fill it in place with each real interface in turn.
FUNCTION HNetworkInterfaceCreate() AS HNetworkInterface
    DIM iface AS HNetworkInterface
    iface.handle = eb_haiku_network_interface_create()
    HNetworkInterfaceCreate = iface
END FUNCTION

''' Fills `interface` (an existing HNetworkInterfaceCreate result) with
''' the next real system interface, advancing `cookie` (BYREF, start at
''' 0). Returns a status code (0 = success); a real negative status
''' once every interface has been enumerated - the natural loop-end
''' condition, not an error.
FUNCTION HNetworkRosterGetNextInterface(BYVAL r AS HNetworkRoster, BYREF cookie AS UINTEGER, BYVAL interface AS HNetworkInterface) AS INTEGER
    DIM c AS UINTEGER
    c = cookie
    HNetworkRosterGetNextInterface = eb_haiku_network_roster_get_next_interface(r.handle, @c, interface.handle)
    cookie = c
END FUNCTION

''' Frees an HNetworkInterface - call exactly once.
SUB HNetworkInterfaceFree(BYVAL interface AS HNetworkInterface)
    CALL eb_haiku_network_interface_destroy(interface.handle)
END SUB

''' The interface's own real name (e.g. "loop", "/dev/net/...").
FUNCTION HNetworkInterfaceName(BYVAL interface AS HNetworkInterface) AS ZSTRING
    HNetworkInterfaceName = eb_haiku_network_interface_name(interface.handle)
END FUNCTION

FUNCTION HNetworkInterfaceFlags(BYVAL interface AS HNetworkInterface) AS UINTEGER
    HNetworkInterfaceFlags = eb_haiku_network_interface_flags(interface.handle)
END FUNCTION

FUNCTION HNetworkInterfaceHasLink(BYVAL interface AS HNetworkInterface) AS INTEGER
    HNetworkInterfaceHasLink = eb_haiku_network_interface_has_link(interface.handle)
END FUNCTION

FUNCTION HNetworkInterfaceCountAddresses(BYVAL interface AS HNetworkInterface) AS INTEGER
    HNetworkInterfaceCountAddresses = eb_haiku_network_interface_count_addresses(interface.handle)
END FUNCTION

TYPE HNetworkInterfaceAddress
    handle AS ANY PTR
END TYPE

FUNCTION HNetworkInterfaceAddressCreate() AS HNetworkInterfaceAddress
    DIM a AS HNetworkInterfaceAddress
    a.handle = eb_haiku_network_interface_address_create()
    HNetworkInterfaceAddressCreate = a
END FUNCTION

''' Frees an HNetworkInterfaceAddress - call exactly once.
SUB HNetworkInterfaceAddressFree(BYVAL a AS HNetworkInterfaceAddress)
    CALL eb_haiku_network_interface_address_destroy(a.handle)
END SUB

''' Fills `ifAddr` with the interface's `index`'th address (0 ..
''' HNetworkInterfaceCountAddresses(interface) - 1). Returns a status
''' code (0 = success).
FUNCTION HNetworkInterfaceGetAddressAt(BYVAL interface AS HNetworkInterface, BYVAL index AS INTEGER, BYVAL ifAddr AS HNetworkInterfaceAddress) AS INTEGER
    HNetworkInterfaceGetAddressAt = eb_haiku_network_interface_get_address_at(interface.handle, index, ifAddr.handle)
END FUNCTION

''' Copies ifAddr's own real address into `outAddr` (an existing
''' HNetworkAddressCreateEmpty result, network.bas) - reuses the
''' existing HNetworkAddress type entirely rather than exposing a third
''' address-shaped handle. Read via HNetworkAddressToString/Port.
SUB HNetworkInterfaceAddressCopyAddress(BYVAL ifAddr AS HNetworkInterfaceAddress, BYVAL outAddr AS HNetworkAddress)
    CALL eb_haiku_network_interface_address_copy_address(ifAddr.handle, outAddr.handle)
END SUB
