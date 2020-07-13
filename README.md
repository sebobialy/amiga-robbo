# amiga-robbo
Amiga remake of Atari's classic: Robbo

Please notice that this is very old code, probably from around '97. This version is not fully functional from gameplay perspective, some logic, code, graphics are missing, expect visual glitches, however it is playable as it is. Single planet only for now, until proper conversion script from original game.

Commited direcly from my old Amiga hdd with no modifications. Source code is kinda AsmOne style, except for relative includes.

compile.bat provided to create adf file on windows, shoud start on A500/A600/A1200 both WinAUE and real hardware. You need vasm and xdftool to create adf file without real hardware.

You can play around with this source code on real Amiga, just use recent AsmOne.

Start game by LMB, use Joy or arrows+shift. RMB exits game.

Known problems:
1) No way to suicide, ESC does not work at all
2) Sometimes title graphics is distorted
3) Floppy will not start robbo.exe, please type "robbo.exe" and hit Enter.
4) No clean exit to OS.

Plans:
1) Convert Atari original levels + modified versions
2) remove known problems
3) clean up the code
4) add some python scripts to manipulate graphics
5) make it fully working on original planets set
6) add colors ;)

Sebastian Bialy.
