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



updateLedOutput: 

	;PUSHS NECESARIOS
	push r16
	lds r16,sreg ; aca guardo sreg porque no se bien todavia que va a hacer el codigo, si no toco esto lo saco luego
	push r16
	push r17
	;

red:

	lds r16,redFrequency
	cp 	r16,RED_DARK
	brlo	redComponentIsCero
	cp 	r16,RED_WHITE
	brsh	redComponentIsTop
	rjmp	redComponentIsComputed

green:

	lds r16,greenFrequency
	cp 	r16,GREEN_DARK
	brlo	greenComponentIsCero
	cp 	r16,GREEN_WHITE
	brsh	greenComponentIsTop
	rjmp	greenComponentIsComputed


blue:

	lds r16,blueFrequency
	cp 	r16,BLUE_DARK
	brlo	blueComponentIsCero
	cp 	r16,BLUE_WHITE
	brsh	blueComponentIsTop
	rjmp	blueComponentIsComputed


redComponentIsCero:
	ldi	redComponent,0
	rjmp green

greenComponentIsCero:
	ldi	greenComponent,0
	rjmp blue

blueComponentIsCero:
	ldi	blueComponent,0
	rjmp out

redComponentIsTop:
	ldi	redComponent,255
	rjmp green

greenComponentIsTop:
	ldi	greenComponent,255
	rjmp blue

blueComponentIsTop:
	ldi	blueComponent,255
	rjmp out

redComponentIsComputed:
	ldi r17,255
	sub r16,RED_DARK
	mul r16,r17
	mov r19,r1 
	mov r18,r0
	ldi r20,RED_WHITE
	sub r20,RED_DARK
	clr r21
	divide 
	lds	redComponent,r21 ; preguntar a mati, si el lsB esta en r21 o r20. porque lo puso al revez...
	rjmp green

greenComponentIsComputed:
	ldi r17,255
	sub r16,GREEN_DARK
	mul r16,r17
	mov r19,r1 
	mov r18,r0
	ldi r20,GREEN_WHITE
	sub r20,GREEN_DARK
	clr r21
	divide 
	lds	greenComponent,r21 ; preguntar a mati, si el lsB esta en r21 o r20. porque lo puso al revez...
	rjmp blue

blueComponentIsComputed:
	ldi r17,255
	sub r16,BLUE_DARK
	mul r16,r17
	mov r19,r1 
	mov r18,r0
	ldi r20,BLUE_WHITE
	sub r20,BLUE_DARK
	clr r21
	divide 
	lds	blueComponent,r21 ; preguntar a mati, si el lsB esta en r21 o r20. porque lo puso al revez...
	rjmp out 


out: 
	; salida de pwm a leds escribirla...

pull r17
pull sreg
pull r16

ret
  ;************************************************************************************

