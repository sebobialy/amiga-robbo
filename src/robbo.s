ALLOCGFX	= 1	; Jesli rowne 1 to dane graficzne beda allokowane
			; (a jesli 0 to zostana wczytane pod adres DATA)
DATA	=	$1a0000
CLS	=	1	; Jesli 1 - czyszczenie bitplanow
ILERAMEK =	2	; Szybkosc gry (standardowa)
SYSTEMOFF =	0	; wylacza system (Forbid i Permit)
KEYBOARD =	1	; wlacza obsluge klawiatury
FLASHCOLOR =	20	; Kolor ktory blyska


* ExitFlag:
KILLED	=	1	; Robbo nie istnieje na planszy
ESCKEY	=	1	; Ktos wcisnol Esc
NEXTPLANET =	3	; Przejdz do nastepnej planety
BREAK	=	4	; przejdz do "Robbo konstruktora"
ENDGAME	=	5	; Koniec gry (wszystkie plansze ukonczone !)
DEATH	=	6	; Koniec gry (Robbo kopnol w kalendarz)



WAITBLIT	macro
		btst	#14,2(a6)
		btst	#14,2(a6)
		bne.s	*-6
		endm






		section	MainCode,code_p


		jsr	Czolowka
		bsr.s	FullGame
		rts



FullGame	bsr.w	ClsPlanszaQ
		bsr.w	InitAll
FG_Again	clr.w	ExitFlag
		bsr.s	MainLoop
		move.w	ExitFlag,d0
		cmp.w	#KILLED,d0
		beq.w	FG_Killed
		cmp.w	#NEXTPLANET,d0
		beq.w	FG_NextGame
		cmp.w	#ENDGAME,d0
		beq.w	FG_EndGame
		cmp.w	#BREAK,d0
		beq.w	FG_EndGame
FG_EndGame	bsr.w	EndAll
		rts


FG_Killed	tst.w	Zycia
		beq.w	FG_Death
		subq.w	#1,Zycia
		bra	FG_Again

FG_Death	move.w	#DEATH,ExitFlag
		bra	FG_EndGame


FG_NextGame	addq.w	#1,Planeta
		bra	FG_Again







OneGame		bsr.w	InitAll
		bsr.s	MainLoop
		bsr.w	EndAll
		rts



MainLoop	move.w	#8,RobboFlag
		move.w	#34,RobboShowChar
		move.w	Planeta,d0
		subq.w	#1,d0
		bsr.w	PrzepiszPlansze
LMB		tst.w	ExitFlag
		bne.w	ML_End
		bsr.w	Anim
		bsr.w	DrawScreen
		bsr.w	Wait
		bsr.w	Joy
		bsr.w	SzukajEkran
		bsr.w	UpdateInfo
		bsr.w	Flash
		tst.w	RobboCounter
		beq.w	ML_NoRobbo
		subq.w	#1,RobboCounter
		addq.w	#1,Counter
		btst	#6,$bfe001
		bne.b	LMB
		bra	ML_rts
ML_End		cmp.w	#BREAK,ExitFlag
		beq.w	ML_rts
		cmp.w	#NEXTPLANET,ExitFlag
		beq.w	ML_OnlyCls
		bsr.w	RozwalPlansze
		bra	ML_rts
ML_OnlyCls	bsr.w	ClsPlansza
ML_rts		rts


ML_NoRobbo	move.w	#KILLED,ExitFlag
		bra	ML_End


*************


InitAll

		IFNE	SYSTEMOFF
			move.l	4.w,a6
			jsr	-132(a6)	; Forbid
		ENDC

		bsr.s	SetScreen
		bsr.w	SetVBL
		bsr.w	CalcCharsAddress
		IFNE	KEYBOARD
			bsr.w	SetKeyboard
		ENDC
		rts

EndAll		IFNE	KEYBOARD
			bsr.w	RemKeyboard
		ENDC
		bsr.w	RemVBL

		IFNE	SYSTEMOFF
			move.l	4.w,a6
			jsr	-138(a6)	; Permit
		ENDC
		rts


SetScreen
		bsr.s	SetBitplans
		move.l	#Copper,d0
		move.w	d0,$dff082
		swap	d0
		move.w	d0,$dff080

		move.w	#160,d0
		bsr.w	SetScreenPos

		moveq	#32-1,d7
		lea	Colors,a0
		lea	Color0,a1
SS_CLoop	move.w	(a0)+,(a1)+
		tst.w	(a1)+
		dbf	d7,SS_CLoop
		bsr.w	ShowInfoBar
		rts


SetBitplans	move.l	BitplansAddress,d0
		add.l	AddBitplans,d0
		lea	AdrH,a1
		moveq	#5-1,d7
SS_Loop		move.w	d0,4(a1)
		swap	d0
		move.w	d0,(a1)
		swap	d0
		add.l	#32,d0
		addq.w	#8,a1
		dbf	d7,SS_Loop
		move.l	#InfoBitplans,d0
		lea	AdrHInfo,a1
		moveq	#5-1,d7
SSS_Loop	move.w	d0,4(a1)
		swap	d0
		move.w	d0,(a1)
		swap	d0
		add.l	#40,d0
		addq.w	#8,a1
		dbf	d7,SSS_Loop
		rts



SetScreenPosMouse
		btst	#10,$dff016
		beq.s	SSP_MakeNew
		rts

SSP_MakeNew	moveq	#0,d0
		move.b	$dff00b,d0



SetScreenPos	cmp.w	#100,d0
		bcc	SSP_Dodat
		moveq	#100,d0
		bra	SSP_Ok

SSP_Dodat	cmp.w	#220,d0
		bcs	SSP_Ok
		move.w	#220,d0

SSP_Ok		and.w	#$f0,d0
		move.w	d0,d1
		or.w	#$2500,d0
		move.w	d0,DIWSTRT
		move.w	d1,d0
		add.w	#256,d0
		and.w	#$ff,d0
		or.w	#$0500,d0
		move.w	d0,DIWSTOP
		sub.w	#16,d1
		lsr.w	#1,d1
		move.w	d1,DDFSTRT
		add.w	#120,d1
		move.w	d1,DDFSTOP
		rts



**** Wait *****
* Czeka "IleRamek" ramek (?) 

Wait		move.w	IleRamek,d0

**** WaitFrames ****
*
* d0 - Ile ramek czekac ?
*

WaitFrames
		movem.w	d0,-(sp)
		bsr.s	WaitVBL
		movem.w	(sp)+,d0
		dbf	d0,WaitFrames
		rts

WaitVBL		move.l	$dff004,d0
		lsr.l	#8,d0
		andi.w	#$1ff,d0
		cmp.w	#$120,d0
		bne.b	WaitVBL
WaitVBL_	move.l	$dff004,d0
		lsr.l	#8,d0
		andi.w	#$1ff,d0
		cmp.w	#$120,d0
		beq.b	WaitVBL_
		rts


**** SetVBL ****
* Ustawia przerwanie VERTB


SetVBL		move.w	$dff01c,d0
		or.w	#$8000,d0
		move.w	d0,INTENAR
		move.w	#$7fff,$dff09a
		move.l	$6c,OldVBL
		move.l	#VBL,$6c
		move.w	#$c020,$dff09a
		rts

**** RemVBL ****
* Usuwa przerwanie VERTB

RemVBL

		move.w	#$7fff,$dff09a
		move.l	OldVBL,$6c
		move.w	INTENAR,$dff09a
		rts

**** Procedura przerwania ****

VBL		movem.l	d0-a6,-(a7)
		bsr.w	SetScreenPosMouse
		bsr.w	Counters
		bsr.w	Scroll
		move.w	#$0020,$dff09c
		movem.l	(a7)+,d0-a6
		rte


**** Ustawia przerwanie klawiatury ****

SetKeyboard	move.w	$dff01c,d0
		or.w	#$8000,d0
		move.w	d0,INTENARK
		move.b	#%01111111,$bfed01
		move.b	#%10001000,$bfed01
		move.w	#$7fff,$dff09a
		move.l	$68,OldSDR
		move.l	#Keyboard,$68
		move.w	#$c008,$dff09a
		move.w	INTENARK,$dff09a
		rts
**** Usuwa przerwanie klawiatury ****

RemKeyboard	move.w	#$7fff,$dff09a
		move.l	OldSDR,$68
		move.w	INTENARK,$dff09a
		move.b	#%11111111,$bfed01
		rts



Keyboard	movem.l	d0-a6,-(a7)
		move.w	$dff01e,d0
		btst	#3,d0
		beq.w	K_NoCIA

		move.b	$bfed01,d0
		btst	#3,d0
		beq.w	K_NoSDR

		move.b	$bfec01,d0
		rept	150
		nop
		endr
		or.b	#%01000000,$bfee01
		move.b	#$0,$bfec01
		eor.b	#%01000000,$bfee01



		ror.b	#1,d0
		eor.b	#$ff,d0
		lea	KeyBuffer,a0
		move.w	KeyPos,d1
		move.b	d0,(a0,d1.w)
		addq.w	#1,KeyPos

		move.w	#$8,$dff09c
K_NoSDR
K_NoCIA		movem.l	(a7)+,d0-a6
		rte



**** Flash ****
* Blyska kolorem FLASHCOLOR

Flash		tst.w	FlashFlag
		beq.w	F_NoFlash
		move.w	#$aaa,Color0+(FLASHCOLOR*4)
		clr.w	FlashFlag
		rts
F_NoFlash	move.w	FLASHCOLOR*2+Colors,d0
		move.w	d0,Color0+(FLASHCOLOR*4)
		rts





**** DrawScreen ****
* Procedura rysuje ekran
* za pomoca blittera


DrawScreen
	lea	$dff000,a6
	move.w	#$09f0,$40(a6)
	move.w	#0,$42(a6)
	move.l	#-1,$44(a6)
	move.w	#0,$64(a6)
	move.w	#30,$66(a6)
	move.w	#(5*16*64)+1,d5	; BLTSIZE
	lea	Plansza+(18+1),a0
	lea	Bitplans,a1
	lea	GfxData,a2
	lea	GfxTable,a3
	lea	CharsAddress,a5

	moveq	#16-1,d7	; Liczba kolumn

DS_LoopX	WAITBLIT
		move.l	a1,$54(a6)
		addq.l	#2,a1

			movem.l	a0,-(sp)
			moveq	#32-1,d6	; Liczba wierszy

DS_LoopY			moveq	#0,d0
				move.b	(a0),d0	; Pobranie bajtu
				add.l	#18,a0
				sub.w	#32,d0
				mulu	#6,d0
				move.b	(a3,d0.w),d0
				and.l	#$000000ff,d0
				lsl.l	#2,d0
				move.l	(a5,d0.l),d0
				lea.l	(a2,d0.l),a4
				WAITBLIT
				move.l	a4,$50(a6)
				move.w	d5,$58(a6)
			dbf	d6,DS_LoopY
			movem.l	(sp)+,a0

		addq.l	#1,a0
		dbf	d7,DS_LoopX

	rts



