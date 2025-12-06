@echo off
setlocal enabledelayedexpansion
chcp 1251 >nul

rem === НАСТРОЙКИ ===
set "SRC=%~dp0input.xlsx"
set "DST=%~dp0output.csv"
set "EXCEL_OUT=%~dp0output.xlsx"
set "VBS_FILE=%~dp0convert.vbs"
set "CSV2XLSX_VBS=%~dp0csv_to_xlsx.vbs"
set "TMP_FILE=%DST%.tmp"
set "LOG_FILE=%~dp0check_log.txt"
set "REL_PATH=AppData\Roaming\1C"
set "REPLACE_SCRIPT=%~dp0add_section.cmd"
set "TARGET_FILE=ibases.v8i"
set "ADD_FILE=%~dp0info.txt"

rem === ШАПКА ЛОГА ===
(
    echo ============================================================
    echo [INFO   ] [%date% %time%] Начало проверки
    echo ============================================================
) >> "%LOG_FILE%"

rem === КОНВЕРТАЦИЯ EXCEL -> CSV ===
echo [INFO] Converting Excel to CSV...
cscript //nologo "%VBS_FILE%" "%SRC%" "%DST%" >nul
if errorlevel 1 (
    echo [ERROR] Conversion failed.
    echo [ERROR  ] [%date% %time%] Ошибка конвертации Excel в CSV >>"%LOG_FILE%"
    goto :END
)
echo [OK] Conversion completed.
echo [OK     ] [%date% %time%] Конвертация Excel -> CSV успешно завершена >>"%LOG_FILE%"

rem === ПРОВЕРКА ПК ===
if not exist "%DST%" (
    echo [ERROR] CSV not found.
    echo [ERROR  ] [%date% %time%] CSV не найден >>"%LOG_FILE%"
    goto :END
)

copy "%DST%" "%TMP_FILE%" >nul
echo [INFO   ] [%date% %time%] Начата проверка компьютеров >>"%LOG_FILE%"

rem --- очищаем CSV перед записью ---
break > "%DST%"

for /f "usebackq tokens=1,2,3 delims=," %%A in ("%TMP_FILE%") do (
    set "PC=%%A"
    set "USER=%%B"
    set "STATUS=%%C"
    set "REMOTE_PATH=\\%%A\C$\Users\%%B\%REL_PATH%\%TARGET_FILE%"
    set "NETWORKPATH=\\%%A\C$\Users\%%B\%REL_PATH%"

    >&2 echo Checking %%A - %%B ...

    if "!STATUS!"=="0" (
        if exist "\\%%A\C$\" (
            if exist "!REMOTE_PATH!" (
                call "%REPLACE_SCRIPT%" "!NETWORKPATH!" "%TARGET_FILE%" "%ADD_FILE%" >nul
                if !errorlevel! equ 0 (
                    set "STATUS=1"
                    echo [OK     ] [%date% %time%] %%A\%%B — файл найден и успешно обновлён >>"%LOG_FILE%"
                ) else (
                    echo [WARN   ] [%date% %time%] %%A\%%B — файл найден, но обновление не удалось >>"%LOG_FILE%"
                )
            ) else (
                echo [WARN   ] [%date% %time%] %%A\%%B — файл не найден: "!REMOTE_PATH!" >>"%LOG_FILE%"
            )
        ) else (
            echo [ERROR  ] [%date% %time%] %%A — недоступен по сети >>"%LOG_FILE%"
        )
    ) else (
        >&2 echo Skipping %%A - %%B because STATUS=!STATUS!
    )

    rem --- выводим информацию о строке в любой случае ---
    echo !PC!,!USER!,!STATUS! >> "%DST%"
)



del "%TMP_FILE%" >nul 2>&1

rem === КОНВЕРТАЦИЯ CSV -> EXCEL С ОБНОВЛЕНИЕМ ===
set "TIME_TAG=%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TIME_TAG=%TIME_TAG: =0%"  :: Заменяем пробел на 0 для часа

set "NEW_EXCEL=%~dp0output_%TIME_TAG%.xlsx"

echo [INFO   ] [%date% %time%] Converting CSV to Excel...
cscript //nologo "%CSV2XLSX_VBS%" "%DST%" "%NEW_EXCEL%" >nul
if errorlevel 1 (
    echo [ERROR  ] [%date% %time%] Ошибка конвертации CSV -> Excel >>"%LOG_FILE%"
) else (
    echo [OK     ] [%date% %time%] CSV успешно конвертирован в Excel: "%NEW_EXCEL%" >>"%LOG_FILE%"
)

rem === ЗАМЕНА СТАРОГО EXCEL ===
if exist "%EXCEL_OUT%" (
    rem Проверяем доступность файла (открыт ли Excel)
    >nul 2>&1 (copy /y "%EXCEL_OUT%" nul)
    if errorlevel 1 (
        echo [WARN   ] [%date% %time%] Старый Excel открыт, новый файл оставлен как "%NEW_EXCEL%" >>"%LOG_FILE%"
    ) else (
        move /y "%NEW_EXCEL%" "%EXCEL_OUT%" >nul
        echo [OK     ] [%date% %time%] Старый Excel заменен новым >>"%LOG_FILE%"
    )
) else (
    move /y "%NEW_EXCEL%" "%EXCEL_OUT%" >nul
    echo [OK     ] [%date% %time%] Новый Excel сохранен как "%EXCEL_OUT%" >>"%LOG_FILE%"
)

