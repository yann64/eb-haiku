' Device Kit - BSerialPort. Lists installed serial ports and, if any
' exist, opens the first one and configures it for 9600 baud.

#include once "../src/lib.bas"

DIM p AS HSerialPort
p = HSerialPortCreate()

DIM count AS INTEGER
count = HSerialPortCountDevices(p)
PRINT "serial ports found: ", count

IF count > 0 THEN
    DIM nameBuf(255) AS BYTE
    DIM nameBufPtr AS ANY PTR
    nameBufPtr = @nameBuf(0)
    CALL HSerialPortGetDeviceName(p, 0, nameBufPtr, 256)
    DIM nameZ AS ZSTRING
    nameZ = nameBufPtr
    DIM deviceName AS STRING
    deviceName = nameZ
    PRINT "opening: ", deviceName

    IF HSerialPortOpen(p, deviceName) >= 0 THEN
        CALL HSerialPortSetDataRate(p, H_9600_BPS)
        CALL HSerialPortSetDataBits(p, H_DATA_BITS_8)
        CALL HSerialPortSetStopBits(p, H_STOP_BITS_1)
        CALL HSerialPortSetParityMode(p, H_NO_PARITY)
        PRINT "configured for 9600 8N1"
        CALL HSerialPortClose(p)
    END IF
END IF

CALL HSerialPortFree(p)
