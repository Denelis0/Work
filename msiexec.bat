@echo off
setlocal enabledelayedexpansion

set "SERVICE=msiexec"
for /f "tokens=2 delims= " %%A in ('tasklist /svc ^| findstr /i "%SERVICE%"') do (
	set PID=%%A
	taskkill /F /PID !PID!
)
endlocal