**** Przepiszplansze ****
* d0 - numer planszy
* Przepisuje plansze do bufora ,z ktorego jest wyswietlana


PrzepiszPlansze	clr.w	Srobki
		clr.w	Naboje
		clr.w	Klucze
		lea	Plansza+(18+1),a0
		lea	Plansze,a1
		mulu	#512,d0
		lea.l	(a1,d0.w),a1
		tst.b	(a1)
		beq.w	PP_End
		moveq	#16-1,d7	; Ilosc kolumn


PP_LoopX		movem.l	a0/a1,-(sp)
			moveq	#32-1,d6	; Ilosc wierszy

PP_LoopY			move.b	(a1),d1
				cmp.b	#36,d1
				bne.b	PP_NoSrob
				addq.w	#1,Srobki
PP_NoSrob			move.b	d1,(a0)
				add.l	#16,a1
				add.l	#18,a0

			dbf	d6,PP_LoopY
		movem.l	(sp)+,a0/a1
		addq.l	#1,a0
		addq.l	#1,a1
		movem.l	d0-a6,-(sp)
		bsr.w	DrawScreen
		moveq	#1,d0
		bsr.w	WaitFrames
		movem.l	(sp)+,d0-a6
		dbf	d7,PP_LoopX
		rts

PP_End		move.w	#ENDGAME,ExitFlag
		rts


********
* Czysci plansze
*
*
ClsPlansza	lea	Plansza+(18+1),a0
		moveq	#16-1,d7	; Ilosc kolumn
CP_LoopX		movem.l	a0/a1,-(sp)
			moveq	#32-1,d6	; Ilosc wierszy
CP_LoopY			move.b	#32,(a0)
				add.l	#18,a0
			dbf	d6,CP_LoopY
		movem.l	(sp)+,a0/a1
		addq.l	#1,a0
		movem.l	d0-a6,-(sp)
		bsr.w	DrawScreen
		moveq	#1,d0
		bsr.w	WaitFrames
		movem.l	(sp)+,d0-a6
		dbf	d7,CP_LoopX
		rts

ClsPlanszaQ	lea	Plansza+(18+1),a0
		moveq	#16-1,d7	; Ilosc kolumn
CPQ_LoopX		movem.l	a0/a1,-(sp)
			moveq	#32-1,d6	; Ilosc wierszy
CPQ_LoopY			move.b	#32,(a0)
				add.l	#18,a0
			dbf	d6,CPQ_LoopY
		movem.l	(sp)+,a0/a1
		addq.l	#1,a0
		dbf	d7,CPQ_LoopX
		rts


RozwalPlansze	movem.l	d0-a6,-(sp)
		lea	Plansza,a0
		move.w	#(16+2)*(32+2)-1,d7
RP_Loop		cmp.b	#33,(a0)
		beq.w	RP_Mur
		cmp.b	#32,(a0)
		beq.w	RP_Mur
		bsr.w	Rnd
		and.b	#%11,d2
		add.b	#48,d2
		move.b	d2,(a0)
RP_Mur		addq.l	#1,a0
		dbf	d7,RP_Loop

		moveq	#9-1,d7
RP_Loop2	movem.l	d7,-(sp)
		bsr.w	DrawScreen
		bsr.w	SzukajEkran
		bsr.w	Wait
		movem.l	(sp)+,d7
		dbf	d7,RP_Loop2
		movem.l	(sp)+,d0-a6
		rts





**** Anim ****
* Animuje znaczki zgodnie z AnimTable

Anim		lea	AnimTable,a0
		lea	GfxTable,a1
A__Loop		moveq	#0,d0
		move.b	(a0),d0
		tst.b	d0
		beq.w	A__End
		tst.b	3(a0)
		bne.b	A__JeszczeNie
		move.b	2(a0),d0
		subq.w	#1,d0
		move.b	d0,3(a0)
		move.b	4(a0),d0
		move.b	5(a0,d0.w),d0
		moveq	#0,d1
		move.b	(a0),d1
		sub.b	#32,d1
		mulu	#6,d1
		move.b	d0,(a1,d1.w)
		move.b	1(a0),d0
		subq.w	#1,d0
		cmp.b	4(a0),d0
		bne.b	A__NZero
		move.b	#-1,4(a0)
A__NZero	addq.b	#1,4(a0)
		bra	A__Next
A__End		rts

A__JeszczeNie	subq.b	#1,3(a0)
		bra	A__Next

A__Next		moveq	#0,d0
		move.b	1(a0),d0
		addq.b	#5,d0
		add.l	d0,a0
		bra	A__Loop


**** Szukaj ekran ****
* obsluga wszystkich objektow na planszy


SzukajEkran	clr.l	RobboAddress
		lea	Plansza,a0
		lea	GfxTable,a1
		move.w	#(16+2)*(32+2),d7

SE_Loop		moveq	#0,d0
		move.b	(a0)+,d0
		btst	#7,d0
		beq.b	SE_Call
		and.b	#%01111111,d0
		move.b	d0,-1(a0)
		bra	SE_Next

SE_Call
		sub.b	#32,d0
		mulu	#6,d0
		lea.l	(a1,d0.w),a2
		tst.l	2(a2)
		beq.w	SE_NoFunc


		move.l	2(a2),a2
		movem.l	d0-a6,-(sp)
		subq.l	#1,a0
		moveq	#32,d0
		jsr	(a2)
		movem.l	(sp)+,d0-a6

SE_NoFunc
SE_Next		dbf	d7,SE_Loop


		tst.l	RobboAddress
		beq.w	NoRobbo

		move.l	RobboAddress,a0
		moveq	#32,d0
		bsr.w	Robbo

NoRobbo		rts


***************************************************************************

***************************************************************************

***************************************************************************




PtaszekWPrawo	cmp.b	1(a0),d0
		bne.w	PWP_Change
		move.b	#37+128,1(a0)
		move.b	d0,(a0)
		rts
PWP_Change	move.b	#38,(a0)
		rts

PtaszekWLewo	cmp.b	-1(a0),d0
		bne.b	PWL_Change
		move.b	(a0),-1(a0)
		move.b	d0,(a0)
		rts
PWL_Change	move.b	#37,(a0)
		rts

PtaszekWGore	cmp.b	-18(a0),d0
		bne.b	PWG_Change
		move.b	(a0),-18(a0)
		move.b	d0,(a0)
		rts
PWG_Change	move.b	#47,(a0)
		rts

PtaszekWDol	cmp.b	18(a0),d0
		bne.b	PWD_Change
		move.b	#47+128,18(a0)
		move.b	d0,(a0)
		rts
PWD_Change	move.b	#46,(a0)
		rts


***********************************

AddWybuch	addq.b	#1,(a0)
		rts
ClsWybuch	move.b	#32,(a0)
		rts

***********************************

