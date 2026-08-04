' Device Kit: BSerialPort. This real Haiku host happens to have a real
' (virtual, QEMU-provided) serial port - confirmed via a standalone
' C++ probe before writing this test, not assumed - so this test opens
' the real, first enumerated device and configures it, rather than
' just checking enumeration doesn't crash.

#include once "../src/lib.bas"

DIM p AS HSerialPort
p = HSerialPortCreate()

DIM count AS INTEGER
count = HSerialPortCountDevices(p)
PRINT "serial device count=", count
IF count < 0 THEN
    PRINT "FAIL: HSerialPortCountDevices returned ", count
    CALL ExitProcess(1)
END IF

IF count = 0 THEN
    PRINT "no real serial hardware on this host - enumeration-only verification"
    CALL HSerialPortFree(p)
    PRINT "serial basics test ok"
    CALL ExitProcess(0)
END IF

DIM nameBuf(255) AS BYTE
DIM nameBufPtr AS ANY PTR
nameBufPtr = @nameBuf(0)
DIM rc AS INTEGER
rc = HSerialPortGetDeviceName(p, 0, nameBufPtr, 256)
IF rc <> 0 THEN
    PRINT "FAIL: HSerialPortGetDeviceName returned ", rc
    CALL ExitProcess(1)
END IF
DIM nameZ AS ZSTRING
nameZ = nameBufPtr
DIM deviceName AS STRING
deviceName = nameZ
PRINT "device 0 name=", deviceName

' Real Open() returns a non-negative value (not necessarily 0) on
' success - confirmed by direct reproduction, see HSerialPortOpen's own
' doc comment.
DIM openRc AS INTEGER
openRc = HSerialPortOpen(p, deviceName)
IF openRc < 0 THEN
    PRINT "FAIL: HSerialPortOpen returned ", openRc
    CALL ExitProcess(1)
END IF
PRINT "opened ok, rc=", openRc

rc = HSerialPortSetDataRate(p, H_9600_BPS)
IF rc <> 0 THEN
    PRINT "FAIL: HSerialPortSetDataRate returned ", rc
    CALL ExitProcess(1)
END IF
DIM rate AS UINTEGER
rate = HSerialPortDataRate(p)
IF rate <> H_9600_BPS THEN
    PRINT "FAIL: data rate readback mismatch, got ", rate
    CALL ExitProcess(1)
END IF
PRINT "data rate set/readback ok"

CALL HSerialPortSetDataBits(p, H_DATA_BITS_8)
IF HSerialPortDataBits(p) <> H_DATA_BITS_8 THEN
    PRINT "FAIL: data bits readback mismatch"
    CALL ExitProcess(1)
END IF

CALL HSerialPortSetStopBits(p, H_STOP_BITS_1)
IF HSerialPortStopBits(p) <> H_STOP_BITS_1 THEN
    PRINT "FAIL: stop bits readback mismatch"
    CALL ExitProcess(1)
END IF

CALL HSerialPortSetParityMode(p, H_NO_PARITY)
IF HSerialPortParityMode(p) <> H_NO_PARITY THEN
    PRINT "FAIL: parity mode readback mismatch"
    CALL ExitProcess(1)
END IF
PRINT "data bits/stop bits/parity mode set/readback ok"

DIM available AS INTEGER
rc = HSerialPortNumCharsAvailable(p, available)
IF rc <> 0 THEN
    PRINT "FAIL: HSerialPortNumCharsAvailable returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "chars available=", available

CALL HSerialPortClose(p)
CALL HSerialPortFree(p)

PRINT "serial basics test ok"
