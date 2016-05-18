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
contador_low:		.byte	1
contador_high:		.byte	1

	.cseg
	
	rjmp	main

	.org	URXCaddr
	rjmp	uart_rx_complete_isr
	
	.org	UDREaddr
	rjmp	uart_reg_vacio_isr
	

	.org	INT0addr
	rjmp	ISR_INT_EXT_0	; ocurre flanco de bajada en pulsador
	.org	INT1addr
	rjmp	ISR_INT_EXT_1	; ocurre flanco de bajada en pulsador

.org INT_VECTORS_SIZE	; (salteo todos los vectores de int)

ISR_INT_EXT_1:
push r16
in r16,sreg
push r16
lds	r16,contador_low
inc r16
sts contador_low,r16

cpi	r16,0
brne fin_isr
lds r16,contador_high
inc r16
sts contador_high,r16

fin_isr:
	pop r16
	out sreg,r16
	pop r16
	reti


ISR_INT_EXT_0:
	rcall 	delay2
	sbic	pind,2
	reti
	
	in		r18,pinc
	andi	r18,0x3
	cpi		r18,0x1
	breq	cambio_a_azul ;estaba en clear
	cpi		r18,0x2
	breq	cambio_a_verde; estaba en azul
	cpi		r18,0x3 ; estaba en verde
	breq	cambio_a_rojo
	cpi		r18,0	;estaba en rojo
	breq	cambio_a_clear

cambio_a_azul:
	ldiw	Z,(MENSAJE_CAMBIO_A_AZUL*2)
	rcall	tx_string
	cbi		portc,0
	sbi		portc,1
	reti	
cambio_a_verde:
	ldiw	Z,(MENSAJE_CAMBIO_A_VERDE*2)
	rcall	tx_string
	sbi		portc,0
	sbi		portc,1
	reti	
cambio_a_rojo:
	ldiw	Z,(MENSAJE_CAMBIO_A_ROJO*2)
	rcall	tx_string
	cbi		portc,0
	cbi		portc,1
	reti	
cambio_a_clear:
	ldiw	Z,(MENSAJE_CAMBIO_A_BLANCO*2)
	rcall	tx_string
	sbi		portc,0
	cbi		portc,1
	reti	
		


main:		
	ldi 	r16,LOW(RAMEND)
	out 	spl,r16
	ldi 	r16,HIGH(RAMEND)
	out 	sph,r16
	
	cbi		DDRD,PD3 ; int1 entrada
	cbi		DDRD,PD2 ; int0 entrada
	sbi		PORTD,PD2
	sbi		PORTD,PD3

	input	t0,EICRA		; configuro int. ext. 0 x flanco de bajada
	ori		t0,0x10
	output	EICRA,t0		
		
	input	t0,EIMSK
	ori		t0,0x03
	output	EIMSK,t0
		

	sbi		DDRC,PC0
	sbi		DDRC,PC1

	sbi		PORTC,PC0
	cbi		PORTC,PC1	
	
	rcall uart_init
	sei

self:	clr r16
		sts contador_low,r16
		sts contador_high,r16
		rcall delay
		lds r18,contador_low
		lds r19,contador_high
		rcall tx_bcd_number
		ldiw z,(MENSAJE_CR_LF*2)
		rcall tx_string
		rjmp 	self

loop:	sbi	PORTD,PD7
	rcall	delay
	cbi	PORTD,PD7
	rcall 	delay
	
	;ldiw	Z,(MENSAJE_FRECUENCIA*2)
	;rcall	tx_string
	
	;ldi	r18,low(1523)
	;ldi	r19,high(1523)
	rcall	tx_bcd_number
	
	ldiw	Z,(MENSAJE_CR_LF*2)
	rcall	tx_string
	rjmp	loop
	
;************************************************************************************

; Rutinas de comunicacion serie:

.equ	BAUD_RATE = 103	; 9600
	
uart_init:
	outi	UBRR0H, high(BAUD_RATE)
	outi	UBRR0L, low(BAUD_RATE)
	outi	UCSR0B, (1<<RXCIE0)|(1<<RXEN0)|(1<<TXEN0)
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
	
; tx_number: Tansmite un numero del 0 al 9.
; Entrada: r18

tx_number:
	ldi	r16,'0'
	add	r16,r18
	rcall	tx_byte
	ret	
	
	
; tx_bcd_number: Tansmite un numero del 0000 al 9999.
; Entrada: r19:r18

tx_bcd_number:
	rcall	bin_to_bcd
	lds	r18,bcd_unidades_mil
	rcall	tx_number
	lds	r18,bcd_centenas
	rcall	tx_number
	lds	r18,bcd_decenas
	rcall	tx_number
	lds	r18,bcd_unidades
	rcall	tx_number
	ret
	
; Interrupcion De Recepcion:
	
uart_rx_complete_isr:
	push	r16
	lds	r16, UDR0
	; Procesar, el dato esta en el r16.
	rcall	tx_byte	;Hace un eco.
	pop	r16
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
	

delay2:
	
delay2_loop_2:
	ldi		r19,50
delay2_loop_3:
	dec		r19
	brne	delay2_loop_3
	dec		r18
	brne	delay2_loop_2
	ret

;************************************************************************************
	
MENSAJE_FRECUENCIA:	.db	"Frecuencia: ", 0
MENSAJE_CR_LF:		.db	13, 10, 0
MENSAJE_CAMBIO_A_AZUL: .db "Cambio a Azul",13,10,0
MENSAJE_CAMBIO_A_VERDE: .db "Cambio a Verde",13,10,0
MENSAJE_CAMBIO_A_ROJO: .db "Cambio a Rojo",13,10,0
MENSAJE_CAMBIO_A_BLANCO: .db "Cambio a Blanco",13,10,0