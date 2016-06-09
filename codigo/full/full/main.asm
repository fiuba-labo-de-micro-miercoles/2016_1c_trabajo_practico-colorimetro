;************************************************************************************
; Compilar:  avra main.asm
; Programar: sudo avrdude -c usbtiny -p m328p -U flash:w:main.hex:i
;************************************************************************************

.include "m328Pdef.inc"
.include "avr_macros.inc"

;************************************************************************************

.def	t0 = r16
.def	t1 = r17

	.dseg

bcd_unidades_mil:	.byte	1
bcd_centenas:		.byte	1
bcd_decenas:		.byte	1
bcd_unidades:		.byte	1
contador_low:		.byte	1
contador_high:		.byte	1
red_freq_low:		.byte	1
red_freq_high:		.byte	1
green_freq_low:		.byte	1
green_freq_high:	.byte	1
blue_freq_low:		.byte	1
blue_freq_high:		.byte	1
red_duty:		.byte	1
green_duty:		.byte	1
blue_duty:		.byte	1

;contador_pwm_red:	.byte	1
;contador_pwm_green:	.byte	1
;contador_pwm_blue:	.byte	1

;************************************************************************************

	.cseg
	rjmp	main
	
	.org	INT0addr
	rjmp	int_ext_0_isr
	
	.org	INT1addr
	rjmp	int_ext_1_isr
	
	.org	OVF0addr
	rjmp	timer_0_overflow_isr
	
	.org	OVF1addr
	rjmp	timer_1_overflow_isr

	.org	URXCaddr
	rjmp	uart_rx_complete_isr
	
	.org	UDREaddr
	rjmp	uart_reg_vacio_isr

	.org INT_VECTORS_SIZE
	
;************************************************************************************

main:		
	ldi 	r16,LOW(RAMEND)
	out 	spl,r16
	ldi 	r16,HIGH(RAMEND)
	out 	sph,r16
	
	call	ext_int_init	
	call	uart_init
	call	color_switcher_init
	call	led_init
	
	call	enable_interrupts

loop:	clr	r16
	sts	contador_high,r16
	sts	contador_low,r16	
	rcall 	delay
	
	call	compute_color
	call	print_values
	call	switch_color
	
	rjmp	loop
	
enable_interrupts:
	sei
	ret
	
disiable_interrupts:
	cli
	ret
	
;************************************************************************************

.equ	RED_LED_PIN = PD6
.equ	GREEN_LED_PIN = PD5
.equ	BLUE_LED_PIN = PB3
.equ	RED_LED_PORT = PORTD
.equ	GREEN_LED_PORT = PORTD
.equ	BLUE_LED_PORT = PORTB
.equ	RED_LED_DDR = DDRD
.equ	GREEN_LED_DDR = DDRD
.equ	BLUE_LED_DDR = DDRB

.equ	TIMER_PERIOD = 150

led_init:
	cbi	RED_LED_PORT,RED_LED_PIN
	cbi	GREEN_LED_PORT,GREEN_LED_PIN
	cbi	BLUE_LED_PORT,BLUE_LED_PIN
	sbi	RED_LED_DDR,RED_LED_PIN
	sbi	GREEN_LED_DDR,GREEN_LED_PIN
	sbi	BLUE_LED_DDR,BLUE_LED_PIN
	
	;TIMER0
	ldi	r16,(1<<COM0B1)|(1<<COM0B0)|(1<<COM0A1)|(1<<COM0A0)|(1<<WGM02)|(1<<WGM00)
	out	TCCR0A,r16
	
	in	r16,TCCR0B
	andi	r16,~((1<<CS02)|(1<<CS01)|(1<<CS00))
	ori	r16,(1<<CS01)
	out	TCCR0B,r16
	
	clr	r16
	out	OCR0A,r16
	out	OCR0B,r16
	
	lds	r16,TIMSK0
	ori	r16,(1<<TOIE0)
	sts	TIMSK0,r16
	
	;TIMER2
	ldi	r16,(1<<COM2A1)|(1<<COM2A0)|(1<<WGM22)|(1<<WGM20)
	sts	TCCR2A,r16
	
	lds	r16,TCCR2B
	andi	r16,~((1<<CS22)|(1<<CS21)|(1<<CS20))
	ori	r16,(1<<CS21)
	sts	TCCR2B,r16
	
	clr	r16
	sts	OCR2A,r16
	
	lds	r16,TIMSK2
	ori	r16,(1<<TOIE2)
	sts	TIMSK2,r16
	
	ret
	
timer_0_overflow_isr:
	push	r16
	lds	r16,sreg
	push	r16
	
	
	lds	r16,red_duty
	out	OCR0A,r16
	lds	r16,green_duty
	out	OCR0B,r16	
	
	pop	r16
	sts	sreg,r16
	pop	r16
	reti
	
	
