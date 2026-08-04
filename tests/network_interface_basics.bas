' Network Kit: BNetworkRoster/BNetworkInterface - real, local
' interface enumeration. Asserts only what's guaranteed on any live
' Haiku host: at least one interface exists, and a real loopback
' address (127.0.0.1) is found among them - not any specific interface
' name or count, which vary by machine.

#include once "../src/lib.bas"

DIM roster AS HNetworkRoster
roster = HNetworkRosterDefault()

DIM ifaceCount AS INTEGER
ifaceCount = HNetworkRosterCountInterfaces(roster)
PRINT "interface count=", ifaceCount
IF ifaceCount < 1 THEN
    PRINT "FAIL: expected at least one real network interface"
    CALL ExitProcess(1)
END IF

DIM iface AS HNetworkInterface
iface = HNetworkInterfaceCreate()
DIM ifAddr AS HNetworkInterfaceAddress
ifAddr = HNetworkInterfaceAddressCreate()
DIM outAddr AS HNetworkAddress
outAddr = HNetworkAddressCreateEmpty()

DIM cookie AS UINTEGER
cookie = 0
DIM rc AS INTEGER
DIM foundLoopback AS INTEGER
foundLoopback = 0

DO
    rc = HNetworkRosterGetNextInterface(roster, cookie, iface)
    IF rc <> 0 THEN
        EXIT DO
    END IF

    DIM ifaceName AS STRING
    ifaceName = HNetworkInterfaceName(iface)
    DIM addrCount AS INTEGER
    addrCount = HNetworkInterfaceCountAddresses(iface)
    PRINT "interface name=", ifaceName, " flags=", HNetworkInterfaceFlags(iface), _
          " hasLink=", HNetworkInterfaceHasLink(iface), " addressCount=", addrCount

    DIM i AS INTEGER
    FOR i = 0 TO addrCount - 1
        DIM addrRc AS INTEGER
        addrRc = HNetworkInterfaceGetAddressAt(iface, i, ifAddr)
        IF addrRc <> 0 THEN
            PRINT "FAIL: HNetworkInterfaceGetAddressAt returned ", addrRc
            CALL ExitProcess(1)
        END IF
        CALL HNetworkInterfaceAddressCopyAddress(ifAddr, outAddr)

        DIM buf(255) AS BYTE
        DIM bufPtr AS ANY PTR
        bufPtr = @buf(0)
        DIM strLen AS INTEGER
        strLen = HNetworkAddressToString(outAddr, bufPtr, 256)
        IF strLen >= 0 THEN
            buf(strLen) = 0
            DIM z AS ZSTRING
            z = bufPtr
            DIM s AS STRING
            s = z
            PRINT "  address[", i, "]=", s
            IF InStr(s, "127.0.0.1") > 0 THEN
                foundLoopback = 1
            END IF
        END IF
    NEXT i
LOOP

CALL HNetworkInterfaceAddressFree(ifAddr)
CALL HNetworkInterfaceFree(iface)
CALL HNetworkAddressFree(outAddr)

IF foundLoopback <> 1 THEN
    PRINT "FAIL: expected to find a real 127.0.0.1 loopback address among the interfaces"
    CALL ExitProcess(1)
END IF
PRINT "GetNextInterface/GetAddressAt/CopyAddress ok"

PRINT "network interface basics test ok"
