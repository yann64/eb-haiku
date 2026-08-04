' BNetworkRoster/BNetworkInterface - enumerate this machine's own real
' network interfaces and their addresses.

#include once "../src/lib.bas"

DIM roster AS HNetworkRoster
roster = HNetworkRosterDefault()

PRINT "interface count=", HNetworkRosterCountInterfaces(roster)

DIM iface AS HNetworkInterface
iface = HNetworkInterfaceCreate()
DIM ifAddr AS HNetworkInterfaceAddress
ifAddr = HNetworkInterfaceAddressCreate()
DIM addr AS HNetworkAddress
addr = HNetworkAddressCreateEmpty()

DIM cookie AS UINTEGER
cookie = 0
DIM rc AS INTEGER

DO
    rc = HNetworkRosterGetNextInterface(roster, cookie, iface)
    IF rc <> 0 THEN
        EXIT DO
    END IF

    PRINT HNetworkInterfaceName(iface), " (hasLink=", HNetworkInterfaceHasLink(iface), ")"

    DIM i AS INTEGER
    FOR i = 0 TO HNetworkInterfaceCountAddresses(iface) - 1
        IF HNetworkInterfaceGetAddressAt(iface, i, ifAddr) = 0 THEN
            CALL HNetworkInterfaceAddressCopyAddress(ifAddr, addr)
            DIM buf(255) AS BYTE
            DIM bufPtr AS ANY PTR
            bufPtr = @buf(0)
            DIM strLen AS INTEGER
            strLen = HNetworkAddressToString(addr, bufPtr, 256)
            IF strLen >= 0 THEN
                buf(strLen) = 0
                DIM z AS ZSTRING
                z = bufPtr
                PRINT "  ", z
            END IF
        END IF
    NEXT i
LOOP

CALL HNetworkInterfaceAddressFree(ifAddr)
CALL HNetworkInterfaceFree(iface)
CALL HNetworkAddressFree(addr)