NabojWLewo	cmp.b	-1(a0),d0
		beq.w	NWL_Przesun
		cmp.b	#81,-1(a0)
		beq.w	NWL_Przesun
		lea.l	-1(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	NWL_NieZabij
		move.b	#48,-1(a0)
		move.b	d0,(a0)
		rts
NWL_NieZabij	move.b	#54,(a0)
		rts
NWL_Przesun	move.b	d0,(a0)
		move.b	#65,-1(a0)
		rts

NabojWPrawo	cmp.b	1(a0),d0
		beq.w	NWP_Przesun
		cmp.b	#79,1(a0)
		beq.w	NWP_Przesun
		lea.l	1(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	NWP_NieZabij
		move.b	#48+128,1(a0)
		move.b	d0,(a0)
		rts
NWP_NieZabij	move.b	#54,(a0)
		rts
NWP_Przesun	move.b	d0,(a0)
		move.b	#67+128,1(a0)
		rts


NabojWGore	cmp.b	-18(a0),d0
		beq.w	NWG_Przesun
		cmp.b	#82,-18(a0)
		beq.w	NWG_Przesun
		lea.l	-18(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	NWG_NieZabij
		move.b	#48,-18(a0)
		move.b	d0,(a0)
		rts
NWG_NieZabij	move.b	#54,(a0)
		rts
NWG_Przesun	move.b	d0,(a0)
		move.b	#66,-18(a0)
		rts




NabojWDol	cmp.b	18(a0),d0
		beq.w	NWD_Przesun
		cmp.b	#80,18(a0)
		beq.w	NWD_Przesun
		lea.l	18(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	NWD_NieZabij
		move.b	#48+128,18(a0)
		move.b	d0,(a0)
		rts
NWD_NieZabij	move.b	#54,(a0)
		rts
NWD_Przesun	move.b	d0,(a0)
		move.b	#68+128,18(a0)
		rts

**********************************


DzialkoWLewo	bsr.w	Rnd2
		tst.l	d1
		bne.w	DWL_Strzal
		rts
DWL_Strzal	cmp.b	-1(a0),d0
		beq.w	DWL_Czysto
		lea.l	-1(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	DWL_Cant
		move.b	#48,-1(a0)
DWL_Cant	rts
DWL_Czysto	move.b	#65,-1(a0)
		rts

DzialkoWGore	bsr.w	Rnd2
		tst.l	d1
		bne.w	DWG_Strzal
		rts
DWG_Strzal	cmp.b	-18(a0),d0
		beq.w	DWG_Czysto
		lea.l	-18(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	DWG_Cant
		move.b	#48,-18(a0)
DWG_Cant	rts
DWG_Czysto	move.b	#66,-18(a0)
		rts

DzialkoWPrawo	bsr.w	Rnd4
		tst.l	d1
		bne.w	DWP_Strzal
		rts
DWP_Strzal	cmp.b	1(a0),d0
		beq.w	DWP_Czysto
		lea.l	1(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	DWP_Cant
		move.b	#48+128,1(a0)
DWP_Cant	rts
DWP_Czysto	move.b	#67+128,1(a0)
		rts

DzialkoWDol	bsr.w	Rnd2
		tst.l	d1
		bne.w	DWD_Strzal
		rts
DWD_Strzal	cmp.b	18(a0),d0
		beq.w	DWD_Czysto
		lea.l	18(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	DWD_Cant
		move.b	#48+128,18(a0)
DWD_Cant	rts
DWD_Czysto	move.b	#68+128,18(a0)
		rts

***********************************


DzialkoObrotoweWLewo
		bsr.w	Rnd4
		tst.l	d1
		bne.b	DOWL_Zmien
		bsr.w	DzialkoWLewo
		rts
DOWL_Zmien	bsr.w	Rnd
		tst.l	d1
		beq.w	DOWL_WPrawo
		move.b	#72,(a0)
		rts
DOWL_WPrawo	move.b	#70,(a0)
		rts

DzialkoObrotoweWGore
		bsr.w	Rnd4
		tst.l	d1
		bne.b	DOWG_Zmien
		bsr.w	DzialkoWGore
		rts
DOWG_Zmien	bsr.w	Rnd
		tst.l	d1
		beq.w	DOWG_WPrawo
		move.b	#69,(a0)
		rts
DOWG_WPrawo	move.b	#71,(a0)
		rts

DzialkoObrotoweWPrawo
		bsr.w	Rnd4
		tst.l	d1
		bne.b	DOWP_Zmien
		bsr.w	DzialkoWPrawo
		rts
DOWP_Zmien	bsr.w	Rnd
		tst.l	d1
		beq.w	DOWP_WPrawo
		move.b	#70,(a0)
		rts
DOWP_WPrawo	move.b	#72,(a0)
		rts

DzialkoObrotoweWDol
		bsr.w	Rnd4
		tst.l	d1
		bne.b	DOWD_Zmien
		bsr.w	DzialkoWDol
		rts
DOWD_Zmien	bsr.w	Rnd
		tst.l	d1
		beq.w	DOWD_WPrawo
		move.b	#71,(a0)
		rts
DOWD_WPrawo	move.b	#69,(a0)
		rts

***************************************

DzialkoChodzaceWPrawo
		move.w	Counter,d1
		btst	#0,d1
		beq.w	DCWP_Stop
		cmp.b	1(a0),d0
		beq.w	DCWP_Clear
		move.b	#57,(a0)
		bsr.w	DzialkoWGore
		rts
DCWP_Clear	move.b	d0,(a0)
		move.b	#56+128,1(a0)
		lea	1(a0),a0
		bsr.w	DzialkoWGore
DCWP_Stop	rts

DzialkoChodzaceWLewo
		move.w	Counter,d1
		btst	#0,d1
		beq.w	DCWL_Stop
		cmp.b	-1(a0),d0
		beq.w	DCWL_Clear
		move.b	#56,(a0)
		bsr.w	DzialkoWGore
		rts
DCWL_Clear	move.b	d0,(a0)
		move.b	#57,-1(a0)
		lea	-1(a0),a0
		bsr.w	DzialkoWGore
DCWL_Stop	rts

*************************************

DzialkoPrzesuwalne
		bra	DzialkoWGore
		rts

*************************************


PtaszekSrajacyWPrawo
		cmp.b	1(a0),d0
		bne.w	PSWP_Change
		move.b	#73+128,1(a0)
		move.b	d0,(a0)
		lea	1(a0),a0
		bsr.w	DzialkoWDol
		rts
PSWP_Change	move.b	#74,(a0)
		bsr.w	DzialkoWDol
		rts

PtaszekSrajacyWLewo
		cmp.b	-1(a0),d0
		bne.w	PSWL_Change
		move.b	#74,-1(a0)
		move.b	d0,(a0)
		lea	-1(a0),a0
		bsr.w	DzialkoWDol
		rts
PSWL_Change	move.b	#73,(a0)
		bsr.w	DzialkoWDol
		rts

***************************************


NabojZeSlademWLewo
		cmp.b	-1(a0),d0
		beq.w	NZSWL_Przesun
		lea.l	-1(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.w	NZSWL_NieZabij
		move.b	#48,-1(a0)
		move.b	#67,(a0)
		rts
NZSWL_NieZabij	move.b	#67,(a0)
		rts
NZSWL_Przesun	move.b	#79,(a0)
		move.b	#75,-1(a0)
		rts

NabojZeSlademWGore
		cmp.b	-18(a0),d0
		beq.w	NZSWG_Przesun
		lea.l	-18(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.w	NZSWG_NieZabij
		move.b	#48,-18(a0)
		move.b	#68,(a0)
		rts
NZSWG_NieZabij	move.b	#68,(a0)
		rts
NZSWG_Przesun	move.b	#80,(a0)
		move.b	#76,-18(a0)
		rts


NabojZeSlademWPrawo
		cmp.b	1(a0),d0
		beq.w	NZSWP_Przesun
		lea.l	1(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.w	NZSWP_NieZabij
		move.b	#48+128,1(a0)
		move.b	#65,(a0)
		rts
NZSWP_NieZabij	move.b	#65,(a0)
		rts
NZSWP_Przesun	move.b	#81,(a0)
		move.b	#77+128,1(a0)
		rts

NabojZeSlademWDol
		cmp.b	18(a0),d0
		beq.w	NZSWD_Przesun
		lea.l	18(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.w	NZSWD_NieZabij
		move.b	#48+128,18(a0)
		move.b	#66,(a0)
		rts
NZSWD_NieZabij	move.b	#66,(a0)
		rts
NZSWD_Przesun	move.b	#82,(a0)
		move.b	#78+128,18(a0)
		rts








***********************************


SladWLewo	cmp.b	#79,-1(a0)
		beq.w	SWL_Stop
		cmp.b	#67,-1(a0)
		beq.w	SWL_Stop
		move.b	#67,(a0)
SWL_Stop	rts

SladWGore	cmp.b	#80,-18(a0)
		beq.w	SWG_Stop
		cmp.b	#68,-18(a0)
		beq.w	SWG_Stop
		move.b	#68,(a0)
SWG_Stop	rts

SladWPrawo	cmp.b	#81,1(a0)
		beq.w	SWP_Stop
		cmp.b	#65,1(a0)
		beq.w	SWP_Stop
		cmp.b	#77,1(a0)
		beq.w	SWP_Stop
		move.b	#65,(a0)
SWP_Stop	rts

SladWDol	cmp.b	#82,18(a0)
		beq.w	SWD_Stop
		cmp.b	#66,18(a0)
		beq.w	SWD_Stop
		cmp.b	#78,18(a0)
		beq.w	SWP_Stop
		move.b	#66+128,(a0)
SWD_Stop	rts

*************************************

DzialkoZeSlademWLewo
		bsr.w	Rnd3
		tst.l	d1
		bne.w	DZSWL_Strzal
		rts
DZSWL_Strzal	cmp.b	-1(a0),d0
		beq.w	DZSWL_Czysto
		lea.l	-1(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	DZSWL_Cant
		move.b	#48,-1(a0)
DZSWL_Cant	rts
DZSWL_Czysto	move.b	#75,-1(a0)
		rts

DzialkoZeSlademWGore
		bsr.w	Rnd3
		tst.l	d1
		bne.w	DZSWG_Strzal
		rts
DZSWG_Strzal	cmp.b	-18(a0),d0
		beq.w	DZSWG_Czysto
		lea.l	-18(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	DZSWG_Cant
		move.b	#48,-18(a0)
DZSWG_Cant	rts
DZSWG_Czysto	move.b	#76,-18(a0)
		rts

DzialkoZeSlademWPrawo
		bsr.w	Rnd3
		tst.l	d1
		bne.w	DZSWP_Strzal
		rts
DZSWP_Strzal	cmp.b	1(a0),d0
		beq.w	DZSWP_Czysto
		lea.l	1(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	DZSWP_Cant
		move.b	#48+128,1(a0)
DZSWP_Cant	rts
DZSWP_Czysto	move.b	#77+128,1(a0)
		rts

DzialkoZeSlademWDol
		bsr.w	Rnd3
		tst.l	d1
		bne.w	DZSWD_Strzal
		rts
DZSWD_Strzal	cmp.b	18(a0),d0
		beq.w	DZSWD_Czysto
		lea.l	18(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	DZSWD_Cant
		move.b	#48+128,18(a0)
DZSWD_Cant	rts
DZSWD_Czysto	move.b	#78+128,18(a0)
		rts


***************************************




Bomba		move.b	#89,(a0)
		rts


BombaWybuchajaca
		move.b	d0,(a0)
		lea	-19(a0),a1
		bsr.s	B_CheckLine
		lea	-1(a0),a1
		bsr.s	B_CheckLine
		lea	17(a0),a1
		bsr.s	B_CheckLine
		rts

B_CheckLine	bsr.s	B_CheckChar
		addq.l	#1,a1
		bsr.s	B_CheckChar
		addq.l	#1,a1
		bsr.s	B_CheckChar
		rts

B_CheckChar	lea	BombTable,a2
		move.b	(a1),d2
		cmp.b	#64,d2
		beq.w	B_NextBomb
B_Loop		tst.b	(a2)
		beq.w	B_Kill
		cmp.b	(a2)+,d2
		beq.w	B_Zostaw
		bra	B_Loop
B_Kill		moveq	#0,d2
		bsr.w	Rnd
		and.b	#%00000011,d2
		add.b	#48,d2
		bsr.s	B_SetNeg
		move.b	d2,(a1)
B_Zostaw	rts

B_NextBomb	move.b	#88,d2
		bsr.s	B_SetNeg
		move.b	d2,(a1)
		rts

B_SetNeg	cmp.l	a0,a1
		ble.b	B_Zostaw
		bset	#7,d2
		rts

***********************************

RobboWciaganyWLewo
		cmp.b	-1(a0),d0
		beq.w	RWWL_Ok
		move.b	#48,(a0)
		rts
RWWL_Ok		move.b	(a0),-1(a0)
		move.b	d0,(a0)
		rts

RobboWciaganyWPrawo
		cmp.b	1(a0),d0
		beq.w	RWWP_Ok
		move.b	#48,(a0)
		rts
RWWP_Ok		move.b	#91+128,1(a0)
		move.b	d0,(a0)
		rts


***********************************

MagnesWPrawo	moveq	#16-1,d7
		lea.l	1(a0),a1
MWP_Loop	move.b	(a1)+,d1
		cmp.b	#87,d1
		beq.w	MWP_Robbo
		cmp.b	#87+128,d1
		beq.w	MWP_Robbo
		cmp.b	#32,d1
		bne.b	MWP_rts
		dbf	d7,MWP_Loop
MWP_rts		rts

MWP_Robbo	move.b	#90+128,-1(a1)
		rts

MagnesWLewo	moveq	#16-1,d7
		lea.l	(a0),a1
MWL_Loop	move.b	-(a1),d1
		cmp.b	#87,d1
		beq.w	MWL_Robbo
		cmp.b	#87+128,d1
		beq.w	MWL_Robbo
		cmp.b	#32,d1
		bne.b	MWL_rts
		dbf	d7,MWL_Loop
MWL_rts		rts

MWL_Robbo	move.b	#91,(a1)
		rts


***********************************

KapsulaZamknieta
		tst.w	Srobki
		bne.b	KZ_Nic
		move.b	#34,(a0)
		move.w	d0,FlashFlag
KZ_Nic		rts





***********************************

RobboProc	move.l	a0,RobboAddress
		move.l	a0,d1
		sub.l	#Plansza,d1
		divu	#18,d1
		subq.w	#1,d1
		move.w	d1,RobboPosY
		rts

***********************************


Robbo		move.w	#15,RobboCounter
		tst.w	RobboFlag
		beq.w	R_Norm
		bra	R_Pojawiaj

R_Norm		bsr.w	CzyZabicRobbo
		tst.w	d1
		beq.w	R_NieZab
		rts
R_NieZab	move.w	JoyData,d1
		tst.w	d1
		beq.w	R_Nic
		cmp.w	#1,d1
		beq.w	RobboWGore
		cmp.w	#2,d1
		beq.w	RobboWPrawo
		cmp.w	#4,d1
		beq.w	RobboWDol
		cmp.w	#8,d1
		beq.w	RobboWLewo

R_Nic		rts


ShowFaza	clr.l	d1
		move.w	RobboFaza,d2
		tst.w	d2
		bne.b	R_NieGora
		moveq	#1,d1
R_NieGora	cmp.w	#1,d2
		bne.b	R_NiePrawo
		moveq	#2,d1
R_NiePrawo	cmp.w	#3,d2
		bne.b	R_NieLewo
		moveq	#3,d1
R_NieLewo	lsl.w	#1,d1
		add.w	#34,d1
		add.w	RobboEorFaza,d1
		move.b	d1,RobboChar
		rts



R_Pojawiaj	move.w	RobboFlag,d2
		subq.w	#1,RobboFlag
		moveq	#34,d3
		sub.w	d2,d3
		cmp.b	#25,d3
		beq.w	R_Kap
		cmp.b	#33,d3
		beq.w	R_Pok
		move.b	d3,RobboChar
		rts
R_Kap		move.b	#12,RobboChar
		rts
R_Pok		move.w	RobboShowChar,d3
		move.b	d3,RobboChar
		rts



***************

RobboWGore	clr.w	RobboFaza
		bsr.s	ShowFaza
		tst.w	FireFlag
		bne.w	RobboFireWGore
		cmp.b	-18(a0),d0
		beq.w	RWG_Go
		lea	-18(a0),a1
		moveq	#3,d3
		bsr.w	CoZTymZrobic
		tst.l	d1
		beq.w	RWG_Stop
		cmp.b	#2,d1
		beq.w	RWG_Przesun
		cmp.b	#1,d1
		beq.w	RWG_Go
		rts

RWG_Go		eor.w	#1,RobboEorFaza
		move.b	(a0),-18(a0)
		move.b	d0,(a0)
		lea	-18(a0),a0
		bsr.w	CzyZabicRobbo
RWG_Stop	rts


RobboFireWGore
		eor.w	#1,RobboEorFaza
		tst.w	FireCounter
		bne.b	RFWG_NotNow
		tst.w	Naboje
		beq.w	RFWG_NoNab
		subq.w	#1,Naboje
		bsr.w	DWG_Strzal	; pewne dzialko
RFWG_NoNab	move.w	#5,FireCounter
		rts
RFWG_NotNow	subq.w	#1,FireCounter
		rts

RWG_Przesun	cmp.b	-36(a0),d0
		bne.b	RWG_Stop
		move.b	-18(a0),d1
		bclr	#7,d1
		move.b	d1,-36(a0)
		bra	RWG_Go



***************


RobboWPrawo	move.w	#1,RobboFaza
		bsr.w	ShowFaza
		tst.w	FireFlag
		bne.w	RobboFireWPrawo
		cmp.b	1(a0),d0
		beq.w	RWP_Go
		lea	1(a0),a1
		moveq	#0,d3
		bsr.w	CoZTymZrobic
		tst.l	d1
		beq.w	RWP_Stop
		cmp.b	#2,d1
		beq.w	RWP_Przesun
		cmp.b	#1,d1
		beq.w	RWP_Go
		rts
RWP_Go
		eor.w	#1,RobboEorFaza
		move.b	(a0),1(a0)
		move.b	d0,(a0)
		lea	1(a0),a0
		bsr.w	CzyZabicRobbo
RWP_Stop	rts

RWP_Przesun	cmp.b	2(a0),d0
		bne.b	RWP_Stop
		move.b	1(a0),d1
		bclr	#7,d1
		move.b	d1,2(a0)
		bra	RWP_Go



RobboFireWPrawo
		eor.w	#1,RobboEorFaza
		tst.w	FireCounter
		bne.b	RFWP_NotNow
		move.w	#5,FireCounter	
		tst.w	Naboje
		beq.w	RFWP_NoNab
		subq.w	#1,Naboje
RFWP_Strzal	cmp.b	1(a0),d0
		beq.w	RFWP_Czysto
		lea.l	1(a0),a1
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	RFWP_Cant
		move.b	#48,1(a0)
RFWP_NoNab
RFWP_Cant	rts
RFWP_Czysto	move.b	#67,1(a0)
		rts

RFWP_NotNow	subq.w	#1,FireCounter
		rts


***************

RobboWDol	move.w	#2,RobboFaza
		bsr.w	ShowFaza
		tst.w	FireFlag
		bne.b	RobboFireWDol
		cmp.b	18(a0),d0
		beq.w	RWD_Go
		lea	18(a0),a1
		moveq	#1,d3
		bsr.w	CoZTymZrobic
		tst.l	d1
		beq.w	RWD_Stop
		cmp.b	#2,d1
		beq.w	RWD_Przesun
		cmp.b	#1,d1
		beq.w	RWD_Go
		rts

RWD_Go
		eor.w	#1,RobboEorFaza
		move.b	(a0),18(a0)
		move.b	d0,(a0)
		lea	18(a0),a0
		bsr.w	CzyZabicRobbo
RWD_Stop	rts

RWD_Przesun	cmp.b	36(a0),d0
		bne.b	RWD_Stop
		move.b	18(a0),d1
		bclr	#7,d1
		move.b	d1,36(a0)
		bra	RWD_Go




RobboFireWDol
		eor.w	#1,RobboEorFaza
		tst.w	FireCounter
		bne.b	RFWD_NotNow
		move.w	#5,FireCounter
		tst.w	Naboje
		beq.w	RFWD_NoNab
		subq.w	#1,Naboje

		cmp.b	18(a0),d0
		beq.w	RFWD_Czysto
		lea.l	18(a0),a1
		moveq	#2,d3
		bsr.w	CzyZabic
		tst.l	d1
		beq.b	RFWD_Cant
		move.b	#48,18(a0)
RFWD_NoNab
RFWD_Cant	rts
RFWD_Czysto	move.b	#68,18(a0)
		rts

RFWD_NotNow	subq.w	#1,FireCounter
		rts


****************


RobboWLewo	move.w	#3,RobboFaza
		bsr.w	ShowFaza
		tst.w	FireFlag
		bne.b	RobboFireWLewo
		cmp.b	-1(a0),d0
		beq.w	RWL_Go
		lea	-1(a0),a1
		moveq	#2,d3
		bsr.w	CoZTymZrobic
		tst.l	d1
		beq.w	RWL_Stop
		cmp.b	#2,d1
		beq.w	RWL_Przesun
		cmp.b	#1,d1
		beq.w	RWL_Go
		rts
RWL_Go
		eor.w	#1,RobboEorFaza
		move.b	(a0),-1(a0)
		move.b	d0,(a0)
		lea	-1(a0),a0
		bsr.s	CzyZabicRobbo
RWL_Stop	rts


RWL_Przesun	cmp.b	-2(a0),d0
		bne.b	RWL_Stop
		move.b	-1(a0),d1
		bclr	#7,d1
		move.b	d1,-2(a0)
		bra	RWL_Go

RobboFireWLewo
		eor.w	#1,RobboEorFaza
		tst.w	FireCounter
		bne.b	RFWL_NotNow
		move.w	#5,FireCounter
		tst.w	Naboje
		beq.w	RFWL_NoNab
		subq.w	#1,Naboje
		bsr.w	DWL_Strzal
RFWL_NoNab	rts

RFWL_NotNow	subq.w	#1,FireCounter
		rts


CzyZabicRobbo	movem.l	d0/d2-a6,-(sp)
		moveq	#0,d1
		move.b	1(a0),d2
		bsr.s	CZR_Sprawdz
		move.b	-1(a0),d2
		bsr.s	CZR_Sprawdz
		move.b	18(a0),d2
		bsr.s	CZR_Sprawdz
		move.b	-18(a0),d2
		bsr.s	CZR_Sprawdz
		movem.l	(sp)+,d0/d2-a6
		rts

CZR_Sprawdz	lea	RobboKillTable,a3
CZRS_Loop	tst.b	(a3)
		beq.w	CZRS_End
		cmp.b	(a3)+,d2
		bne.b	CZRS_Loop
		moveq	#1,d1
		move.b	#48,(a0)
CZRS_End	rts




*****************************************

Dodatek		cmp.w	#99,Zycia
		beq.w	D_Cant
		addq.w	#1,Zycia
D_Cant		moveq	#1,d1
		move.l	#$00010000,AddValue
		bsr.w	AddScore
		rts

Srobka		tst.w	Srobki
		beq.w	S_Zero
		subq.w	#1,Srobki
S_Zero		moveq	#1,d1
		move.l	#$00000300,AddValue
		bsr.w	AddScore
		rts


Drzwi		tst.w	Klucze
		beq.w	D_Zero
		subq.w	#1,Klucze
		move.b	d0,(a1)
		move.l	#$00000200,AddValue
		bsr.w	AddScore
D_Zero		moveq	#0,d1
		rts

Klucz		cmp.w	#99,Klucze
		beq.w	K_Cant
		addq.w	#1,Klucze
K_Cant		moveq	#1,d1
		move.l	#$00000400,AddValue
		bsr.w	AddScore
		rts



Naboj		addq.w	#8,Naboje
		cmp.w	#99,Naboje
		bcs.w	N_99
		move.w	#99,Naboje
N_99		moveq	#1,d1
		move.l	#$00000300,AddValue
		bsr.w	AddScore
		rts
		




KapsulaOtwarta	move.w	#NEXTPLANET,ExitFlag
		rts




****************************************

**** Co z tym zrobic ****
* Sprawdza co zrobic ze znakiem w (a1)
* d3 :	0 - Robbo w prawo
* 	1 - Robbo w dol
*	2 - Robbo w lewo
*	3 - Robbo w gore
****
* d1 -0 - Nic nie rob
* d1 -1 - Wez
* d1 -2 - Przesun



CoZTymZrobic
		movem.l	d2/a1/a2,-(sp)
		moveq	#0,d1
		move.b	(a1),d2
		cmp.b	#97,d2
		bne.b	CZTZ_NieTeleport1
		bsr.s	CZTZ_ToTeleport

CZTZ_NieTeleport1
		cmp.b	#98,d2
		bne.b	CZTZ_NieTeleport2
		bsr.s	CZTZ_ToTeleport

CZTZ_NieTeleport2
		cmp.b	#99,d2
		bne.b	CZTZ_NieTeleport3
		bsr.s	CZTZ_ToTeleport

CZTZ_NieTeleport3
		cmp.b	#100,d2
		bne.b	CZTZ_NieTeleport4
		bsr.s	CZTZ_ToTeleport

CZTZ_NieTeleport4
		cmp.b	#101,d2
		bne.b	CZTZ_NieTeleport5
		bsr.s	CZTZ_ToTeleport

CZTZ_NieTeleport5
		cmp.b	#102,d2
		bne.b	CZTZ_NieTeleport6
		bsr.s	CZTZ_ToTeleport

CZTZ_NieTeleport6


		lea	MoveTable,a2
CZTZ_Loop	tst.b	(a2)
		beq.w	CZTZ_EndMove
		cmp.b	(a2)+,d2
		bne.b	CZTZ_Loop
		moveq	#2,d1
		bra	CZTZ_End
CZTZ_EndMove	lea	GetTable,a2

CZTZ_Loop2	tst.b	(a2)
		beq.w	CZTZ_End
		addq.l	#6,a2
		cmp.b	-6(a2),d2
		bne.b	CZTZ_Loop2
		move.l	-4(a2),a3
		movem.l	d0/d2-d7/a0-a6,-(sp)
		jsr	(a3)
		movem.l	(sp)+,d0/d2-d7/a0-a6
CZTZ_End	movem.l	(sp)+,d2/a1/a2
		rts







***********************
* procedury teleportacji
***********************
******************
************
*****
*

CZTZ_ToTeleport	movem.l	d0-a6,-(sp)
		move.b	#48,(a0)	; Robbo znika z aktualnej pozycji
		move.b	d3,RobboWTeleporcie+1	; Kierunek robbo
		move.b	(a1),d2
		sub.b	#96,d2
		move.b	d2,RobboWTeleporcie	; Numer teleportu
		lea	1(a1),a1
		bsr.s	Teleport
		movem.l	(sp)+,d0-a6
		rts


AutoTeleport	lea.l	(a0),a1
		bra	Teleport




*******
* a1 - Poczatek poszukiwania



Teleport	move.b	RobboWTeleporcie,d3
		beq.w	T_NieMaTeleportu
		add.b	#96,d3		; Obliczenie numeru teleportu
					; rzeczywistego (97,98,99,100,...)
		move.l	a1,a3
		lea	Plansza+(16+2)*(31+2),a2	; Koniec planszy
T_Loop1		cmp.l	a2,a3
		beq.w	T_Loop1End
		cmp.b	(a3),d3		; Czy to "cos" to teleport ?
		bne.b	T_Loop1Nie
		bsr.s	T_Sprawdz
		tst.l	d1
		beq.w	T_RobboWyszedl
T_Loop1Nie	addq.l	#1,a3
		bra	T_Loop1


T_Loop1End	lea	1(a1),a2
		lea	Plansza,a3

T_Loop2		cmp.l	a2,a3
		beq.w	T_Loop2End
		cmp.b	(a3),d3		; Czy to "cos" to teleport ?
		bne.b	T_Loop2Nie
		bsr.s	T_Sprawdz
		tst.l	d1
		beq.w	T_RobboWyszedl
T_Loop2Nie	addq.l	#1,a3
		bra	T_Loop2


T_Loop2End
T_NieMaTeleportu
		rts


T_RobboWyszedl	clr.w	RobboWTeleporcie
		rts


*********
* Sprawdza czy Robbo moze "wyjsc" tym teleportem
* a3 - adres teleportu
*****
* d1 - 0 - Robbo wyszedl
T_Sprawdz	movem.l	d2-a6,-(sp)
		moveq	#1,d1
		move.b	RobboWTeleporcie+1,d2
		bne.b	T_NieWPrawo
		bsr.w	T_WPrawo
		bra	T_Zajety
T_NieWPrawo	cmp.b	#1,d2
		bne.b	T_NieWDol
		bsr.s	T_WDol
		bra	T_Zajety
T_NieWDol	cmp.b	#2,d2
		bne.b	T_NieWLewo
		bsr.s	T_WLewo
		bra	T_Zajety
T_NieWLewo	cmp.b	#3,d2
		bne.b	T_NieWGore
		bsr.s	T_WGore
		bra	T_Zajety
T_NieWGore
T_Zajety	movem.l	(sp)+,d2-a6
		rts


T_WPrawo	bsr.s	T_Right
		bsr.s	T_Left
		bsr.w	T_Up
		bsr.w	T_Down
		rts

T_WLewo		bsr.w	T_Left
		bsr.s	T_Right
		bsr.w	T_Down
		bsr.s	T_Up
		rts

T_WGore		bsr.s	T_Up
		bsr.w	T_Down
		bsr.s	T_Right
		bsr.s	T_Left
		rts

T_WDol		bsr.w	T_Down
		bsr.s	T_Up
		bsr.s	T_Left
		bsr.s	T_Right
		rts







T_Right		cmp.b	1(a3),d0
		beq.w	T_WyjdzR
		rts
T_WyjdzR	move.b	#87,1(a3)
		moveq	#0,d1
		movem.l	(sp)+,d7
		move.b	#26,RobboChar
		move.w	#7,RobboFlag
		move.w	#38,RobboShowChar
		rts

T_Left		cmp.b	-1(a3),d0
		beq.w	T_WyjdzL
		rts
T_WyjdzL	move.b	#87,-1(a3)
		moveq	#0,d1
		movem.l	(sp)+,d7
		move.b	#26,RobboChar
		move.w	#7,RobboFlag
		move.w	#40,RobboShowChar
		rts

T_Up		cmp.b	-18(a3),d0
		beq.w	T_WyjdzU
		rts
T_WyjdzU	move.b	#87,-18(a3)
		moveq	#0,d1
		movem.l	(sp)+,d7
		move.b	#26,RobboChar
		move.w	#7,RobboFlag
		move.w	#36,RobboShowChar
		rts

T_Down		cmp.b	18(a3),d0
		beq.w	T_WyjdzD
		rts
T_WyjdzD	move.b	#87,18(a3)
		moveq	#0,d1
		movem.l	(sp)+,d7
		move.b	#26,RobboChar
		move.w	#7,RobboFlag
		move.w	#34,RobboShowChar
		rts






*
*****
***********
*****************
**********************




***************************************

SowaWLewo	cmp.b	-1(a0),d0
		bne.w	SWL_WGore
		move.b	d0,(a0)
		cmp.b	17(a0),d0
		beq.w	SWL_WDol
		move.b	#103,-1(a0)
		rts
SWL_WDol	move.b	#104,-1(a0)
		rts
SWL_WGore	move.b	#106,(a0)
		rts


SowaWDol	cmp.b	18(a0),d0
		bne.b	SWD_WLewo
		move.b	d0,(a0)
		cmp.b	19(a0),d0
		beq.w	SWD_WPrawo
		move.b	#104+128,18(a0)
		rts
SWD_WPrawo	move.b	#105+128,18(a0)
		rts
SWD_WLewo	move.b	#103,(a0)
		rts


SowaWPrawo	cmp.b	1(a0),d0
		bne.b	SWP_WDol
		move.b	d0,(a0)
		cmp.b	-17(a0),d0
		beq.w	SWP_WGore
		move.b	#105+128,1(a0)
		rts
SWP_WGore	move.b	#106+128,1(a0)
		rts
SWP_WDol	move.b	#104,(a0)
		rts


SowaWGore	cmp.b	-18(a0),d0
		bne.w	SWG_WPrawo
		move.b	d0,(a0)
		cmp.b	-19(a0),d0
		beq.w	SWG_WLewo
		move.b	#106,-18(a0)
		rts
SWG_WLewo	move.b	#103,-18(a0)
		rts
SWG_WPrawo	move.b	#105,(a0)
		rts


**********************************


StworekWPrawo	cmp.b	1(a0),d0
		bne.b	SSWP_WGore
		move.b	d0,(a0)
		cmp.b	19(a0),d0
		beq.w	SSWP_WDol
		move.b	#107+128,1(a0)
		rts
SSWP_WDol	move.b	#110+128,1(a0)
		rts
SSWP_WGore	move.b	#108,(a0)
		rts


StworekWGore	cmp.b	-18(a0),d0
		bne.b	SSWG_WLewo
		move.b	d0,(a0)
		cmp.b	-17(a0),d0
		beq.w	SSWG_WPrawo
		move.b	#108,-18(a0)
		rts
SSWG_WPrawo	move.b	#107,-18(a0)
		rts
SSWG_WLewo	move.b	#109,(a0)
		rts


StworekWLewo	cmp.b	-1(a0),d0
		bne.b	SSWL_WDol
		move.b	d0,(a0)
		cmp.b	-19(a0),d0
		beq.w	SSWL_WGore
		move.b	#109,-1(a0)
		rts
SSWL_WGore	move.b	#108,-1(a0)
		rts
SSWL_WDol	move.b	#110,(a0)
		rts




StworekWDol	cmp.b	18(a0),d0
		bne.b	SSWD_WPrawo
		move.b	d0,(a0)
		cmp.b	17(a0),d0
		beq.w	SSWD_WLewo
		move.b	#110+128,18(a0)
		rts
SSWD_WLewo	move.b	#109+128,18(a0)
		rts
SSWD_WPrawo	move.b	#107,(a0)
		rts













**** czy zabic ***
* Sprawdza czy znak pod adresem a1 ma zostac zniszczony
* (automatycznie sprawdza bombe i ja ustawia)
***
* d1 = 0 - Zostaw
* d1 = 1 - Zabij

CzyZabic	movem.l	d0/d2/a0/a1/a2,-(sp)
		lea	KillTable,a2
		moveq	#0,d1
		move.b	(a1),d2
		bclr	#7,d2
		cmp.b	#64,d2	;(bomba)
		beq.w	CZ_Bomba
CZ_Loop		tst.b	(a2)
		beq.w	CZ_Dont
		cmp.b	(a2)+,d2
		bne.b	CZ_Loop
		moveq	#1,d1		
CZ_Dont		movem.l	(sp)+,d0/d2/a0/a1/a2
		rts


CZ_Bomba	move.b	#88,(a1)
		bra	CZ_Dont



**** Rnd ****
* Wyznacza liczbe losowa
***
* d1 - 0 lub nie 0
* d2 - liczba losowa .l

Rnd		move.l	RndData,d2
		ror.l	d2
		bcc.b	R_Zero
		bchg	#6,d2
		bchg	#18,d2
		bra	R_Ok
R_Zero		bchg	#12,d2
		bchg	#21,d2
R_Ok		move.l	d2,RndData
		moveq	#0,d1
		btst	#15,d2
		beq.w	R_Nie
		rts
R_Nie		moveq	#1,d1
		rts


**** Rnd2 ****
* Wyznacza liczbe losowa ( 2 razy czesciej 0 niz 1)
***
* d1 - 0 (czesciej) lub nie 0
* d2 - liczba losowa .l

Rnd2		movem.l	d3,-(sp)
		bsr.s	Rnd
		move.l	d1,d3
		bsr.s	Rnd
		and.l	d2,d1
		movem.l	(sp)+,d3
		rts

**** Rnd3 ****
* Wyznacza liczbe losowa (3 razy czesciej 0 niz 1)
***
* d1 - 0 lub nie 0
* d2 - liczba losowa.l

Rnd3		movem.l	d3,-(sp)
		bsr.s	Rnd2
		move.l	d1,d3
		bsr.s	Rnd
		and.l	d3,d1
		movem.l	(sp)+,d3
		rts




**** Rnd4 ****
* Wyznacza liczbe losowa (4 razy czesciej 0 niz 1)
***
* d1 - 0 lub nie 0
* d2 - liczba losowa.l

Rnd4		movem.l	d3,-(sp)
		bsr.s	Rnd2
		move.l	d1,d3
		bsr.s	Rnd2
		and.l	d3,d1
		movem.l	(sp)+,d3
		rts



**** Counters ****
* Zmienia warosci wszystkich potrzebnych licznikow co kazde VBL

Counters	addq.w	#1,VBLCounter
		rts



**** CalcCharsAddress ****
* Oblicza adresy dla grafiki znaczkow

CalcCharsAddress
		lea	CharsAddress,a0
		moveq	#0,d0
		move.l	#160,d1
		move.w	#256-1,d7
CCA_Loop	move.l	d0,(a0)+
		add.l	d1,d0
		dbf	d7,CCA_Loop
		rts



**** Joy ****

; bity:
;	0
;	|
;     3-X-1
;	|
;	2
;

Joy		bsr.w	GetKey
		move.b	d0,ActualKey
		bsr.w	KeyJoy
		tst.w	KeyJoyData
		beq.w	J_Joy
		move.w	KeyJoyData,JoyData
		tst.w	KeyFireFlag
		beq.w	J_FireTest
		move.w	KeyFireFlag,FireFlag
		rts

J_Joy		lea	$dff000,a6
		moveq	#0,d0
		move.w	$c(a6),d1
		btst	#1,d1
		beq.w	J_NiePrawo
		bset	#1,d0
J_NiePrawo	btst	#9,d1
		beq.w	J_NieLewo
		bset	#3,d0
J_NieLewo	move.w	d1,d2
		lsr.w	#1,d2
		eor.w	d2,d1
		btst	#0,d1
		beq.b	J_NieDol
		bset	#2,d0
J_NieDol	btst	#8,d1
		beq.b	J_NieGora
		bset	#0,d0
J_NieGora	
		move.w	d0,JoyData
		bne.b	J_NoZero
		clr.w	FireCounter
J_NoZero
J_FireTest	clr.w	FireFlag
		btst	#7,$bfe001
		bne.b	J_NieFire
		move.w	#1,FireFlag
		rts

J_NieFire	clr.w	FireCounter
		rts


Scroll		moveq	#0,d0
		move.w	RobboPosY,d0
		subq.w	#4,d0
		bpl	S_NoNeg
		move.w	#0,d0
S_NoNeg		lsr.w	#2,d0
		lsl.w	#2,d0
		cmp.b	#19,d0
		bcs.b	S_TooMuch
		move.w	#19,d0

S_TooMuch	mulu	#5,d0
		lsl.l	#8,d0
		lsl.l	#1,d0
		cmp.l	AddBitplans,d0
		beq.w	S_Cont
		bcc	S_Add
		sub.l	#32*5*2,AddBitplans
		bra	S_Cont
S_Add		add.l	#32*5*2,AddBitplans
S_Cont		bsr.w	SetBitplans
		rts



**** GetKey ****
* Pobiera znak z bufora klawiatury
***
* wyj:
* d0 - znak RawKey

GetKey		movem.l	d1/a0,-(sp)
		move.w	$dff01c,d0
		or.w	#$8000,d0
		movem.w	d0,-(a7)
		move.w	#$7fff,$dff09a

		move.w	KeyPos,d1
		tst.w	d1
		beq.w	GK_NoKey
		subq.w	#1,d1
		lea	KeyBuffer,a0
		move.b	(a0),d0
GK_Loop		move.b	1(a0),(a0)+
		dbf	d1,GK_Loop
		subq.w	#1,KeyPos

GK_End		movem.w	(a7)+,d1
		move.w	d1,$dff09a
		movem.l	(sp)+,d1/a0
		rts

GK_NoKey	move.b	#0,d0
		bra	GK_End
 


**** KeyJoy ****
* Jesli gracz uzywa klawiatury to zostanie to wpisane do JoyData 
*

KeyJoy		move.b	ActualKey,d1
		move.w	KeyJoyData,d2
		moveq	#0,d3	; znacznik czy znowu (1) lub tylko odczyt
		cmp.b	#$4c,d1
		bne.b	KJ_NoUp
		bset	#0,d2
KJ_NoUp		cmp.b	#$4c+128,d1
		bne.b	KJ_NoUpN
		bclr	#0,d2
		moveq	#1,d3
KJ_NoUpN	cmp.b	#$4e,d1
		bne.b	KJ_NoRight
		bset	#1,d2
KJ_NoRight	cmp.b	#$4e+128,d1
		bne.b	KJ_NoRightN
		bclr	#1,d2
		moveq	#1,d3
KJ_NoRightN
		cmp.b	#$4d,d1
		bne.b	KJ_NoDown
		bset	#2,d2
KJ_NoDown	cmp.b	#$4d+128,d1
		bne.b	KJ_NoDownN
		bclr	#2,d2
		moveq	#1,d3
KJ_NoDownN
		cmp.b	#$4f,d1
		bne.b	KJ_NoLeft
		bset	#3,d2
KJ_NoLeft	cmp.b	#$4f+128,d1
		bne.b	KJ_NoLeftN
		bclr	#3,d2
		moveq	#1,d3
KJ_NoLeftN
		move.w	d2,KeyJoyData

		move.w	KeyFireFlag,d2
		cmp.b	#$61,d1
		bne.b	KJ_NoFire
		bset	#0,d2
KJ_NoFire	cmp.b	#$61+128,d1
		bne.b	KJ_NoFireN
		bclr	#0,d2
		moveq	#1,d3
KJ_NoFireN
		cmp.b	#$60,d1
		bne.b	KJ_NoFire_
		bset	#0,d2
KJ_NoFire_	cmp.b	#$60+128,d1
		bne.b	KJ_NoFireN_
		bclr	#0,d2
		moveq	#1,d3
KJ_NoFireN_

		move.w	d2,KeyFireFlag
		tst.w	d3
		beq.w	KJ_NoAgain
		bsr.w	GetKey
		move.b	d0,ActualKey
		bra	KeyJoy
KJ_NoAgain	rts




ShowInfoBar	moveq	#51,d0
		moveq	#18,d1
		bsr.s	ShowInfoChar
		moveq	#52,d0
		moveq	#15,d1
		bsr.s	ShowInfoChar
		moveq	#48,d0
		moveq	#12,d1
		bsr.s	ShowInfoChar
		moveq	#50,d0
		moveq	#9,d1
		bsr.s	ShowInfoChar
		moveq	#53,d0
		moveq	#6,d1
		bsr.s	ShowInfoChar
		bsr.s	UpdateInfo
		rts


UpdateInfo	move.w	Planeta,d0
		moveq	#34,d1
		bsr.s	ShowInfoNumber2
		move.w	Naboje,d0
		moveq	#28,d1
		bsr.s	ShowInfoNumber2
		move.w	Zycia,d0
		moveq	#22,d1
		bsr.s	ShowInfoNumber2
		move.w	Klucze,d0
		moveq	#16,d1
		bsr.s	ShowInfoNumber2
		move.w	Srobki,d0
		moveq	#10,d1
		bsr.s	ShowInfoNumber2
		bsr.s	ShowScore
		rts

**************
* ShowInfoChar
* d0 - znak
* d1 - pozycja (co slowo)

ShowInfoChar	lea	GfxData,a0
		mulu	#160,d0
		lea.l	(a0,d0.w),a0
		lea	InfoBitplans,a1
		lsl.w	#1,d1
		lea.l	(a1,d1.w),a1
		moveq	#(5*16)-1,d7
SIC_Loop	move.w	(a0)+,(a1)
		lea	40(a1),a1
		dbf	d7,SIC_Loop
		rts


***************
* ShowInfoNumber2
* d0 - liczba (0-99)
* d1 - pozycja (co bajt)
*
ShowInfoNumber2
		move.w	d0,d3
		divu	#10,d0
		bsr.s	ShowInfoNumber
		addq.w	#1,d1
		mulu	#10,d0
		sub.w	d0,d3
		move.w	d3,d0
		bsr.s	ShowInfoNumber
		rts



ShowScore	moveq	#2,d1
		moveq	#6-1,d7
		lea	Score,a0
SS_Loop_	move.b	(a0)+,d0
		bsr.s	ShowInfoNumber
		addq.w	#1,d1
		dbf	d7,SS_Loop_
		rts	





**************
* ShowInfoNumber
* d0 - liczba (0-9)
* d1 - pozycja (co bajt)

ShowInfoNumber	movem.l	d0-a6,-(sp)
		and.w	#$f,d0
		lea	ClockFonty,a0
		lea	InfoBitplans,a1
		lea	128(a0),a2
		lea.l	(a1,d1.w),a1
		lsl.w	#4,d0
		lea.l	(a0,d0.w),a0
		moveq	#16-1,d7
SIN_Loop	move.b	(a2)+,40(a1)
		move.b	(a0)+,120(a1)
		lea.l	(40*5)(a1),a1
		dbf	d7,SIN_Loop
		movem.l	(sp)+,d0-a6
		rts


AddScore	movem.l	d0-a6,-(sp)
		moveq	#4-1,d7
		lea	AddValue,a0
		lea	Score+2,a1
AS_Loop		move.b	(a0)+,d0
		add.b	d0,(a1)+
		dbf	d7,AS_Loop

		moveq	#5-1,d7
		lea	Score+5,a0
		moveq	#6-1,d7
AS_Loop2	cmp.b	#9,(a0)
		ble.b	AS_Next	; Gdy Mniejszy lub rowny
		sub.b	#10,(a0)
		addq.b	#1,-1(a0)
AS_Next		subq.l	#1,a0
		dbf	d7,AS_Loop2
		movem.l	(sp)+,d0-a6
		rts












		section	plansza,data_p
Plansza		blk.b	(16+2)*(32+2),33

;  		- Puste miejsce
; !		- Murek zwykly		
; #		- Skrzynka
; $		- Srobka
; %		- Ptaszek w prawo
; &		- Ptaszek w lewo
; '		- Kapsula zamknieta
; (		- Magnes w prawo
; )		- Magnes w lewo
; *		- Gruz
; +		- Dodatek
; ,		- Dzialko przesuwalne
; -		- Naboje
; .		- Ptaszek w gore
; /		- Ptaszek w dol
; 0		- Pierwsza faza wybuchu
; 1
; 2
; 3
; 4
; 5
; 6
; 7		- Ostatnia faza wybuchu
; 8		- Dzialko chodzace w prawo
; 9		- Dzialko chodzace w lewo
; :		- Murek miekki
; ; 		- Drzwi
; <		- Dzialko w lewo
; =		- Dzialko w gore
; >		- Dzialko w prawo
; ?		- Dzialko w dol
; @		- Bomba
; A		- Naboj w lewo
; B		- Naboj w gore
; C		- Naboj w prawo
; D		- Naboj w dol
; E		- Dzialko obrotowe w lewo
; F		- Dzialko obrotowe w gore
; G		- Dzialko obrotowe w prawo
; H		- Dzialko obrotowe w dol
; I		- Ptaszek srajacy w prawo
; J		- Ptaszek srajacy w lewo
; K		- Naboj ze sladem w lewo
; L		- Naboj ze sladem w gore
; M		- Naboj ze sladem w prawo
; N		- Naboj ze sladem w dol
; O		- Slad w lewo
; P		- Slad w gore
; Q		- Slad w prawo
; R		- Slad w dol
; S		- Dzialko ze sladem w lewo
; T		- Dzialko ze sladem w gore
; U		- Dzialko ze sladem w prawo
; V		- Dzialko ze sladem w dol
; W		- ROBBO !!!
; X		- Bomba (1 faza wybuchu)
; Y		- Bomba (2 faza wybuchu)
; Z		- Robbo wciagany w lewo
; [		- Robbo wciagany w prawo
; \		- Klucz
; a		- Teleport typu 1
; b		- Teleport typu 2
; c		- Teleport typu 3
; d		- Teleport typu 4
; e		- Teleport typu 5
; f		- Teleport typu 6
; g		- sowa w lewo
; h		- sowa w dol
; i 		- sowa w prawo
; j		- sowa w gore
; k		- sworek w prawo
; l		- sworek w gore
; m		- stworek w lewo
; n		- stworek w dol



Plansze

*		dc.b	"!!!!!!!!!!!!!!!!"
*		dc.b	"!W            a!"
*		dc.b	"!             !!"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!     !g       !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!    l!        !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!              !"
*		dc.b	"!!!!!!!!!!!!!!!!"

		dc.b	"!!!!!!!!!!!!!!!!"
		dc.b	"!W  !\ ## ! $  !"
		dc.b	"!  $!   # !! !a!"
		dc.b	"!#  !!!#  ! # !!"
		dc.b	"!# #  !#  !# # !"
		dc.b	"! # ! !   !#   !"
		dc.b	"!!!!! %        !"
		dc.b	"!!!!! !!!!!!!!!!"
		dc.b	"!     !$  !a $'!"
		dc.b	"!U    !   !!!!!!"
		dc.b	"!     !!! !!b $!"
		dc.b	"!(        !!!!!!"
		dc.b	"!!!   E   !!c $!"
		dc.b	"!f!       !!!!!!"
		dc.b	"!   T!  !T!!d $!"
		dc.b	"!b! !!!!!!!!!!!!"
		dc.b	"!!!  !    !!e \!"
		dc.b	"!    !! ! !!!!!!"
		dc.b	"!  !      !!b f!"
		dc.b	"!  !  !!!!!!!!!!"
		dc.b	"! !!! !d;    # !"
		dc.b	"! ! ! !!!!  # #!"
		dc.b	"!       @! # # !"
		dc.b	"! !! $   !# #  !"
		dc.b	"! c!     !!!!# !"
		dc.b	"! !!#       ! #!"
		dc.b	"!  !!!!!!!!    !"
		dc.b	"!         !!!!!!"
		dc.b	"!!!!      !   f!"
		dc.b	"! e!      ! !!!!"
		dc.b	"!  ;  8   !;$\!!"
		dc.b	"!!!!!!!!!!!!!!!!"

		dc.b	0		; Koniec




		section	BombTable,data_p

**** Co nie da sie rozwalic za pomoca bomby ****
BombTable	dc.b	33,40,41,88,89,88+128,89+128,0
		section	KillTable,data_p
**** Tu znajduje sie wszystko co mozna zabic strzalem (0 - koniec)
KillTable	dc.b	37,38,42,43,45,46,47,73,74,87
		dc.b	103,104,105,106,107,108,109,110,0
		section	MoveTable,data_p
**** Co Robbo moze przesuwac ****
MoveTable	dc.b	35,44,44+128,56,56+128,57,57+128
		dc.b	64,64+128,39
		dc.b	0

**** Co moze zabic robba ****
RobboKillTable	dc.b	37,38,37+128,38+128
		dc.b	46,47,46+128,47+128
		dc.b	73,74,73+128,74+128
		dc.b	103,104,105,106
		dc.b	103+128,104+128,105+128,106+128
		dc.b	107,108,109,110
		dc.b	107+128,108+128,109+128,110+128
		dc.b	0





		section	GetTable,data_p

**** Co Robbo moze brac ****
* .b - znaczek do zebrania
* .b
* .l - procedura

GetTable	dc.b	43,0
		dc.l	Dodatek
		dc.b	36,0
		dc.l	Srobka
		dc.b	59,0
		dc.l	Drzwi
		dc.b	92,0
		dc.l	Klucz
		dc.b	34,0
		dc.l	KapsulaOtwarta
		dc.b	45,0
		dc.l	Naboj
		dc.b	0



		section	GfxTable,data_p


**** Gfx table ****
* 0.b GfxChar
* 0.b
* 0.l Function

GfxTable	dc.b	0,0
		dc.l	0
	* 33
		dc.b	1,0
		dc.l	0
	* 34
		dc.b	1,0
		dc.l	0
	* 35
		dc.b	2,0	; skrzynka
		dc.l	0
	* 36
		dc.b	3,0
		dc.l	0
	* 37
		dc.b	10,0
		dc.l	PtaszekWPrawo
	* 38
		dc.b	10,0
		dc.l	PtaszekWLewo
	* 39
		dc.b	12,0
		dc.l	KapsulaZamknieta
	* 40
		dc.b	18,0	; Magnes |->
		dc.l	MagnesWPrawo
	* 41
		dc.b	19,0
		dc.l	MagnesWLewo
	* 42
		dc.b	4,0	; Gruz
		dc.l	0
	* 43
		dc.b	25,0
		dc.l	0
	* 44
		dc.b	20,0
		dc.l	DzialkoPrzesuwalne
	* 45
		dc.b	24,0	; Naboje
		dc.l	0
	* 46
		dc.b	0,0
		dc.l	PtaszekWGore
	* 47
		dc.b	0,0
		dc.l	PtaszekWDol
	* 48
		dc.b	26,0
		dc.l	AddWybuch
	* 49
		dc.b	27,0
		dc.l	AddWybuch
	* 50
		dc.b	28,0
		dc.l	AddWybuch
	* 51
		dc.b	29,0
		dc.l	AddWybuch
	* 52
		dc.b	30,0
		dc.l	AddWybuch
	* 53
		dc.b	31,0
		dc.l	AddWybuch
	* 54
		dc.b	32,0
		dc.l	AddWybuch
	* 55
		dc.b	33,0
		dc.l	ClsWybuch
	* 56
		dc.b	20,0
		dc.l	DzialkoChodzaceWPrawo
	* 57
		dc.b	20,0
		dc.l	DzialkoChodzaceWLewo
	* 58
		dc.b	5,0
		dc.l	0
	* 59
		dc.b	15,0
		dc.l	0
	* 60
		dc.b	23,0
		dc.l	DzialkoWLewo
	* 61
		dc.b	20,0
		dc.l	DzialkoWGore
	* 62
		dc.b	21,0
		dc.l	DzialkoWPrawo
	* 63
		dc.b	22,0
		dc.l	DzialkoWDol
	* 64
		dc.b	16,0
		dc.l	0


	* 65
		dc.b	6,0
		dc.l	NabojWLewo
	* 66
		dc.b	8,0
		dc.l	NabojWGore
	* 67
		dc.b	6,0
		dc.l	NabojWPrawo
	* 68
		dc.b	8,0
		dc.l	NabojWDol

	* 69
		dc.b	23,0
		dc.l	DzialkoObrotoweWLewo

	* 70
		dc.b	20,0
		dc.l	DzialkoObrotoweWGore

	* 71
		dc.b	21,0
		dc.l	DzialkoObrotoweWPrawo

	* 72
		dc.b	22,0
		dc.l	DzialkoObrotoweWDol

	* 73
		dc.b	10,0
		dc.l	PtaszekSrajacyWPrawo

	* 74
		dc.b	10,0
		dc.l	PtaszekSrajacyWLewo

	* 75
		dc.b	0,0
		dc.l	NabojZeSlademWLewo

	* 76
		dc.b	0,0
		dc.l	NabojZeSlademWGore

	* 77
		dc.b	0,0
		dc.l	NabojZeSlademWPrawo

	* 78
		dc.b	0,0
		dc.l	NabojZeSlademWDol


	* 79
		dc.b	0,0
		dc.l	SladWLewo

	* 80
		dc.b	0,0
		dc.l	SladWGore

	* 81
		dc.b	0,0
		dc.l	SladWPrawo

	* 82
		dc.b	0,0
		dc.l	SladWDol

	* 83
		dc.b	23,0
		dc.l	DzialkoZeSlademWLewo

	* 84
		dc.b	20,0
		dc.l	DzialkoZeSlademWGore

	* 85
		dc.b	21,0
		dc.l	DzialkoZeSlademWPrawo

	* 86
		dc.b	22,0
		dc.l	DzialkoZeSlademWDol

	* 87
RobboChar	dc.b	12,0
		dc.l	RobboProc

	* 88
		dc.b	16,0
		dc.l	Bomba
	* 89
		dc.b	17,0
		dc.l	BombaWybuchajaca

	* 90
		dc.b	38,0
		dc.l	RobboWciaganyWLewo

	* 91
		dc.b	40,0
		dc.l	RobboWciaganyWPrawo

	* 92
		dc.b	14,0
		dc.l	0

	* 93
		dc.b	40,0
		dc.l	0

	* 94
		dc.b	40,0
		dc.l	0

	* 95
		dc.b	40,0
		dc.l	0

	* 96
		dc.b	40,0
		dc.l	0

	* 97
		dc.b	42,0
		dc.l	AutoTeleport

	* 98
		dc.b	42,0
		dc.l	AutoTeleport

	* 99
		dc.b	42,0
		dc.l	AutoTeleport

	* 100
		dc.b	42,0
		dc.l	AutoTeleport

	* 101
		dc.b	42,0
		dc.l	AutoTeleport

	* 102
		dc.b	42,0
		dc.l	AutoTeleport

	* 103
		dc.b	44,0
		dc.l	SowaWLewo

	* 104
		dc.b	44,0
		dc.l	SowaWDol

	* 105
		dc.b	44,0
		dc.l	SowaWPrawo

	* 106
		dc.b	44,0
		dc.l	SowaWGore

	* 107
		dc.b	46,0
		dc.l	StworekWPrawo

	* 108
		dc.b	46,0
		dc.l	StworekWGore

	* 109
		dc.b	46,0
		dc.l	StworekWLewo

	* 110
		dc.b	46,0
		dc.l	StworekWDol










**** Anim table ****
* .b - znak do animacji (0 - koniec)
* .b - ilosc faz
* .b - ilosc ramek
* .b - licznik (nie zapisywac !)
* .b - licznik faz (nie zapisywac !)
* .b - fazy znaku ...

AnimTable

	dc.b	37,2,4,0,0,10,11
	dc.b	38,2,4,0,0,10,11
	dc.b	73,2,4,0,0,10,11
	dc.b	74,2,4,0,0,10,11

	dc.b	65,2,2,0,0,6,7
	dc.b	67,2,2,0,0,6,7
	dc.b	66,2,2,0,0,8,9
	dc.b	68,2,2,0,0,8,9

	dc.b	75,2,2,0,0,6,7
	dc.b	76,2,2,0,0,8,9
	dc.b	77,2,2,0,0,6,7
	dc.b	78,2,2,0,0,8,9

	dc.b	79,2,2,0,0,6,7
	dc.b	80,2,2,0,0,8,9
	dc.b	81,2,2,0,0,6,7
	dc.b	82,2,2,0,0,8,9

	dc.b	46,2,4,0,0,10,11
	dc.b	47,2,4,0,0,10,11

	dc.b	90,2,1,0,0,38,39
	dc.b	91,2,1,0,0,40,41

	dc.b	34,2,4,0,0,12,13

	dc.b	97,2,4,0,0,42,43
	dc.b	98,2,4,0,0,42,43
	dc.b	99,2,4,0,0,42,43
	dc.b	100,2,4,0,0,42,43
	dc.b	101,2,4,0,0,42,43
	dc.b	102,2,4,0,0,42,43


	dc.b	103,2,4,0,0,44,45
	dc.b	104,2,4,0,0,44,45
	dc.b	105,2,4,0,0,44,45
	dc.b	106,2,4,0,0,44,45

	dc.b	107,2,4,0,0,46,47
	dc.b	108,2,4,0,0,46,47
	dc.b	109,2,4,0,0,46,47
	dc.b	110,2,4,0,0,46,47

	dc.b	0









		section	data,data_p


BitplansAddress	dc.l	Bitplans
IleRamek	dc.w	ILERAMEK
INTENAR		dc.w	0
INTENARK	dc.w	0
OldVBL		dc.l	0
OldSDR		dc.l	0
RndData		dc.l	$1634cf39
Counter		dc.w	0
VBLCounter	dc.w	0
RobboAddress	dc.l	0
JoyData		dc.w	0
KeyJoyData	dc.w	0	; To samo co Joy Data tylko z klawiatury
FireFlag	dc.w	0
KeyFireFlag	dc.w	0
RobboPosY	dc.w	0
AddBitplans	dc.l	0	; Wartosc dodawana do adresu bitplanu
KeyPos		dc.w	0	; Pozycja klawisza w buforze
ActualKey	dc.b	0,0	; Aktualny klawisz
RobboFaza	dc.w	1	; Faza robba
RobboEorFaza	dc.w	0	; "Faza" fazy (?)
FlashFlag	dc.w	0
FireCounter	dc.w	0
RobboCounter	dc.w	15	; Gdy odliczy do 0 to robbo na pewno zginol
RobboFlag	dc.w	8	; Jesli <>0 to robbo dopiero sie pojawia
RobboShowChar	dc.w	34	; faza robba jaka ma sie pojawic po skonczeniu
				; pojawiania

RobboWTeleporcie
		dc.w	0	; 0.b - Numer teleportu (1,2,3,4,5,6)
				; gdy = 0 to Robba nie ma w teleporcie
				;
				; 1.b - Kierunek w ktorym robbo "wszedl" do
				; teleportu :
				; 0   ->&
				;
				;
				; 1	|
				;	&
				;
				; 2	&<-
				;
				;
				; 3	&
				;	^
				;	|


ExitFlag	dc.w	0	; jesli 0 to dalej trwa gra


************************************************

Planeta		dc.w	1
Zycia		dc.w	8
Srobki		dc.w	3
Klucze		dc.w	0
Naboje		dc.w	0
AddValue	dc.l	$00000100	; Ile ma dodac procedura AddScore

Score		dc.b	0,0,0,0,0,0	; Punkty



		section	KeyboardBuffer,BSS_p

KeyBuffer	ds.b	100	; Bufor klawiatury




		section	CopperData,data_c

Copper		dc.l	$00960020



		dc.w	$0092
DDFSTRT		dc.w	$0048
		dc.w	$0094
DDFSTOP		dc.w	$00ba
		dc.w	$008e
DIWSTRT		dc.w	$3039
		dc.w	$0090
DIWSTOP		dc.w	$00fe


		dc.w	$00e0
AdrH		dc.w	0
		dc.l	$00e20000
		dc.l	$00e40000
		dc.l	$00e60000
		dc.l	$00e80000
		dc.l	$00ea0000
		dc.l	$00ec0000
		dc.l	$00ee0000
		dc.l	$00f00000
		dc.l	$00f20000

		dc.w	$0180
Color0		dc.w	0
		dc.l	$01820000
		dc.l	$01840000
		dc.l	$01860000
		dc.l	$01880000
		dc.l	$018a0000
		dc.l	$018c0000
		dc.l	$018e0000

		dc.l	$01900000
		dc.l	$01920000
		dc.l	$01940000
		dc.l	$01960000
		dc.l	$01980000
		dc.l	$019a0000
		dc.l	$019c0000
		dc.l	$019e0000

		dc.l	$01a00000
		dc.l	$01a20000
		dc.l	$01a40000
		dc.l	$01a60000
		dc.l	$01a80000
		dc.l	$01aa0000
		dc.l	$01ac0000
		dc.l	$01ae0000

		dc.l	$01b00000
		dc.l	$01b20000
		dc.l	$01b40000
		dc.l	$01b60000
		dc.l	$01b80000
		dc.l	$01ba0000
		dc.l	$01bc0000
		dc.l	$01be0000

		dc.l	$01080080
		dc.l	$010a0080
		dc.l	$01005000
		dc.l	$01020000
		dc.l	$01e40000
		dc.l	$01fc0000

		dc.l	$f507fffe
		dc.l	$01000000


		dc.w	$00e0
AdrHInfo	dc.w	0
		dc.l	$00e20000
		dc.l	$00e40000
		dc.l	$00e60000
		dc.l	$00e80000
		dc.l	$00ea0000
		dc.l	$00ec0000
		dc.l	$00ee0000
		dc.l	$00f00000
		dc.l	$00f20000


		dc.l	$008e2c81
		dc.l	$00901cc1
		dc.l	$00920038
		dc.l	$009400d0


		dc.l	$010800a0
		dc.l	$010a00a0


		dc.l	$ffdffffe
		dc.l	$0007fffe
		dc.l	$01005000
		dc.l	$1007fffe
		dc.l	$01000000

		dc.l	$fffffffe


		section	Bitplans,BSS_c
Bitplans	ds.b	79360*2

		section	InfoBitplans,BSS_c

; Linia statusowa na dole ekranu
InfoBitplans	ds.b	40*5*16



		section	CharsAddress,BSS_c

CharsAddress	ds.b	256*4



********************


		IFEQ	ALLOCGFX
>Extern	"work:programming/assembler/progs/robbo/data/robbo2.data",DATA
Colors	=		DATA
GfxData	=		DATA+64
ClockFonty	=	GfxData+40960
Fonts		=	ClockFonty+160
>Extern "work:programming/assembler/progs/robbo/data/clockfonty.data",ClockFonty
>Extern "work:programming/assembler/progs/robbo/data/8Fonty.data",Fonts
				IFNE	CLS
					AUTO	F\Bitplans\Bitplans+41023\0\
				ENDC
		ELSE
			section	Gfx,data_c
Colors			incbin "data/robbo2.data"
			section	Gfx2,data_c
ClockFonty		incbin "data/clockfonty.data"
			section	Gfx3,data_c
Fonts			incbin "data/8Fonty.data"
GfxData	=		Colors+64
		ENDC


*******************************************************************************
*******************************************************************************
******************************** Czolowka *************************************
*******************************************************************************


		section	C_code,code_p


Czolowka	bsr.s	C_InitAll


		bsr.w	C_PrintTitle

C_LMB		btst	#6,$bfe001
		bne.b	C_LMB
		bsr.s	C_EndAll
		rts



C_InitAll	bsr.s	C_SetCopper
		rts

C_EndAll	rts



C_SetCopper	move.l	#C_Copper,d0
		move.w	d0,$dff082
		swap	d0
		move.w	d0,$dff080

		move.l	#Bitplans,d0
		move.w	d0,C_AdrH+4
		swap	d0
		move.w	d0,C_AdrH
		rts



** PrintAt
* d0 - X
* d1 - Y
* a0 - text

C_PrintAt	lea.l	Bitplans,a1
		mulu	#40*8,d1
		add.w	d0,d1
		lea.l	(a1,d1.w),a1
C_PA_Loop	tst.b	(a0)
		beq.w	C_PA_End
		moveq	#0,d0
		move.b	(a0)+,d0
		sub.b	#32,d0
		movem.l	a1,-(sp)
		lsl.w	#3,d0
		lea.l	Fonts,a2
		lea.l	(a2,d0.w),a2
		moveq	#8-1,d7
C_PA_Loop2	move.b	(a2)+,(a1)
		add.l	#40,a1
		dbf	d7,C_PA_Loop2
		movem.l	(sp)+,a1
		addq.l	#1,a1
		bra	C_PA_Loop
C_PA_End	rts


C_PrintTitle	lea	C_TextTable,a5
C_PTLoop
		tst.l	(a5)
		beq.w	C_PTEnd
		move.l	(a5)+,a0
		move.w	(a5)+,d0
		moveq	#0,d1
		move.w	(a5)+,d1
		bsr.s	C_PrintAt
		bra	C_PTLoop

C_PTEnd		rts
******
* .l text (aptr)
* .w pos x
* .w pos y

C_TextTable
		dc.l	TextProg
		dc.w	0,0
		dc.l	TextGraf
		dc.w	0,1
		dc.l	TextMuz
		dc.w	0,2
		dc.l	0




TextProg	dc.b	"Program : Sebastian Bialy    Sterowanie ",0
TextGraf	dc.b	"Grafika :                   klaw.kursora",0
TextMuz		dc.b	"Muzyka  :                      lub joy  ",0


		section	C_Copper,data_c
C_Copper	
*******
* Napisy
*******
		dc.l	$00960020
		dc.w	$00e0
C_AdrH		dc.w	0
		dc.w	$00e2
		dc.w	0
		dc.l	$008e6081
		dc.l	$00902cc1
		dc.l	$00920038
		dc.l	$009400d0
		dc.l	$01800000
		dc.l	$01820444
		dc.l	$01001000
		dc.l	$5d07fffe
		dc.l	$01800333
		dc.l	$5e07fffe
		dc.l	$01800000

		dc.l	$7b07fffe
		dc.l	$01800333
		dc.l	$7c07fffe
		dc.l	$01800000

		dc.l	$fffffffe
