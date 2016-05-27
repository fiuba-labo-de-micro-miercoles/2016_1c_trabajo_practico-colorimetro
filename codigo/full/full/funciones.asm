  ;************************************************************************************

; la funcion recibe redFrequency, greenFrequency, blueFrequency y modifica redComponent, greenComponent, blueComponent
; Entrada: redFrequency, greenFrequency, blueFrequency , redComponent, greenComponent, blueComponent
;
; Salida: se modifica redComponent, greenComponent, blueComponent
; Se encienden leds.	

.equ	RED_DARK = 34
.equ 	GREEN_DARK = 30
.equ 	BLUE_DARK = 40

.equ 	RED_WHITE = 265
.equ 	GREEN_WHITE = 220
.equ 	BLUE_WHITE = 240

.equ	MAX_COLOR = 255



updateLedOutput: 
	push	r0
	push	r1
	push	r16
	push	r17
	push	r18
	push	r19
	push	r20
	push	r21

red:	lds 	r16,redFrequency
	cpi 	r16,RED_DARK
	brlo	redComponentIsCero
	cpi 	r16,RED_WHITE
	brsh	redComponentIsTop
	rjmp	redComponentIsComputed

green:	lds	r16,greenFrequency
	cpi 	r16,GREEN_DARK
	brlo	greenComponentIsCero
	cpi 	r16,GREEN_WHITE
	brsh	greenComponentIsTop
	rjmp	greenComponentIsComputed


blue:	lds	r16,blueFrequency
	cpi 	r16,BLUE_DARK
	brlo	blueComponentIsCero
	cpi 	r16,BLUE_WHITE
	brsh	blueComponentIsTop
	rjmp	blueComponentIsComputed


redComponentIsCero:
	ldi	redComponent,0
	rjmp	green

greenComponentIsCero:
	ldi	greenComponent,0
	rjmp	blue

blueComponentIsCero:
	ldi	blueComponent,0
	rjmp	analog_out_to_leds

redComponentIsTop:
	ldi	redComponent,MAX_COLOR
	rjmp	green

greenComponentIsTop:
	ldi	greenComponent,MAX_COLOR
	rjmp	blue

blueComponentIsTop:
	ldi	blueComponent,MAX_COLOR
	rjmp	analog_out_to_leds

redComponentIsComputed:
	sub	r16,RED_DARK
	ldi	r17,MAX_COLOR
	mul	r16,r17
	mov	r19,r1 
	mov	r18,r0
	ldi	r20,(RED_WHITE-RED_DARK)
	clr	r21
	rcall	divide 
	lds	redComponent,r20
	rjmp	green

greenComponentIsComputed:
	ldi	r17,MAX_COLOR
	sub	r16,GREEN_DARK
	mul	r16,r17
	mov	r19,r1 
	mov	r18,r0
	ldi	r20,(GREEN_WHITE-GREEN_DARK)
	clr	r21
	rcall	divide 
	lds	greenComponent,r20
	rjmp	blue

blueComponentIsComputed:
	ldi	r17,MAX_COLOR
	sub	r16,BLUE_DARK
	mul	r16,r17
	mov	r19,r1 
	mov	r18,r0
	ldi	r20,(BLUE_WHITE-BLUE_DARK)
	clr	r21
	rcall	divide 
	lds	blueComponent,r20
	rjmp	analog_out_to_leds 

analog_out_to_leds: 
	;Se escriben los pwm de los leds.
		
end_update_led_output
	pop	r21
	pop	r20
	pop	r19
	pop	r18
	pop	r17
	pop	r16
	pop	r1
	pop	r0
	ret
	
;************************************************************************************


;************************************************************************************


; La funcion recibe en el r16 la lectura de S3:S2, y devuelve en el r16 sus nuevos valores.
;
; S2| S3| 	MEASURE     	| HEXA 
; --+---+-----------------------+-----
; 0 | 0 |	RED 		| 0x00
; 0 | 1 |	BLUE 		| 0x01
; 1 | 0 |	CLEAR 		| 0x02
; 1 | 1 |	GREEN 		| 0x03
;

.equ	INPUT_MEASURE_RED	= 0x00 
.equ	INPUT_MEASURE_BLUE	= 0x01
.equ	INPUT_MEASURE_CLEAR	= 0x02 
.equ	INPUT_MEASURE_GREEN	= 0x03 
.equ	INPUT_MEASURE_MASK	= 0x03

input_switcher:
	andi	r16,INPUT_MEASURE_MASK
	cpi	r16,INPUT_MEASURE_RED
	breq	changeToGreen
	cpi	r16,INPUT_MEASURE_GREEN
	breq	changeToBlue
	cpi	r16,INPUT_MEASURE_BLUE
	breq	changeToClear
	rjmp	changeToRed
changeToRed:
	ldi	r16,INPUT_MEASURE_RED
	ret
changeToGreen:
	ldi	r16,INPUT_MEASURE_GREEN
	ret
changeToBlue:
	ldi	r16,INPUT_MEASURE_BLUE
	ret
changeToClear:
	ldi	r16,INPUT_MEASURE_CLEAR
	ret

;************************************************************************************

int_ext_0:
	push	r16
	in	r16,sreg
	push	r16
	push	r18
	push	r19
	
	rcall 	delay2	;Antirrebotes
	sbic	pind,2
	rjmp	ex_int_ext_0_isr
	in	r16,PORTX		;INDICAR BIEN EL PUERTO
	;HACER LAS ROTACIONES Y ENMASCARAMIENTOS EN r16 PARA QUE QUEDE 0-0-0-0-0-0-S3-S2
	rcall	input_switcher
	;HACER ROTACIONES Y ENMASCARAMIENTOS PARA Q EL VALOR DE r16 ENCAJE EN EL PUERTO.
	out	PORTX,r16		;IDICAR EL PUERTO

end_int_ext_0_isr:
	pop	r19
	pop	r18
	pop	r16
	out	sreg,r16
	pop	r16
	reti
	
;****************************************
	
int_ext_1:
	push	r16
	in	r16,sreg
	push	r16

	lds	r16,contador_low
	inc	r16
	sts	contador_low,r16
	cpi	r16,0
	brne	end_int_ext_1_isr
	lds	r16,contador_high
	inc	r16
	sts	contador_high,r16
	
end_int_ext_1_isr:
	pop	r16
	out	sreg,r16
	pop	r16
	reti
	
;************************************************************************************

