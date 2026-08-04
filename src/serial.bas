' Idiomatic layer: BSerialPort - real serial I/O (talking to Arduino-
' style hardware, etc.), directly analogous to the already-bound
' file/socket work.

#include once "raw/haiku_shim_device.bas"

TYPE HSerialPort
    handle AS ANY PTR
END TYPE

FUNCTION HSerialPortCreate() AS HSerialPort
    DIM p AS HSerialPort
    p.handle = eb_haiku_serial_port_create()
    HSerialPortCreate = p
END FUNCTION

''' Opens the named port (e.g. one of HSerialPortGetDeviceName's own
''' results, typically under `/dev/ports/`). IMPORTANT, confirmed by
''' direct reproduction against real hardware: returns a non-negative
''' value (not necessarily 0) on success - check `>= 0`, not `= 0`,
''' unlike almost every other status-code-returning function in this
''' package.
FUNCTION HSerialPortOpen(BYVAL p AS HSerialPort, portName AS ZSTRING) AS INTEGER
    HSerialPortOpen = eb_haiku_serial_port_open(p.handle, portName)
END FUNCTION

SUB HSerialPortClose(BYVAL p AS HSerialPort)
    CALL eb_haiku_serial_port_close(p.handle)
END SUB

''' Reads up to `count` bytes into `buf` (a plain caller-owned byte
''' buffer, e.g. `@someArray(0)`). Returns bytes read (>= 0), or a
''' negative status code.
FUNCTION HSerialPortRead(BYVAL p AS HSerialPort, BYVAL buf AS ANY PTR, BYVAL count AS INTEGER) AS INTEGER
    HSerialPortRead = eb_haiku_serial_port_read(p.handle, buf, count)
END FUNCTION

''' Writes `count` bytes from `buf`. Returns bytes written (>= 0), or a
''' negative status code.
FUNCTION HSerialPortWrite(BYVAL p AS HSerialPort, BYVAL buf AS ANY PTR, BYVAL count AS INTEGER) AS INTEGER
    HSerialPortWrite = eb_haiku_serial_port_write(p.handle, buf, count)
END FUNCTION

SUB HSerialPortSetBlocking(BYVAL p AS HSerialPort, BYVAL blocking AS INTEGER)
    CALL eb_haiku_serial_port_set_blocking(p.handle, blocking)
END SUB

FUNCTION HSerialPortSetTimeout(BYVAL p AS HSerialPort, BYVAL microSeconds AS LONGINT) AS INTEGER
    HSerialPortSetTimeout = eb_haiku_serial_port_set_timeout(p.handle, microSeconds)
END FUNCTION

''' `bitsPerSecond` is one of the H_*_BPS constants
''' (raw/haiku_shim_device.bas) - NOT the literal baud rate (real
''' Haiku enum values are small sequential indices, e.g. H_9600_BPS is
''' 13, not 9600 - see that file's own comment).
FUNCTION HSerialPortSetDataRate(BYVAL p AS HSerialPort, BYVAL bitsPerSecond AS UINTEGER) AS INTEGER
    HSerialPortSetDataRate = eb_haiku_serial_port_set_data_rate(p.handle, bitsPerSecond)
END FUNCTION

FUNCTION HSerialPortDataRate(BYVAL p AS HSerialPort) AS UINTEGER
    HSerialPortDataRate = eb_haiku_serial_port_data_rate(p.handle)
END FUNCTION

''' `numBits` is H_DATA_BITS_7/H_DATA_BITS_8.
SUB HSerialPortSetDataBits(BYVAL p AS HSerialPort, BYVAL numBits AS UINTEGER)
    CALL eb_haiku_serial_port_set_data_bits(p.handle, numBits)
END SUB

FUNCTION HSerialPortDataBits(BYVAL p AS HSerialPort) AS UINTEGER
    HSerialPortDataBits = eb_haiku_serial_port_data_bits(p.handle)
END FUNCTION

''' `numBits` is H_STOP_BITS_1/H_STOP_BITS_2.
SUB HSerialPortSetStopBits(BYVAL p AS HSerialPort, BYVAL numBits AS UINTEGER)
    CALL eb_haiku_serial_port_set_stop_bits(p.handle, numBits)
END SUB

FUNCTION HSerialPortStopBits(BYVAL p AS HSerialPort) AS UINTEGER
    HSerialPortStopBits = eb_haiku_serial_port_stop_bits(p.handle)
END FUNCTION

''' `which` is H_NO_PARITY/H_ODD_PARITY/H_EVEN_PARITY.
SUB HSerialPortSetParityMode(BYVAL p AS HSerialPort, BYVAL which AS UINTEGER)
    CALL eb_haiku_serial_port_set_parity_mode(p.handle, which)
END SUB

FUNCTION HSerialPortParityMode(BYVAL p AS HSerialPort) AS UINTEGER
    HSerialPortParityMode = eb_haiku_serial_port_parity_mode(p.handle)
END FUNCTION

''' Fills `outCount` with the real number of bytes currently available
''' to read without blocking. Returns a status code (0 = success).
FUNCTION HSerialPortNumCharsAvailable(BYVAL p AS HSerialPort, BYREF outCount AS INTEGER) AS INTEGER
    DIM count AS INTEGER
    DIM rc AS INTEGER
    rc = eb_haiku_serial_port_num_chars_available(p.handle, @count)
    outCount = count
    HSerialPortNumCharsAvailable = rc
END FUNCTION

''' Blocks until input is available. Returns a status code.
FUNCTION HSerialPortWaitForInput(BYVAL p AS HSerialPort) AS INTEGER
    HSerialPortWaitForInput = eb_haiku_serial_port_wait_for_input(p.handle)
END FUNCTION

''' The real number of serial ports installed on this system.
FUNCTION HSerialPortCountDevices(BYVAL p AS HSerialPort) AS INTEGER
    HSerialPortCountDevices = eb_haiku_serial_port_count_devices(p.handle)
END FUNCTION

''' Fills `outName` (caller-supplied, at least 256 bytes) with the
''' `index`-th installed serial port's own real device name (usable
''' directly with HSerialPortOpen). Returns a status code (0 = success).
FUNCTION HSerialPortGetDeviceName(BYVAL p AS HSerialPort, BYVAL index AS INTEGER, BYVAL outName AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HSerialPortGetDeviceName = eb_haiku_serial_port_get_device_name(p.handle, index, outName, bufSize)
END FUNCTION

''' Frees an HSerialPort - call exactly once.
SUB HSerialPortFree(BYVAL p AS HSerialPort)
    CALL eb_haiku_serial_port_destroy(p.handle)
END SUB
