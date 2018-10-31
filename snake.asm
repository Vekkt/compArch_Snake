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
    addi t0, r0, LEDS   ; t0 = 0x2000
    stw r0, 0x0 (t0)    ; LED[0] = 0
    stw r0, 0x4 (t0)    ; LED[1] = 0
    stw r0, 0x8 (t0)    ; LED[2] = 0
    ret
; END:clear_leds

; BEGIN:set_pixel
set_pixel:
    addi t0, r0, 1      ; t0 = 1
	andi t2, a0, 7		; t2 = x % 8
    slli t2, t2, 3      ; t2 = x * 8
    add  t2, t2, a1     ; t2 = y + x * 8
    sll  t0, t0, t2     ; t0 = 1 << y
    ldw  t1, LEDS (a0)  ; t1 = MEM[0x2000 + x]
    or   t1, t1, t0     ; t1 = MEM[0x2000 + x] or (1 << y)
    stw  t1, LEDS (a0)  ; MEM[0x2000 + x] = t1
    ret
; END:set_pixel
