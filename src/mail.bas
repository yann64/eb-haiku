' Idiomatic layer: Mail Kit - BEmailMessage (compose/send) and
' BMailDaemon (query/control the real mail_daemon system service).
'
' IMPORTANT, confirmed by direct reproduction: on a host with no mail
' account configured and no mail_daemon process running, real delivery
' isn't possible - HMailDaemonCheckMail/HMailDaemonCountNewMessages
' return a real H_MAIL_NO_DAEMON status promptly (no hang), and
' HEmailMessageSend returns a real, non-zero failure status. This is
' expected, documented behavior in that environment, not a binding
' bug - a host with a real configured account/running daemon will see
' these calls succeed instead.

#include once "raw/haiku_shim_mail.bas"

CONST H_MAIL_NO_DAEMON = -2147450880

TYPE HEmailMessage
    handle AS ANY PTR
END TYPE

FUNCTION HEmailMessageCreate() AS HEmailMessage
    DIM m AS HEmailMessage
    m.handle = eb_haiku_email_message_create()
    HEmailMessageCreate = m
END FUNCTION

FUNCTION HEmailMessageInitCheck(BYVAL m AS HEmailMessage) AS INTEGER
    HEmailMessageInitCheck = eb_haiku_email_message_init_check(m.handle)
END FUNCTION

SUB HEmailMessageSetTo(BYVAL m AS HEmailMessage, toAddr AS ZSTRING)
    CALL eb_haiku_email_message_set_to(m.handle, toAddr)
END SUB

SUB HEmailMessageSetFrom(BYVAL m AS HEmailMessage, fromAddr AS ZSTRING)
    CALL eb_haiku_email_message_set_from(m.handle, fromAddr)
END SUB

SUB HEmailMessageSetReplyTo(BYVAL m AS HEmailMessage, replyTo AS ZSTRING)
    CALL eb_haiku_email_message_set_reply_to(m.handle, replyTo)
END SUB

SUB HEmailMessageSetCC(BYVAL m AS HEmailMessage, cc AS ZSTRING)
    CALL eb_haiku_email_message_set_cc(m.handle, cc)
END SUB

SUB HEmailMessageSetBCC(BYVAL m AS HEmailMessage, bcc AS ZSTRING)
    CALL eb_haiku_email_message_set_bcc(m.handle, bcc)
END SUB

SUB HEmailMessageSetSubject(BYVAL m AS HEmailMessage, subject AS ZSTRING)
    CALL eb_haiku_email_message_set_subject(m.handle, subject)
END SUB

SUB HEmailMessageSetPriority(BYVAL m AS HEmailMessage, BYVAL priority AS INTEGER)
    CALL eb_haiku_email_message_set_priority(m.handle, priority)
END SUB

SUB HEmailMessageSetBodyTextTo(BYVAL m AS HEmailMessage, text AS ZSTRING)
    CALL eb_haiku_email_message_set_body_text(m.handle, text)
END SUB

FUNCTION HEmailMessageBodyText(BYVAL m AS HEmailMessage) AS ZSTRING
    HEmailMessageBodyText = eb_haiku_email_message_body_text(m.handle)
END FUNCTION

''' Attaches the real file at `path` (constructs its entry_ref
''' internally). Returns a status code (0 = success).
FUNCTION HEmailMessageAttach(BYVAL m AS HEmailMessage, path AS ZSTRING, BYVAL includeAttributes AS INTEGER) AS INTEGER
    HEmailMessageAttach = eb_haiku_email_message_attach(m.handle, path, includeAttributes)
END FUNCTION

