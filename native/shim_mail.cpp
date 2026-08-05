#include "shim_mail.h"

#include <Entry.h>
#include <MailDaemon.h>
#include <MailMessage.h>

namespace {

bool refForPath(const char* path, entry_ref* outRef) {
    BEntry entry(path);
    return entry.InitCheck() == B_OK && entry.GetRef(outRef) == B_OK;
}

} // namespace

extern "C" {

// ---- BEmailMessage ----

void* eb_haiku_email_message_create(void) { return new BEmailMessage(); }

int eb_haiku_email_message_init_check(void* msg) {
    return static_cast<BEmailMessage*>(msg)->InitCheck();
}

void eb_haiku_email_message_set_to(void* msg, const char* to) {
    static_cast<BEmailMessage*>(msg)->SetTo(to);
}

void eb_haiku_email_message_set_from(void* msg, const char* from) {
    static_cast<BEmailMessage*>(msg)->SetFrom(from);
}

void eb_haiku_email_message_set_reply_to(void* msg, const char* replyTo) {
    static_cast<BEmailMessage*>(msg)->SetReplyTo(replyTo);
}

void eb_haiku_email_message_set_cc(void* msg, const char* cc) {
    static_cast<BEmailMessage*>(msg)->SetCC(cc);
}

void eb_haiku_email_message_set_bcc(void* msg, const char* bcc) {
    static_cast<BEmailMessage*>(msg)->SetBCC(bcc);
}

void eb_haiku_email_message_set_subject(void* msg, const char* subject) {
    static_cast<BEmailMessage*>(msg)->SetSubject(subject);
}

void eb_haiku_email_message_set_priority(void* msg, int priority) {
    static_cast<BEmailMessage*>(msg)->SetPriority(priority);
}

void eb_haiku_email_message_set_body_text(void* msg, const char* text) {
    static_cast<BEmailMessage*>(msg)->SetBodyTextTo(text);
}

const char* eb_haiku_email_message_body_text(void* msg) {
    return static_cast<BEmailMessage*>(msg)->BodyText();
}

int eb_haiku_email_message_attach(void* msg, const char* path, int includeAttributes) {
    entry_ref ref;
    if (!refForPath(path, &ref)) return B_ENTRY_NOT_FOUND;
    static_cast<BEmailMessage*>(msg)->Attach(&ref, includeAttributes != 0);
    return B_OK;
}

int eb_haiku_email_message_is_component_attachment(void* msg, int index) {
    return static_cast<BEmailMessage*>(msg)->IsComponentAttachment(index) ? 1 : 0;
}

int eb_haiku_email_message_count_components(void* msg) {
    return static_cast<BEmailMessage*>(msg)->CountComponents();
}

int eb_haiku_email_message_send(void* msg, int sendNow) {
    return static_cast<BEmailMessage*>(msg)->Send(sendNow != 0);
}

void eb_haiku_email_message_destroy(void* msg) { delete static_cast<BEmailMessage*>(msg); }

// ---- BMailDaemon ----

void* eb_haiku_mail_daemon_create(void) { return new BMailDaemon(); }

void eb_haiku_mail_daemon_destroy(void* daemon) { delete static_cast<BMailDaemon*>(daemon); }

int eb_haiku_mail_daemon_is_running(void* daemon) {
    return static_cast<BMailDaemon*>(daemon)->IsRunning() ? 1 : 0;
}

int eb_haiku_mail_daemon_check_mail(void* daemon, int accountID) {
    return static_cast<BMailDaemon*>(daemon)->CheckMail(accountID);
}

int eb_haiku_mail_daemon_check_and_send_queued_mail(void* daemon, int accountID) {
    return static_cast<BMailDaemon*>(daemon)->CheckAndSendQueuedMail(accountID);
}

int eb_haiku_mail_daemon_send_queued_mail(void* daemon) {
    return static_cast<BMailDaemon*>(daemon)->SendQueuedMail();
}

int eb_haiku_mail_daemon_count_new_messages(void* daemon, int waitForFetchCompletion) {
    return static_cast<BMailDaemon*>(daemon)->CountNewMessages(waitForFetchCompletion != 0);
}

int eb_haiku_mail_daemon_mark_as_read(void* daemon, int account, const char* path, int flag) {
    entry_ref ref;
    if (!refForPath(path, &ref)) return B_ENTRY_NOT_FOUND;
    return static_cast<BMailDaemon*>(daemon)->MarkAsRead(account, ref,
                                                          static_cast<read_flags>(flag));
}

int eb_haiku_mail_daemon_quit(void* daemon) { return static_cast<BMailDaemon*>(daemon)->Quit(); }

int eb_haiku_mail_daemon_launch(void* daemon) {
    return static_cast<BMailDaemon*>(daemon)->Launch();
}

} // extern "C"
