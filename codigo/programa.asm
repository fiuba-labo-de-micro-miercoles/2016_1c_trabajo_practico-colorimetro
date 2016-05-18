; Compilar:  avra programa.asm
; Programar: sudo avrdude -c usbtiny -p m328p -U flash:w:programa.hex:i

.include "m328Pdef.inc"
.include "avr_macros.inc"

.def	t0 = r16
.def	t1 = r17

	.dseg

bcd_unidades_mil:	.byte	1
bcd_centenas:		.byte	1
bcd_decenas:		.byte	1
bcd_unidades:		.byte	1

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

loop:	sbi	PORTD,PD7
	rcall	delay
	cbi	PORTD,PD7
	rcall 	delay
	
	ldi	r18, low(3512)
	ldi	r19, high(3512)
	rcall	bin_to_bcd
	lds	r16,bcd_unidades_mil
	cpi	r16,3
	brne	division_fallida
	
	lds	r16,bcd_centenas
	cpi	r16,5
	brne	division_fallida
	
	lds	r16,bcd_decenas
	cpi	r16,1
	brne	division_fallida
	
	lds	r16,bcd_unidades
	cpi	r16,2
	brne	division_fallida
	
division_exitosa:
	ldiw	Z,(MENSAJE_DIVISION_EXITOSA*2)
	rcall	tx_string
	rjmp	loop

division_fallida:
	ldiw	Z,(MENSAJE_DIVISION_FALLIDA*2)
	rcall	tx_string
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

; Rutina que divide dos numeros de dos bytes:
; Entrada: r19:r18 Numerador.
;	   r21:r20 Denominador.
; Salida:  r20,r21 Division.
;	   r19,r18 Resto.

divide:	push	r16
	push	r17
	clr	r16
	clr	r17
divide_loop:
	cp	r19,r21
	brlo	divide_end
	brne	substract
	cp	r18,r20
	brlo	divide_end
substract:
	sub	r18,r20
	sbc	r19,r21
	inc	r16
	cpi	r16,0
	brne	divide_loop
	inc	r17
	rjmp	divide_loop
divide_end:
	mov	r20,r16
	mov	r21,r17
	pop	r17
	pop	r16
	ret

;************************************************************************************

; bin_to_bcd: Rutina que convierte un numero binario en BCD.
; Entrada: r19:r18.
; Salida: bcd_unidades_mil
;	  bcd_centenas
;	  bcd_decenas
;	  bcd_unidades

bin_to_bcd:
	
	ldi	r20,low(1000)
	ldi	r21,high(1000)
	rcall	divide
	sts	bcd_unidades_mil, r20
	
	ldi	r20,low(100)
	ldi	r21,high(100)
	rcall	divide
	sts	bcd_centenas, r20
	
	ldi	r20,low(10)
	ldi	r21,high(10)
	rcall	divide
	sts	bcd_decenas, r20
	
	sts	bcd_unidades, r18
	
	ret

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
	
MENSAJE_DIVISION_FALLIDA:	.db	"mal", 13, 10, 0
MENSAJE_DIVISION_EXITOSA:	.db	"bien", 13, 10, 0
