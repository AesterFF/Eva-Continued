@echo off
call "%windir%\Modules\config.bat"
cls & echo Applying NVIDIA GPU settings...
:: RE-APPLY NVIDIA CONTROL PANEL SETTINGS SINCE SOME DO NOT STICK AFTER THE POST INSTALL SCRIPT

:: USE CONTROLSET001 SO UPDATES ARE IN REALTIME SO USER DOES NOT NEED TO RESTART TO VIEW CONTROL PANEL CHANGES

for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\ControlSet001\Enum\%%i" /v "Driver"') do (
		for /f %%i in ('echo %%a ^| findstr "{"') do (
			%= VIDEO =%
				%= ADJUST VIDEO IMAGE SETTINGS =%
					%= EDGE ENHANCEMENT - USE THE NVIDIA SETTING =%
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Edge_Enhance" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					%= EDGE ENHANCEMENT 0 =%
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_VAL_Edge_Enhance" /t REG_DWORD /d "0" /f > NUL 2>&1
					%= NOISE REDUCTION - USE THE NVIDIA SETTING =%
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Noise_Reduce" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					%= NOISE REDUCTION - 0 =%
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_VAL_Noise_Reduce" /t REG_DWORD /d "0" /f > NUL 2>&1
					%= DEINTERLACING - DISABLE "USE INVERSE TELECINE" =%
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_XALG_Cadence" /t REG_BINARY /d "0000000000000000" /f > NUL 2>&1

				%= ADJUST VIDEO COLOR SETTINGS =%
					%= COLOR ADJUSTMENTS - WITH THE NVIDIA SETTINGS =%
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Contrast" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_RGB_Gamma_G" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_RGB_Gamma_R" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_RGB_Gamma_B" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Hue" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Saturation" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Brightness" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Color_Range" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					%= DYNAMIC RANGE - FULL =%
					Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "_User_SUB0_DFP2_XALG_Color_Range" /t REG_BINARY /d "0000000000000000" /f > NUL 2>&1
					
				%= DISABLE HDCP =%
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "RMHdcpKeyglobZero" /t REG_DWORD /d 1 /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "RmDisableHdcp22" /t REG_DWORD /d 1 /f > NUL 2>&1
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "RmSkipHdcp22Init" /t REG_DWORD /d 1 /f > NUL 2>&1
				%= DEVELOPER - MANAGE GPU PERFORMANCE COUNTERS - "ALLOW ACCESS TO THE GPU PERFORMANCE COUNTERS TO ALL USERS" =%
				Reg.exe add "HKLM\System\ControlSet001\Control\Class\%%i" /v "RmProfilingAdminOnly" /t REG_DWORD /d "0" /f > NUL 2>&1
				%= https://github.com/djdallmann/GamingPCSetup/tree/master/CONTENT/RESEARCH/WINDRIVERS#q-is-there-a-registry-setting-that-can-force-your-display-adapter-to-remain-at-its-highest-performance-state-pstate-p0 =%
				if %DISABLE_NVIDIA_PSTATES% EQU TRUE Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "DisableDynamicPstate" /t REG_DWORD /d "1" /f > NUL 2>&1
		)
	)
)
:: DESKTOP > ENABLE DEVELOPER SETTINGS 
Reg.exe add "HKLM\System\ControlSet001\Services\nvlddmkm\Global\NVTweak" /v "NvDevToolsVisible" /t REG_DWORD /d "1" /f > NUL 2>&1
:: ADJUST IMAGE SETTINGS WITH PREVIEW - "USE THE ADVANCED 3D IMAGE SETTINGS"
Reg.exe add "HKCU\Software\NVIDIA Corporation\Global\NVTweak" /v "Gestalt" /t REG_DWORD /d "513" /f > NUL 2>&1
:: CONFIGURE SURROUND, PHYSX - PROCESSOR: GPU
Reg.exe add "HKLM\System\ControlSet001\Services\nvlddmkm\Global\NVTweak" /v "NvCplPhysxAuto" /t REG_DWORD /d "0" /f > NUL 2>&1
:: MANAGE 3D SETTINGS - UNHIDE SILK SMOOTHNESS OPTION
Reg.exe add "HKLM\SYSTEM\ControlSet001\Services\nvlddmkm\FTS" /v "EnableRID61684" /t REG_DWORD /d "1" /f > NUL 2>&1
:: DEVELOPER - MANAGE GPU PERFORMANCE COUNTERS - "ALLOW ACCESS TO THE GPU PERFORMANCE COUNTERS TO ALL USERS"
Reg.exe add "HKLM\System\ControlSet001\Services\nvlddmkm\Global\NVTweak" /v "RmProfilingAdminOnly" /t REG_DWORD /d "0" /f > NUL 2>&1

:: TODO: STRING SEARCH IN OLDER DRIVERS TO SEE IF DWORD IS PRESENT
:: DISABLE PREEMPTION IF CONDITION APPLIES

if %DISABLE_PREEMPTION% EQU TRUE Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "DisablePreemption" /t REG_DWORD /d "1" /f > NUL 2>&1
if %DISABLE_PREEMPTION% EQU TRUE Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "DisableCudaContextPreemption" /t REG_DWORD /d "1" /f > NUL 2>&1

:: ONLY DISABLE WRITE COMBINING IN SUPPORTED DRIVERS
for %%a in (419.35 425.31 441.41) do (
	if %NVIDIADRIVER% EQU %%a Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "DisableWriteCombining" /t REG_DWORD /d "1" /f > NUL 2>&1
)
for /f "delims=" %%a in ('reg query HKLM\System\CurrentControlSet\Services\nvlddmkm\State\DisplayDatabase') do (
	:: OVERRIDE THE SCALING MODE SET BY GAMES AND PROGRAMS
	PowerRun.exe /SW:0 Reg.exe add "%%a" /v "ScalingConfig" /t REG_BINARY /d "DB01000010000000800000006C010000" /f > NUL 2>&1
	:: DISPLAY - CHANGE RESOLUTION - "USE NVIDIA COLOR SETTINGS"
	PowerRun.exe /SW:0 Reg.exe add "%%a" /v "ColorformatConfig" /t REG_BINARY /d "DB02000014000000000A00080000000003010000" /f > NUL 2>&1
)

C:\Windows\Modules\Inspector.exe "C:\Windows\Modules\EVA_Basic.nip" > NUL 2>&1
start "" "C:\Program Files\NVIDIA Corporation\Control Panel Client\nvcplui.exe"
cls
cls & echo NVIDIA GPU settings imported successfully
pause
exit /b