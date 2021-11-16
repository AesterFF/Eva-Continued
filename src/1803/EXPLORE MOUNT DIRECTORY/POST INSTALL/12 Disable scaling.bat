@echo off
for %%i in (Scaling) do (
    for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /s /f "%%i"^| findstr "HKEY"') do (
		reg add "%%a" /v "Scaling" /t REG_DWORD /d "1" /f  > NUL 2>&1
    )
)
cls
echo Scaling disabled successfully.
echo.
echo NOTE: The scaling mode may not be consistent in the graphics control panel (e.g scaling mode may be on Aspect ratio). Ignore it, as long as you run this and do not touch the control panel scaling option you will be fine.
pause
exit /b