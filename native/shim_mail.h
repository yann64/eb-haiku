// eb-haiku native shim - Mail Kit (os/mail/) - BEmailMessage/
// BMailDaemon. Plain new/delete throughout, no ref-counting. Real
// entry_ref parameters are constructed internally from a plain file
// path, matching this shim's own established convention (e.g.
// eb_haiku_roster_find_app_for_path in shim.cpp).
//
// mail_encoding.h's plain encode/decode free functions are not bound -
// low priority, not needed for basic compose/send.
#pragma once

extern "C" {

// ---- BEmailMessage (mail/MailMessage.h) ----

void* eb_haiku_email_message_create(void);
int eb_haiku_email_message_init_check(void* msg);

void eb_haiku_email_message_set_to(void* msg, const char* to);
void eb_haiku_email_message_set_from(void* msg, const char* from);
void eb_haiku_email_message_set_reply_to(void* msg, const char* replyTo);
void eb_haiku_email_message_set_cc(void* msg, const char* cc);
void eb_haiku_email_message_set_bcc(void* msg, const char* bcc);
void eb_haiku_email_message_set_subject(void* msg, const char* subject);
void eb_haiku_email_message_set_priority(void* msg, int priority);

void eb_haiku_email_message_set_body_text(void* msg, const char* text);
const char* eb_haiku_email_message_body_text(void* msg);

// Constructs a real entry_ref internally from `path` (matching this
// shim's own path-to-entry_ref convention elsewhere). Returns a
// status_t (0 = success).
int eb_haiku_email_message_attach(void* msg, const char* path, int includeAttributes);
int eb_haiku_email_message_is_component_attachment(void* msg, int index);
int eb_haiku_email_message_count_components(void* msg);

// Queues the message; also attempts real delivery via the mail daemon
// if `sendNow` is true. Returns a status_t (0 = success) - a real,
// non-zero status is expected/documented on a host with no configured
// mail account (see mail.bas's own top comment).
int eb_haiku_email_message_send(void* msg, int sendNow);

void eb_haiku_email_message_destroy(void* msg);

// ---- BMailDaemon (mail/MailDaemon.h) ----

void* eb_haiku_mail_daemon_create(void);
void eb_haiku_mail_daemon_destroy(void* daemon);

int eb_haiku_mail_daemon_is_running(void* daemon);
int eb_haiku_mail_daemon_check_mail(void* daemon, int accountID);
int eb_haiku_mail_daemon_check_and_send_queued_mail(void* daemon, int accountID);
int eb_haiku_mail_daemon_send_queued_mail(void* daemon);
int eb_haiku_mail_daemon_count_new_messages(void* daemon, int waitForFetchCompletion);
// Constructs a real entry_ref internally from `path`, matching
// eb_haiku_email_message_attach's own convention.
int eb_haiku_mail_daemon_mark_as_read(void* daemon, int account, const char* path, int flag);
int eb_haiku_mail_daemon_quit(void* daemon);
int eb_haiku_mail_daemon_launch(void* daemon);

} // extern "C"
