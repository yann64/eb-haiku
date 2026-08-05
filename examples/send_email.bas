' Mail Kit: compose a real BEmailMessage and queue it for delivery.
' Real delivery needs a configured mail account and a running
' mail_daemon - on a host with neither, Send still runs safely and
' just reports a real failure status (see mail.bas's own top comment).

#include once "../src/lib.bas"

DIM msg AS HEmailMessage
msg = HEmailMessageCreate()

CALL HEmailMessageSetTo(msg, "someone@example.com")
CALL HEmailMessageSetFrom(msg, "me@example.com")
CALL HEmailMessageSetSubject(msg, "Hello from eb-haiku")
CALL HEmailMessageSetBodyTextTo(msg, "This message was composed by an eBasic program.")

DIM rc AS INTEGER
rc = HEmailMessageSend(msg, 1)
PRINT "Send returned ", rc

CALL HEmailMessageFree(msg)

DIM daemon AS HMailDaemon
daemon = HMailDaemonCreate()
PRINT "mail_daemon running=", HMailDaemonIsRunning(daemon)
CALL HMailDaemonFree(daemon)