timer_1_overflow_isr:
	push	r16
	lds	r16,sreg
	push	r16
	
	lds	r16,blue_duty
	sts	OCR2A,r16	
	
	pop	r16
	sts	sreg,r16
	pop	r16
	reti
	
;************************************************************************************

; S3 | S2 | MEASURE | HEXA
;----+----+---------+------
; 0  | 0  | RED	    | 0x00
; 0  | 1  | CLEAR   | 0x01
; 1  | 0  | BLUE    | 0x02
; 1  | 1  | GREEN   | 0x03

.equ	INPUT_MEASURE_RED	= 0x00
.equ	INPUT_MEASURE_CLEAR	= 0x01  
.equ	INPUT_MEASURE_BLUE	= 0x02
.equ	INPUT_MEASURE_GREEN	= 0x03
.equ	INPUT_MEASURE_MASK	= 0x03

.equ	S2_PIN = PC0
.equ	S3_PIN = PC1
.equ	S_PORT = PORTC
.equ	S_DDR  = DDRC

;*************************************************

color_switcher_init:
	sbi	S_DDR,S2_PIN
	sbi	S_DDR,S3_PIN
	cbi	S_PORT,S2_PIN
	cbi	S_PORT,S3_PIN
	ret
	
;*************************************************

switch_color:
	in	r16,S_PORT
	andi	r16,INPUT_MEASURE_MASK
	cpi	r16,INPUT_MEASURE_RED
	breq	changeToGreen
	cpi	r16,INPUT_MEASURE_GREEN
	breq	changeToBlue
	cpi	r16,INPUT_MEASURE_BLUE
	breq	changeToClear
changeToRed:
	ldi	r16,INPUT_MEASURE_RED
	rjmp	end_switch_color
changeToGreen:
	ldi	r16,INPUT_MEASURE_GREEN
	rjmp	end_switch_color
changeToBlue:
	ldi	r16,INPUT_MEASURE_BLUE
	rjmp	end_switch_color
changeToClear:
	ldi	r16,INPUT_MEASURE_CLEAR
end_switch_color:
	in	r17,S_PORT
	andi	r17,~INPUT_MEASURE_MASK
	or	r16,r17
	out	S_PORT,r16
	
	ret
	
;*************************************************
	
compute_color:		
	in	r16,S_PORT
	andi	r16,INPUT_MEASURE_MASK
	cpi	r16,INPUT_MEASURE_RED
	breq	compute_red
	cpi	r16,INPUT_MEASURE_GREEN
	breq	compute_green
	cpi	r16,INPUT_MEASURE_BLUE
	breq	compute_blue
	rjmp	end_compute_color
compute_red:
	lds	r18,contador_low
	lds	r19,contador_high
	sts	red_freq_low,r18
	sts	red_freq_high,r19
	call	compute_red_duty
	rjmp	end_compute_color
	
compute_green:
	lds	r18,contador_low
	lds	r19,contador_high
	sts	green_freq_low,r18
	sts	green_freq_high,r19
	call	compute_green_duty
	rjmp	end_compute_color
	
compute_blue:
	lds	r18,contador_low
	lds	r19,contador_high
	sts	blue_freq_low,r18
	sts	blue_freq_high,r19
	call	compute_blue_duty
	rjmp	end_compute_color
	
end_compute_color:
	ret
	
;*************************************************

.equ	RED_DARK = 9
.equ 	GREEN_DARK = 7
.equ 	BLUE_DARK = 8

.equ 	RED_WHITE = 60
.equ 	GREEN_WHITE = 40
.equ 	BLUE_WHITE = 90

.equ	MAX_COLOR = 255
	
compute_red_duty:
	lds	r16,red_freq_high
	cpi	r16,0
	brne	max_red_duty
	lds 	r16,red_freq_low
	cpi 	r16,RED_DARK
	brlo	min_red_duty
	cpi 	r16,RED_WHITE
	brsh	max_red_duty
red_duty_proporcional:
	subi	r16,RED_DARK
	ldi	r17,MAX_COLOR
	mul	r16,r17
	mov	r19,r1 
	mov	r18,r0
	ldi	r20,(RED_WHITE-RED_DARK)
	clr	r21
	call	divide 
	sts	red_duty,r20
	ret
max_red_duty:
	ldi	r16,MAX_COLOR
	sts	red_duty,r16
	ret
min_red_duty:
	clr	r16
	sts	red_duty,r16
	ret
	
compute_green_duty:
	lds	r16,green_freq_high
	cpi	r16,0
	brne	max_green_duty
	lds 	r16,green_freq_low
	cpi 	r16,GREEN_DARK
	brlo	min_green_duty
	cpi 	r16,GREEN_WHITE
	brsh	max_green_duty
green_duty_proporcional:
	subi	r16,GREEN_DARK
	ldi	r17,MAX_COLOR
	mul	r16,r17
	mov	r19,r1 
	mov	r18,r0
	ldi	r20,(GREEN_WHITE-GREEN_DARK)
	clr	r21
	call	divide 
	sts	green_duty,r20
	ret
