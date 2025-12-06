@echo off
setlocal enabledelayedexpansion
chcp 1251 >nul

rem === АРГУМЕНТЫ ===
set "networkpath=%~1"
set "targetfile=%~2"
set "sourcefile=%~3"

rem === ПРОВЕРКИ ===
if not exist "%sourcefile%" (
    echo ERROR: Source file "%sourcefile%" not found.
    exit /b 1
)

pushd "%networkpath%" || (
    echo ERROR: Failed to map network path "%networkpath%".
    exit /b 1
)

if not exist "%targetfile%" (
    echo ERROR: Target file "%targetfile%" not found in "%networkpath%".
    popd
    exit /b 1
)

rem === ПРОВЕРКА НА ДУБЛИКАТ  ===
rem Мы заменяем кавычки (") на точки (.) и используем ключ /r (Regex).
rem Точка означает "любой символ", поэтому она совпадет с кавычкой в файле.
type "%targetfile%" | findstr /r /c:"Вторая строка секции(вместо кавычек ставить точки)" >nul
if !errorlevel! == 0 (
    rem Секция уже есть. Успех.
    popd
    exit /b 0
) 

rem === ДОБАВЛЕНИЕ СОДЕРЖИМОГО ===
(
    echo.
    type "%sourcefile%"
) >> "%targetfile%" 2>nul
if errorlevel 1 (
    rem ОШИБКА: Файл занят или нет прав на запись
    echo ERROR: Could not write to file "%targetfile%". Access denied?
    popd
    exit /b 1
)

rem УСПЕХ
popd
exit /b 0