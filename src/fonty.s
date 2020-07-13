

		move.l	#Copper,d0
		move.w	d0,$dff082
		swap	d0
		move.w	d0,$dff080

		move.l	#Bitplan,d0
		move.w	d0,AdrH+4
		swap	d0
		move.w	d0,AdrH


		bsr.w	WriteText
LMB		btst	#6,$bfe001
		bne.b	LMB
		rts


WriteText	lea	Bitplan,a1
		lea	Text,a0
		moveq	#40-1,d7
Loop
		moveq	#0,d0
		move.b	(a0)+,d0
		sub.l	#32,d0
		bsr.s	WriteChar
		addq.l	#1,a1
		dbf	d7,Loop
		rts


WriteChar	movem.l	d0-a6,-(sp)
		lea	Fonty,a0
		and.l	#$ff,d0
		lsl.l	#3,d0
		lea.l	(a0,d0.l),a0
		moveq	#8-1,d7
QQQ		move.b	(a0)+,(a1)
		add.l	#40,a1
		dbf	d7,QQQ
		movem.l	(sp)+,d0-a6
		rts







Copper		dc.l	$008e4081
		dc.l	$009000c1
		dc.l	$00920038
		dc.l	$009400d0
		dc.l	$01001000

		dc.w	$00e0
AdrH		dc.w	0
		dc.w	$00e2
		dc.w	0

		dc.l	$01800000
		dc.l	$01820222
		dc.l	$fffffffe

Bitplan		blk.b	40*200,0


Text		dc.b	'!#%&()*+,-./0123456789'



Fonty		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000

		dc.b	%00000000	33 !
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%00000000
		dc.b	%00010000
		dc.b	%00000000

		dc.b	%00000000	34 "
		dc.b	%00100100
		dc.b	%00100100
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000

		dc.b	%00000000	35 #
		dc.b	%00100100
		dc.b	%01111110
		dc.b	%00100100
		dc.b	%00100100
		dc.b	%01111110
		dc.b	%00100100
		dc.b	%00000000

		dc.b	%00001000	36 $
		dc.b	%00111110
		dc.b	%01001000
		dc.b	%00110000
		dc.b	%00001100
		dc.b	%00010010
		dc.b	%01111100
		dc.b	%00010000

		dc.b	%00000000	37 %
		dc.b	%01100010
		dc.b	%01100100
		dc.b	%00001000
		dc.b	%00010000
		dc.b	%00100110
		dc.b	%01000110
		dc.b	%00000000

		dc.b	%00111000	38 &
		dc.b	%01000100
		dc.b	%01000100
		dc.b	%00111000
		dc.b	%01000101
		dc.b	%01000110
		dc.b	%01000110
		dc.b	%00111001

		dc.b	%00000000	39 '
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000

		dc.b	%00001000	40 (
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%00001000

		dc.b	%00010000	41 )
		dc.b	%00001000
		dc.b	%00001000
		dc.b	%00001000
		dc.b	%00001000
		dc.b	%00001000
		dc.b	%00001000
		dc.b	%00010000

		dc.b	%00000000	42 *
		dc.b	%00100100
		dc.b	%00011000
		dc.b	%00111100
		dc.b	%00011000
		dc.b	%00100100
		dc.b	%00000000
		dc.b	%00000000

		dc.b	%00000000	43 +
		dc.b	%00000000
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%01111100
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%00000000

		dc.b	%00000000	44 ,
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00011000
		dc.b	%00001000
		dc.b	%00010000

		dc.b	%00000000	45 -
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%01111100
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000

		dc.b	%00000000	46 .
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00000000
		dc.b	%00010000
		dc.b	%00000000

		dc.b	%00000000	47 /
		dc.b	%00000010
		dc.b	%00000100
		dc.b	%00001000
		dc.b	%00010000
		dc.b	%00100000
		dc.b	%01000000
		dc.b	%00000000

		dc.b	%00000000	48 0
		dc.b	%01111100
		dc.b	%10000110
		dc.b	%10001010
		dc.b	%10010010
		dc.b	%10100010
		dc.b	%11000010
		dc.b	%01111100

		dc.b	%00000000	49 1
		dc.b	%00010000
		dc.b	%00110000
		dc.b	%01010000
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%00010000
		dc.b	%00111000



