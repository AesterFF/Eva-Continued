@echo off
call "%windir%\Modules\config.bat"
cls & echo Applying AMD GPU settings...
if exist "C:\Program Files\AMD\CNext\CNext\Radeonsoftware.exe" start "" "C:\Program Files\AMD\CNext\CNext\Radeonsoftware.exe" atlogon
timeout 3 > NUL 2>&1
taskkill /F /IM RadeonSoftware.exe > NUL 2>&1
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
		for /f %%i in ('echo %%a ^| findstr "{"') do ( 
			Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "DisableDMACopy" /t REG_DWORD /d "1" /f > NUL 2>&1
			Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "DisableBlockWrite" /t REG_DWORD /d "0" /f > NUL 2>&1
			Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "StutterMode" /t REG_DWORD /d "0" /f > NUL 2>&1
			if %AMD_OPTIONAL% EQU TRUE Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "EnableUlps" /t REG_DWORD /d "0" /f > NUL 2>&1
			if %AMD_OPTIONAL% EQU TRUE Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "PP_SclkDeepSleepDisable" /t REG_DWORD /d "1" /f > NUL 2>&1
			if %AMD_OPTIONAL% EQU TRUE Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "PP_ThermalAutoThrottlingEnable" /t REG_DWORD /d "0" /f > NUL 2>&1
			if %AMD_OPTIONAL% EQU TRUE Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "DisableDrmdmaPowerGating" /t REG_DWORD /d "1" /f > NUL 2>&1
			if %AMD_PRERENDERED_FRAMES% EQU 0 (
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "KMD_DeLagEnabled" /t REG_DWORD /d "1" /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "Main3D_DEF" /t REG_SZ /d "0" /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "Main3D" /t REG_BINARY /d "3000" /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "FlipQueueSize" /t REG_BINARY /d "3000" /f > NUL 2>&1
			)
			if %AMD_PRERENDERED_FRAMES% EQU 1 (
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "KMD_DeLagEnabled" /t REG_DWORD /d "0" /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "Main3D_DEF" /t REG_SZ /d "1" /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "Main3D" /t REG_BINARY /d "3100" /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "FlipQueueSize" /t REG_BINARY /d "3100" /f > NUL 2>&1
			)
			if %AMD_PRERENDERED_FRAMES% EQU 2 (
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "KMD_DeLagEnabled" /t REG_DWORD /d "0" /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "Main3D_DEF" /t REG_SZ /d "2" /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "Main3D" /t REG_BINARY /d "3200" /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "FlipQueueSize" /t REG_BINARY /d "3200" /f > NUL 2>&1
			)
			if %AMD_PRERENDERED_FRAMES% EQU 3 (
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "KMD_DeLagEnabled" /t REG_DWORD /d "0" /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "Main3D_DEF" /t REG_SZ /d "3" /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "Main3D" /t REG_BINARY /d "3300" /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "FlipQueueSize" /t REG_BINARY /d "3300" /f > NUL 2>&1
			)
			if %DISABLE_PREEMPTION% EQU TRUE Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "KMD_EnableComputePreemption" /t REG_DWORD /d "0" /f > NUL 2>&1
			Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "KMD_RadeonBoostHotkey" /t REG_DWORD /d "0" /f > NUL 2>&1
			Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "KMD_ChillHotkey" /t REG_DWORD /d "0" /f > NUL 2>&1
			Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "KMD_DeLagHotKey" /t REG_DWORD /d "0" /f > NUL 2>&1
			Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "ShaderCache" /t REG_BINARY /d "3200" /f > NUL 2>&1
			Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "Tessellation_OPTION" /t REG_BINARY /d "3200" /f > NUL 2>&1
			Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "Tessellation" /t REG_BINARY /d "3100" /f > NUL 2>&1
			Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "VSyncControl" /t REG_BINARY /d "3000" /f > NUL 2>&1
			Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i\UMD" /v "TFQ" /t REG_BINARY /d "3200" /f > NUL 2>&1
		)
	)
)

Reg.exe add "HKCU\SOFTWARE\AMD\DVR" /v "DvrEnabled" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\AMD\DVR" /v "PrevInstantReplayEnable" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\AMD\DVR" /v "PrevInGameReplayEnabled" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\AMD\DVR" /v "PrevInstantGifEnabled" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\AMD\DVR" /v "ToggleRsPerfRecordingHotkey" /t REG_SZ /d "None" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\AMD\CN" /v "SystemTray" /t REG_SZ /d "false" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\AMD\CN" /v "AllowWebContent" /t REG_SZ /d "false" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\AMD\CN" /v "CN_Hide_Toast_Notification" /t REG_SZ /d "true" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\AMD\CN" /v "AnimationEffect" /t REG_SZ /d "false" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\AMD\CN" /v "UA_Pref" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\AMD\CN" /v "AutoUpdate" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\SOFTWARE\AMD\CN\Performance" /v "HideMetricswhileRecordingMetrics" /t REG_DWORD /d "0" /f > NUL 2>&1
start "" "C:\Program Files\AMD\CNext\CNext\Radeonsoftware.exe"
cls
cls & echo AMD GPU settings imported successfully
pause
exit /b