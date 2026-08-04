' Support Kit: BLocker - a real mutex/locking primitive. Verified two
' ways: (a) single-threaded correctness (lock/unlock/IsLocked, real
' recursive-locking semantics via CountLocks, LockWithTimeout); (b) the
' actual reason this exists - two REAL window threads racing to
' increment a shared counter 1000 times each, contending for the same
' HLocker. Without a working lock this would very likely lose updates
' (a classic data race) - an exact final count of 2000 is a real,
' meaningful confirmation the lock genuinely serializes access across
' threads, not just that the calls don't crash.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

' ---- Part 1: single-threaded correctness ----

DIM l AS HLocker
l = HLockerCreate()

IF HLockerIsLocked(l) <> 0 THEN
    PRINT "FAIL: a freshly created locker should not be locked"
    CALL ExitProcess(1)
END IF

IF HLockerLock(l) = 0 THEN
    PRINT "FAIL: HLockerLock should succeed on an unlocked locker"
    CALL ExitProcess(1)
END IF
IF HLockerIsLocked(l) = 0 THEN
    PRINT "FAIL: HLockerIsLocked should be true after HLockerLock"
    CALL ExitProcess(1)
END IF
IF HLockerCountLocks(l) <> 1 THEN
    PRINT "FAIL: HLockerCountLocks should be 1 after one lock"
    CALL ExitProcess(1)
END IF

' Real recursive semantics - the same thread can lock again.
IF HLockerLock(l) = 0 THEN
    PRINT "FAIL: recursive HLockerLock should succeed on the same thread"
    CALL ExitProcess(1)
END IF
IF HLockerCountLocks(l) <> 2 THEN
    PRINT "FAIL: HLockerCountLocks should be 2 after two recursive locks"
    CALL ExitProcess(1)
END IF

CALL HLockerUnlock(l)
IF HLockerIsLocked(l) = 0 THEN
    PRINT "FAIL: should still be locked after unlocking only one level"
    CALL ExitProcess(1)
END IF
CALL HLockerUnlock(l)
IF HLockerIsLocked(l) <> 0 THEN
    PRINT "FAIL: should be fully unlocked after unlocking both levels"
    CALL ExitProcess(1)
END IF
PRINT "recursive lock/unlock ok"

DIM rc AS INTEGER
rc = HLockerLockWithTimeout(l, 1000000)
IF rc <> 0 THEN
    PRINT "FAIL: LockWithTimeout should succeed immediately on an unlocked locker, got ", rc
    CALL ExitProcess(1)
END IF
CALL HLockerUnlock(l)
PRINT "LockWithTimeout ok"

CALL HLockerFree(l)

' ---- Part 2: real cross-thread race-free counter ----

DIM gLocker AS HLocker
gLocker = HLockerCreate()
DIM gCounter AS INTEGER
gCounter = 0

SUB OnDrawIncrement(userData AS ANY PTR, updateLeft AS SINGLE, updateTop AS SINGLE, updateRight AS SINGLE, updateBottom AS SINGLE)
    DIM i AS INTEGER
    FOR i = 1 TO 1000
        CALL HLockerLock(gLocker)
        gCounter = gCounter + 1
        CALL HLockerUnlock(gLocker)
    NEXT i
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-LockerTest")

DIM w1 AS HWindow
w1 = HWindowCreate(100, 100, 300, 200, "locker test 1", H_QUIT_ON_WINDOW_CLOSE)
DIM canvas1 AS HShimView
canvas1 = HShimViewCreate(0, 0, 180, 80, "canvas1", H_FOLLOW_ALL, H_WILL_DRAW)
CALL HShimViewSetDrawCallback(canvas1, @OnDrawIncrement, 0)
CALL HWindowAddChild(w1, canvas1.handle)

DIM w2 AS HWindow
w2 = HWindowCreate(320, 100, 520, 200, "locker test 2", H_QUIT_ON_WINDOW_CLOSE)
DIM canvas2 AS HShimView
canvas2 = HShimViewCreate(0, 0, 180, 80, "canvas2", H_FOLLOW_ALL, H_WILL_DRAW)
CALL HShimViewSetDrawCallback(canvas2, @OnDrawIncrement, 0)
CALL HWindowAddChild(w2, canvas2.handle)

CALL HWindowShow(w1)
CALL HWindowShow(w2)

' Trigger each window's own real Draw call on its own real thread.
CALL HShimViewInvalidate(canvas1)
CALL HShimViewInvalidate(canvas2)

CALL Sleep(2000) ' generous - each loop is 1000 fast lock/unlock cycles

CALL HWindowClose(w1)
CALL HWindowClose(w2)

CALL HApplicationRun(app)
CALL HApplicationFree(app)

PRINT "final counter=", gCounter
IF gCounter <> 2000 THEN
    PRINT "FAIL: expected exactly 2000 (no lost updates), got ", gCounter
    CALL ExitProcess(1)
END IF
PRINT "cross-thread race-free counter ok"

CALL HLockerFree(gLocker)

PRINT "locker basics test ok"
