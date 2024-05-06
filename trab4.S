; Ficheiro:  Trabalho 4
; Descricao: Programa para realizar testes de reação.
;            
; Autor: Lucas Silva e Gonçalo Almeida
; Data:      31-05-2023

; Definicao dos valores dos simbolos utilizados no programa
;
	.equ	STACK_SIZE, 64                ; Dimensao do stack - 64 B
; *** Para completar ***
	.equ	INPORT_ADDRESS, 0xFF80       
	.equ	OUTPORT_ADDRESS, 0xFFC0       
	.equ	SYSCLK_FREQ, 0x0A ; 10hz
	
	.equ 	PTC_ADDRESS, 0xFF00
	.equ	PTC_TCR, 0                    ; Deslocamento do registo TCR do pTC
	.equ	PTC_TMR, 2                    ; Deslocamento do registo TMR do pTC
	.equ	PTC_TC,  4                    ; Deslocamento do registo TC do pTC
	.equ	PTC_TIR, 6                    ; Deslocamento do registo TIR do pTC

	.equ	PTC_CMD_START, 0              ; Comando para iniciar a contagem no pTC
	.equ	PTC_CMD_STOP, 1               ; Comando para parar a contagem no pTC
	.equ	CPSR_BIT_I, 0x10
; Seccao:    startup
; Descricao: Guarda o código de arranque do sistema
;
	.section startup
	b	_start
	ldr	pc, isr_addr
_start:
	ldr	sp, tos_addr
	ldr	pc, main_addr

tos_addr:
	.word	tos
main_addr:
	.word	main
isr_addr:
	.word	isr

; Seccao:    text
; Descricao: Guarda o código do programa
;
	.text

; Rotina:    main
; Descricao: 
; Entradas:  
; Saidas:  
; Efeitos:   
main:
start_time:
	mov	r0, #SYSCLK_FREQ ;START TIME & INTERRUPTIONS
	bl	ptc_init
	mrs	r0, cpsr
	mov	r1, #CPSR_BIT_I
	orr	r0, r0, r1 
	msr	cpsr, r0	
