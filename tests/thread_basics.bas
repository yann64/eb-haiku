' Kernel Kit concurrency: real preemptive threads, semaphores, and
' ports. Verified with real concurrency correctness, not just "the
' calls don't crash": a semaphore genuinely blocks a second thread
' until released, and a port round-trip actually blocks the reader
' until the writer thread sends.

#include once "../src/lib.bas"

' ---- Part 1: a real spawned thread actually runs concurrently ----

DIM gThreadRan AS INTEGER
gThreadRan = 0

FUNCTION SimpleThreadFunc(data AS ANY PTR) AS INTEGER
    gThreadRan = 1
    SimpleThreadFunc = 42
END FUNCTION

DIM t1 AS INTEGER
t1 = HSpawnThread(@SimpleThreadFunc, "eb-haiku-simple-thread", H_NORMAL_PRIORITY, 0)
IF t1 < 0 THEN
    PRINT "FAIL: HSpawnThread returned ", t1
    CALL ExitProcess(1)
END IF
CALL HResumeThread(t1)

DIM rv AS INTEGER
DIM rc AS INTEGER
rc = HWaitForThread(t1, rv)
IF rc <> 0 THEN
    PRINT "FAIL: HWaitForThread returned ", rc
    CALL ExitProcess(1)
END IF
IF gThreadRan <> 1 THEN
    PRINT "FAIL: spawned thread never set gThreadRan"
    CALL ExitProcess(1)
END IF
IF rv <> 42 THEN
    PRINT "FAIL: expected thread return value 42, got ", rv
    CALL ExitProcess(1)
END IF
PRINT "spawned thread ran ok, return value=", rv

' ---- Part 2: a real semaphore blocks a second thread until released ----

DIM gSemFlag AS INTEGER
gSemFlag = 0
DIM gSem AS INTEGER
gSem = HSemaphoreCreate(0, "eb-haiku-test-sem")
IF gSem < 0 THEN
    PRINT "FAIL: HSemaphoreCreate returned ", gSem
    CALL ExitProcess(1)
END IF

FUNCTION SemWaiterFunc(data AS ANY PTR) AS INTEGER
    CALL HSemaphoreAcquire(gSem)
    gSemFlag = 1
    SemWaiterFunc = 0
END FUNCTION

DIM t2 AS INTEGER
t2 = HSpawnThread(@SemWaiterFunc, "eb-haiku-sem-waiter", H_NORMAL_PRIORITY, 0)
CALL HResumeThread(t2)

CALL HSnooze(300000) ' 300ms - long enough for the waiter to reach Acquire and block
IF gSemFlag <> 0 THEN
    PRINT "FAIL: gSemFlag should still be 0 - the waiter should be blocked"
    CALL ExitProcess(1)
END IF
PRINT "semaphore correctly blocked the waiter thread"

CALL HSemaphoreRelease(gSem)
CALL HWaitForThread(t2, rv)
IF gSemFlag <> 1 THEN
    PRINT "FAIL: gSemFlag should be 1 after release"
    CALL ExitProcess(1)
END IF
CALL HSemaphoreDelete(gSem)
PRINT "semaphore release unblocked the waiter thread ok"

' ---- Part 3: a real port round-trip blocks the reader until a writer thread sends ----

DIM gPort AS INTEGER
gPort = HPortCreate(1, "eb-haiku-test-port")
IF gPort < 0 THEN
    PRINT "FAIL: HPortCreate returned ", gPort
    CALL ExitProcess(1)
END IF

CONST PORT_CODE = 7777
CONST PORT_MESSAGE = "hello from writer thread"

FUNCTION PortWriterFunc(data AS ANY PTR) AS INTEGER
    CALL HSnooze(300000) ' delay - proves the reader genuinely blocked, not just got lucky
    DIM msgBuf(255) AS BYTE
    DIM i AS INTEGER
    FOR i = 1 TO Len(PORT_MESSAGE)
        msgBuf(i - 1) = Asc(Mid(PORT_MESSAGE, i, 1))
    NEXT i
    CALL HPortWrite(gPort, PORT_CODE, @msgBuf(0), Len(PORT_MESSAGE))
    PortWriterFunc = 0
END FUNCTION

DIM t3 AS INTEGER
t3 = HSpawnThread(@PortWriterFunc, "eb-haiku-port-writer", H_NORMAL_PRIORITY, 0)
CALL HResumeThread(t3)

DIM readBuf(255) AS BYTE
DIM readBufPtr AS ANY PTR
readBufPtr = @readBuf(0)
DIM outCode AS INTEGER
DIM n AS INTEGER
n = HPortRead(gPort, outCode, readBufPtr, 256) ' blocks until the writer thread sends
IF n <= 0 THEN
    PRINT "FAIL: HPortRead returned ", n
    CALL ExitProcess(1)
END IF
IF outCode <> PORT_CODE THEN
    PRINT "FAIL: expected port code ", PORT_CODE, ", got ", outCode
    CALL ExitProcess(1)
END IF
readBuf(n) = 0
DIM readZ AS ZSTRING
readZ = readBufPtr
DIM readStr AS STRING
readStr = readZ
PRINT "port received=", readStr
IF readStr <> PORT_MESSAGE THEN
    PRINT "FAIL: port message mismatch"
    CALL ExitProcess(1)
END IF

CALL HWaitForThread(t3, rv)
CALL HPortDelete(gPort)
PRINT "port round-trip ok"

PRINT "thread basics test ok"
