' BNetworkInterface configuration - SAFETY: only ever targets the real
' loopback interface, never a live NIC.

#include once "../src/lib.bas"

DIM roster AS HNetworkRoster
roster = HNetworkRosterDefault()

DIM iface AS HNetworkInterface
iface = HNetworkInterfaceCreate()
DIM cookie AS UINTEGER
cookie = 0
DIM found AS INTEGER
found = 0
DO
    IF HNetworkRosterGetNextInterface(roster, cookie, iface) <> 0 THEN
        EXIT DO
    END IF
    DIM ifaceName AS STRING
    ifaceName = HNetworkInterfaceName(iface)
    IF ifaceName = "loop" THEN
        found = 1
        EXIT DO
    END IF
LOOP

IF found = 1 THEN
    DIM extraAddr AS HNetworkAddress
    extraAddr = HNetworkAddressCreateEmpty()
    CALL HNetworkAddressSetTo(extraAddr, "127.0.0.2", 0)

    DIM rc AS INTEGER
    rc = HNetworkInterfaceAddAddress(iface, extraAddr)
    PRINT "AddAddress(127.0.0.2) rc=", rc
    PRINT "address count=", HNetworkInterfaceCountAddresses(iface)

    CALL HNetworkInterfaceRemoveAddress(iface, extraAddr)
    CALL HNetworkAddressFree(extraAddr)
END IF

CALL HNetworkInterfaceFree(iface)
