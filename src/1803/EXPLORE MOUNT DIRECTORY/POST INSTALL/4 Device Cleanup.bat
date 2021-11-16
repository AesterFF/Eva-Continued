@echo off
echo Removing hidden devices...
"%windir%\Modules\DeviceCleanup.exe" -s * > NUL 2>&1
cls
echo Hidden devices removed successfully
pause
exit /b