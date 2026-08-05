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

' ---- BNetworkInterface configuration (write side) ----
'
' SAFETY, IMPORTANT: every operation below targets ONLY the real
' loopback interface ("loop"), confirmed via a standalone C++ probe
' before writing this test to be genuinely safe (SetFlags/SetMTU set
' back to their own current/known-real values; AddAddress/RemoveAddress
' round-trip a harmless extra loopback-range address; AutoConfigure on
' "loop" is a real no-op) - NEVER a live NIC this SSH session itself
' might depend on.

DIM loopIface AS HNetworkInterface
loopIface = HNetworkInterfaceCreate()
cookie = 0
DIM foundLoop AS INTEGER
foundLoop = 0
DO
    rc = HNetworkRosterGetNextInterface(roster, cookie, loopIface)
    IF rc <> 0 THEN
        EXIT DO
    END IF
    DIM loopIfaceName AS STRING
    loopIfaceName = HNetworkInterfaceName(loopIface)
    IF loopIfaceName = "loop" THEN
        foundLoop = 1
        EXIT DO
    END IF
LOOP
IF foundLoop <> 1 THEN
    PRINT "FAIL: expected to find the real loopback interface named 'loop'"
    CALL ExitProcess(1)
END IF

DIM currentFlags AS UINTEGER
currentFlags = HNetworkInterfaceFlags(loopIface)
CALL HNetworkInterfaceSetFlags(loopIface, currentFlags)
PRINT "SetFlags(self, no-op) ran ok"

rc = HNetworkInterfaceSetMTU(loopIface, 65536)
IF rc <> 0 THEN
    PRINT "FAIL: SetMTU on loop returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "SetMTU(65536, loop's own real value) ok"

DIM extraAddr AS HNetworkAddress
extraAddr = HNetworkAddressCreateEmpty()
CALL HNetworkAddressSetTo(extraAddr, "127.0.0.2", 0)

DIM countBefore AS INTEGER
countBefore = HNetworkInterfaceCountAddresses(loopIface)
rc = HNetworkInterfaceAddAddress(loopIface, extraAddr)
IF rc <> 0 THEN
    PRINT "FAIL: AddAddress(127.0.0.2) on loop returned ", rc
    CALL ExitProcess(1)
END IF
DIM countAfterAdd AS INTEGER
countAfterAdd = HNetworkInterfaceCountAddresses(loopIface)
PRINT "address count before=", countBefore, " after AddAddress=", countAfterAdd
IF countAfterAdd <= countBefore THEN
    PRINT "FAIL: expected CountAddresses to increase after AddAddress"
    CALL ExitProcess(1)
END IF

rc = HNetworkInterfaceRemoveAddress(loopIface, extraAddr)
IF rc <> 0 THEN
    PRINT "FAIL: RemoveAddress(127.0.0.2) on loop returned ", rc
    CALL ExitProcess(1)
END IF
DIM countAfterRemove AS INTEGER
countAfterRemove = HNetworkInterfaceCountAddresses(loopIface)
PRINT "address count after RemoveAddress=", countAfterRemove
IF countAfterRemove <> countBefore THEN
    PRINT "FAIL: expected CountAddresses to return to its original value after RemoveAddress"
    CALL ExitProcess(1)
END IF
PRINT "AddAddress/RemoveAddress round-trip ok"

rc = HNetworkInterfaceAutoConfigure(loopIface, H_AF_INET)
PRINT "AutoConfigure(loop, AF_INET) rc=", rc

CALL HNetworkAddressFree(extraAddr)
CALL HNetworkInterfaceFree(loopIface)

PRINT "network interface basics test ok"
