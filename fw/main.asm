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
	TMP3
	TMP4
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
	tbl_tmp
	
	variables_end
	endc

#define		var_len			variables_end-0
  
#define		f_int_fin		flagvar1,0
#define		f_invert		flagvar1,1
#define		f_line			flagvar1,3
#define		f_run			flagvar1,4
#define		f_step			flagvar1,5
#define		f_clean			flagvar1,6
#define		f_disp_half		flagvar1,7
	
#define		input_buff		0x40
#define		stack_buff		0x80
#define		out_buff		0xD0
#define		out_buff_len	program_buff-out_buff
#define		program_buff	0xE0	
#define		array_buff		0xB00

#define		LCD_PORT		LATA
#define		LCD_TRIS		TRISA
#define		LCD_A0			LATC,0
#define		LCD_A0_T		TRISC,0
#define		LCD_A0_I		PORTC,0
#define		LCD_RST			LATC,1
#define		LCD_E1			LATC,2
#define		LCD_E0			LATC,3
#define		LCD_RW			LATC,4
  
#define		LEDG			LATB,2
	
#define		DISP_HALFWIDTH	.12
 
	
#define		TEST_INPUT		1	

    org	    0x0000
	bra		main

tbl_vectors
	db	0x00,0x49,0x09,0x01
	db	0x70,0x08,0x40,0x41
	db	0x3E,0x7F,0x22,0x14
	db	0x45,0x4F,0x06,0x30
tbl_charmap
	db	0x00,0x00	;0x20 ' '
	db	0x00,0xD0	;0x21 !
	db	0x0E,0x0E	;0x22 "
	db	0x9A,0x9A	;0x23 #
	db	0x0E,0x1F	;0x24 $
	db	0x00,0x00	;0x25 % - undefined
	db	0x00,0x00	;0x26 & - undefined
	db	0x00,0xE0	;0x27 '
	db	0x08,0x77	;0x28 (
	db	0x07,0x78	;0x29 )
	db	0x0B,0x8B	;0x2A *
	db	0x05,0x85	;0x2B +
	db	0x06,0xF0	;0x2C ,
	db	0x05,0x55	;0x2D -
	db	0x0F,0xF0	;0x2E .
	db	0x06,0x83	;0x2F /
	db	0x81,0xC8	;0x30 0
	db	0x0E,0x90	;0x31 1
	db	0x41,0xCE	;0x32 2
	db	0x07,0x1B	;0x33 3
	db	0xE5,0x59	;0x34 4
	db	0x0D,0x1D	;0x35 5
	db	0x08,0x14	;0x36 6 
	db	0x03,0x39	;0x37 7
	db	0x81,0x18	;0x38 8 
	db	0xE1,0x18	;0x39 9 
	db	0x0B,0x00	;0x3A :
	db	0x0F,0xB0	;0x3B ;
	db	0x5B,0xA7	;0x3C <
	db	0x0B,0xBB	;0x3D =
	db	0x7A,0xB5	;0x3E >	
	db	0x0C,0xE0	;0x3F ?
	db	0x87,0x1D	;0x40 @
	db	0x92,0x29	;0x41 A
	db	0x91,0x1A	;0x42 B
	db	0x87,0x7A	;0x43 C
	db	0x97,0x78	;0x44 D
	db	0x91,0x11	;0x45 E
	db	0x92,0x23	;0x46 F
	db	0x87,0x1F	;0x47 G
	db	0x95,0x59	;0x48 H
	db	0x00,0x90	;0x49 I
	db	0xF6,0x79	;0x4A J
	db	0x9B,0xA7	;0x4B K
	db	0x96,0x60	;0x4C L
	db	0x9E,0xE9	;0x4D M
	db	0x9E,0x59	;0x4E N
	db	0x87,0x78	;0x4F O
	db	0x92,0x2E	;0x50 P
	db	0x87,0x86	;0x51 Q
	db	0x92,0xB6	;0x52 R
	db	0xE1,0x1F	;0x53 S
	db	0x39,0x30	;0x54 T
	db	0x86,0x68	;0x55 U
	db	0xE5,0xF9	;0x56 V
	db	0x9F,0xF9	;0x57 W
	db	0xA5,0x5A	;0x58 X
	db	0xE4,0xE0	;0x59 Y
	db	0x71,0xC7	;0x5A Z
	db	0x07,0x79	;0x5B [
	db	0x03,0x86	;0x5C \
	db	0x09,0x77	;0x5D ]
	db	0x0E,0x3E	;0x5E ^
	db	0x06,0x66	;0x5F _

#ifdef	TEST_INPUT	
src2
    db	   ",[.,]abcdefghijklmnopqr"
	db		0x00
inp    
	db	   "TEST INPUT"
	db		0x00

tblcpy_rout
	movwf   TBLPTRL
copy_loop1
    tblrd*+
	movff	TABLAT,POSTINC1
	tstfsz	TABLAT
	bra		copy_loop1
	return

#endif	
	
main
	lfsr	1,0
	movlw	var_len
	clrf	POSTINC1
	decfsz	WREG
	bra		$-4
	movlb	.15
	clrf	ANSELA,BANKED
	clrf	ANSELB,BANKED
	clrf	TRISA
	clrf	TRISB
	clrf	TRISC	
	movlw	0xC7
	movwf	T0CON
	movlw	0x70
	movwf	OSCCON
	
#ifdef	TEST_INPUT
	clrf   TBLPTRH
	lfsr	1,program_buff		;program
	movlw   LOW src2
	rcall	tblcpy_rout
	
	lfsr	1,input_buff
	movlw   LOW inp
	rcall	tblcpy_rout	
