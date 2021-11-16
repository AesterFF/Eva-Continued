@echo off
SETLOCAL EnableDelayedExpansion

:getusbaffinity
set CPUCORES=%NUMBER_OF_PROCESSORS%
set /a CPUCORES=%CPUCORES% - 1
set "output="
for /L %%a in (0 1 %CPUCORES%) do set "output=!output! %%a"
echo.
echo This script will remove cycle hungry processes from running on the core you enter each time on startup.
echo.
echo I would recommend entering your USB affinity or GPU affinity to prevent those processes from running on those cores
echo.
echo e.g scenario: USB affinity on CPU 1, enter 1 in this script and processes will run on every core except CPU 1
echo.
echo possible values: !output:~1!
echo.
set /p affinity="what CPU would you like to prevent processes from running on?: "

if defined affinity (
  set affinity=%affinity: =%
) else goto invalidusb

if %affinity% GTR %CPUCORES% goto invalidusb
if %affinity% LEQ %CPUCORES% cls & goto readusbaffinity

:invalidusb
cls
echo invalid input.
echo.
goto getusbaffinity

:readusbaffinity
set CPUCORES=%NUMBER_OF_PROCESSORS%
set /a "mask_dec=1<<affinity"

set "bin="
for /L %%A in (1,1,32) do (
    set /a "bit=mask_dec&1, mask_dec>>=1"
    set bin=!bit!!bin!
)

set mask=!bin:~-%cpucores%!

set "inverted=%mask:1=#%"
set "inverted=%inverted:0=1%"
set "inverted=%inverted:#=0%"

set binaryaffinity=%inverted%

:START
IF     "binaryaffinity"=="" GOTO START
IF NOT "%~2"=="" GOTO START

ECHO "%binaryaffinity%"| FINDSTR /R /B /C:"\"[01][01]*\"$" >NUL || GOTO START

SET Binary=%binaryaffinity%
SET Decimal=0
SET DigVal=1

:LOOP
IF %Binary% GTR 1 (
	SET Digit=%Binary:~-1%
	SET Binary=%Binary:~0,-1%
) ELSE (
	SET /A Digit = %Binary%
	SET Binary=0
)

IF %Digit% EQU 1 SET /A Decimal = %Decimal% + %DigVal%

SET /A DigVal *= 2

IF %Binary% GTR 0 GOTO LOOP

SET Binary=
SET Digit=
SET DigVal=

cls
>> "%windir%\EVA\startup.bat" echo set affinity=%Decimal%
cls
timeout t 2 > NUL 2>&1
start "" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Startup.lnk"
cls
echo Successfully set processes to NOT run on the USB core.
pause
exit /b