' Idiomatic layer: real Kernel Kit concurrency - threads/semaphores/
' ports/areas. Unlike every other Kit in this package, `thread_id`/
' `sem_id`/`port_id`/`area_id` are plain real Haiku integers, not
' pointers - so there's no opaque `TYPE ... : handle AS ANY PTR : END
' TYPE` wrapper here, just plain INTEGER values passed around directly
' (matching how `HRosterTeamFor` already treats `team_id` the same way).

#include once "raw/haiku_kernel.bas"

''' Creates a new thread (not yet running - call HResumeThread to start
''' it). `func` must be a plain top-level bodied FUNCTION taking (data
''' AS ANY PTR) AS INTEGER, supplied via `@YourFuncName`. `priority` is
''' one of the H_*_PRIORITY constants (raw/haiku_kernel.bas). Returns
''' the new thread's real thread_id (negative on failure).
FUNCTION HSpawnThread(func AS ANY PTR, name AS ZSTRING, BYVAL priority AS INTEGER, data AS ANY PTR) AS INTEGER
    HSpawnThread = spawn_thread(func, name, priority, data)
END FUNCTION

''' Starts a spawned thread running. Returns a status code (0 = success).
FUNCTION HResumeThread(BYVAL thread AS INTEGER) AS INTEGER
    HResumeThread = resume_thread(thread)
END FUNCTION

''' Blocks the calling thread until `thread` exits, filling
''' `outReturnValue` with its own real return value. Returns a status
''' code (0 = success).
FUNCTION HWaitForThread(BYVAL thread AS INTEGER, BYREF outReturnValue AS INTEGER) AS INTEGER
    DIM rv AS INTEGER
    DIM rc AS INTEGER
    rc = wait_for_thread(thread, @rv)
    outReturnValue = rv
    HWaitForThread = rc
END FUNCTION

''' Forcibly terminates a thread - prefer a cooperative shutdown signal
''' (e.g. a semaphore/port message) where possible; real Haiku offers
''' no cleanup guarantees here.
FUNCTION HKillThread(BYVAL thread AS INTEGER) AS INTEGER
    HKillThread = kill_thread(thread)
END FUNCTION

''' Sleeps the calling thread for `amountMicros` microseconds.
FUNCTION HSnooze(BYVAL amountMicros AS LONGINT) AS INTEGER
    HSnooze = snooze(amountMicros)
END FUNCTION

''' Creates a counting semaphore with the given initial `count`.
''' Returns the new semaphore's real sem_id (negative on failure).
FUNCTION HSemaphoreCreate(BYVAL count AS INTEGER, name AS ZSTRING) AS INTEGER
    HSemaphoreCreate = create_sem(count, name)
END FUNCTION

''' Blocks the calling thread until a unit is available, then takes it.
FUNCTION HSemaphoreAcquire(BYVAL id AS INTEGER) AS INTEGER
    HSemaphoreAcquire = acquire_sem(id)
END FUNCTION

''' Returns a unit to the semaphore, waking a waiting thread if any.
FUNCTION HSemaphoreRelease(BYVAL id AS INTEGER) AS INTEGER
    HSemaphoreRelease = release_sem(id)
END FUNCTION

FUNCTION HSemaphoreDelete(BYVAL id AS INTEGER) AS INTEGER
    HSemaphoreDelete = delete_sem(id)
END FUNCTION

''' Creates a real message port with the given queue `capacity`.
''' Returns the new port's real port_id (negative on failure).
FUNCTION HPortCreate(BYVAL capacity AS INTEGER, name AS ZSTRING) AS INTEGER
    HPortCreate = create_port(capacity, name)
END FUNCTION

''' Sends `bufferSize` bytes from `buffer` (a plain caller-owned byte
''' buffer, e.g. `@someArray(0)`), tagged with `code` - blocks if the
''' port's queue is full. Returns a status code (0 = success).
FUNCTION HPortWrite(BYVAL port AS INTEGER, BYVAL code AS INTEGER, BYVAL buffer AS ANY PTR, BYVAL bufferSize AS INTEGER) AS INTEGER
    HPortWrite = write_port(port, code, buffer, bufferSize)
END FUNCTION

''' Blocks until a message is available, filling `outCode` with its
''' real tag and `buffer` with up to `bufferSize` bytes of its own
''' payload. Returns the real payload size in bytes (>= 0), or a
''' negative status code.
FUNCTION HPortRead(BYVAL port AS INTEGER, BYREF outCode AS INTEGER, BYVAL buffer AS ANY PTR, BYVAL bufferSize AS INTEGER) AS INTEGER
    DIM code AS INTEGER
    DIM n AS INTEGER
    n = read_port(port, @code, buffer, bufferSize)
    outCode = code
    HPortRead = n
END FUNCTION

FUNCTION HPortDelete(BYVAL port AS INTEGER) AS INTEGER
    HPortDelete = delete_port(port)
END FUNCTION

''' Allocates a `size`-byte shared/virtual memory region, filling
''' `outStartAddress` with its own real start address. `addressSpec` is
''' H_ANY_ADDRESS/H_EXACT_ADDRESS, `lock` is H_NO_LOCK/H_FULL_LOCK,
''' `protection` is H_READ_AREA/H_WRITE_AREA (combine with OR - see
''' this package's own established OR-is-bitwise note in file.bas).
''' Returns the new area's real area_id (negative on failure).
FUNCTION HAreaCreate(name AS ZSTRING, BYREF outStartAddress AS ANY PTR, BYVAL addressSpec AS UINTEGER, BYVAL size AS INTEGER, BYVAL lock AS UINTEGER, BYVAL protection AS UINTEGER) AS INTEGER
    DIM addr AS ANY PTR
    DIM rc AS INTEGER
    rc = create_area(name, @addr, addressSpec, size, lock, protection)
    outStartAddress = addr
    HAreaCreate = rc
END FUNCTION

FUNCTION HAreaDelete(BYVAL id AS INTEGER) AS INTEGER
    HAreaDelete = delete_area(id)
END FUNCTION
