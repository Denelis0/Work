@echo off
setlocal enabledelayedexpansion
chcp 1251 >nul

rem --- Аргументы ---
set "networkpath=%~1"
set "infile=%~2"

rem --- Переменные ---
set "ansiFile=%infile%.ansi.tmp"
set "tmpfile=%infile%.tmp"
set "filteredfile=%infile%.filtered.tmp"
set "utf8File=%infile%.utf8.tmp"

rem --- Проверки ---
pushd "%networkpath%" || (
    echo ERROR: failed to map network path "%networkpath%".
    exit /b 1
)

if not exist "%infile%" (
    echo ERROR: file "%infile%" not found in "%networkpath%".
    popd
    exit /b 1
)

rem --- Создание ANSI копии файла ---
type "%infile%" > "%ansiFile%"

rem --- Создание временного файла с номерами строк ---
if exist "%tmpfile%" del /f /q "%tmpfile%" >nul 2>&1
set /a linenum=0
set "foundRefLine="
set /a totalLines=0

for /f "usebackq delims=" %%A in ("%ansiFile%") do (
    set /a linenum+=1
    set "line=%%A"
    >>"%tmpfile%" echo !linenum!^|!line!
    echo !line! | findstr /i /c:"Ref=""test_operation""" >nul
    if !errorlevel! == 0 if not defined foundRefLine set "foundRefLine=!linenum!"
)

set /a totalLines=linenum

if not defined foundRefLine (
    echo Ref="test_operation" not found in file "%infile%".
    if exist "%tmpfile%" del /f /q "%tmpfile%" >nul 2>&1
    popd
    exit /b 2
)

rem --- Поиск ближайшей секции вниз ---
set "lowerSectionLine="
for /f "usebackq tokens=1* delims=|" %%N in ("%tmpfile%") do (
    set "num=%%N"
    set "txt=%%O"
    if !num! gtr !foundRefLine! (
        echo !txt! | findstr /r "\[.*\]" >nul
        if !errorlevel! == 0 (
            set "lowerSectionLine=!num!"
            goto :found_lower
        )
    )
)
:found_lower
if not defined lowerSectionLine set /a lowerSectionLine=%totalLines%+1

rem --- Поиск ближайшей секции вверх ---
set "upperSectionLine="
for /f "usebackq tokens=1* delims=|" %%N in ("%tmpfile%") do (
    set "num=%%N"
    set "txt=%%O"
    if !num! lss !foundRefLine! (
        echo !txt! | findstr /r "\[.*\]" >nul
        if !errorlevel! == 0 set "upperSectionLine=!num!"
    )
)
if not defined upperSectionLine set "upperSectionLine=1"

rem --- Создание временного файла с удалением секции ---
if exist "%filteredfile%" del /f /q "%filteredfile%" >nul 2>&1
for /f "usebackq tokens=1* delims=|" %%L in ("%tmpfile%") do (
    set "num=%%L"
    set "txt=%%M"

    rem --- До верхней секции сохраняем строки ---
    if !num! lss !upperSectionLine! (
        if not "!txt!"=="" >>"%filteredfile%" echo !txt!
    )

    rem --- После нижней секции сохраняем строки ---
    if !num! geq !lowerSectionLine! (
        if not "!txt!"=="" >>"%filteredfile%" echo !txt!
    )
)

rem --- Конвертация обратно в UTF-8 без пустых строк и с обрезкой пробелов ---
set "finalFile=%utf8File%"
if exist "%finalFile%" del /f /q "%finalFile%" >nul 2>&1
for /f "usebackq delims=" %%A in ("%filteredfile%") do (
    set "line=%%A"
    call :rtrim line
    if not "!line!"=="" >> "%finalFile%" echo !line!
)

rem --- Подмена оригинала ---
move /y "%finalFile%" "%infile%" >nul
if errorlevel 1 (
    echo ERROR: Failed to replace "%infile%".
    popd
    exit /b 1
) else (
    echo File "%infile%" successfully updated.
)

rem --- Очистка ---
for %%T in ("%tmpfile%" "%ansiFile%" "%filteredfile%" "%utf8File%") do (
    if exist %%~T del /f /q %%~T >nul 2>&1
)

popd
endlocal
exit /b 0

:rtrim
setlocal enabledelayedexpansion
set "s=!%1!"
:loop
if "!s:~-1!"==" " (
    set "s=!s:~0,-1!"
    goto loop
)
endlocal & set "%1=%s%"
goto :eof