while1:
	MOV R4, #0
	MOV R5, #0
	MOV R3, #0
	mov R6, #0	
	MOV R0, #0xFF
	BL outport_write	;Colocar todos os LED's a 1
	BL inport_read		;Analisar o bit user
	LSL R0, R0, #15		
	LSR R0, R0, #15		
	CMP R0, R6			;Caso o bit user esteja a 0 mantém dentro do While
	BEQ while1 	
	ldr	r0, sysclk_addr_addr
	MOV R7, #0
	str r7, [r0, #0]
	MOV R0, #0x01
	BL outport_write	;Deixar ligado apenas o LED do estimulo
while2:
	BL inport_read		;Analisar o bit user
	LSL R0, R0, #15
	LSR R0, R0, #15
	CMP R0, R6			;Caso o bit user seja colocado a 0 retorna ao ciclo anterior
	BEQ while1  
	BL inport_read		;Analisar os bits time
	LSL R0, R0, #8 
	LSR R0, R0, #12 	;Analise dos Bits correspondentes a variavel time
	LDR R3, waittime_addr  ; Array de bytes: 1|2|3|4|5|6|7|8|9|10|...|10
	LDRB r0, [r3, r0]
	LDR r4, sysclk_addr
	ldr	r7, [r4, #0]
	CMP R7, R0			;Aguarda o número de segundos colocados na variavel waittime, caso o nosso contador seja menor, permanece no loop
	BLO while2
	MOV R0, #0			
	BL outport_write	;Desligar todos os LED's
	MOV R5, #0
	ldr	r0, sysclk_addr
	ldr	r7, [r0, #0]
	MOV R7, #0
	str r7, [r0, #0]	;Reset na variavel contadora
while3:	;Este ciclo vai aguardar o bit user ser colocado a 0
	BL inport_read
	LSL R0, R0, #15
	LSR R0, R0, #15
	CMP R0, R5
	BNE while3
resultado:
	LDR r4, sysclk_addr
	ldr	r7, [r4, #0]
	MOV R0, R7
	MOV R5, #0x3F	;Valor máximo de reação
	CMP r0, r5		;Verifica se não ultrapassou o tempo máximo, caso não tenha passado faz um branch para print_resultado
	BLO print_resultado
	MOV r0, #0x60 ;-64 com um logic shift à direita
print_resultado:	
	LSL r0, r0, #1
	BL outport_write		;Liga os led's correspondentes ao tempo demorado a responder ao estimulo de reação em segundos
	ldr	r0, sysclk_addr
	ldr	r7, [r0, #0]
	MOV R7, #0	
	str r7, [r0, #0]		;Reset na variavel contadora
	mov r0, #SYSCLK_FREQ
	bl	ptc_init
LOOP_END:					;Aguarda 5 segundos e volta ao Loop inicial
	LDR R3, waittime_addr  ;1|2|3|4|5|6|7|8|9|10|...|10
	LDRB r0, [r3, #4]
	LDR r4, sysclk_addr
	ldr	r7, [r4, #0]
	CMP R7, R0
	BLO LOOP_END
	B start_time

sysclk_addr_addr:
	.word sysclk
; Rotina:    inport_read
; Descricao: Guarda em R0 os conteudos inseridos no Porto de entrada ; not sure
; Entradas:  -
; Saidas:    r0 - *** Para completar ***
; Efeitos:   r1 - *** Para completar ***
inport_read:
	ldr	r1, inport_addr
	ldrb	r0, [r1, #0]
	mov	pc, lr

inport_addr:
	.word	INPORT_ADDRESS


; Rotina:    outport_write
; Descricao: Guarda em R0 os conteudos inseridos no Porto de saida ; not sure
; Entradas:  r0 - *** Para completar ***
; Saidas:    -
; Efeitos:   r1 - *** Para completar ***
outport_write:
	ldr	r1, outport_addr
	strb	r0, [r1, #0]
	mov	pc, lr

outport_addr:
	.word	OUTPORT_ADDRESS

isr:
	push	r0
	push	r1
	ldr	r0, PTC_ADDR
	strb r2, [r0, #PTC_TIR]
	ldr	r0, sysclk_addr
	ldr	r1, [r0, #0]
	add	r1, r1, #1
	str r1, [r0, #0]
	pop	r1
	pop	r0
	movs	pc, lr

sysclk_addr:
	.word sysclk

waittime_addr:
	.word waittime
;ROTINAS: PTC

;Rotina: PTC_START
ptc_start:
	ldr	r0, PTC_ADDR
	mov	r1, #PTC_CMD_START
	strb	r1, [r0, #PTC_TCR]
	mov	pc, lr

; Rotina:    ptc_stop
ptc_stop:
	ldr	r0, PTC_ADDR
	mov	r1, #PTC_CMD_STOP
	strb	r1, [r0, #PTC_TCR]
	mov	pc, lr

; Rotina:    ptc_get_value
ptc_get_value:
	ldr	r1, PTC_ADDR
	ldrb	r0, [r1, #PTC_TC]
	mov	pc, lr

; Rotina:    ptc_init
ptc_init:
push lr
push r0
bl ptc_stop
pop r0
ldr r1, PTC_ADDR
strb r0, [r1, #PTC_TMR]
bl ptc_start
pop pc

PTC_ADDR:
.word	PTC_ADDRESS


; Seccao:    data
; Descricao: Guarda as variáveis globais com um valor inicial definido
;
	.data
	
waittime:	
	.byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10, 10, 10, 10
; Seccao:    bss
; Descricao: Guarda as variáveis globais sem valor inicial definido
;
	.bss

sysclk:
	.space	2
; Seccao:    stack
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
	.stack
	.space	STACK_SIZE
tos:
