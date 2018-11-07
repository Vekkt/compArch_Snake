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
.equ EDGE_CAPT,   0x2034 ; Falling edge detection address

; BEGIN:main
main:
    addi sp, r0, LEDS  ; initi sp
    call clear_leds ; clear screen

    addi t6, r0, 1
    addi t3, r0, 0
    stw  t6, GSA (t3)
    addi t3, r0, 136
    stw  t6, GSA (t3)
    addi t3, r0, 172
    stw  t6, GSA (t3)
    addi t3, r0, 208
    stw  t6, GSA (t3)
    addi t3, r0, 244
    stw  t6, GSA (t3)
    
    call draw_array
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
    ; compute position
    addi t0, r0, 1      ; t0 = 1
	andi t2, a0, 7		; t2 = x % 8
    slli t2, t2, 3      ; t2 = x * 8
    add  t2, t2, a1     ; t2 = y + x * 8

    sll  t0, t0, t2     ; t0 = 1 << t2
    ldw  t1, LEDS (a0)  ; t1 = MEM[LEDS + x]
    or   t1, t1, t0     ; t1 = MEM[LEDS + x] or (1 << t2)
    stw  t1, LEDS (a0)  ; MEM[LEDS + x] = t1
    ret
; END:set_pixel

; BEGIN:get_input
get_input:
    addi t0, r0, EDGE_CAPT  ; t0 = edgecapture
    andi t0, t0, 31         ; t0 = edgecapture[0:5]
    beq  t0, r0, return     ; button pressed ? if no end
    addi t4, r0, 1          ; position tester (= 1)
    add  t6, r0, r0         ; position (= 0)
index:
    and  t5, t4, t0         ; t5 = t4 & t0
    bne  t5, r0, update     ; if t5 != 0 we found the index
    slli t4, t4, 1          ; else shift t4 by 1 to the left
    addi t6, t6, 1          ; and incr pos
    br   index
update:
    addi t1, r0, HEAD_X     ; t1 = head_x
    addi t2, r0, HEAD_Y     ; t2 = head_y
    slli t3, t1, 3          ; t3 = x * 8
    add  t3, t3, t2         ; t3 = x * 8 + y
    slli t3, t3, 2          ; t3 = t3 * 4
    stw  t6, GSA (t3)       ; MEM[GSA + t3] = t0
return:
    ret
; END:get_input

; BEGIN:draw_array
draw_array:
    add  t3, r0, r0         ; t3 = x
    add  t4, r0, r0         ; t4 = y
    addi t5, r0, 12         ; max x = 12
    addi t6, r0, 8          ; max y = 8
lpx:
    beq t3, t5, end_lpx     ; if x == 12 break
    add t4, r0, r0          ; t4 = y = 0
lpy:
    beq t4, t6, end_lpy     ; if y == 8 break

    ; save position
    addi sp, sp, -12        ; make space on stack
	stw  ra, 8 (sp)			; push ra
    stw  t3, 4 (sp)         ; push t3
    stw  t4, 0 (sp)         ; push t4

    ; set args
    add  a0, t3, r0         ; put t3 in a0
    add  a1, t4, r0         ; put t4 in a1

    ; compute address shift
    slli t0, t3, 3     		; t0 = x * 8
    add  t0, t0, t4     	; t0 = y + x * 8
	slli t0, t0, 2          ; t0 = t0 * 4
	addi t0, t0, GSA        ; t0 = GSA + t0

    ; get LED value
    ldw  t0, 0 (t0)         ; t0 = GSA[x][y]
	andi t0, t0, 15	        ; take the first 8 bits
    beq t0, r0, next        ; if GSA[x][y] == 0 then dont set_pixel
    call set_pixel          ; else draw the pixel
next:
    ; retrieve old values
	ldw ra, 8 (sp)          ; pop the return address
    ldw t3, 4 (sp)          ; pop x into t3
    ldw t4, 0 (sp)          ; pop y into t4
    addi sp, sp, 12         ; hand back space on stack

    addi t4, t4, 1          ; incr y
    br lpy                  ; loop on y coordinate
end_lpy:
    addi t3, t3, 1          ; incr x
    br lpx                  ; loop on x coordinate
end_lpx:
    ret
; END:draw_array