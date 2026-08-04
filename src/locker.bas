' Idiomatic layer: BLocker - a real mutex/locking primitive. Directly
' closes a real, previously-documented risk (see this package's own
' README "Threading" section - "eBasic has no locking primitives... a
' real, unsolved risk this package doesn't protect you from"): a
' window/app callback running on its own thread can now Lock/Unlock a
' shared HLocker before touching state another callback also touches.
'
' BAutolock (real Haiku's RAII lock-scope helper) is deliberately not
' bound - it's header-only inline C++ with no out-of-line methods to
' wrap, and doesn't map onto eBasic's own scoping model anyway. Call
' HLockerUnlock explicitly once you're done, the same way every other
' handle in this package is freed/released explicitly.

#include once "raw/haiku_shim.bas"

TYPE HLocker
    handle AS ANY PTR
END TYPE

FUNCTION HLockerCreate() AS HLocker
    DIM l AS HLocker
    l.handle = eb_haiku_locker_create()
    HLockerCreate = l
END FUNCTION

''' Blocks the calling thread until the lock is acquired (real Haiku
''' recursive semantics - the same thread can lock it again without
''' deadlocking itself, see HLockerCountLocks). Returns nonzero on
''' success.
FUNCTION HLockerLock(BYVAL l AS HLocker) AS INTEGER
    HLockerLock = eb_haiku_locker_lock(l.handle)
END FUNCTION

''' Same as HLockerLock, but gives up after `timeoutMicros` microseconds
''' instead of blocking forever. Returns a status code (0 = success).
FUNCTION HLockerLockWithTimeout(BYVAL l AS HLocker, BYVAL timeoutMicros AS LONGINT) AS INTEGER
    HLockerLockWithTimeout = eb_haiku_locker_lock_with_timeout(l.handle, timeoutMicros)
END FUNCTION

''' Releases one level of the lock - call exactly once per successful
''' HLockerLock/LockWithTimeout call (see HLockerCountLocks for
''' recursive locking).
SUB HLockerUnlock(BYVAL l AS HLocker)
    CALL eb_haiku_locker_unlock(l.handle)
END SUB

FUNCTION HLockerIsLocked(BYVAL l AS HLocker) AS INTEGER
    HLockerIsLocked = eb_haiku_locker_is_locked(l.handle)
END FUNCTION

''' How many times the current thread has locked this HLocker
''' recursively (0 if not locked by the current thread).
FUNCTION HLockerCountLocks(BYVAL l AS HLocker) AS INTEGER
    HLockerCountLocks = eb_haiku_locker_count_locks(l.handle)
END FUNCTION

''' Frees an HLocker - call exactly once, only once fully unlocked.
SUB HLockerFree(BYVAL l AS HLocker)
    CALL eb_haiku_locker_destroy(l.handle)
END SUB
