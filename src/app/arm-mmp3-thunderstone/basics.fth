\ Load file for application-specific Forth extensions

: alloc-mem  drop 0  ;  : free-mem 2drop  ;

: basic-setup ;
\ fl clockset.fth

fl initdram.fth

: wljoin  ( w w -- l )  d# 16 lshift or  ;
: third  ( a b c -- a b c a )  2 pick  ;

[ifdef] INCLUDE-DISPLAY
fl ../arm-mmp2/lcd.fth
fl lcdcfg.fth
[then]

: short-delay ;

fl ../arm-xo-1.75/ccalls.fth
fl ../arm-xo-1.75/banner.fth

: enable-interrupts  ( -- )  psr@ h# 80 invert and psr!  ;
: disable-interrupts  ( -- )  psr@ h# 80 or psr!  ;

[ifdef] use_mmp2_keypad_control
fl ../arm-mmp2/keypad.fth
[then]

\ Thunderstone
: early-activate-cforth?  true  ;
false constant activate-cforth?
false constant show-fb?

false value fb-shown?
h# 8009.1100 constant fb-on-value

: show-fb ;
: ?visible ;

: init-drivers
   banner
   basic-setup
   init-timers
   enable-wdt-clock
   set-gpio-directions
   init-mfprs

[ifdef] use_mmp2_keypad_control
   keypad-on
   8 keypad-direct-mode
[then]
;
