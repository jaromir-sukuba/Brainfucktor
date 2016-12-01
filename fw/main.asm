#include "p18f26k22.inc"
  CONFIG  FOSC = INTIO67        ; Oscillator Selection bits (Internal oscillator block)
  CONFIG  PLLCFG = OFF          ; 4X PLL Enable (Oscillator used directly)
  CONFIG  PRICLKEN = ON         ; Primary clock enable bit (Primary clock enabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
  CONFIG  IESO = OFF            ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)
  CONFIG  PWRTEN = OFF          ; Power-up Timer Enable bit (Power up timer disabled)
  CONFIG  WDTEN = NOSLP         ; Watchdog Timer Enable bits (WDT is disabled in sleep, otherwise enabled. SWDTEN bit has no effect)
  CONFIG  CCP2MX = PORTC1       ; CCP2 MUX bit (CCP2 input/output is multiplexed with RC1)
  CONFIG  PBADEN = ON           ; PORTB A/D Enable bit (PORTB<5:0> pins are configured as analog input channels on Reset)
  CONFIG  CCP3MX = PORTC6       ; P3A/CCP3 Mux bit (P3A/CCP3 input/output is mulitplexed with RC6)
  CONFIG  HFOFST = ON           ; HFINTOSC Fast Start-up (HFINTOSC output and ready status are not delayed by the oscillator stable status)
  CONFIG  T3CMX = PORTC0        ; Timer3 Clock input mux bit (T3CKI is on RC0)
  CONFIG  P2BMX = PORTC0        ; ECCP2 B output mux bit (P2B is on RC0)
  CONFIG  MCLRE = EXTMCLR       ; MCLR Pin Enable bit (MCLR pin enabled, RE3 input pin disabled)
  CONFIG  STVREN = ON           ; Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset)
  CONFIG  LVP = ON              ; Single-Supply ICSP Enable bit (Single-Supply ICSP enabled if MCLRE is also 1)
  CONFIG  XINST = OFF           ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))
	
	cblock	0x000	
	input_p
	input_len
	stackl_t
	out_p
	out_len
	out_sh_cnt
	out_sh_tmp
	TMP0	
	TMP1	
	TMP2	
	cursor	
	flagvar1
	keys_old
	keys	
	keys_new
	position
	block_1
	block_2
	addrh_1
	addrl_1
	addrh_2
	addrl_2
	
	variables_end
	endc

#define		var_len			variables_end-0
  
#define		f_int_fin		flagvar1,0
#define		f_shift			flagvar1,1
#define		f_shift_old		flagvar1,2
#define		f_line			flagvar1,3
#define		f_run			flagvar1,4
#define		f_step			flagvar1,5
#define		f_clean			flagvar1,6
  
#define		input_buff		0x40
#define		stack_buff		0x80
#define		out_buff		0xD0
#define		out_buff_len	program_buff-out_buff
#define		program_buff	0xE0	
#define		array_buff		0xB00

#define		LCD_PORT		LATA
#define		LCD_TRIS		TRISA
#define		LCD_RS			LATB,5
#define		LCD_RS_T		TRISB,5
#define		LCD_RS_I		PORTB,5
#define		LCD_EN			LATB,4
  
#define		LEDY			LATC,1
#define		LEDR			LATC,2
 

    org	    0x0000
	bra		main
src1
    db	   "++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>."
	db		0x00
src2
    db	   ",[.,]"
	db		0x00
inp    
	db	   "Test input"
	db		0x00

tblcpy_rout
	movwf   TBLPTRL
copy_loop1
    tblrd*+
	movff	TABLAT,POSTINC1
	tstfsz	TABLAT
	bra		copy_loop1
	return
	
