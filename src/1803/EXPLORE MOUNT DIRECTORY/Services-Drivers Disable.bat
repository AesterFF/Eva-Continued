@echo off
call :AGREED
if "%AGREED%" EQU "FALSE" (
	echo NOBODY IS RESPONSIBLE FOR DAMAGE CAUSED TO YOUR OPERATING SYSTEM OR COMPUTER. RUN AT YOUR OWN RISK
	echo.
	pause
	>> "%~f0" echo set AGREED=TRUE
)
cls
echo Disabling Drivers and Services...
PowerRun.exe /SW:0 "C:\Windows\EVA\Services Disable.bat"
exit /b

:AGREED
set AGREED=FALSE
