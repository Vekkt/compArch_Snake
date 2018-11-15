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
    addi sp, r0, LEDS       ; initi sp

    ; init snake
    stw  r0, HEAD_X (r0)    ; snake head x = 0
    stw  r0, HEAD_Y (r0)    ; snake head y = 0
    stw  r0, TAIL_X (r0)    ; snake tail x = 0
    stw  r0, TAIL_Y (r0)    ; snake tail y = 0
    addi t0, r0, 4          ; t0 = 4
    stw  t0, GSA (r0)       ; GSA[0][0] = 4

	call create_food        ; create apple
    call draw_array         ; draw board
    call display_score

step:
    call clear_leds     	; clear screen
    call get_input      	; button pressed
	call hit_test			; check for collision
	addi t0, r0, 2			; t0 = 2
	bne  v0, t0, not_lost	; if v0 != 2, game continues
	addi ra, r0, end_game	; ra = end_game
	br end_game
not_lost:
	beq v0, r0, move		; if v0 = 0, move
	call create_food		; else (v0 = 1) create apple
    ldw t0, SCORE (r0)      ; t0 = score
    addi t0, t0, 1          ; t0 = score + 1
    stw t0, SCORE (r0)      ; MEM[SCORE] = score + 1
    call display_score
move:
	add a0, r0, v0 			; a0 = v0
    call move_snake     	; change direction
    call draw_array     	; draw board
	call wait
	call restart_game
    br step             	; cycle
end_game:
	call restart_game
	ret
; END:main

; BEGIN: wait
wait:
	addi t0, r0, 32767
decr:
	addi t0, t0, -1
	bne t0, r0, decr
	ret
; END:wait

; BEGIN:clear_leds
clear_leds:
    addi t0, r0, LEDS   	; t0 = 0x2000
    stw r0, 0x0 (t0)    	; LED[0] = 0
    stw r0, 0x4 (t0)    	; LED[1] = 0
    stw r0, 0x8 (t0)    	; LED[2] = 0
    ret
; END:clear_leds

; BEGIN:create_food
create_food:
    ; get random pos
    ldw  t0, RANDOM_NUM (r0)    ; t0 = random pos
    andi t0, t0, 255            ; t0 = low byte of t0

    ; check pos validity
    addi t1, r0, 96             ; t1 = 96
    bge  t0, t1, create_food    ; if t0 >= 96: invalid pos

    slli t1, t0, 2              ; t1 = t0 * 4
    ldw  t1, GSA (t1)           ; t1 = MEM[GSA + t1]
    bne  t1, r0, create_food    ; if t1 != 0: invalid pos

    ; create food
    slli t0, t0, 2              ; t0 = t0 * 4
    addi t1, r0, 5              ; t1 = 5
    stw  t1, GSA (t0)           ; MEM[GSA + t0] = 5
    ret
; END:create_food

; BEGIN:set_pixel
set_pixel:
    ; compute position
    addi t0, r0, 1      ; t0 = 1
    andi t2, a0, 7      ; t2 = x % 8
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
    ldw  t0, EDGE_CAPT (r0) ; t0 = edge_capture
    andi t0, t0, 31         ; t0 = edgecapture[0:5]
    beq  t0, r0, return     ; button pressed ? if no end
    stw  r0, EDGE_CAPT (r0) ; reset edge capture
    addi t4, r0, 1          ; position tester (= 1)
    addi t6, r0, 1          ; position (= 1)
index:
    and  t5, t4, t0         ; t5 = t4 & t0
    bne  t5, r0, set        ; if t5 != 0 we found the index
    slli t4, t4, 1          ; else shift t4 by 1 to the left
    addi t6, t6, 1          ; and incr pos
    br   index
set:
    ldw  t1, HEAD_X (r0)    ; t1 = head_x
    ldw  t2, HEAD_Y (r0)    ; t2 = head_y
    slli t3, t1, 3          ; t3 = x * 8
    add  t3, t3, t2         ; t3 = x * 8 + y
    slli t3, t3, 2          ; t3 = t3 * 4
    stw  t6, GSA (t3)       ; MEM[GSA + t3] = t6
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
    stw  ra, 8 (sp)         ; push ra
    stw  t3, 4 (sp)         ; push t3
    stw  t4, 0 (sp)         ; push t4

    ; set args
    add  a0, t3, r0         ; put t3 in a0
    add  a1, t4, r0         ; put t4 in a1

    ; compute address shift
    slli t0, t3, 3          ; t0 = x * 8
    add  t0, t0, t4         ; t0 = y + x * 8
    slli t0, t0, 2          ; t0 = t0 * 4
    addi t0, t0, GSA        ; t0 = GSA + t0

    ; get LED value
    ldw  t0, 0 (t0)         ; t0 = GSA[x][y]
    andi t0, t0, 15         ; take the first 8 bits
    beq t0, r0, pass        ; if GSA[x][y] == 0 then dont set_pixel
    call set_pixel          ; else draw the pixel
