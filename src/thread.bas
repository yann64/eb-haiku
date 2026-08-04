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

''' Like HWaitForThread, but with a real timeout - `flags` is
''' H_RELATIVE_TIMEOUT/H_ABSOLUTE_TIMEOUT (raw/haiku_kernel.bas).
''' Returns a status code (B_TIMED_OUT on timeout).
FUNCTION HWaitForThreadEtc(BYVAL thread AS INTEGER, BYVAL flags AS UINTEGER, BYVAL timeoutMicros AS LONGINT, BYREF outReturnValue AS INTEGER) AS INTEGER
    DIM rv AS INTEGER
    DIM rc AS INTEGER
    rc = wait_for_thread_etc(thread, flags, timeoutMicros, @rv)
    outReturnValue = rv
    HWaitForThreadEtc = rc
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

''' Like HSemaphoreAcquire, but with a real timeout - `flags` is
''' H_RELATIVE_TIMEOUT/H_ABSOLUTE_TIMEOUT. Returns a status code
''' (B_TIMED_OUT on timeout).
FUNCTION HSemaphoreAcquireEtc(BYVAL id AS INTEGER, BYVAL count AS INTEGER, BYVAL flags AS UINTEGER, BYVAL timeoutMicros AS LONGINT) AS INTEGER
    HSemaphoreAcquireEtc = acquire_sem_etc(id, count, flags, timeoutMicros)
END FUNCTION

''' Like HSemaphoreRelease, but `flags` is H_DO_NOT_RESCHEDULE/
''' H_RELEASE_ALL (a different flag space than HSemaphoreAcquireEtc's
''' own - see raw/haiku_kernel.bas's own note about the shared bit
''' value between the two).
FUNCTION HSemaphoreReleaseEtc(BYVAL id AS INTEGER, BYVAL count AS INTEGER, BYVAL flags AS UINTEGER) AS INTEGER
    HSemaphoreReleaseEtc = release_sem_etc(id, count, flags)
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

''' Like HPortWrite, but with a real timeout - `flags` is
''' H_RELATIVE_TIMEOUT/H_ABSOLUTE_TIMEOUT. Returns a status code
''' (B_TIMED_OUT on timeout/full queue).
FUNCTION HPortWriteEtc(BYVAL port AS INTEGER, BYVAL code AS INTEGER, BYVAL buffer AS ANY PTR, BYVAL bufferSize AS INTEGER, BYVAL flags AS UINTEGER, BYVAL timeoutMicros AS LONGINT) AS INTEGER
    HPortWriteEtc = write_port_etc(port, code, buffer, bufferSize, flags, timeoutMicros)
END FUNCTION

''' Like HPortRead, but with a real timeout - `flags` is
''' H_RELATIVE_TIMEOUT/H_ABSOLUTE_TIMEOUT. Returns the real payload
''' size in bytes (>= 0), or a negative status code (B_TIMED_OUT on
''' timeout).
FUNCTION HPortReadEtc(BYVAL port AS INTEGER, BYREF outCode AS INTEGER, BYVAL buffer AS ANY PTR, BYVAL bufferSize AS INTEGER, BYVAL flags AS UINTEGER, BYVAL timeoutMicros AS LONGINT) AS INTEGER
    DIM code AS INTEGER
    DIM n AS INTEGER
    n = read_port_etc(port, @code, buffer, bufferSize, flags, timeoutMicros)
    outCode = code
    HPortReadEtc = n
END FUNCTION

''' Allocates a `size`-byte shared/virtual memory region, filling
''' `outStartAddress` (an ANY PTR to a caller-owned ANY PTR variable,
''' e.g. `DIM addr AS ANY PTR : HAreaCreate(..., @addr, ...)` - matching
''' this package's own established buffer-out convention, e.g.
''' HClipboardGetText) with its own real start address. `addressSpec` is
''' H_ANY_ADDRESS/H_EXACT_ADDRESS, `lock` is H_NO_LOCK/H_FULL_LOCK,
''' `protection` is H_READ_AREA/H_WRITE_AREA (combine with OR - see
''' this package's own established OR-is-bitwise note in file.bas).
''' Returns the new area's real area_id (negative on failure).
'''
''' NOTE: takes `outStartAddress` BYVAL (as a pointer-to-pointer, not
''' BYREF) - a real eBasic codegen limitation, confirmed by direct
''' reproduction, means a BYREF ANY PTR parameter can't be called with a
''' plain ANY PTR-typed argument at all (an invalid `static_cast`
''' breaks reference binding) - this shape is the correct, callable
''' workaround, not a stylistic choice.
FUNCTION HAreaCreate(name AS ZSTRING, BYVAL outStartAddress AS ANY PTR, BYVAL addressSpec AS UINTEGER, BYVAL size AS INTEGER, BYVAL lock AS UINTEGER, BYVAL protection AS UINTEGER) AS INTEGER
    HAreaCreate = create_area(name, outStartAddress, addressSpec, size, lock, protection)
END FUNCTION

FUNCTION HAreaDelete(BYVAL id AS INTEGER) AS INTEGER
    HAreaDelete = delete_area(id)
END FUNCTION

''' Maps `source`'s own memory into a new area in this address space,
''' filling `outStartAddress` (see HAreaCreate's own doc comment for the
''' calling convention) with its own real start address (real
''' clone_area has no separate `lock` parameter - it inherits the
''' source area's own locking). Returns the new area's real area_id
''' (negative on failure).
FUNCTION HAreaClone(name AS ZSTRING, BYVAL outStartAddress AS ANY PTR, BYVAL addressSpec AS UINTEGER, BYVAL protection AS UINTEGER, BYVAL source AS INTEGER) AS INTEGER
    HAreaClone = clone_area(name, outStartAddress, addressSpec, protection, source)
END FUNCTION

''' Resizes an existing area in place. Returns a status code (0 =
''' success) - the area's own start address never changes.
FUNCTION HAreaResize(BYVAL id AS INTEGER, BYVAL newSize AS INTEGER) AS INTEGER
    HAreaResize = resize_area(id, newSize)
END FUNCTION

''' Looks up an area by its own real name. Returns its area_id, or a
''' negative status code if no such area exists.
FUNCTION HAreaFind(name AS ZSTRING) AS INTEGER
    HAreaFind = find_area(name)
END FUNCTION

''' Looks up the area containing a given address. Returns its area_id,
''' or a negative status code if `address` isn't inside any area.
FUNCTION HAreaFor(BYVAL address AS ANY PTR) AS INTEGER
    HAreaFor = area_for(address)
END FUNCTION