main
	lfsr	1,0
	movlw	var_len
	clrf	POSTINC1
	decfsz	WREG
	bra		$-4
	clrf	TRISA
	movlb	.15
	clrf	ANSELA,BANKED
	clrf	ANSELB,BANKED
	movlw	0x02
	movwf	TRISB
	movlw	0xC7
	movwf	T0CON
	movlw	0x70
	movwf	OSCCON

	clrf   TBLPTRH
	lfsr	1,program_buff		;program
	movlw   LOW src1
	btfsc	LCD_RS_I
	movlw   LOW src2
	rcall	tblcpy_rout
	
	lfsr	1,input_buff
	movlw   LOW inp
	rcall	tblcpy_rout
	
	clrf	TRISC	
	movlw	.20
	rcall	dly_nms
	movlw	0x38
	rcall	lcd_cmd
	movlw	0x0F
	rcall	lcd_cmd
	movlw	0x01
	rcall	lcd_cmd
	rcall	dly_4ms
	movlw	0x02
	rcall	lcd_cmd
	rcall	dly_4ms
	
	lfsr	1,out_buff
	movlw	out_buff_len
	clrf	POSTINC1
	decfsz	WREG
	bra		$-4	
	
;	rcall	int_init
	
temp_loop
	rcall	int_execute
	btfss	INTCON,TMR0IF
	bra		temp_loop
	bcf		INTCON,TMR0IF
	rcall	display_refresh
	rcall	keys_check
	rcall	editor

	bcf		LEDY
	btfsc	f_shift
	bsf		LEDY

	btfss	f_run
	bra		n_run
	bcf		f_run
	rcall	int_init
n_run	
	bcf		LEDR
	btfss	f_int_fin
	bsf		LEDR

	bra		temp_loop
	
editor
	movff	FSR2L,stackl_t
	
	btfsc	f_line
	bra		editor_line1
	lfsr	2,program_buff
	movf	addrl_1,W
	addwf	FSR2L,f
	movf	addrh_1,W
	addwfc	FSR2H,f
	bra		editor_lineend
editor_line1
	lfsr	2,input_buff
	movf	addrl_2,W
	addwf	FSR2L,f
	movf	addrh_2,W
	addwfc	FSR2H,f	
editor_lineend	
	btfss	f_shift
	bra		editor_normal
	movlw	.0
	btfss	keys,0
	bra		editor_d1
	movlw	'<'
editor_d1	
	btfss	keys,1
	bra		editor_d2
	movlw	'>'
editor_d2	
	btfss	keys,2
	bra		editor_d3
	movlw	'+'
editor_d3
	btfss	keys,3
	bra		editor_d4
	movlw	'-'
editor_d4
	btfss	keys,4
	bra		editor_d5
	movlw	'.'
editor_d5
	btfss	keys,5
	bra		editor_d6
	movlw	','
editor_d6
	btfss	keys,6
	bra		editor_d7
	movlw	'['
editor_d7
	btfss	keys,7
	bra		editor_d8
	movlw	']'
editor_d8
	clrf	keys
	andlw	0xFF
	bz		editor_end
	movwf	INDF2
	btfsc	f_line
	bra		editor_d_l
	incf	addrl_1
	btfsc	STATUS,C
	incf	addrh_1
	bra		editor_1
editor_d_l
	incf	addrl_2
	btfsc	STATUS,C
	incf	addrh_2	
	
	bra		editor_end
	
editor_normal	
	btfss	keys,4
	bra		editor_1
	btfsc	f_line
	bra		editor_0_l1
	incf	addrl_1
	btfsc	STATUS,C
	incf	addrh_1
	bra		editor_1
editor_0_l1
	incf	addrl_2
	btfsc	STATUS,C
	incf	addrh_2	
editor_1
	btfss	keys,5
	bra		editor_2
	btfsc	f_line
	bra		editor_1_l1
	decf	addrl_1
	btfss	STATUS,C
	decf	addrh_1
	bra		editor_2
editor_1_l1
	decf	addrl_2
	btfss	STATUS,C
	decf	addrh_2	
editor_2
	btfss	keys,0
	bra		editor_3
	incf	INDF2
editor_3	
	btfss	keys,1
	bra		editor_4
	decf	INDF2
