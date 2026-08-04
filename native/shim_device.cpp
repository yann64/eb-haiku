#include "shim_device.h"

#include <SerialPort.h>

extern "C" {

void* eb_haiku_serial_port_create(void) { return new BSerialPort(); }

int eb_haiku_serial_port_open(void* port, const char* portName) {
    return static_cast<BSerialPort*>(port)->Open(portName);
}

void eb_haiku_serial_port_close(void* port) { static_cast<BSerialPort*>(port)->Close(); }

int eb_haiku_serial_port_read(void* port, void* buf, int count) {
    return static_cast<int>(
        static_cast<BSerialPort*>(port)->Read(buf, static_cast<size_t>(count)));
}

int eb_haiku_serial_port_write(void* port, const void* buf, int count) {
    return static_cast<int>(
        static_cast<BSerialPort*>(port)->Write(buf, static_cast<size_t>(count)));
}

void eb_haiku_serial_port_set_blocking(void* port, int blocking) {
    static_cast<BSerialPort*>(port)->SetBlocking(blocking != 0);
}

int eb_haiku_serial_port_set_timeout(void* port, long long microSeconds) {
    return static_cast<BSerialPort*>(port)->SetTimeout(static_cast<bigtime_t>(microSeconds));
}

int eb_haiku_serial_port_set_data_rate(void* port, unsigned int bitsPerSecond) {
    return static_cast<BSerialPort*>(port)->SetDataRate(static_cast<data_rate>(bitsPerSecond));
}

unsigned int eb_haiku_serial_port_data_rate(void* port) {
    return static_cast<unsigned int>(static_cast<BSerialPort*>(port)->DataRate());
}

void eb_haiku_serial_port_set_data_bits(void* port, unsigned int numBits) {
    static_cast<BSerialPort*>(port)->SetDataBits(static_cast<data_bits>(numBits));
}

unsigned int eb_haiku_serial_port_data_bits(void* port) {
    return static_cast<unsigned int>(static_cast<BSerialPort*>(port)->DataBits());
}

void eb_haiku_serial_port_set_stop_bits(void* port, unsigned int numBits) {
    static_cast<BSerialPort*>(port)->SetStopBits(static_cast<stop_bits>(numBits));
}

unsigned int eb_haiku_serial_port_stop_bits(void* port) {
    return static_cast<unsigned int>(static_cast<BSerialPort*>(port)->StopBits());
}

void eb_haiku_serial_port_set_parity_mode(void* port, unsigned int which) {
    static_cast<BSerialPort*>(port)->SetParityMode(static_cast<parity_mode>(which));
}

unsigned int eb_haiku_serial_port_parity_mode(void* port) {
    return static_cast<unsigned int>(static_cast<BSerialPort*>(port)->ParityMode());
}

int eb_haiku_serial_port_num_chars_available(void* port, int* outCount) {
    int32 count = 0;
    status_t rc = static_cast<BSerialPort*>(port)->NumCharsAvailable(&count);
    *outCount = count;
    return rc;
}

int eb_haiku_serial_port_wait_for_input(void* port) {
    return static_cast<int>(static_cast<BSerialPort*>(port)->WaitForInput());
}

int eb_haiku_serial_port_count_devices(void* port) {
    return static_cast<BSerialPort*>(port)->CountDevices();
}

int eb_haiku_serial_port_get_device_name(void* port, int index, char* outName, int bufSize) {
    return static_cast<BSerialPort*>(port)->GetDeviceName(index, outName,
                                                            static_cast<size_t>(bufSize));
}

void eb_haiku_serial_port_destroy(void* port) { delete static_cast<BSerialPort*>(port); }

} // extern "C"
