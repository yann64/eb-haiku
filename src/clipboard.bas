' Idiomatic layer: BClipboard - the shared system clipboard, via the
' `be_clipboard` singleton (exposed the same way `be_roster` is - see
' roster.bas), plus HClipboardCreate for a custom, named clipboard.
'
' IMPORTANT: BClipboard::Lock() (and, by extension, every function
' here) hangs indefinitely if called before any HApplication exists -
' confirmed by direct reproduction in a standalone C++ program with no
' eBasic involved at all (the same category of gotcha as the
' Translation Kit's own GetBitmap requirement - see this package's own
' README). Always call HApplicationCreate first - not a new burden for
' a real GUI/app program, which already needs one anyway, but a real
' trap if you only want to use the clipboard on its own. You do not
' need to call HApplicationRun - just constructing the HApplication is
' enough.
'
' Real Haiku's own plain-text convention, confirmed via the real
' `clipboard` command-line tool's own `-d`/debug dump (not assumed): a
' raw H_ATTR_TYPE_MIME field named "text/plain" on the clipboard's own
' payload message - NOT a string field via HMessageAddString.
' HClipboardSetText/GetText below already handle this correctly.

#include once "raw/haiku_shim.bas"
#include once "message.bas"

TYPE HClipboard
    handle AS ANY PTR
END TYPE

''' The shared system clipboard - never freed by this package (owned by
''' the Application Kit itself).
FUNCTION HClipboardDefault() AS HClipboard
    DIM c AS HClipboard
    c.handle = eb_haiku_clipboard_default()
    HClipboardDefault = c
END FUNCTION

''' A custom, named clipboard (not the shared system one) - free it via
''' HClipboardFree once done.
FUNCTION HClipboardCreate(name AS ZSTRING) AS HClipboard
    DIM c AS HClipboard
    c.handle = eb_haiku_clipboard_create(name)
    HClipboardCreate = c
END FUNCTION

''' Locks the clipboard - required before Clear/Data/Commit/Revert.
FUNCTION HClipboardLock(BYVAL c AS HClipboard) AS INTEGER
    HClipboardLock = eb_haiku_clipboard_lock(c.handle)
END FUNCTION

SUB HClipboardUnlock(BYVAL c AS HClipboard)
    CALL eb_haiku_clipboard_unlock(c.handle)
END SUB

''' Empties the clipboard's own payload message - call before writing
''' new content (matching real Haiku's own Lock/Clear/write/Commit/
''' Unlock usage pattern).
FUNCTION HClipboardClear(BYVAL c AS HClipboard) AS INTEGER
    HClipboardClear = eb_haiku_clipboard_clear(c.handle)
END FUNCTION

''' Publishes changes made to HClipboardData's own result system-wide.
FUNCTION HClipboardCommit(BYVAL c AS HClipboard) AS INTEGER
    HClipboardCommit = eb_haiku_clipboard_commit(c.handle)
END FUNCTION

''' Discards local changes, reloading the real system clipboard's own
''' current content.
FUNCTION HClipboardRevert(BYVAL c AS HClipboard) AS INTEGER
    HClipboardRevert = eb_haiku_clipboard_revert(c.handle)
END FUNCTION

''' The clipboard's own payload message - read/write it directly via
''' HMessageAddData/FindData (message.bas) for content beyond plain
''' text (e.g. a custom MIME type), or use HClipboardSetText/GetText
''' below for the common plain-text case.
FUNCTION HClipboardData(BYVAL c AS HClipboard) AS HMessage
    DIM m AS HMessage
    m.handle = eb_haiku_clipboard_data(c.handle)
    HClipboardData = m
END FUNCTION

''' Frees a custom HClipboardCreate instance - never call this on
''' HClipboardDefault's own result.
SUB HClipboardFree(BYVAL c AS HClipboard)
    CALL eb_haiku_clipboard_destroy(c.handle)
END SUB

''' Puts `text` on the clipboard using real Haiku's own plain-text
''' convention (see this file's own top comment) - handles the full
''' Lock/Clear/write/Commit/Unlock sequence internally. Returns a status
''' code (0 = success).
FUNCTION HClipboardSetText(BYVAL c AS HClipboard, text AS ZSTRING) AS INTEGER
    HClipboardSetText = eb_haiku_clipboard_set_text(c.handle, text)
END FUNCTION

''' Reads the clipboard's own plain text into `outBuf` (caller-supplied,
''' `bufSize` bytes) - NOT null-terminated automatically, matching this
''' package's own established buffer-out convention (e.g.
''' HVolumeGetName). Returns the real text length in bytes (>= 0), or a
''' negative status code if there's no plain text on the clipboard.
'''
''' DIM buf(1023) AS BYTE
''' DIM bufPtr AS ANY PTR : bufPtr = @buf(0)
''' DIM n AS INTEGER : n = HClipboardGetText(HClipboardDefault(), bufPtr, 1024)
''' IF n >= 0 THEN
'''     buf(n) = 0
'''     DIM z AS ZSTRING : z = bufPtr
'''     DIM s AS STRING : s = z
''' END IF
FUNCTION HClipboardGetText(BYVAL c AS HClipboard, BYVAL outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
    HClipboardGetText = eb_haiku_clipboard_get_text(c.handle, outBuf, bufSize)
END FUNCTION
