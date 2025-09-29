; a2_morse.asm
; CSC 230: Fall 2024
;
; Student name: Travis Schaffrick
; Student ID: V01038877
; Date of completed work:
;
; *******************************
; Code provided for Assignment #2
;
; Author: Mike Zastre (2024-Oct-09)
; 
; This skeleton of an assembly-language program is provided to help you
; begin with the programming tasks for A#2. As with A#1, there are 
; "DO NOT TOUCH" sections. You are *not* to modify the lines
; within these sections. The only exceptions are for specific
; changes announced on conneX or in written permission from the course
; instructor. *** Unapproved changes could result in incorrect code
; execution during assignment evaluation, along with an assignment grade
; of zero. ****
;
; I have added for this assignment an additional kind of section
; called "TOUCH CAREFULLY". The intention here is that one or two
; constants can be changed in such a section -- this will be needed
; as you try to test your code on different messages.
;


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

.include "m2560def.inc"

.cseg
.equ S_DDRB=0x24
.equ S_PORTB=0x25
.equ S_DDRL=0x10A
.equ S_PORTL=0x10B

	
.org 0
	; Copy test encoding (of SOS) into SRAM
	;
	;ldi ZH, high(TESTBUFFER)
	;ldi ZL, low(TESTBUFFER)
	;ldi r16, 0x30
	;st Z+, r16
	;ldi r16, 0x37
	;st Z+, r16
	;ldi r16, 0x30
	;st Z+, r16
	;clr r16
	;st Z, r16

	; initialize run-time stack
	ldi r17, high(0x21ff)
	ldi r16, low(0x21ff)
	out SPH, r17
	out SPL, r16

	; initialize LED ports to output
	ldi r17, 0xff
	sts S_DDRB, r17
	sts S_DDRL, r17

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================

; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION **** 
; ***************************************************

	; If you're not yet ready to execute the
	; encoding and flashing, then leave the
	; rjmp in below. Otherwise delete it or
	; comment it out.


    ; The following seven lines are only for testing of your
    ; code in part B (meant to be C?). When you are confident that your part B (meant to be C?)
    ; is working, you can then delete these seven lines. 
	;ldi r17, high(TESTBUFFER)
	;ldi r16, low(TESTBUFFER)
	;push r17
	;push r16
	;rcall flash_message
    ;pop r16
    ;pop r17
	;rjmp stop
   
; ***************************************************
; **** END OF FIRST "STUDENT CODE" SECTION ********** 
; ***************************************************


; ################################################
; #### BEGINNING OF "TOUCH CAREFULLY" SECTION ####
; ################################################

; The only things you can change in this section is
; the message (i.e., MESSAGE01 or MESSAGE02 or MESSAGE03,
; etc., up to MESSAGE09).
;

	; encode a message

	ldi r17, high(MESSAGE02 << 1)
	ldi r16, low(MESSAGE02 << 1)
	push r17
	push r16
	ldi r17, high(BUFFER01)
	ldi r16, low(BUFFER01)
	push r17
	push r16
	rcall encode_message
	pop r16
	pop r16
	pop r16
	pop r16

; ##########################################
; #### END OF "TOUCH CAREFULLY" SECTION ####
; ##########################################


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================
	; display the message three times

	ldi r18, 3
main_loop:
	ldi r17, high(BUFFER01)
	ldi r16, low(BUFFER01)
	push r17
	push r16
	rcall flash_message
	pop r16
	pop r17
	dec r18
	tst r18
	brne main_loop

stop:
	rjmp stop
; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================


; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION **** 
; ****************************************************

flash_message:
    ; Input: character values on the stack
    push r16
	mov r25, r23
    
    ; keep track of how many letters we have left to process
    dec_loop_in_flash:
        tst r25
        breq final_dec
        sbiw X, 1
        dec r25
        rjmp dec_loop_in_flash

    final_dec:
        sbiw X, 1

    morse_flash_loop_in_flash:
        ld r16, X+
        tst r16
        breq flash_message_end
        call morse_flash
        rjmp morse_flash_loop_in_flash

    flash_message_end:
        pop r16
        ret


morse_flash:
    ; Input: binary string in r16 representing what will be shown on LED
    push r17
    push r18
    push r19
    push r20
    push r21

    .def count = r20
    .def morse = r17

    ldi count, 0b11110000 ;bitmask for lower 4 digits
    ldi morse, 0b00001111 ;bitmask for higher 4 digits

    and count, r16
    lsr count
    lsr count
    lsr count
    lsr count
    
    ; handling for if there is a space
    cpi count, 0x0F
    breq space

    and morse, r16

    ; shift morse code so first significant bit is at left
    ldi r21, 4
    sub r21, count

    cpi r21, 0
    breq no_adjust_morse
    morse_shift:
        lsl morse
        dec r21
        cpi r21, 0
        brne morse_shift

    no_adjust_morse:
    ldi r18, 0b1000
    mov r19, r18

    morse_loop:
        and r19, morse
        cpi r19, 0 ; signifies dot
        breq dot
        brne dash
        rjmp end
        dot:
            ldi r16, 6
            call leds_on
            call delay_short
            call leds_off
            call delay_long
            rjmp end
        
        dash:
            ldi r16, 6
            call leds_on
            call delay_long
            call leds_off
            call delay_long
            rjmp end

        space:
            call delay_long
            call delay_long
            call delay_long

            rjmp space_end

        end:
            lsl morse
            mov r19, r18
            dec count
            cpi count, 0
            brne morse_loop

	space_end:
    pop r21
    pop r20
    pop r19
    pop r18
    pop r17
    ret




leds_on:
	; parameters: value in r16 determines how many leds turn on
	; returns nothing

	;set PORTL and PORTB as output
	push r17
	ldi r17, 0xFF
	sts DDRL, r17 ;DDRL Data Direction Register L
	out DDRB, r17
	pop r17

	cpi r16, 1
	breq one_on
	cpi r16, 2
	breq two_on
	cpi r16, 3
	breq three_on
	cpi r16, 4
	breq four_on
	cpi r16, 5
	breq five_on
	cpi r16, 0x06
	breq six_on

	one_on:
		push r16
		ldi r16, 0b00000010
		out PORTB, r16
		pop r16
		ret

	two_on:
		push r16
		ldi r16, 0b00001010
		out PORTB, r16
		pop r16
		ret

	three_on:
		push r16
		ldi r16, 0b00001010
		out PORTB, r16
		ldi r16, 0b00000010
		sts PORTL, r16
		pop r16
		ret

	four_on:
		push r16
		ldi r16, 0b00001010
		out PORTB, r16
		ldi r16, 0b00001010
		sts PORTL, r16
		pop r16
		ret

	five_on:
		push r16
		ldi r16, 0b00001010
		out PORTB, r16
		ldi r16, 0b00101010
		sts PORTL, r16
		pop r16
		ret

	six_on:
		push r16
		ldi r16, 0b00001010
		out PORTB, r16
		ldi r16, 0b10101010
		sts PORTL, r16
		pop r16
		ret




leds_off:
	push r18
	ldi r18, 0
	out PORTB, r18
	sts PORTL, r18
	pop r18
	ret

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;     ENCODE MESSAGE AND LETTER TO CODE
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
encode_message:
    push r17
    push r18
    push r19

    in YH, SPH
    in YL, SPL

    ldd ZH, Y + 10
    ldd ZL, Y + 9  ; message address in Z
    ldd XH, Y + 8
    ldd XL, Y + 7  ; buffer address in X
    
    loop_in_encode:
        lpm r20, Z+
        mov YH, ZH
        mov YL, ZL

        tst r20
        breq add_final_space  ; Jump to add a space

        mov r18, YH
        mov r17, YL

        push r20
        call letter_to_code
        pop r20

        mov YH, r18
        mov YL, r17

		st X+, r0
		mov ZH, YH
		mov ZL, YL

        rjmp loop_in_encode

    add_final_space:
        ; Add space at end of message
        ldi r20, ' '
        push r20
        call letter_to_code
        pop r20
		st X+, r0

    done_encoding_chars:
        clr r0
        st X+, r0
        mov r23, r25

    end_of_encode_message:
        pop r19
        pop r18
        pop r17
        ret


letter_to_code:
    ; takes in one letter from the stack

	; Stack layout after entering letter_to_code:
	; [old value]    <-- Y+6
	; [return addr]  <-- Y+3,4,5  (3 bytes for return address on ATmega2560)
	; [input letter] <-- Y+2
	; [saved r18]    <-- Y+1
	; [saved r19]    <-- Y

    push r18
    push r19

	in YL, SPL
	in YH, SPH

    clr count
    ldi r18, 0b00010000

    ldi ZH, high(ITU_MORSE << 1)
    ldi ZL, low(ITU_MORSE << 1)

    ldd r21, Y+6 ; the letter we're looking for

	clr r0
	clr r19

    ;check for spaces
    cpi r21, ' '
    breq process_space

    letter_loop: 
        lpm r22, Z
        cp r22, r21 ; compare with our target letter
        breq letter_finished
        adiw Z, 8 ; increment pointer by 8 bits
        rjmp letter_loop

    letter_finished:
        adiw Z, 1 ; move to morse code start
        lpm r22, Z

    get_morse_loop:
        cpi r22, 0
        breq final_letter_to_code
        cpi r22, '-'
        breq process_dash
        cpi r22, '.'
        breq process_dot

    process_dash:
        inc r0
        lsl r0
        rjmp reset_loop_letter_to_code

    process_dot:
        lsl r0
        rjmp reset_loop_letter_to_code

    process_space:
        ldi r19, 0xFF ; distinct value for spaces
        add r0, r19
        inc r25
        
		rjmp end_letter_to_code

    reset_loop_letter_to_code:
        inc r19
        adiw Z, 1
        lpm r22, Z
        
		rjmp get_morse_loop

    final_letter_to_code:
        lsl r19
        lsl r19
        lsl r19
        lsl r19

        lsr r0
        add r0, r19
        inc r25

    end_letter_to_code:
        pop r19
        pop r18
        ret

; **********************************************
; **** END OF SECOND "STUDENT CODE" SECTION **** 
; **********************************************


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

delay_long:
	rcall delay
	rcall delay
	rcall delay
	ret

delay_short:
	rcall delay
	ret

; When wanting about a 1/5th of second delay, all other
; code must call this function
;
delay:
	rcall delay_busywait
	ret


; This function is ONLY called from "delay", and
; never directly from other code.
;
delay_busywait:
	push r16
	push r17
	push r18

	ldi r16, 0x08
delay_busywait_loop1:
	dec r16
	breq delay_busywait_exit
	
	ldi r17, 0xff
delay_busywait_loop2:
	dec	r17
	breq delay_busywait_loop1

	ldi r18, 0xff
delay_busywait_loop3:
	dec r18
	breq delay_busywait_loop2
	rjmp delay_busywait_loop3

delay_busywait_exit:
	pop r18
	pop r17
	pop r16
	ret

; if char doesnt match inc pointer by 8
; if character matches inc by 1 to access the morse then 7 to get to next bit
ITU_MORSE: .db "A", ".-", 0, 0, 0, 0, 0
	.db "B", "-...", 0, 0, 0
	.db "C", "-.-.", 0, 0, 0
	.db "D", "-..", 0, 0, 0, 0
	.db "E", ".", 0, 0, 0, 0, 0, 0
	.db "F", "..-.", 0, 0, 0
	.db "G", "--.", 0, 0, 0, 0
	.db "H", "....", 0, 0, 0
	.db "I", "..", 0, 0, 0, 0, 0
	.db "J", ".---", 0, 0, 0
	.db "K", "-.-", 0, 0, 0, 0
	.db "L", ".-..", 0, 0, 0
	.db "M", "--", 0, 0, 0, 0, 0
	.db "N", "-.", 0, 0, 0, 0, 0
	.db "O", "---", 0, 0, 0, 0
	.db "P", ".--.", 0, 0, 0
	.db "Q", "--.-", 0, 0, 0
	.db "R", ".-.", 0, 0, 0, 0
	.db "S", "...", 0, 0, 0, 0
	.db "T", "-", 0, 0, 0, 0, 0, 0
	.db "U", "..-", 0, 0, 0, 0
	.db "V", "...-", 0, 0, 0
	.db "W", ".--", 0, 0, 0, 0
	.db "X", "-..-", 0, 0, 0
	.db "Y", "-.--", 0, 0, 0
	.db "Z", "--..", 0, 0, 0
	.db 0, 0, 0, 0, 0, 0, 0, 0

MESSAGE01: .db "A A A", 0
MESSAGE02: .db "BOOBS", 0
MESSAGE03: .db "A BOX", 0
MESSAGE04: .db "DAIRY QUEEN", 0
MESSAGE05: .db "THE SHAPE OF WATER", 0, 0
MESSAGE06: .db "DEADPOOL AND WOLVERINE", 0, 0
MESSAGE07: .db "EVERYTHING EVERYWHERE ALL AT ONCE", 0
MESSAGE08: .db "O CANADA TERRE DE NOS AIEUX", 0
MESSAGE09: .db "HARD TO SWALLOW PILLS", 0

; First message ever sent by Morse code (in 1844)
MESSAGE10: .db "WHAT GOD HATH WROUGHT", 0


.dseg
BUFFER01: .byte 128
BUFFER02: .byte 128
TESTBUFFER: .byte 4

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================