#endif	

	clrf	LATC
	movlw	.10
	rcall	dly_nms
	bsf		LCD_RST

	movlw	0xAF
	rcall	disp_cmd
	bsf		f_disp_half
	rcall	disp_cmd
	
	
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

	btfss	f_run
	bra		n_run
	bcf		f_run
	rcall	int_init
n_run	
	bcf		LEDG
	btfss	f_int_fin
	bsf		LEDG

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
	setf	LCD_TRIS
	movlw	.50
	rcall	dly_n10us
	comf	PORTA,W
	movwf	keys_new
	xorwf	keys_old,W
	andwf	keys_new,W
	iorwf	keys,f
	movff	keys_new,keys_old
	clrf	LCD_TRIS
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
	rcall	lcd_print_h4
	movf	TMP2,W
lcd_print_h4
	andlw	0x0F
	addlw	0-D'10'			; test: Is W < 10 ?
	btfsc	STATUS,C		; If 0 <= W <= 9, skip ahead
	addlw	'A'-'0'-D'10'	; If A <= W <= F, add ASCII char 'A', and
							; subtract enough to make the next
							; line have no effect
	addlw	'0'+D'10'		; Add ASCII character '0' as well as
							; replace the original 10 that was subtracted	
					
lcd_char	
	movwf	TMP4
	movlw	0x20
	cpfslt	TMP4
	bra		char_gt_0x20
	movlw	.0
	bra		lcd_char_now
char_gt_0x20
	movlw	0x60
	cpfslt	TMP4
	bra		char_gt_0x60
	movf	TMP4,W
	addlw	.256-0x20
	bra		lcd_char_now
char_gt_0x60	
	movf	TMP4,W
	addlw	.256-0x40
lcd_char_now
	andlw	0x3F
	rlncf	WREG,f
	addlw	tbl_charmap
	movwf	TBLPTRL
	clrf	TBLPTRH
	rcall	lcd_char_t1
	rcall	lcd_char_t2
	rcall	lcd_char_t1
	rcall	lcd_char_t2
	movlw	.0
	bra		disp_dat

lcd_char_t1
	tblrd*
	swapf	TABLAT,W
	bra		lcd_print_vector
lcd_char_t2
	tblrd*+
	movf	TABLAT,W
	bra		lcd_print_vector
	
lcd_print_vector
	andlw	0x0F
	movff	TBLPTRL,tbl_tmp
	addlw	tbl_vectors
	movwf	TBLPTRL
	tblrd*+
	movf	TABLAT,W
	movff	tbl_tmp,TBLPTRL
disp_dat
	bsf		LCD_A0	
	btfsc	f_invert
	comf	WREG
	bra		disp_proc
disp_cmd
	bcf		LCD_A0
disp_proc
	movwf	LCD_PORT
	bcf		LCD_E0
	bcf		LCD_E1
;	nop
	btfsc	f_disp_half
	bsf		LCD_E0
	btfss	f_disp_half
	bsf		LCD_E1
;	nop
	bcf		LCD_E0
	bcf		LCD_E1
	return							

dly_n10us
	movwf	TMP1
dly_10us_lop
	movlw	.12
	decfsz	WREG
	bra		$-2
	decfsz	TMP1
	bra		dly_10us_lop
	
	return
	

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

disp_line
	addlw	0xB8
	rcall	disp_cmd
	movlw	0x00
	rcall	disp_cmd
	return
	
display_refresh
	movff	FSR2L,stackl_t

	bcf		f_disp_half	
	movlw	.0
	rcall	disp_line
	lfsr	2,program_buff
	movf	addrl_1,W
	rcall	disp_refresh_helper
	rcall	disp_sr_l1

	bsf		f_disp_half
	movlw	.0
	rcall	disp_line
	movlw	.16-DISP_HALFWIDTH
	rcall	disp_sr_noinit

	movlw	' '
	rcall	lcd_char
	movlw	'P'
	rcall	lcd_char
	movf	block_1,W
	rcall	lcd_print_h8	
	
	
	bcf		f_disp_half	
	movlw	.1
	rcall	disp_line
	lfsr	2,input_buff
	movf	addrl_2,W
	rcall	disp_refresh_helper
	rcall	disp_sr_l2
	
	bsf		f_disp_half
	movlw	.1
	rcall	disp_line
	movlw	.16-DISP_HALFWIDTH
	rcall	disp_sr_noinit
	movlw	' '
	rcall	lcd_char
	movlw	'I'
	rcall	lcd_char
	movf	block_2,W
	rcall	lcd_print_h8

	
	bcf		f_disp_half	
	movlw	.2
	rcall	disp_line
	lfsr	2,out_buff
	movlw	DISP_HALFWIDTH
	rcall	disp_sr_l3
	
	
	movff	stackl_t,FSR2L
	clrf	FSR2H

	return
	
disp_refresh_helper
	andlw	0xF0
	addwf	FSR2L,f
	movf	addrh_1,W
	addwfc	FSR2H,f
	movlw	DISP_HALFWIDTH
	return
	
disp_sr_l3
	bsf		TMP3,7
	bra		disp_sr_l_ok
disp_sr_l2
	clrf	TMP3
	btfss	f_line
	bsf		TMP3,7
	bra		disp_sr_l_ok
disp_sr_l1
	clrf	TMP3
	btfsc	f_line
	bsf		TMP3,7
disp_sr_l_ok
	bcf		f_clean
disp_sr_noinit
	movwf	TMP2
disp_l1
	movf	TMP3,W
	subwf	position,W
	bnz		disp_sr_nz
	bsf		f_invert
disp_sr_nz
	incf	TMP3
	movf	POSTINC2,W
	btfsc	STATUS,Z
	bsf		f_clean
	btfsc	f_clean
	movlw	' '
	rcall	lcd_char
	bcf		f_invert
	decfsz	TMP2
	bra		disp_l1
	return
	
    END