' eb-haiku: a binding for Haiku OS's own native (BeAPI) Kits.
'
' Phase 1: Storage Kit (BPath/BEntry/BDirectory/BNode+BNodeInfo), Support
' Kit (BMessage), and BApplication's basic lifecycle.
' Phase 2 (in progress): Interface Kit - BWindow/BView, via a real C++
' shim subclass (ShimWindow) forwarding MessageReceived/QuitRequested/
' FrameResized to eBasic callbacks - see this package's own README.
'
' Aggregates the raw FFI layer and every idiomatic wrapper into one
' #include. Consumers only ever #include this file's own generated
' interface (target/eb-haiku.iface.bas, after `ebpm build`).

#include once "raw/haiku_shim.bas"
#include once "raw/haiku_shim_interface.bas"
#include once "raw/haiku_shim_translation.bas"
#include once "raw/haiku_shim_storage.bas"
#include once "path.bas"
#include once "entry.bas"
#include once "directory.bas"
#include once "node.bas"
#include once "message.bas"
#include once "application.bas"
#include once "window.bas"
#include once "view.bas"
#include once "controls.bas"
#include once "layout.bas"
#include once "bitmap.bas"
#include once "file.bas"
#include once "translation.bas"
#include once "symlink.bas"
#include once "volume.bas"
#include once "query.bas"
#include once "locker.bas"
#include once "menu.bas"
#include once "roster.bas"
#include once "clipboard.bas"
#include once "network.bas"
#include once "locale.bas"
#include once "thread.bas"
#include once "serial.bas"
#include once "package.bas"
#include once "media.bas"
#include once "printjob.bas"
