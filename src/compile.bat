c:\app\vasm\vasmm68k_mot_win32.exe -Fhunkexe -kick1hunks Robbo.S -o robbo.exe
xdftool robbo.adf format 'Robbo'
xdftool robbo.adf boot install
xdftool robbo.adf write robbo.exe
echo|set /p foo=robbo.exe>startup-sequence
rem xdftool robbo.adf write startup-sequence s\startup-sequence
xdftool robbo.adf list
