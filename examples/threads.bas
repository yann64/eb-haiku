' Kernel Kit - real preemptive threads and semaphores. Two worker
' threads increment a shared counter, each protected by a semaphore
' used as a mutex (count 1).

#include once "../src/lib.bas"

DIM gMutex AS INTEGER
gMutex = HSemaphoreCreate(1, "eb-haiku-example-mutex")
DIM gCounter AS INTEGER
gCounter = 0

FUNCTION WorkerFunc(data AS ANY PTR) AS INTEGER
    DIM i AS INTEGER
    FOR i = 1 TO 500
        CALL HSemaphoreAcquire(gMutex)
        gCounter = gCounter + 1
        CALL HSemaphoreRelease(gMutex)
    NEXT i
    WorkerFunc = 0
END FUNCTION

DIM t1 AS INTEGER
t1 = HSpawnThread(@WorkerFunc, "worker-1", H_NORMAL_PRIORITY, 0)
DIM t2 AS INTEGER
t2 = HSpawnThread(@WorkerFunc, "worker-2", H_NORMAL_PRIORITY, 0)
CALL HResumeThread(t1)
CALL HResumeThread(t2)

DIM rv AS INTEGER
CALL HWaitForThread(t1, rv)
CALL HWaitForThread(t2, rv)
CALL HSemaphoreDelete(gMutex)

PRINT "final counter (expect 1000): ", gCounter
