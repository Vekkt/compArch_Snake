.equ HEAD_X,      0x1000 ; snake head's position on x-axis
.equ HEAD_Y,      0x1004 ; snake head's position on y-axis
.equ TAIL_X,      0x1008 ; snake tail's position on x-axis
.equ TAIL_Y,      0x100C ; snake tail's position on y-axis
.equ SCORE,       0x1010 ; score address
.equ GSA,         0x1014 ; game state array
.equ LEDS,        0x2000 ; LED addresses
.equ SEVEN_SEGS,  0x1198 ; 7-segment display addresses
.equ RANDOM_NUM,  0x2010 ; Random number generator address
.equ BUTTONS,     0x2030 ; Button addresses

; BEGIN:main
main:
    call clear_leds
    addi a0, r0, 5
    addi a1, r0, 3
    call set_pixel
    ret
; END:main

; BEGIN:clear_leds
clear_leds:
    stw 0, LEDS (0x0)
    stw 0, LEDS (0x2)
    stw 0, LEDS (0x4)
    stw 0, LEDS (0x6)
    stw 0, LEDS (0x8)
    stw 0, LEDS (0xA)
    ret
; END:clear_leds

; BEGIN:set_pixel
set_pixel:
    addi t0, r0, 1      ; t0 = 1
    sll t0, t0, a1      ; t0 = 1 << y
    ldb t1, LEDS (a0)   ; t1 = MEM[0x2000 + x](7:0)
    or t1, t1, t0       ; t1 = MEM[0x2000 + x](7:0) or (1 << y)
    stb t1, LEDS (a0)   ; MEM[0x2000 + x](7:0) = t1
    ret
; END:set_pixel