editor_4	
	btfss	keys,2
	bra		editor_5
	movlw	.8
	addwf	INDF2,f
editor_5	
	btfss	keys,3
	bra		editor_6
	movlw	.256-.8
	addwf	INDF2,f
editor_6		
	btfss	keys,7
	bra		editor_7
	bsf		f_run
editor_7	
	btfss	keys,6
	bra		editor_8
	btg		f_line
editor_8
	clrf	keys
editor_end
	
	
	movf	addrl_1,W
	btfsc	f_line
	movf	addrl_2,W
	andlw	0x0F
	movwf	position

	swapf	addrl_1,W
	andlw	0x0F
	movwf	block_1
	swapf	addrh_1,W
	andlw	0xF0
	iorwf	block_1,f
	
	swapf	addrl_2,W
	andlw	0x0F
	movwf	block_2
	swapf	addrh_2,W
	andlw	0xF0
	iorwf	block_2,f

	clrf	FSR2H
	movff	stackl_t,FSR2L
	return
	
keys_check
	bsf		LCD_RS_T
	setf	LCD_TRIS
	movlw	.50
	rcall	dly_n10us
	btfsc	LCD_RS_I
	bra		keys_check_no_rs
	btfss	f_shift_old
	bra		keys_check_no_rs
	btg		f_shift
keys_check_no_rs	
	bcf		f_shift_old
	btfsc	LCD_RS_I
	bsf		f_shift_old
	comf	PORTA,W
	movwf	keys_new
	xorwf	keys_old,W
	andwf	keys_new,W
	iorwf	keys,f
	movff	keys_new,keys_old
	clrf	LCD_TRIS
	bcf		LCD_RS_T
	return
	
int_init
	movlw	.255
	lfsr	1,input_buff
int_init_getlen
	incf	WREG
	tstfsz	POSTINC1
	bra		int_init_getlen
	movwf	input_len
	movlw	out_buff
	movwf	out_p
	clrf	out_len
	movlw	input_buff
	movwf	input_p
	lfsr	1,array_buff
	movlw	.255
	clrf	POSTINC1
	decfsz	WREG
	bra		$-4
	lfsr	0,array_buff		;array
	lfsr	1,program_buff		;program
	lfsr	2,stack_buff		;stack
	bcf		f_int_fin	
	return
int_execute
	btfsc	f_int_fin
	return
	movlw	'>'
    cpfseq  INDF1
    bra	    int_1
	incf	FSR0L
	bra		int_e
int_1
	movlw	'<'
    cpfseq  INDF1
    bra	    int_2
	decf	FSR0L
	bra		int_e
int_2
	movlw	'+'
    cpfseq  INDF1
    bra	    int_3
	incf	INDF0
	bra		int_e
int_3
	movlw	'-'
    cpfseq  INDF1
    bra	    int_4
	decf	INDF0
	bra		int_e
int_4
	movlw	'.'
    cpfseq  INDF1
    bra	    int_5
	movf	INDF0,W
	rcall	put_obuff
	;OUTPUT
	bra		int_e
int_5    
	movlw	','
    cpfseq  INDF1
    bra	    int_6
	;INPUT
	movlw	.0
	cpfsgt	input_len
	bra		int_finished
	movff	FSR2L,stackl_t
	movff	input_p,FSR2L
	movff	INDF2,INDF0
	incf	input_p
	decf	input_len
	movff	stackl_t,FSR2L
	bra		int_e
int_6
	movlw	'['
    cpfseq  INDF1
    bra	    int_7
	movff	FSR1H,PREINC2
	movff	FSR1L,PREINC2
	bra		int_e
int_7
	movlw	']'
    cpfseq  INDF1
    bra	    int_8
	tstfsz	INDF0
	bra		int_7a
	bra		int_8
int_7a
	movff	POSTDEC2,FSR1L
	movff	POSTDEC2,FSR1H
	movf	POSTDEC1,W
	bra		int_e
int_8
	
int_e
	movf	POSTINC1,W
	tstfsz	INDF1
    return
	
