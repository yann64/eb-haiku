' Mail Kit: BEmailMessage (compose, no real send assertion) + BMailDaemon
' (query the real mail_daemon system service).
'
' IMPORTANT, confirmed by direct reproduction (standalone C++ probe,
' run before writing this test): on a host with no mail account
' configured and no mail_daemon process running (this development
' host's own real state), HMailDaemonCheckMail/CountNewMessages return
' a real H_MAIL_NO_DAEMON status promptly (no hang), and
' HEmailMessageSend returns a real, non-zero failure status. This test
' only asserts the real, documented behavior for THIS environment - a
' host with a configured account/running daemon would see different,
' successful results instead.

#include once "../src/lib.bas"

DIM msg AS HEmailMessage
msg = HEmailMessageCreate()
IF HEmailMessageInitCheck(msg) <> 0 THEN
    PRINT "FAIL: HEmailMessageInitCheck failed"
    CALL ExitProcess(1)
END IF

CALL HEmailMessageSetTo(msg, "someone@example.com")
CALL HEmailMessageSetFrom(msg, "me@example.com")
CALL HEmailMessageSetSubject(msg, "Hello from eb-haiku")
CALL HEmailMessageSetBodyTextTo(msg, "This is the body.")

DIM body AS STRING
body = HEmailMessageBodyText(msg)
PRINT "body=", body
IF body <> "This is the body." THEN
    PRINT "FAIL: body text round-trip mismatch"
    CALL ExitProcess(1)
END IF

CONST ATTACH_TEST_PATH = "/boot/home/eb-haiku-mail-attach-test.txt"
CALL Kill(ATTACH_TEST_PATH)
CALL WriteFile(ATTACH_TEST_PATH, "real file for BEmailMessage::Attach")

DIM countBefore AS INTEGER
countBefore = HEmailMessageCountComponents(msg)

DIM rc AS INTEGER
rc = HEmailMessageAttach(msg, ATTACH_TEST_PATH, 1)
IF rc <> 0 THEN
    PRINT "FAIL: HEmailMessageAttach returned ", rc
    CALL ExitProcess(1)
END IF

DIM countAfter AS INTEGER
countAfter = HEmailMessageCountComponents(msg)
PRINT "components before=", countBefore, " after=", countAfter
IF countAfter <= countBefore THEN
    PRINT "FAIL: expected CountComponents to increase after Attach"
    CALL ExitProcess(1)
END IF
' IMPORTANT: real, confirmed Haiku behavior - IsComponentAttachment
' returns false even for this genuine attachment (see mail.bas's own
' doc comment on this function) - printed informationally only, not
' asserted.
PRINT "IsComponentAttachment(last)=", HEmailMessageIsComponentAttachment(msg, countAfter - 1)
CALL Kill(ATTACH_TEST_PATH)
PRINT "Attach/CountComponents ok"

' Real send is expected to fail on this host (no configured account) -
' just confirm it returns promptly, doesn't hang, and reports failure.
rc = HEmailMessageSend(msg, 0)
PRINT "Send(sendNow=0) rc=", rc
IF rc = 0 THEN
    PRINT "note: Send unexpectedly succeeded - a real account must now be configured"
END IF
CALL HEmailMessageFree(msg)

DIM daemon AS HMailDaemon
daemon = HMailDaemonCreate()
PRINT "daemon IsRunning=", HMailDaemonIsRunning(daemon)

DIM checkRc AS INTEGER
checkRc = HMailDaemonCheckMail(daemon, -1)
PRINT "CheckMail rc=", checkRc
IF checkRc <> 0 AND checkRc <> H_MAIL_NO_DAEMON THEN
    PRINT "FAIL: unexpected CheckMail status ", checkRc
    CALL ExitProcess(1)
END IF

DIM newCount AS INTEGER
newCount = HMailDaemonCountNewMessages(daemon, 0)
PRINT "CountNewMessages=", newCount
IF newCount < 0 AND newCount <> H_MAIL_NO_DAEMON THEN
    PRINT "FAIL: unexpected CountNewMessages status ", newCount
    CALL ExitProcess(1)
END IF

CALL HMailDaemonFree(daemon)

PRINT "mail basics test ok"
