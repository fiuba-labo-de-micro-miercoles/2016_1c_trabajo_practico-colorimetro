; Compilar:  avra programa.asm
; Programar: sudo avrdude -c usbtiny -p m328p -U flash:w:programa.hex:i

.include "m328Pdef.inc"
.include "avr_macros.inc"

.def	t0 = r16
.def	t1 = r17

	.dseg

	.cseg
	
	rjmp	main

	.org	URXCaddr
	rjmp	uart_rx_complete_isr
	
	.org	UDREaddr
	rjmp	uart_reg_vacio_isr
	
	.org 	INT_VECTORS_SIZE

main:	ldi 	r16,LOW(RAMEND)
	out 	spl,r16
	ldi 	r16,HIGH(RAMEND)
	out 	sph,r16
	
	cbi	PORTD,PD7
	sbi	DDRD,PD7

	rcall	uart_init

loop:	rcall	transmitir
	sbi	PORTD,PD7
	rcall	delay
	cbi	PORTD,PD7
	rcall 	delay
	rjmp	loop
	
.equ	BAUD_RATE = 103	; 9600
	
uart_init:
	outi	UBRR0H, high(BAUD_RATE)
	outi	UBRR0L, low(BAUD_RATE)
	outi	UCSR0B, (1<<RXEN0)|(1<<TXEN0)
	outi    UCSR0C, (1<<USBS0)|(3<<UCSZ00)
	ret
	
transmitir:
	rcall	esperar_buffer_de_tx_vacio
	ldi	r16, 'A'
	sts	UDR0, r16
	ret
	
esperar_buffer_de_tx_vacio:
	lds	r16, UCSR0A
	sbrs	r16, UDRE0
	rjmp	esperar_buffer_de_tx_vacio
	ret
	
uart_rx_complete_isr:
	reti
	
uart_reg_vacio_isr:
	reti
	
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