int_finished
	movlw	.0
	rcall	put_obuff
	bsf		f_int_fin
	return

put_obuff
	movff	FSR2L,stackl_t
	movff	out_p,FSR2L
	movwf	INDF2
	incf	out_p
	incf	out_len
	movlw	out_buff_len
	cpfseq	out_len
	bra		int_4_e
	movwf	out_sh_cnt
	movlw	out_buff+1
	movwf	out_sh_tmp
int_4_loop	
	movff	out_sh_tmp,FSR2L
	movf	POSTDEC2,W
	movwf	INDF2
	incf	out_sh_tmp
	decfsz	out_sh_cnt
	bra		int_4_loop
	clrf	INDF2
	decf	out_p
	decf	out_len
int_4_e
	movff	stackl_t,FSR2L	
	return
	
lcd_print_h8
	movwf	TMP2
	swapf	TMP2,W
	andlw	0x0F
	rcall	lcd_print_h4
	movf	TMP2,W
	andlw	0x0F
lcd_print_h4
	addlw	0-D'10'			; test: Is W < 10 ?
	btfsc	STATUS,C		; If 0 <= W <= 9, skip ahead
	addlw	'A'-'0'-D'10'	; If A <= W <= F, add ASCII char 'A', and
							; subtract enough to make the next
							; line have no effect
	addlw	'0'+D'10'		; Add ASCII character '0' as well as
							; replace the original 10 that was subtracted	
lcd_data
	bsf		LCD_RS
	bra		lcd_put_word
lcd_cmd
	bcf		LCD_RS
lcd_put_word
	movwf	LCD_PORT
	bsf		LCD_EN	
	bra		$+2
	bcf		LCD_EN	
	rcall	dly_40us
	return

dly_40us
	movlw	.4
dly_n10us
	movwf	TMP1
dly_10us_lop
	movlw	.12
	decfsz	WREG
	bra		$-2
	decfsz	TMP1
	bra		dly_10us_lop
	
	return
	
dly_4ms
	movlw	.4
dly_nms
	movwf	TMP2
dly_ms_loop
        MOVLW 0x06  ;6 DEC
        MOVWF TMP1
        MOVLW 0x2F  ;47 DEC
        MOVWF TMP0
        DECFSZ TMP0,F
        bra $-2
        DECFSZ TMP1,F
        bra $-6
		decfsz	TMP2
		bra		dly_ms_loop
	return

	
display_refresh
	movff	FSR2L,stackl_t
	movlw	0x02
	rcall	lcd_cmd
	movlw	0x02
	rcall	dly_nms

	lfsr	2,program_buff
	movf	addrl_1,W
	andlw	0xF0
	addwf	FSR2L,f
	movf	addrh_1,W
	addwfc	FSR2H,f
	movlw	.16
	rcall	disp_sr
	
	lfsr	2,out_buff
	movlw	.16
	rcall	disp_sr

	movlw	0xC0
	rcall	lcd_cmd
	
	lfsr	2,input_buff
	movf	addrl_2,W
	andlw	0xF0
	addwf	FSR2L,f
	movf	addrh_2,W
	addwfc	FSR2H,f

	movlw	.16
	rcall	disp_sr

	movlw	'P'
	rcall	lcd_data
	movf	block_1,W
	rcall	lcd_print_h8
	movlw	' '
	rcall	lcd_data
	movlw	'I'
	rcall	lcd_data
	movf	block_2,W
	rcall	lcd_print_h8
	
	movff	stackl_t,FSR2L
	clrf	FSR2H
	
	movlw	0x80
	btfsc	f_line	
	iorlw	0x40
	addwf	position,W
	rcall	lcd_cmd
	return

disp_sr
	movwf	TMP2
	bcf		f_clean
disp_l1
	movf	POSTINC2,W
	btfsc	STATUS,Z
	bsf		f_clean
	btfsc	f_clean
	movlw	' '
	rcall	lcd_data
	decfsz	TMP2
	bra		disp_l1
	return
	
    END