max_green_duty:
	ldi	r16,MAX_COLOR
	sts	green_duty,r16
	ret
min_green_duty:
	clr	r16
	sts	green_duty,r16
	ret

compute_blue_duty:
	lds	r16,blue_freq_high
	cpi	r16,0
	brne	max_blue_duty
	lds 	r16,blue_freq_low
	cpi 	r16,BLUE_DARK
	brlo	min_blue_duty
	cpi 	r16,BLUE_WHITE
	brsh	max_blue_duty
blue_duty_proporcional:
	subi	r16,BLUE_DARK
	ldi	r17,MAX_COLOR
	mul	r16,r17
	mov	r19,r1 
	mov	r18,r0
	ldi	r20,(BLUE_WHITE-BLUE_DARK)
	clr	r21
	call	divide 
	sts	blue_duty,r20
	ret
max_blue_duty:
	ldi	r16,MAX_COLOR
	sts	blue_duty,r16
	ret
min_blue_duty:
	clr	r16
	sts	blue_duty,r16
	ret
	
;*************************************************
	
print_values:
	in	r16,S_PORT
	andi	r16,INPUT_MEASURE_MASK
	cpi	r16,INPUT_MEASURE_CLEAR		;Solo imprime cuando esta midiendo clear, o sea ya midio los otros 3.
	breq	print_freq
	ret
	
print_freq:
	ldiw	Z,(MENSAJE_FREQ*2)
	call	tx_string
	
	ldiw	Z,(MENSAJE_R*2)
	rcall	tx_string
	lds	r18,red_freq_low
	lds	r19,red_freq_high
	call	tx_bcd_number
	
	ldiw	Z,(MENSAJE_G*2)
	rcall	tx_string
	lds	r18,green_freq_low
	lds	r19,green_freq_high
	call	tx_bcd_number
	
	ldiw	Z,(MENSAJE_B*2)
	rcall	tx_string
	lds	r18,blue_freq_low
	lds	r19,blue_freq_high
	call	tx_bcd_number
	
	ldiw	Z,(MENSAJE_DUTY*2)
	call	tx_string
	
	ldiw	Z,(MENSAJE_R*2)
	rcall	tx_string
	lds	r18,red_duty
	clr	r19
	call	tx_bcd_number
	
	ldiw	Z,(MENSAJE_G*2)
	rcall	tx_string
	lds	r18,green_duty
	clr	r19
	call	tx_bcd_number
	
	ldiw	Z,(MENSAJE_B*2)
	rcall	tx_string
	lds	r18,blue_duty
	clr	r19
	call	tx_bcd_number
	
	ldiw	Z,(MENSAJE_CR_LF*2)
	call	tx_string
	ret
	
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
	lds	r16,sreg
	push	r16
	lds	r16, UDR0
	; Procesar, el dato esta en el r16.
	rcall	tx_byte	;Hace un eco.
	pop	r16
	sts	sreg,r16
	pop	r16
	reti
	
uart_reg_vacio_isr:
	reti
	
;************************************************************************************

; Rutina que divide dos numeros de dos bytes:
; Entrada: r19:r18 Numerador.
;	   r21:r20 Denominador.
; Salida:  r21:r20 Division.
;	   r19:r18 Resto.

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
	ldi	r17,2
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
	
MENSAJE_FREQ:		.db	"FREQ ", 0	
MENSAJE_R:		.db	"R: ", 0
MENSAJE_G:		.db	" G: ", 0
MENSAJE_B:		.db	" B: ", 0
MENSAJE_DUTY:		.db	" | DUTY ", 0
MENSAJE_CR_LF:		.db	13, 10, 0

;*************************************************************************************

ext_int_init:
	cbi	DDRD,PD2	;INT0
	cbi	DDRD,PD3	;INT1
	sbi	PORTD,PD2	;Pull Up Activada
	sbi	PORTD,PD3	;Pull Up Activada

	;Ambas con flanco descendente.
	
	ldi	r16,(1<<ISC11)|(0<<ISC10)|(1<<ISC01)|(0<<ISC00)
	output	EICRA,r16		
	ldi	r16,(1<<INT1)|(1<<INT0)
	output	EIMSK,r16
	ret

int_ext_0_isr:
	reti	
		
int_ext_1_isr:
	push	r16
	in	r16,sreg
	push	r16
	lds	r16,contador_low
	inc	r16
	sts	contador_low,r16
	cpi	r16,0
	brne	end_int_ext_1_isr
	;lds	r16,contador_high
	;inc	r16
	;sts	contador_high,r16
	ldi	r16,255
	sts	contador_low,r16
end_int_ext_1_isr:
	pop r16
	out sreg,r16
	pop r16
	reti
	
;*************************************************************************************

