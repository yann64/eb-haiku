' Raw FFI layer: eb-haiku's Screen Saver Kit shim additions - see
' /home/yann64/git/cpp/eb-haiku/native/shim_screensaver.h.

Extern "C" Lib "ebhaikushim"
    Declare Function eb_haiku_screensaver_create(BYVAL archive AS ANY PTR, BYVAL id AS INTEGER) AS ANY PTR
    Declare Sub eb_haiku_screensaver_set_init_check_callback(BYVAL saver AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_screensaver_set_start_saver_callback(BYVAL saver AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_screensaver_set_stop_saver_callback(BYVAL saver AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_screensaver_set_draw_callback(BYVAL saver AS ANY PTR, BYVAL cb AS ANY PTR, BYVAL userData AS ANY PTR)
    Declare Sub eb_haiku_screensaver_set_tick_size(BYVAL saver AS ANY PTR, BYVAL tickSize AS LONGINT)
    Declare Function eb_haiku_screensaver_tick_size(BYVAL saver AS ANY PTR) AS LONGINT
    Declare Sub eb_haiku_screensaver_set_loop(BYVAL saver AS ANY PTR, BYVAL onCount AS INTEGER, BYVAL offCount AS INTEGER)
    Declare Function eb_haiku_screensaver_loop_on_count(BYVAL saver AS ANY PTR) AS INTEGER
    Declare Function eb_haiku_screensaver_loop_off_count(BYVAL saver AS ANY PTR) AS INTEGER
End Extern