rem === ОБНОВЛЕНИЕ ИСХОДНИКА (SRC) ===
set "DATE_TAG=%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "DATE_TAG=%DATE_TAG: =0%"  :: пробелы в часах заменяем нулями

for %%F in ("%SRC%") do (
    set "SRC_DIR=%%~dpF"
    set "SRC_BASENAME=%%~nF"
    set "SRC_EXT=%%~xF"
)

set "SRC_NEW=%SRC_DIR%%SRC_BASENAME%_%DATE_TAG%%SRC_EXT%"

echo [INFO   ] [%date% %time%] Обновление исходного файла "%SRC%" >>"%LOG_FILE%"

if exist "%SRC%" (
    rem Попытка удалить существующий исходник
    del /f /q "%SRC%" >nul 2>&1

    rem Проверяем, действительно ли файл удалён
    if exist "%SRC%" (
        rem Удаление не удалось — переименовываем output в input_дата.xlsx
        echo [WARN   ] [%date% %time%] Не удалось удалить "%SRC%" — возможно, файл открыт. >>"%LOG_FILE%"
        echo [INFO   ] [%date% %time%] Переименование "%EXCEL_OUT%" в "%SRC_NEW%" >>"%LOG_FILE%"
        move /y "%EXCEL_OUT%" "%SRC_NEW%" >nul 2>&1
        if errorlevel 1 (
            echo [ERROR  ] [%date% %time%] Не удалось переименовать "%EXCEL_OUT%" в "%SRC_NEW%". >>"%LOG_FILE%"
        ) else (
            echo [OK     ] [%date% %time%] "%EXCEL_OUT%" переименован в "%SRC_NEW%". >>"%LOG_FILE%"
        )
    ) else (
        rem Удаление прошло успешно — перемещаем новый файл на место исходника
        echo [OK     ] [%date% %time%] Файл "%SRC%" удалён. Заменяю на новый "%EXCEL_OUT%". >>"%LOG_FILE%"
        move /y "%EXCEL_OUT%" "%SRC%" >nul 2>&1
        if errorlevel 1 (
            echo [ERROR  ] [%date% %time%] Не удалось переместить "%EXCEL_OUT%" в "%SRC%". >>"%LOG_FILE%"
            rem В случае ошибки перемещения попробуем сохранить с датой как fallback
            echo [INFO   ] [%date% %time%] Пытаюсь переименовать "%EXCEL_OUT%" в "%SRC_NEW%" >>"%LOG_FILE%"
            move /y "%EXCEL_OUT%" "%SRC_NEW%" >nul 2>&1
            if errorlevel 1 (
                echo [ERROR  ] [%date% %time%] Не удалось переименовать "%EXCEL_OUT%" в "%SRC_NEW%". >>"%LOG_FILE%"
            ) else (
                echo [OK     ] [%date% %time%] "%EXCEL_OUT%" переименован в "%SRC_NEW%". >>"%LOG_FILE%"
            )
        ) else (
            echo [OK     ] [%date% %time%] Новый файл успешно перемещён на место исходного "%SRC%". >>"%LOG_FILE%"
        )
    )
) else (
    rem Если исходника нет — просто перемещаем output в SRC
    echo [WARN   ] [%date% %time%] Исходный "%SRC%" не найден, создаётся новый. >>"%LOG_FILE%"
    move /y "%EXCEL_OUT%" "%SRC%" >nul 2>&1
    if errorlevel 1 (
        echo [ERROR  ] [%date% %time%] Не удалось переместить "%EXCEL_OUT%" в "%SRC%". Попытка переименования в "%SRC_NEW%". >>"%LOG_FILE%"
        move /y "%EXCEL_OUT%" "%SRC_NEW%" >nul 2>&1
        if errorlevel 1 (
            echo [ERROR  ] [%date% %time%] Не удалось переименовать "%EXCEL_OUT%" в "%SRC_NEW%". >>"%LOG_FILE%"
        ) else (
            echo [OK     ] [%date% %time%] "%EXCEL_OUT%" переименован в "%SRC_NEW%". >>"%LOG_FILE%"
        )
    ) else (
        echo [OK     ] [%date% %time%] "%EXCEL_OUT%" перемещён в "%SRC%". >>"%LOG_FILE%"
    )
)


rem === УДАЛЕНИЕ CSV ===
for %%F in ("%DST%") do if exist "%%F" del /f /q "%%F" >nul 2>&1

:END
(
    echo ============================================================
    echo [INFO   ] [%date% %time%] Проверка завершена
    echo ============================================================
) >> "%LOG_FILE%"

echo [DONE   ] All checks completed.
pause
endlocal
