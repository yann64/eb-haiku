' Raw FFI layer: Haiku's own real Kernel Kit concurrency primitives
' (kernel/OS.h) - genuine, plain extern "C" functions (like
' find_directory/fs_create_index - see raw/haiku_find_directory.bas's
' own top comment), not shim wrappers. Real, language-level
' concurrency (actual preemptive OS threads/semaphores/ports/shared-
' memory areas) - a different kind of addition than the rest of this
' package's own "OS Kit" wrappers, but a genuinely useful one.
'
' thread_id/sem_id/port_id/area_id/status_t are all real 4-byte signed
' types; bigtime_t is a real 8-byte signed type (microseconds) -
' confirmed via the same compiled probe already used for BLocker's own
' timeout parameter.

' Real thread priority constants (kernel/OS.h) - plain literal macros,
' values directly visible in the real header (not FourCC-packed or
' otherwise ambiguous), still confirmed by reading the real header, not
' hand-recalled.
CONST H_LOWEST_ACTIVE_PRIORITY = 1
CONST H_LOW_PRIORITY = 5
CONST H_NORMAL_PRIORITY = 10
CONST H_DISPLAY_PRIORITY = 15
CONST H_URGENT_DISPLAY_PRIORITY = 20
CONST H_REAL_TIME_DISPLAY_PRIORITY = 100
CONST H_URGENT_PRIORITY = 110
CONST H_REAL_TIME_PRIORITY = 120

' Real create_area constants (kernel/OS.h).
CONST H_ANY_ADDRESS = 0
CONST H_EXACT_ADDRESS = 1
CONST H_NO_LOCK = 0
CONST H_FULL_LOCK = 2
CONST H_READ_AREA = 1
CONST H_WRITE_AREA = 2

Extern "C" Lib "root"
    ' ---- Threads ----
    ' `func` must be a plain top-level bodied FUNCTION taking (data AS
    ' ANY PTR) AS INTEGER, supplied via `@YourFuncName` - the same
    ' `@ProcName` mechanism this package's window/view callbacks
    ' already use (see docs/reference/namespaces-pointers-unions.md).
    Declare Function spawn_thread(BYVAL func AS ANY PTR, BYVAL name AS ZSTRING, BYVAL priority AS INTEGER, BYVAL data AS ANY PTR) AS INTEGER
    Declare Function resume_thread(BYVAL thread AS INTEGER) AS INTEGER
    Declare Function wait_for_thread(BYVAL thread AS INTEGER, BYVAL returnValue AS ANY PTR) AS INTEGER
    Declare Function kill_thread(BYVAL thread AS INTEGER) AS INTEGER
    Declare Function snooze(BYVAL amountMicros AS LONGINT) AS INTEGER

    ' ---- Semaphores ----
    Declare Function create_sem(BYVAL count AS INTEGER, BYVAL name AS ZSTRING) AS INTEGER
    Declare Function acquire_sem(BYVAL id AS INTEGER) AS INTEGER
    Declare Function release_sem(BYVAL id AS INTEGER) AS INTEGER
    Declare Function delete_sem(BYVAL id AS INTEGER) AS INTEGER

    ' ---- Ports (real message-passing IPC) ----
    Declare Function create_port(BYVAL capacity AS INTEGER, BYVAL name AS ZSTRING) AS INTEGER
    Declare Function write_port(BYVAL port AS INTEGER, BYVAL code AS INTEGER, BYVAL buffer AS ANY PTR, BYVAL bufferSize AS INTEGER) AS INTEGER
    Declare Function read_port(BYVAL port AS INTEGER, BYVAL outCode AS ANY PTR, BYVAL buffer AS ANY PTR, BYVAL bufferSize AS INTEGER) AS INTEGER
    Declare Function delete_port(BYVAL port AS INTEGER) AS INTEGER

    ' ---- Areas (shared/virtual memory regions) ----
    ' `outStartAddress` is an ANY PTR to a caller-owned ANY PTR variable
    ' (real Haiku's own `void**` out-param) - the area's own start
    ' address is written through it.
    Declare Function create_area(BYVAL name AS ZSTRING, BYVAL outStartAddress AS ANY PTR, BYVAL addressSpec AS UINTEGER, BYVAL size AS INTEGER, BYVAL lock AS UINTEGER, BYVAL protection AS UINTEGER) AS INTEGER
    Declare Function delete_area(BYVAL id AS INTEGER) AS INTEGER
End Extern
