@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

set "PathInstall="
set "PathList="
set "PathError="

set /p version=Введите версию платформы для логов:

echo ----------------------------------------------------------------------------------------- >> %PathError%
echo Запуск установки платформы версии %version% от ПК %COMPUTERNAME%: %date% %time% >> %PathError%
echo ----------------------------------------------------------------------------------------- >> %PathError% 
echo ----------------------------------------------------------------------------------------- >> %PathInstall%
echo Запуск установки платформы версии %version% от ПК %COMPUTERNAME%: %date% %time% >> %PathInstall%
echo ----------------------------------------------------------------------------------------- >> %PathInstall%
echo ----------------------------------------------------------------------------------------- >> %PathList%
echo Запуск установки платформы версии %version% от ПК %COMPUTERNAME%: %date% %time% >> %PathList%
echo ----------------------------------------------------------------------------------------- >> %PathList%

for /f "tokens=1" %%i in (Users.txt) do (
	ping -n 1 -w 1000 %%i
	set ErrorCode=!errorlevel!
	if !ErrorCode! neq 0 (
		echo [%time%]   %%i: Выключен>>%PathInstall%
		echo [%time%]   %%i: Выключен>>"PathError%
		echo %%i>>%PathList%
	) else (
		start /b psexec \\%%i -s -h -d start_install.bat	
	)	
)
endlocal	