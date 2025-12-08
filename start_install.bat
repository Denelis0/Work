@echo off
setlocal enabledelayedexpansion

set "PathInstall="
set "PathList="
set "PathError="

set "version=8.3.27.1559"
set "SERVICE1=msiexec"
wmic product where "name like '1C:Enterprise%%'" get version | findstr /r /c:"%version%" > nul

	if !errorlevel! equ 0 (
		echo [%time%]   %COMPUTERNAME%: Уже установлено>>%PathInstall%
	) else (
		for /f "tokens=2 delims= " %%A in ('tasklist /svc ^| findstr /i "%SERVICE1%"') do (
			set PID=%%A
			taskkill /F /PID !PID!
		)
		msiexec /i "1CEnterprise 8 Thin client (x86-64)" /qn /norestart
		set ErrorCode=!errorlevel!

		if !ErrorCode! equ 0 (
			echo [%time%]   %COMPUTERNAME%: Установлено>>%PathInstall%
		) else (
			echo [%time%]   %COMPUTERNAME%: Ошибка !ErrorCode!>>%PathInstall%
			echo [%time%]   %COMPUTERNAME%: Ошибка !ErrorCode!>>%PathError%
			echo %COMPUTERNAME%>>%PathList%
		)
	)
endlocal	