pass:
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

; BEGIN:move_snake
move_snake:
	add t7, r0, a0

	; update head
    addi a0, r0, HEAD_X     ; a0 = head_x
    addi a1, r0, HEAD_Y     ; a1 = head_y
	addi a2, r0, 0    		; a2 = 0 (head)
	addi sp, sp, -4         ; make space on stack
	stw  ra, 0 (sp)			; push ra
    call update				; update head position
	ldw ra, 0 (sp)          ; pop the return address
	addi sp, sp, 4          ; hand back space on stack

    ; update tail
	bne  t7, r0, end_move
    addi a0, r0, TAIL_X     ; a0 = tail_x
    addi a1, r0, TAIL_Y     ; a1 = tail_y
	addi a2, r0, 1    		; a2 = 1 (tail)
	addi sp, sp, -4         ; make space on stack
	stw  ra, 0 (sp)			; push ra
    call update				; update tail position
	ldw ra, 0 (sp)          ; pop the return address
	addi sp, sp, 4          ; hand back space on stack
end_move:
	ret

update:
    ldw t1, 0 (a0)    		; get x pos
    ldw t2, 0 (a1)    		; get y pos

    ; compute LED address
    slli t0, t1, 3     		; t0 = x * 8
    add  t0, t0, t2     	; t0 = y + x * 8
	slli t0, t0, 2          ; t0 = t0 * 4
	addi t0, t0, GSA        ; t0 = GSA + t0
	
    ; get LED value
    ldw  t4, 0 (t0)         ; t4 = GSA[x][y]
	andi t4, t4, 15	        ; take the first 8 bits

	beq a2, r0, start_move	; need to delete tail if head
	stw	r0, 0 (t0)			; clear tail
start_move:
    ;compute x offset
    cmpeqi t3, t4, 4        ; if t4 = 4 then x_os = 1
	addi t5, r0, 1			; t5 = 1
    bne  t4, t5, update_x   ; if t4 = 1 then
    addi t3, r0, -1         ; x_os = -1
update_x:
    add  t1, t1, t3         ; x = x + x_os
    
    ;compute y offset
    cmpeqi t3, t4, 3        ; if t4 = 3 then y_os = 1
	addi t5, r0, 2			; t5 = 2
    bne  t4, t5, update_y   ; if t4 = 2 then
    addi t3, r0, -1         ; y_os = -1
update_y:
    add  t2, t2, t3         ; y = y + y_os

    stw t1, 0 (a0)          ; update x
    stw t2, 0 (a1)          ; update y
	
	bne a2, r0, end_update	; if tail, finish

    ; compute new LED address
    slli t0, t1, 3     		; t0 = x * 8
    add  t0, t0, t2     	; t0 = y + x * 8
	slli t0, t0, 2          ; t0 = t0 * 4
	addi t0, t0, GSA        ; t0 = GSA + t0

    stw  t4, 0 (t0)         ; MEM[x][y] = t4
end_update:
    ret
; END:move_snake

; BEGIN: hit_test
hit_test:
    ldw t1, HEAD_X (r0)    	; get x pos
    ldw t2, HEAD_Y (r0)    	; get y pos

    ; compute LED address
    slli t0, t1, 3     		; t0 = x * 8
    add  t0, t0, t2     	; t0 = y + x * 8
	slli t0, t0, 2          ; t0 = t0 * 4
	addi t0, t0, GSA        ; t0 = GSA + t0
	
    ; get LED value
    ldw  t4, 0 (t0)         ; t4 = GSA[x][y]
	andi t4, t4, 15	        ; take the first 8 bits

    ;compute x offset
    cmpeqi t3, t4, 4        ; if t4 = 4 then x_os = 1
	addi t5, r0, 1			; t5 = 1
    bne  t4, t5, upd_x      ; if t4 = 1 then
    addi t3, r0, -1         ; x_os = -1
