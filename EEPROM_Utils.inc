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
