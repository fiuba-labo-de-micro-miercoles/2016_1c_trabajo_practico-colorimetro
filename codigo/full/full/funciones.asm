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
	rjmp analog_out_to_leds

redComponentIsTop:
	ldi	redComponent,MAX_COLOR
	rjmp green

greenComponentIsTop:
	ldi	greenComponent,MAX_COLOR
	rjmp blue

blueComponentIsTop:
	ldi	blueComponent,MAX_COLOR
	rjmp analog_out_to_leds

redComponentIsComputed:
	ldi r17,MAX_COLOR
	sub r16,RED_DARK
	mul r16,r17
	mov r19,r1 
	mov r18,r0
	ldi r20,(RED_WHITE-RED_DARK)
	clr r21
	rcall	divide 
	lds	redComponent,r21 ; preguntar a mati, si el lsB esta en r21 o r20. porque lo puso al revez...
	rjmp green

greenComponentIsComputed:
	ldi r17,MAX_COLOR
	sub r16,GREEN_DARK
	mul r16,r17
	mov r19,r1 
	mov r18,r0
	ldi r20,(GREEN_WHITE-GREEN_DARK)
	clr r21
	rcall	divide 
	lds	greenComponent,r21 ; preguntar a mati, si el lsB esta en r21 o r20. porque lo puso al revez...
	rjmp blue

blueComponentIsComputed:
	ldi r17,MAX_COLOR
	sub r16,BLUE_DARK
	mul r16,r17
	mov r19,r1 
	mov r18,r0
	ldi r20,(BLUE_WHITE-BLUE_DARK)
	clr r21
	rcall	divide 
	lds	blueComponent,r21 ; preguntar a mati, si el lsB esta en r21 o r20. porque lo puso al revez...
	rjmp analog_out_to_leds 


analog_out_to_leds: 
	; salida de pwm a leds escribirla...

pull r17
pull sreg
pull r16

ret
  ;************************************************************************************


  ;************************************************************************************


; la funcion recibe S2 y S3 del registro de logica de input del sensor con un registro llamado inputSwitchReg
;
; inputSwitchReg
; bit_reg	|	pin_sensor
----------------------------
; b0		|	S3
; b1		|	S2
; b2-b7		|	X
;
; Entrada: S2, S3, se supone que S2 y S3 son registros que ya fueron asignados con .def antes, y solo poseen este trabajo
;
; Salida: se modifica S2 y S3 de modo de cambiar lo que se esta midiendo
;
;
;truth table
;
; S2| S3| 	MEASURE     | HEXA 
; --------------------------------
; 0 | 0 |	RED 		| 0x00
; 0 | 1 |	BLUE 		| 0x01
; 1 | 0 |	CLEAR 		| 0x02
; 1 | 1 |	GREEN 		| 0x03
;
.equ INPUT_MEASURE_RED =   0x00 
.equ INPUT_MEASURE_BLUE =  0x01
.equ INPUT_MEASURE_CLEAR = 0x02 
.equ INPUT_MEASURE_GREEN = 0x03 

input_switcher:
	cp inputSwitchReg,INPUT_MEASURE_RED
	breq changeToGreen
	cp inputSwitchReg,INPUT_MEASURE_GREEN
	breq changeToBlue
	cp inputSwitchReg,INPUT_MEASURE_BLUE
	breq changeToClear
	rjmp changeToRed

changeToRed:
	sts inputSwitchReg,INPUT_MEASURE_RED
	ret

changeToGreen:
	sts inputSwitchReg,INPUT_MEASURE_GREEN
	ret
changeToBlue:
	sts inputSwitchReg,INPUT_MEASURE_BLUE
	ret
changeToClear:
	sts inputSwitchReg,INPUT_MEASURE_CLEAR
	ret

;************************************************************************************



