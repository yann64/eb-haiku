' Raw FFI layer: eb-haiku's Mail Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_mail.h.

CONST H_UNREAD = 0
CONST H_SEEN = 1
CONST H_READ = 2

Extern "C" Lib "ebhaikushim"
    ' ---- BEmailMessage ----
    Declare Function eb_haiku_email_message_create() AS ANY PTR
    Declare Function eb_haiku_email_message_init_check(BYVAL msg AS ANY PTR) AS INTEGER

    Declare Sub eb_haiku_email_message_set_to(BYVAL msg AS ANY PTR, BYVAL toAddr AS ZSTRING)
    Declare Sub eb_haiku_email_message_set_from(BYVAL msg AS ANY PTR, BYVAL fromAddr AS ZSTRING)
    Declare Sub eb_haiku_email_message_set_reply_to(BYVAL msg AS ANY PTR, BYVAL replyTo AS ZSTRING)
    Declare Sub eb_haiku_email_message_set_cc(BYVAL msg AS ANY PTR, BYVAL cc AS ZSTRING)
    Declare Sub eb_haiku_email_message_set_bcc(BYVAL msg AS ANY PTR, BYVAL bcc AS ZSTRING)
    Declare Sub eb_haiku_email_message_set_subject(BYVAL msg AS ANY PTR, BYVAL subject AS ZSTRING)
    Declare Sub eb_haiku_email_message_set_priority(BYVAL msg AS ANY PTR, BYVAL priority AS INTEGER)

    Declare Sub eb_haiku_email_message_set_body_text(BYVAL msg AS ANY PTR, BYVAL text AS ZSTRING)
    Declare Function eb_haiku_email_message_body_text(BYVAL msg AS ANY PTR) AS ZSTRING

    Declare Function eb_haiku_email_message_attach(BYVAL msg AS ANY PTR, BYVAL path AS ZSTRING, BYVAL includeAttributes AS INTEGER) AS INTEGER
    Declare Function eb_haiku_email_message_is_component_attachment(BYVAL msg AS ANY PTR, BYVAL index AS INTEGER) AS INTEGER
    Declare Function eb_haiku_email_message_count_components(BYVAL msg AS ANY PTR) AS INTEGER

    Declare Function eb_haiku_email_message_send(BYVAL msg AS ANY PTR, BYVAL sendNow AS INTEGER) AS INTEGER

    Declare Sub eb_haiku_email_message_destroy(BYVAL msg AS ANY PTR)

    ' ---- BMailDaemon ----
    Declare Function eb_haiku_mail_daemon_create() AS ANY PTR
    Declare Sub eb_haiku_mail_daemon_destroy(BYVAL daemon AS ANY PTR)

    Declare Function eb_haiku_mail_daemon_is_running(BYVAL daemon AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_mail_daemon_check_mail(BYVAL daemon AS ANY PTR, BYVAL accountID AS INTEGER) AS INTEGER
    Declare Function eb_haiku_mail_daemon_check_and_send_queued_mail(BYVAL daemon AS ANY PTR, BYVAL accountID AS INTEGER) AS INTEGER
    Declare Function eb_haiku_mail_daemon_send_queued_mail(BYVAL daemon AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_mail_daemon_count_new_messages(BYVAL daemon AS ANY PTR, BYVAL waitForFetchCompletion AS INTEGER) AS INTEGER
    Declare Function eb_haiku_mail_daemon_mark_as_read(BYVAL daemon AS ANY PTR, BYVAL account AS INTEGER, BYVAL path AS ZSTRING, BYVAL flag AS INTEGER) AS INTEGER
    Declare Function eb_haiku_mail_daemon_quit(BYVAL daemon AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_mail_daemon_launch(BYVAL daemon AS ANY PTR) AS INTEGER
End Extern
