// eb-haiku native shim - Device Kit (BSerialPort only - real, simple,
// directly analogous to the already-bound file/socket work). See
// shim.h's own top comment for why a hand-written shim is needed at
// all. Links against libdevice.so (confirmed real, present on the
// host via `ls /boot/system/lib/`).
#pragma once

extern "C" {

void* eb_haiku_serial_port_create(void);
// IMPORTANT, confirmed by direct reproduction: real Open() returns a
// non-negative value (not necessarily 0/B_OK) on success - check
// `>= 0`, not `== 0`, unlike almost every other status_t-returning
// function in this package.
int eb_haiku_serial_port_open(void* port, const char* portName);
void eb_haiku_serial_port_close(void* port);
int eb_haiku_serial_port_read(void* port, void* buf, int count);
int eb_haiku_serial_port_write(void* port, const void* buf, int count);
void eb_haiku_serial_port_set_blocking(void* port, int blocking);
int eb_haiku_serial_port_set_timeout(void* port, long long microSeconds);

// data_rate/data_bits/stop_bits/parity_mode are real Haiku enums -
// values are NOT the literal baud rate etc. (B_9600_BPS is 13, not
// 9600 - confirmed via a compiled probe, matching this package's own
// "verify, don't hand-derive" discipline) - see raw/haiku_shim_device.
// bas's own H_* constants.
int eb_haiku_serial_port_set_data_rate(void* port, unsigned int bitsPerSecond);
unsigned int eb_haiku_serial_port_data_rate(void* port);
void eb_haiku_serial_port_set_data_bits(void* port, unsigned int numBits);
unsigned int eb_haiku_serial_port_data_bits(void* port);
void eb_haiku_serial_port_set_stop_bits(void* port, unsigned int numBits);
unsigned int eb_haiku_serial_port_stop_bits(void* port);
void eb_haiku_serial_port_set_parity_mode(void* port, unsigned int which);
unsigned int eb_haiku_serial_port_parity_mode(void* port);

int eb_haiku_serial_port_num_chars_available(void* port, int* outCount);
int eb_haiku_serial_port_wait_for_input(void* port);

int eb_haiku_serial_port_count_devices(void* port);
int eb_haiku_serial_port_get_device_name(void* port, int index, char* outName, int bufSize);

void eb_haiku_serial_port_destroy(void* port);

} // extern "C"
