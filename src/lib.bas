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
