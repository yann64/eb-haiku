' eb-haiku: a binding for Haiku OS's own native (BeAPI) Kits.
'
' Phase 1: Storage Kit (BPath/BEntry/BDirectory/BNode+BNodeInfo), Support
' Kit (BMessage), and BApplication's basic lifecycle - no GUI
' subclassing (BWindow/BView), see this package's own README.
'
' Aggregates the raw FFI layer and every idiomatic wrapper into one
' #include. Consumers only ever #include this file's own generated
' interface (target/eb-haiku.iface.bas, after `ebpm build`).

#include once "raw/haiku_shim.bas"
#include once "path.bas"
#include once "entry.bas"
#include once "directory.bas"
#include once "node.bas"
#include once "message.bas"
#include once "application.bas"
