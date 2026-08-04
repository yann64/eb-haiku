' Raw FFI layer: eb-haiku's Device Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_device.h. BSerialPort only.

' Real data_rate/data_bits/stop_bits/parity_mode enum values
' (device/SerialPort.h) - confirmed by compiling and printing each one
' on the real Haiku host, NOT hand-derived: B_9600_BPS is 13, not the
' literal baud rate 9600 - a plain sequential enum index, matching
' this package's own "verify, don't assume" discipline (the same
' category of trap as the real B_ALIGN_TOP/B_JPEG_FORMAT values found
' earlier).
CONST H_9600_BPS = 13
CONST H_19200_BPS = 14
CONST H_38400_BPS = 15
CONST H_57600_BPS = 16
CONST H_115200_BPS = 17
CONST H_DATA_BITS_7 = 0
CONST H_DATA_BITS_8 = 1
CONST H_STOP_BITS_1 = 0
CONST H_STOP_BITS_2 = 1
CONST H_NO_PARITY = 0
CONST H_ODD_PARITY = 1
CONST H_EVEN_PARITY = 2

Extern "C" Lib "ebhaikushim"
    Declare Function eb_haiku_serial_port_create() AS ANY PTR
    ' IMPORTANT: returns a non-negative value (not necessarily 0) on
    ' success, confirmed by direct reproduction against a real serial
    ' device - check `>= 0`, not `= 0`, unlike almost every other
    ' status-code-returning function in this package.
    Declare Function eb_haiku_serial_port_open(BYVAL port AS ANY PTR, BYVAL portName AS ZSTRING) AS INTEGER
    Declare Sub eb_haiku_serial_port_close(BYVAL port AS ANY PTR)
    Declare Function eb_haiku_serial_port_read(BYVAL port AS ANY PTR, BYVAL buf AS ANY PTR, BYVAL count AS INTEGER) AS INTEGER
    Declare Function eb_haiku_serial_port_write(BYVAL port AS ANY PTR, BYVAL buf AS ANY PTR, BYVAL count AS INTEGER) AS INTEGER
    Declare Sub eb_haiku_serial_port_set_blocking(BYVAL port AS ANY PTR, BYVAL blocking AS INTEGER)
    Declare Function eb_haiku_serial_port_set_timeout(BYVAL port AS ANY PTR, BYVAL microSeconds AS LONGINT) AS INTEGER
    Declare Function eb_haiku_serial_port_set_data_rate(BYVAL port AS ANY PTR, BYVAL bitsPerSecond AS UINTEGER) AS INTEGER
    Declare Function eb_haiku_serial_port_data_rate(BYVAL port AS ANY PTR) AS UINTEGER
    Declare Sub eb_haiku_serial_port_set_data_bits(BYVAL port AS ANY PTR, BYVAL numBits AS UINTEGER)
    Declare Function eb_haiku_serial_port_data_bits(BYVAL port AS ANY PTR) AS UINTEGER
    Declare Sub eb_haiku_serial_port_set_stop_bits(BYVAL port AS ANY PTR, BYVAL numBits AS UINTEGER)
    Declare Function eb_haiku_serial_port_stop_bits(BYVAL port AS ANY PTR) AS UINTEGER
    Declare Sub eb_haiku_serial_port_set_parity_mode(BYVAL port AS ANY PTR, BYVAL which AS UINTEGER)
    Declare Function eb_haiku_serial_port_parity_mode(BYVAL port AS ANY PTR) AS UINTEGER
    Declare Function eb_haiku_serial_port_num_chars_available(BYVAL port AS ANY PTR, BYVAL outCount AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_serial_port_wait_for_input(BYVAL port AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_serial_port_count_devices(BYVAL port AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_serial_port_get_device_name(BYVAL port AS ANY PTR, BYVAL index AS INTEGER, BYVAL outName AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    Declare Sub eb_haiku_serial_port_destroy(BYVAL port AS ANY PTR)
End Extern