upd_x:
    add  t1, t1, t3         ; x = x + x_os
    
    ;compute y offset
    cmpeqi t3, t4, 3        ; if t4 = 3 then y_os = 1
	addi t5, r0, 2			; t5 = 2
    bne  t4, t5, upd_y      ; if t4 = 2 then
    addi t3, r0, -1         ; y_os = -1
upd_y:
    add  t2, t2, t3         ; y = y + y_os

    cmpgeui t3, t1, 12		; t0 = 1 if x >= 12
	cmpgeui t4, t2, 8		; t1 = 1 if y >= 8
	or t3, t3, t4			; t0 = t0 || t1
	
    addi v0, r0, 2          ; v0 = 2 by default
	bne t3, r0, end_hit		; if out of bounds, end game

    ; compute LED address
    slli t0, t1, 3     		; t0 = x * 8
    add  t0, t0, t2     	; t0 = y + x * 8
	slli t0, t0, 2          ; t0 = t0 * 4

    ldw t0, GSA (t0)        ; t0 = MEM[GSA + t0]
    cmpeqi v0, t0, 5        ; v0 = 1 if we head on an element
end_hit:
    ret
; END:hit_test

; BEGIN:display_score
display_score:
    ldw t0, SCORE (r0)      ; t0 = MEM[SCORE]
    add t1, r0, r0          ; t1 = 0
    addi t2, r0, 10         ; t2 = 0
split:
    blt t0, t2, display     ; if t0 < 10 display score
    addi t0, t0, -10        ; else t0 = t0 - 10
    addi t1, t1, 1          ; t1 = t1 + 1
    br split                ; loop
display:
	slli t0, t0, 2          ; t0 = t0 * 4
	slli t1, t1, 2          ; t1 = t1 * 4
	addi t3, r0, 4          ; t3 = 4
	ldw t0, font_data (t0)  ; translate value
	ldw t1, font_data (t1)  ; translate value
    stw t0, SEVEN_SEGS (r0) ; MEM[SEVEN_SEGS] = score % 10
    stw t1, SEVEN_SEGS (t3) ; MEM[SEVEN_SEGS + 4] = score / 10
    ret
; END:display_score

; BEGIN:restart_game
restart_game:
    ldw  t0, EDGE_CAPT (r0) ; t0 = edge_capture
    andi t0, t0, 31         ; t0 = edgecapture[0:5]
	addi t4, r0, 1			; position tester (= 1)
    slli t4, t4, 5          ; position tester (= 32)
	and  t4, t4, t0			; t4 = t0 & t4
	or   t4, t4, v0			; t4 = t4 | v0
    addi t0, r0, 2          ; t0 = 2
	blt  t4, t0, end_reset  ; if not reset and not lose, continue
    stw  r0, EDGE_CAPT (r0) ; reset edge capture

    ; reset score and display
	addi t0, r0, 4          ; t0 = 4
	stw r0, SCORE (r0)      ; MEM[SCORE] = 0
	stw r0, SEVEN_SEGS (r0) ; MEM[SEVEN_SEGS] = 0
	stw r0, SEVEN_SEGS (t0) ; MEM[SEVEN_SEGS + 4] = 0

    ; reset GSA
    add  t3, r0, r0         ; t3 = x
    add  t4, r0, r0         ; t4 = y
    addi t5, r0, 12         ; max x = 12
    addi t6, r0, 8          ; max y = 8
lpx_r:
    beq t3, t5, end_lpx_r   ; if x == 12 break
    add t4, r0, r0          ; t4 = y = 0
lpy_r:
    beq t4, t6, end_lpy_r   ; if y == 8 break
	
    ; compute address shift
    slli t0, t3, 3          ; t0 = x * 8
    add  t0, t0, t4         ; t0 = y + x * 8
    slli t0, t0, 2          ; t0 = t0 * 4
    stw  r0, GSA (t0)       ; reset LED value

    addi t4, t4, 1          ; incr y
    br lpy_r                ; loop on y coordinate
end_lpy_r:
    addi t3, t3, 1          ; incr x
    br lpx_r                ; loop on x coordinate
end_lpx_r:
	addi ra, r0, main
end_reset:
    ret
; END:restart_game

font_data:
	.word 0xFC ; 0
	.word 0x60 ; 1
	.word 0xDA ; 2
	.word 0xF2 ; 3
	.word 0x66 ; 4
	.word 0xB6 ; 5
	.word 0xBE ; 6
	.word 0xE0 ; 7
	.word 0xFE ; 8
	.word 0xF6 ; 9