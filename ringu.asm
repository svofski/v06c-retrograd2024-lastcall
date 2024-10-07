                ;      7 days (until RETROGRAD Summer 2024)
                ;      
                ;                    -=-==-_-
                ;                 -- -     - --
                ;                =      7     `--
                ;              -= -           - =-
                ;               - -д  н  е  й   =-
                ;              --            --- -
                ;               ``--_-      -=--
                ;                 - -  -===--
                ;                     -  --  
                ;      
                ;        Out of compo  last call invitro
                ;                in 1024 bytes
                ;         for the unexpanded Vector-06c
                ;      
                ;                  svofski 2024
                ;     
                ;
                ; Использует 🐟 рисования окружности по алгоритму Мичнера
                ; Иван Городецкий 28.11.2018-01.12.2018
                .project ringu.rom

		.org 100h

start:
		xra	a
		out	10h             ; switch off ramdisk
		mvi	a,0C3h          ; install restart handlers
		sta	0               ; rst 0 ::= jmp 
		sta     8               ; rst 1 ::= jmp
		sta     $38             ; rst 7 ::= jmp
		lxi     h, spreadpixel4 
		shld    9               ; rst 1 ::= spreadpixel4

		lxi b,208
		lxi d,Xcorr
GenXcorr:
		mov l,b
		mov h,e
		dad h\ jnc $+4\ dad b
		dad h\ jnc $+4\ dad b
		dad h\ jnc $+4\ dad b
		dad h\ jnc $+4\ dad b
		dad h\ jnc $+4\ dad b
		dad h\ jnc $+4\ dad b
		dad h\ jnc $+4\ dad b
		dad h\ jnc $+4\ dad b
		xchg
		mov a,e
		add a
		jnc $+4
		inr d
		mov m,d
		xchg
		inr e
		jnz GenXcorr

		lxi	h,Restart
		shld	1               ; rst0 ::= Restart
		pchl                    ; jmp Restart
		

                ;; draw a horizontal line
hline1: 
                push h
		rst 1                   ; call spreadpixel4
                pop h
                inr h \ inr h
hline1x2        equ .+1
                mvi a, $60
                cmp h
                jp hline1
                ret
colorset:
		mvi	a, 88h
		out	0
		mvi	c, 15
colorset1:	mov	a, c
		out	2
		mov	a, m
		out	0Ch
		dcx	h
		out	0Ch
		out	0Ch
		dcr	c
		out	0Ch
		out	0Ch
		out	0Ch
		jp	colorset1
		mvi	a,255
		out	3
                ret
; выход:
; HL - число от 1 до 65535
rnd16_val       equ .+1
rnd16:
		lxi h,65535
		dad h
		shld rnd16+1
		rnc
		mvi a,00000001b ;перевернул 80h - 10000000b
		xra l
		mov l,a
		mvi a,01101000b	;перевернул 16h - 00010110b
		xra h
		mov h,a
		shld rnd16+1
		ret

                ;; setpixel somewhere around h=x, l=y
                ;; see setspread_hv for changing the spread
spreadpixel1:                
                push h
                call rnd16
                pop h
                lda rnd16_val
hspread_mask    equ .+1                
                ani 31          ; horizontal spread
hspread_ofs     equ .+1                
                sui 15
                add h
                mov h, a
                lda rnd16_val+1
vspread_mask    equ .+1                
                ani 15          ; vertical spread
vspread_ofs     equ .+1                
                sui 7
                add l
                mov l, a

                ;; --- normal setpixel_xy
                ;; вход:
                ;; H - X
                ;; L - Y
                ;; адрес пикселя =  base + (x / 8) << 8 + y
                ;; номер пикселя = x % 8
setpixel_xy:
		mvi a, 111b 		; сначала вычисляем смещение 
		ana h 			; пикселя в PixelMask
		sta SetPixelMaskAdr_xy+1
		xra h
		rrc 			; 
		rrc 			; 
		rrc
setpixel_bpl    equ .+1		
		ori $80
		mov h,a 		; h = 0x8000 | (a >> 3)
SetPixelMaskAdr_xy:
		lda PixelMask
		ora m 			; a = память с пикселем
		mov m,a 		; записать в память
dup7:		
		; удвоить пиксель номер 7
		lda SetPixelMaskAdr_xy+1
		cpi 7
		rnz
		inr h
		mvi a, $80
		ora m
		mov m, a
		ret

glitches_paint:
glitches_loop:                
                mov e, m \ inx h
                mov d, m \ inx h
                mov a, m \ inx h
                ora a
                jz glitches_end
                sta hline1x2
                push h
                xchg
                call hline1
                pop h
                jmp glitches_loop
glitches_end:                
                ret
                
interrupt:
                push h
                push psw
                ; increment framecnt
                lxi h, framecnt
                inr m

                call trilldo
                
                pop psw
                pop h
                ei
                ret
                
trill_init:     
                mvi a, 0b00110110       ; timer chan 0 mode 3 square
                out 8

                lxi h, trill_seq-1      ; advance trill_seq to the beginning
                shld trill_ptr
                jmp trilldo_next


                ; Make sure that the previous section ends before 0x0200
		
		.org 200h
PixelMask:      ; double pixels except for #7 (see dup7)
		.db 11000000b
		.db 01100000b
		.db 00110000b
		.db 00011000b
		.db 00011100b
		.db 00000110b
		.db 00000011b
		.db 00000001b


                ;; effects sequencer, invoked from the interrupt
trilldo:
                lhld trill_ptr
                mov a, m
                ral
                rc                      ; full stop
                rar
                ani $f
                jz trilldo_nop          ; one of the main sequence bit enables
                dcr a
                jz trilldo_trill        ; 1 == trill
                
                dcr a
                jz trilldo_pause        ; 2 == pause
                
                ; main sequence, just skip a number of frames
                jmp trilldo_nop
trilldo_pause:
                mvi a, 0b00110110       ; timer chan 0 mode 3 square
                out 8
trilldo_nop:                
                lda trill_cnt
                ora a
                jz trilldo_next
                dcr a
                sta trill_cnt
                ret

trilldo_trill:                
                lda framecnt
                rar \ rar 
                                ; pitches for the phone trill: c6/g#5  1032/829 Hz
                lxi h, $05ad    ; 1.5e6/1032 = 1453 0x5ad
                jc $+6
                lxi h, $0771    ; 1.5e6/829  = 1809 0x771
                mov a, l
                out $b
                mov a, h
                out $b
                ;
                lda trill_cnt
                dcr a
                sta trill_cnt
                jz trilldo_next
                ret
                
trilldo_next:
                lhld trill_ptr
                inx h                   ; trill_ptr = &nframes
                mov a, m                
                sta trill_cnt
                inx h                   ; trill_ptr = &what
                shld trill_ptr
                ret

                ; effects sequence defined in pairs (nframes, code)
                ; low nibble is 1 = trill, 2 = pause
                ; high nibble 7:stop 6:noise 5:desync 4:visible 

                ; 3x rings + final pause
trill_seq:      db 25,1, 6,2, 25,1, 150,2, 25,1, 6,2, 25,1, 150,2, 25,1, 6,2, 25,1, 150,2  
                db 2,   0b0100_0000         ; noise + no visual                
                db 50,  0b0000_0000         ; no noise + no visual
                db 20,  0b0111_0000         ; noise + crazy sync + visual
                db 50,  0b0100_0000         ; noise + no visual
                db 2,   0b0000_0000         ; no noise + no visual
                db 25,  0b0100_0000         ; noise + no visual
                db 10,  0b0111_0000         ; noise + crazy sync + visual
                db 0,   0b1101_1000         ; forever noise + visual

                ; variables in "data" at $7000
trill_ptr       equ $7000
trill_cnt       equ $7002
framecnt        equ $7004 ; db 0
prevcol         equ $7006 ; db 0
current_pal     equ $7008 ; dw 0
                ; "bss" at $7800 (Cls zeroes it out)
colors0         equ $7800                   ; all blaxk palette

                ;; set spread for spreadpixel4
                ;; takes 4 byte parameters after call: hmask, hofs, vmask, vofs
setspread_hv:   
                xthl
                mov a, m \ sta hspread_mask \ inx h
                mov a, m \ sta hspread_ofs  \ inx h
                mov a, m \ sta vspread_mask \ inx h
                mov a, m \ sta vspread_ofs  \ inx h
                xthl
                ret

Restart:
		lxi sp,100h
		lxi h, interrupt
		shld $39
		call trill_init

		ei
                ; clear bss and screen
Cls:
		lxi	h,07800h
		xra	a
ClrScr:
		mov	m,a
		inx	h
		cmp	h
		jnz	ClrScr
		
                ; set initial palette before the main loop
		hlt
		lxi h, colors0+15
		call colorset

                ; -----------------------------
                ; paint the ring
                ; -----------------------------
                call setspread_hv \ db 31,15,15,7   ; set v/h spreads wide

		lxi h,8080h	;H=xc, L=yc
		mvi a,110	;радиус
loop:		
		push psw
		push h
		call circle
		pop h
		pop psw
		sui 10
		cpi 100
		jp loop

                ; make vertical spread narrower, intensify the main circle
                call setspread_hv \ db 7, 3, 15, 7
                mvi a, 106
                call circle

                ; paint text with narrower spread
                call setspread_hv \ db 1, 1, 7, 0
                lxi h, text_db
                call glitches_paint

                ; text again, sharper
                call setspread_hv \ db 0, 0, 3, 0
                lxi h, text_db
                call glitches_paint

                ; horizontal tearing 
                call setspread_hv \ db 15, 7, 7, 3
                lxi h, glitches_db
                call glitches_paint

foreva:
                hlt

                lhld trill_ptr                  ; get current sequence id
                mov a, m                        ; 6: noise, 5: sync, 4: visible
                mov b, a
                ani 1<<4
                lhld current_pal
                jnz ms_colorset
                lxi h, colors0+15
ms_colorset:
                push b
                call colorset
                pop b

                ; crazy sync
                mvi a, 1<<5
                ana b
                jz ms_normalsync
ms_crazysync:
                lda rnd16_val
                out 3
                jmp pick_next
                
                ; normal sync with a bit of a wiggle
ms_normalsync:                
                lda framecnt
                cpi 200
                jc shake_small
                ani 3
                jmp shake_out
shake_small:    ani 1
shake_out:      out 3

                ;; pick next frame at random, re-roll if same frame happens twice
pick_next:
                push b
rollagain:     
                call rnd16
                mvi a, 3<<4 ; (rnd & 3) * 16
                ana l
                mov b, a
                
                ; same as previous?
                lda prevcol
                cmp b
                jz rollagain
                mov a, b
                sta prevcol
                
                lxi h, colors1+15
                add l
                mov l, a
                mov a, h
                aci 0
                mov h, a
                shld current_pal
                
                pop b
                mvi a, 1<<6
                ana b
                jz foreva             ; z = noise not enabled

                ; emit PWM approximation of white noise
                ; this loop takes most of the frame time
                ; inject raster noise as well
noise:
                xra a                 ; BSR for beeper (PC.0)
                out 0
                mov c, a              ; c = 0, maximum loop length
psssst:            
                call rnd16
                mov a, l
                cpi 244q
                jnz novisual
                out $c
                xra a
                out $c
                out $c
                out $c
                out $c
                out $c
novisual:                
                ani 1                 ; PC.0 beepor
                out 1
                ;mov a, a             ; mov a,a == louder noise than nop, but it's a bit harsh
                nop
                xra a
                out 1
                dcr c
                jnz psssst
                jmp foreva

                ; extra horizontal lines around the ring: X1YY, X2
glitches_db:
                ; 12 o'cock
                dw $80f8 \ db $a0
                ; 1 o'clock
                dw $d0c2 \ db $e0
                ; top glitch line
                dw $10c0 ; x1,y1
                db $60
                dw $98ba ; x1,y1
                db $f8

                ; 3 o'clock larger glitch
                dw $d09b ; x1,y1
                db $f2
                dw $c890 ; x1,y1
                db $e8

                ; 5 o clock longer line
                dw $883c ; x1,y1
                db $f0

                ; 6 o'clock
                dw $5008 ; x1,y1
                db $a0

                ; 8 o'clock
                dw $2048 ; x1,y1
                db $40

                ; 9                
                dw $20a0 ; x1,y1
                db $40
                
                ; middle
                dw $5a55 ; x1,y1
                db $95

                ; end
                dw $0000
                db $00

                ;; text graphics, X1YY, X2
text_db:                
                ; 7
                dw $74c0 \ db $90
                dw $8bb8 \ db $8e
                dw $89b0 \ db $8c
                dw $88a8 \ db $8a
                dw $86a0 \ db $88
                dw $8698 \ db $88
                dw $8690 \ db $88
                
                ; g
                dw $4680 \ db $55
                dw $4078 \ db $44 \ dw $5278 \ db $55
                dw $4070 \ db $44 \ dw $5070 \ db $55
                dw $4568 \ db $50 \ dw $5268 \ db $55
                dw $5160 \ db $55
                dw $4558 \ db $50 \ dw $3858 \ db $43 \ dw $505b \ db $53
                ; н
                dw $6880 \ db $6a \ dw $7880 \ db $7a
                dw $6878 \ db $6a \ dw $7878 \ db $7a
                dw $6870 \ db $7c ;$6a \ dw $7870 \ db $7a
                dw $6868 \ db $6a \ dw $7868 \ db $7a
                ; е
                ; 
                dw $9380 \ db $a0
                dw $907b \ db $92 \ dw $a078 \ db $a2
                dw $9070 \ db $98 \ dw $9974 \ db $a0 

                dw $9468 \ db $a0
                
                ; й
                dw $b490 \ db $bd
                dw $b080 \ db $b2 \ dw $c080 \ db $c2
                dw $b078 \ db $b2 \ dw $c078 \ db $c2
                dw $b070 \ db $b2 \ dw $bf70 \ db $c2
                ;dw $b068 \ db $b2 \ dw $c068 \ db $c2
                dw $b368 \ db $c4

                ; end
                dw $0000
                db $00
        
                ;; circle drawing routine
circle:
		shld ycxc+1
		mov b,a
		mov l,a
		mvi h,0
		dad h	;2*R
		mov a,l
		cma
		mov l,a
		mov a,h
		cma
		mov h,a
		inx h	;HL=-2*R
		lxi d,3
		dad d	;HL=3-2*R
		mvi c,0FFh
circle_loop:
		inr c
		mov a,b
		cmp c
		rc
		push h
		push b
		mov l,c
		mvi h,Xcorr>>8
		mov c,m
ycxc:		
		lxi d,0
;xc+x, yc+y
		mov l,b
		mov h,c
		dad d
		rst 1 ; call spreadpixel4
;xc+x, yc-y
		mov a,e
		sub b
		mov l,a
		rst 1 ; call spreadpixel4

;xc-x, yc-y
		mov a,d
		sub c
		mov h,a
		rst 1 ; call spreadpixel4
;xc-x, yc+y
		mov a,e
		add b
		mov l,a
		rst 1 ; call spreadpixel4

		pop b
		push b
		mov l,b
		mvi h,Xcorr>>8
		mov b,m
;xc+y, yc+x
		mov l,c
		mov h,b
		dad d
		rst 1 ; call spreadpixel4
;xc+y, yc-x
		mov a,e
		sub c
		mov l,a
		rst 1 ; call spreadpixel4

;xc-y, yc-x
		mov a,d
		sub b
		mov h,a
		rst 1 ; call spreadpixel4
;xc-y, yc+x
		mov a,e
		add c
		mov l,a
		rst 1 ; call spreadpixel4

		pop b
		pop d

		xra a
		ora d
		jp DmoreZ
;D<0
		mov l,c
		mvi h,0
		dad h
		dad h
		dad d
		lxi d,6
		dad d
		jmp circle_loop

DmoreZ:
		mov a,c
		sub b
		mov l,a
		mvi h,0FFh
		dad h
		dad h
		dad d
		lxi d,10
		dad d
		dcr b
		jmp circle_loop

spreadpixel4:
                push b
                mvi b, $20
                mvi a, $80
sp4loop:                
                push h
                sta setpixel_bpl
                push psw
                call spreadpixel1
                pop psw
                pop h
                add b
                jnz sp4loop
                pop b

                ret

; debug palette
; colors:
; 		.db 00000000b,00001001b,00010010b,00011011b,00100100b,00101101b,00110110b,00111111b
; 		.db 11111111b,00001001b,00010010b,00011011b,00100100b,00101101b,00110110b,00111111b

colors1:        .db 000q, 377q, 000q, 377q, 000q, 377q, 000q, 377q
                .db 000q, 255q, 000q, 255q, 000q, 255q, 000q, 255q
colors2:        .db 000q, 000q, 255q, 255q, 000q, 000q, 255q, 255q
                .db 000q, 000q, 377q, 377q, 000q, 000q, 377q, 377q
colors3:        .db 000q, 000q, 000q, 000q, 377q, 377q, 377q, 377q
                .db 000q, 000q, 000q, 000q, 377q, 377q, 377q, 377q
colors4:        .db 000q, 000q, 000q, 000q, 000q, 000q, 000q, 000q
                .db 256q, 265q, 277q, 377q, 377q, 377q, 377q, 377q
                db 'svofski', $1a,'retrograd 10.2024!'

                .org 256 + .&0xff00
Xcorr:           
