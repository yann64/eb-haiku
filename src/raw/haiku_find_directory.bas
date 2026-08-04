' Raw FFI layer: Haiku's own find_directory() (storage/FindDirectory.h)
' - a genuine, plain extern "C" function (unlike every other Haiku Kit
' class this package binds, which needed a hand-written shim - see
' native/shim.h's own top comment), so it's declared directly here with
' no shim wrapper at all.
'
' This also closes a real, previously-documented gap: linking against
' this package needed `-l be` passed explicitly, since `libbe` is a
' transitive dependency of the shim's own internals, not something any
' `Lib` clause in this package's own .bas source captured. Declaring a
' real, useful function under its own `Lib "be"` clause here means
' `ebpm`'s own `.libs`-sidecar forwarding mechanism now captures `be`
' automatically alongside `ebhaikushim` - fixed as a natural side
' effect of adding a real function, not a workaround.

Extern "C" Lib "be"
    Declare Function find_directory(BYVAL which AS INTEGER, BYVAL volume AS INTEGER, BYVAL createIt AS INTEGER, outBuf AS ANY PTR, BYVAL bufSize AS INTEGER) AS INTEGER
End Extern

' A representative subset of Haiku's real directory_which constants
' (storage/FindDirectory.h) - confirmed against the real enum values on
' the Haiku host, not hand-counted from the header's own entries (most
' of which have explicit jumps, not a plain sequential numbering).
CONST H_USER_DIRECTORY = 3000
CONST H_USER_CONFIG_DIRECTORY = 3001
CONST H_USER_SETTINGS_DIRECTORY = 3006
