; PIC16F628A Configuration Bit Settings

; ASM source line config statements

#include "p16F628A.inc"

; CONFIG
; __config 0xFF19
 __CONFIG _FOSC_INTOSCCLK & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
	    
reg1    EQU	h'20'	;swap register
reg2    EQU	h'21'	;swap register
aux	EQU	h'22'	;swap register
index	EQU	h'23'	;index 
left	EQU	h'24'	;index of left child
right	EQU	h'25'	;index of righ child
higher	EQU	h'26'	;index of higher number on heapfy
subtree	EQU	h'27'	;index of a subtree root
content	EQU	h'28'	;content of an index
heap	EQU	h'30'	;30: array length, 31+: array content
 
        org 0x0000
        GOTO setup
	    
        org 0x0004
        BANKSEL	PORTA
        BTFSS	PIR1, EEIF
        GOTO	isr_exit
        INCF	index, F
        INCF	FSR, F
        BCF		PIR1, EEIF
isr_exit:
	RETFIE
	    
writeEEByte:
        MOVF	index, W
        BANKSEL	EECON1
        MOVWF	EEADR
        MOVF	INDF, W
        MOVWF	EEDATA

        BSF	EECON1, WREN
        BCF	INTCON, GIE
        BTFSC	INTCON,GIE
        GOTO	$ - 2
        MOVLW	h'55'
        MOVWF	EECON2
        MOVLW	h'AA'
        MOVWF	EECON2
        BSF	EECON1,WR
	BSF	INTCON, GIE
	BCF	EECON1, WREN
	
	MOVF	index, W
	SUBWF	heap, W
	BTFSC	STATUS, C
	GOTO	writeEEByte
	    
	RETURN
	    
readEEByte:   
        BANKSEL EEADR
        MOVWF   EEADR
        BSF	EECON1, RD
        MOVF    EEDATA, W
	BANKSEL PORTA
	RETURN

readEEData:	    
	MOVLW   h'31'
        MOVWF   FSR
        CLRF    index	    
readLoop:
        INCF    index
        MOVF    index, W
        CALL    readEEByte
        MOVWF   INDF
        INCF    FSR	    
        MOVF    index, W    
        SUBWF   heap, W	    
        BTFSS   STATUS, Z
        GOTO    readLoop
        RETURN
	    
swap:	    
	MOVF	reg1, W
	MOVWF	FSR
	MOVF	INDF, W
	MOVWF	aux
	
	MOVF	reg2,W
	MOVWF	FSR
	MOVF	INDF, W
	MOVWF	content
	
	MOVF	aux, W
	MOVWF	INDF
	MOVF	reg1, W
	MOVWF	FSR
	MOVF	content, W
	MOVWF	INDF
	
	RETURN
	
maxheapify:
	MOVF	index, W
	MOVWF	left
	BCF	STATUS, C
	RLF	left
	
	MOVF	index, W
	MOVWF	right
	BCF	STATUS, C
	RLF	right
	INCF	right
	
	MOVF	index, W
	MOVWF	higher
	
	;verify_left
	MOVF	left, W
	SUBWF	heap, W
	BTFSS	STATUS, C
	GOTO	verify_right
	
	MOVF	left, W
	MOVWF	FSR
	MOVLW	h'30'
	ADDWF	FSR
	MOVF	INDF, W
	MOVWF	content
	
	MOVF	index, W
	MOVWF	FSR
	MOVLW	h'30'
	ADDWF	FSR
	MOVF	INDF, W
	
	SUBWF	content, W
	BTFSS	STATUS, C
	GOTO	verify_right
	
	MOVF	left, W
	MOVWF	higher
	
verify_right:
	MOVF	right, W
	SUBWF	heap, W
	BTFSS	STATUS, C
	GOTO	verify_higher
	
	MOVF	right, W
	MOVWF	FSR
	MOVLW	h'30'
	ADDWF	FSR
	MOVF	INDF, W
	MOVWF	content
	
	MOVF	higher, W
	MOVWF	FSR
	MOVLW	h'30'
	ADDWF	FSR
	MOVF	INDF, W
	
	SUBWF	content, W
	BTFSS	STATUS, C
	GOTO	verify_higher
	
	MOVF	right, W
	MOVWF	higher
	
verify_higher:
	MOVF	index, W
	SUBWF	higher, W
	BTFSC	STATUS, Z
	GOTO	heapify_end
	
	MOVF	index, W
	MOVWF	reg1
	MOVLW	h'30'
	ADDWF	reg1
	MOVF	higher, W
	MOVWF	reg2
	MOVLW	h'30'
	ADDWF	reg2
	CALL	swap
	
	MOVF	higher,W
	MOVWF	index
	GOTO	maxheapify
	
heapify_end:	
	RETURN
	
build_maxheap:
	MOVF	heap, W
	MOVWF	subtree
	BCF	STATUS, C
	RRF	subtree
	
verify_subtree:
	MOVF	subtree, W
	MOVWF	index
	CALL	maxheapify
	DECF	subtree
	BTFSS	STATUS, Z
	GOTO	verify_subtree
	
	RETURN

setup:	
	BANKSEL PORTA	    
	MOVLW   h'30'
	MOVWF   FSR
	MOVLW   h'00'
	CALL    readEEByte
	MOVWF   INDF
	CALL    readEEData
	
	MOVLW	b'11000000'
	MOVWF	INTCON
	BANKSEL	EECON1
	BSF	PIE1, EEIE

	BANKSEL	PORTA
	MOVLW	h'01'
	MOVWF	index
	GOTO main
	
main:	
	CALL	build_maxheap
	
 	CLRF	index
	MOVLW	h'01'
	MOVWF	index
	MOVLW	h'31'
	MOVWF	FSR
	CALL	writeEEByte
	
	SLEEP
	
	ORG	    0x2100	    
	DE	    0x1B, 0x06, 0x81, 0x87, 0x14, 0x17, 0x12, 0x28, 0x71, 0x25, 0x80, 0x20, 0x52, 0x78, 0x31, 0x42, 0x31, 0x59, 0x16, 0x24, 0x79, 0x63, 0x18, 0x19, 0x32, 0x13, 0x15, 0x48
	END
