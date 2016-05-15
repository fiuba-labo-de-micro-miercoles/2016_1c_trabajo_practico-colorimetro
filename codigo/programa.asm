; Compilar:  avra programa.asm
; Programar: sudo avrdude -c usbtiny -p m328p -U flash:w:programa.hex:i

.include "m328Pdef.inc"

.cseg

main:
	clr	r16
	ldi	r17,(1<<PD7)
	out	PORTD,r16
	out	DDRD,r17
loop:
	ldi	r16,(1<<PD7)
	out	PORTD,r16
	rcall	delay	
	ldi	r16,0
	out	PORTD,r16
	rcall	delay
	rjmp	loop
	
delay:
	ldi	r17,255
delay_loop_1:
	ldi	r18,255
delay_loop_2:
	ldi	r19,50
delay_loop_3:
	dec	r19
	brne	delay_loop_3
	dec	r18
	brne	delay_loop_2
	dec	r17
	brne	delay_loop_1
	ret
