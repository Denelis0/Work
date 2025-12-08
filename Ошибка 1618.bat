@echo off
setlocal enabledelayedexpansion

set PathError=
set PathInstall=
set PathList=


for /f "tokens=1" %%i in (Users.txt) do (

	start /b psexec \\%%i -s -h -d msiexec.bat
	
)
endlocal	