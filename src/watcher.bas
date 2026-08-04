' Idiomatic layer: HWatcher - a small real BHandler, AddHandler'd onto
' be_app, that becomes a live BMessenger target for BQuery::SetTarget
' (query.bas), BVolumeRoster::StartWatching (volume.bas), and
' BClipboard::StartWatching (clipboard.bas) - the one primitive all
' three of Haiku's own live-notification mechanisms are built on.
'
' IMPORTANT: needs a real BApplication to already exist (HApplicationCreate)
' before HWatcherCreate - the same "needs BApplication first" gotcha as
' Translation Kit's GetBitmap/BClipboard::Lock (see this package's own
' README). Delivered messages are forwarded to an eBasic callback
' exactly like HWindowSetMessageReceivedCallback.

#include once "raw/haiku_shim.bas"

TYPE HWatcher
    handle AS ANY PTR
END TYPE

FUNCTION HWatcherCreate() AS HWatcher
    DIM w AS HWatcher
    w.handle = eb_haiku_watcher_create()
    HWatcherCreate = w
END FUNCTION

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, messageHandle AS ANY PTR), supplied via `@YourSubName` - same
''' shape as HWindowSetMessageReceivedCallback. Wrap `messageHandle` via
''' `DIM msg AS HMessage : msg.handle = messageHandle` to read it with
''' this package's own HMessage* functions.
SUB HWatcherSetMessageReceivedCallback(BYVAL w AS HWatcher, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_watcher_set_message_received_callback(w.handle, cb, userData)
END SUB

''' Frees an HWatcher - call exactly once, after unregistering it from
''' any HQuerySetTarget/HVolumeRosterStartWatching/
''' HClipboardStartWatching it was passed to.
'''
''' IMPORTANT, confirmed by direct reproduction: call this BEFORE
''' HApplicationFree, never after - internally this does a real
''' `be_app->RemoveHandler(...)`, and freeing the BApplication first
''' leaves the global `be_app` pointer dangling, so a later
''' HWatcherFree would touch already-freed memory (observed as a real
''' hang, not a clean crash). The same ordering applies to any HQuery
''' still live via HQuerySetTarget - free it before HApplicationFree too.
SUB HWatcherFree(BYVAL w AS HWatcher)
    CALL eb_haiku_watcher_destroy(w.handle)
END SUB