''' IMPORTANT, confirmed by direct reproduction (a standalone C++
''' probe with no eBasic involved): this returns false even for a
''' genuine attachment added via HEmailMessageAttach on this real
''' Haiku build - the underlying BMailComponent's own IsAttachment()
''' likewise returns false, despite ComponentType() correctly reporting
''' B_MAIL_ATTRIBUTED_ATTACHMENT for that same component. Use
''' HEmailMessageCountComponents (compare before/after Attach) to
''' verify an attachment was really added instead of trusting this
''' function's return value.
FUNCTION HEmailMessageIsComponentAttachment(BYVAL m AS HEmailMessage, BYVAL index AS INTEGER) AS INTEGER
    HEmailMessageIsComponentAttachment = eb_haiku_email_message_is_component_attachment(m.handle, index)
END FUNCTION

FUNCTION HEmailMessageCountComponents(BYVAL m AS HEmailMessage) AS INTEGER
    HEmailMessageCountComponents = eb_haiku_email_message_count_components(m.handle)
END FUNCTION

''' Queues the message; also attempts real delivery via the mail
''' daemon if `sendNow` is true. Returns a status code (0 = success) -
''' see this file's own top comment for the real "no configured
''' account" failure case.
FUNCTION HEmailMessageSend(BYVAL m AS HEmailMessage, BYVAL sendNow AS INTEGER) AS INTEGER
    HEmailMessageSend = eb_haiku_email_message_send(m.handle, sendNow)
END FUNCTION

''' Frees an HEmailMessage - call exactly once.
SUB HEmailMessageFree(BYVAL m AS HEmailMessage)
    CALL eb_haiku_email_message_destroy(m.handle)
END SUB

TYPE HMailDaemon
    handle AS ANY PTR
END TYPE

''' Cheap to construct - just builds a real messenger to the
''' mail_daemon system service (does not launch it).
FUNCTION HMailDaemonCreate() AS HMailDaemon
    DIM d AS HMailDaemon
    d.handle = eb_haiku_mail_daemon_create()
    HMailDaemonCreate = d
END FUNCTION

FUNCTION HMailDaemonIsRunning(BYVAL d AS HMailDaemon) AS INTEGER
    HMailDaemonIsRunning = eb_haiku_mail_daemon_is_running(d.handle)
END FUNCTION

''' Pass -1 for "all accounts". Returns a status code (0 = success).
FUNCTION HMailDaemonCheckMail(BYVAL d AS HMailDaemon, BYVAL accountID AS INTEGER) AS INTEGER
    HMailDaemonCheckMail = eb_haiku_mail_daemon_check_mail(d.handle, accountID)
END FUNCTION

FUNCTION HMailDaemonCheckAndSendQueuedMail(BYVAL d AS HMailDaemon, BYVAL accountID AS INTEGER) AS INTEGER
    HMailDaemonCheckAndSendQueuedMail = eb_haiku_mail_daemon_check_and_send_queued_mail(d.handle, accountID)
END FUNCTION

FUNCTION HMailDaemonSendQueuedMail(BYVAL d AS HMailDaemon) AS INTEGER
    HMailDaemonSendQueuedMail = eb_haiku_mail_daemon_send_queued_mail(d.handle)
END FUNCTION

FUNCTION HMailDaemonCountNewMessages(BYVAL d AS HMailDaemon, BYVAL waitForFetchCompletion AS INTEGER) AS INTEGER
    HMailDaemonCountNewMessages = eb_haiku_mail_daemon_count_new_messages(d.handle, waitForFetchCompletion)
END FUNCTION

''' Marks the real message file at `path` as read/unread/seen
''' (H_UNREAD/H_SEEN/H_READ). Constructs the entry_ref internally.
FUNCTION HMailDaemonMarkAsRead(BYVAL d AS HMailDaemon, BYVAL account AS INTEGER, path AS ZSTRING, BYVAL flag AS INTEGER) AS INTEGER
    HMailDaemonMarkAsRead = eb_haiku_mail_daemon_mark_as_read(d.handle, account, path, flag)
END FUNCTION

FUNCTION HMailDaemonQuit(BYVAL d AS HMailDaemon) AS INTEGER
    HMailDaemonQuit = eb_haiku_mail_daemon_quit(d.handle)
END FUNCTION

FUNCTION HMailDaemonLaunch(BYVAL d AS HMailDaemon) AS INTEGER
    HMailDaemonLaunch = eb_haiku_mail_daemon_launch(d.handle)
END FUNCTION

''' Frees an HMailDaemon - call exactly once.
SUB HMailDaemonFree(BYVAL d AS HMailDaemon)
    CALL eb_haiku_mail_daemon_destroy(d.handle)
END SUB
