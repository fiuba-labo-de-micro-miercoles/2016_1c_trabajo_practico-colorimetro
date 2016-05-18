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

loop:	ldiw	Z,(MENSAJE*2)	
	rcall	tx_string
	sbi	PORTD,PD7
	rcall	delay
	cbi	PORTD,PD7
	rcall 	delay
	rjmp	loop
	
;************************************************************************************

; Rutinas de comunicacion serie:

.equ	BAUD_RATE = 103	; 9600
	
uart_init:
	outi	UBRR0H, high(BAUD_RATE)
	outi	UBRR0L, low(BAUD_RATE)
	outi	UCSR0B, (1<<RXEN0)|(1<<TXEN0)
	outi    UCSR0C, (1<<USBS0)|(3<<UCSZ00)
	ret

; tx_string: Transmite una cadena hubicada en ROM.
; Entrada: Z: Posicion donde comienza la cadena.	
	
tx_string:
	push	r16
tx_string_loop:
	lpm	r16, Z+
	cpi	r16, 0
	breq	fin_tx_string
	rcall	tx_byte
	rjmp	tx_string_loop
fin_tx_string:
	pop	r16	
	ret
	
; tx_byte: Tansmite un byte.
; Entrada: r16: Byte a transmitir.	
	
tx_byte:
	rcall	esperar_buffer_de_tx_vacio
	sts	UDR0, r16
	ret
	
esperar_buffer_de_tx_vacio:
	push	r16
esperar_buffer_de_tx_vacio_loop:
	lds	r16, UCSR0A
	sbrs	r16, UDRE0
	rjmp	esperar_buffer_de_tx_vacio_loop
	pop	r16
	ret
	
uart_rx_complete_isr:
	reti
	
uart_reg_vacio_isr:
	reti
	
;************************************************************************************
	
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
	
;************************************************************************************
	
MENSAJE:	.db	"hola", 13, 10, 0
