@echo off
SETLOCAL EnableDelayedExpansion

bcdedit | findstr /L "testsigning" > NUL 2>&1
if %errorlevel% EQU 0 (
	start /MIN "" powershell -Command "& {Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Test signing is enabled. After installing your drivers type "bcdedit /deletevalue testsigning" in cmd and reboot to run the post install script again in normal mode', 'EVA - TEST SIGNING ENABLED', 'OK', [System.Windows.Forms.MessageBoxIcon]::Information);}" > NUL 2>&1
	exit /b
)

bcdedit /set {current} description "EVA" > NUL 2>&1
set version=1.0.0
TITLE EVA %version%
wscript "%windir%\Modules\FullscreenCMD.vbs"
set log="%windir%\EVA\logs\POST INSTALL.log"
set QC=32

:SET_PATH
setx PATH "%windir%\EVA;" > NUL 2>&1
call "%windir%\Modules\refresh_env.bat"
call "check_env.bat"
if %errorlevel% NEQ 0 (
	cls & echo PATH was not updated successfully. Retrying in 3 seconds...
	timeout 3 > NUL 2>&1
	cls & goto SET_PATH
)

set config="%windir%\Modules\config.bat"
if exist %config% goto BREAKPOINT

Regedit.exe /s "%windir%\Modules\EVA.reg"
PowerRun.exe /SW:0 regedit.exe /s "%windir%\Modules\EVA.reg"
gpupdate /force > NUL 2>&1

:SELECT_OPTIONS
cls
echo DISCLAIMER
echo.
echo You should NOT change from what you pick in what you select in the interactive section of the post install script.
echo A good example would be switching from Ethernet to wifi after you selected Ethernet
echo.
echo By continuing, you agree to have read the PRE-INSTALL and POST-INSTALL on github.com/amitxvv/EVA
echo.
echo If you need support, join the EVA discord.
echo.
pause

:CONNECTION_TYPE
cls
echo [1/%QC%] What will be your primary internet connection type?
echo.
echo [1] Ethernet
echo. 
echo [2] Wi-Fi
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set CONNECTION_TYPE=WIFI
	cls & goto GRAPHICS
)
if errorlevel 1 (
	>> %config% echo set CONNECTION_TYPE=ETHERNET
	cls & goto GRAPHICS
)

:GRAPHICS
cls
echo [2/%QC%] What GPU combination do you have in your system?
echo.
echo [1] AMD GPU or AMD iGPU
echo. 
echo [2] NVIDIA GPU
echo.
echo [3] INTEL iGPU
echo.
echo [4] INTEL iGPU + AMD GPU
echo.
echo [5] INTEL iGPU + NVIDIA GPU
echo.
choice /c:12345 /n > NUL 2>&1
if errorlevel 5 (
	>> %config% echo set GRAPHICS=INTEL_NVIDIA
	cls & goto NVIDIADRIVER
)
if errorlevel 4 (
	>> %config% echo set GRAPHICS=INTEL_AMD
	cls & goto AMDDRIVER
)
if errorlevel 3 (
	>> %config% echo set GRAPHICS=INTEL
	cls & goto CUSTOM_NIC_AFFINITY
)
if errorlevel 2 (
	>> %config% echo set GRAPHICS=NVIDIA
	cls & goto NVIDIADRIVER
)
if errorlevel 1 (
	>> %config% echo set GRAPHICS=AMD
	cls & goto AMDDRIVER
)

:AMDDRIVER
echo Available AMD Drivers:
echo.
echo 20.4.2 
echo 20.8.3
echo 21.10.2
echo.
set /p AMDDRIVER="Enter what driver you would like to use: "
set AMDDRIVER=%AMDDRIVER: =%

if "%AMDDRIVER%" EQU " =" cls & goto INVALID_AMD
if "%AMDDRIVER%" EQU "=" cls & goto INVALID_AMD

for %%i in (skip SKIP 20.4.2 20.8.3 21.10.2) do (
    if %AMDDRIVER% EQU %%i (
		>> %config% echo set AMDDRIVER=%AMDDRIVER%
		cls & goto RADEON_SOFTWARE
	)
)

:INVALID_AMD
cls
echo Invalid input
echo.
goto AMDDRIVER

:RADEON_SOFTWARE
cls
echo Would you like to install the Radeon Software (control panel)?
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set RADEON_SOFTWARE=FALSE
	cls & goto AMD_OPTIONAL
)
if errorlevel 1 (
	>> %config% echo set RADEON_SOFTWARE=TRUE
	cls & goto AMD_OPTIONAL
)

:AMD_OPTIONAL
cls
echo Would you like to disable powersaving , force max boost core clock frequency and disable thermal throttling within the AMD GPU driver?
echo.
echo WARNING: Temperatures may increase and your GPU will not throttle if it exceeds a set temperature
echo.
echo [1] Yes (highly recommended but ensure you have sufficient cooling/airflow in your case)
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set AMD_OPTIONAL=FALSE
	cls & goto AMD_PRERENDERED_FRAMES
)
if errorlevel 1 (
	>> %config% echo set AMD_OPTIONAL=TRUE
	cls & goto AMD_PRERENDERED_FRAMES
)

:AMD_PRERENDERED_FRAMES
cls
echo How many frames would you like the CPU to buffer before it is rendered by the GPU? (pre rendered frames)
echo.
echo NOTE: This setting requires testing. Alot of people recommend setting it to 0 or 1 however this can negatively impact performance (even on high end systems) and may cause stuttering. It's best left on default (3) if you have not tested each value.
echo.
echo [press 1] 0
echo. 
echo [press 2] 1 (recommended)
echo. 
echo [press 3] 2
echo. 
echo [press 4] 3 (default)
echo.
choice /c:1234 /n > NUL 2>&1
if errorlevel 4 (
	>> %config% echo set AMD_PRERENDERED_FRAMES=3
	cls & goto CUSTOM_NIC_AFFINITY
)
if errorlevel 3 (
	>> %config% echo set AMD_PRERENDERED_FRAMES=2
	cls & goto CUSTOM_NIC_AFFINITY
)
if errorlevel 2 (
	>> %config% echo set AMD_PRERENDERED_FRAMES=1
	cls & goto CUSTOM_NIC_AFFINITY
)
if errorlevel 1 (
	>> %config% echo set AMD_PRERENDERED_FRAMES=0
	cls & goto CUSTOM_NIC_AFFINITY
)

:NVIDIADRIVER
echo Available NVIDIA Drivers:
echo.
echo 419.35
echo 425.31
echo 441.41
echo 442.74
echo 456.71
echo 457.30
echo 457.51
echo 461.92
echo 466.11
echo 472.12
echo.
set /p NVIDIADRIVER="enter what driver you would like to use: "
set NVIDIADRIVER=%NVIDIADRIVER: =%

if "%NVIDIADRIVER%" EQU " =" cls & goto INVALID_NVIDIA
if "%NVIDIADRIVER%" EQU "=" cls & goto INVALID_NVIDIA

for %%i in (skip SKIP 457.30 441.41 391.35 425.31 442.74 457.51 461.92 466.11 419.35 456.71 472.12) do (
    if %NVIDIADRIVER% EQU %%i (
		>> %config% echo set NVIDIADRIVER=%NVIDIADRIVER%
		cls & goto DISABLE_NVIDIA_PSTATES
	)
)

:INVALID_NVIDIA
cls
echo Invalid input
echo.
goto NVIDIADRIVER

:DISABLE_NVIDIA_PSTATES
cls
echo Would you like to disable p-states within the NVIDIA GPU driver? This will allow the GPU to run at boost clock consistently
echo.
echo WARNING: Temperatures may increase
echo.
echo [1] Yes (highly recommended but ensure you have sufficient cooling/airflow in your case)
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set DISABLE_NVIDIA_PSTATES=FALSE
	cls & goto DISABLE_WRITECOMBINING
)
if errorlevel 1 (
	>> %config% echo set DISABLE_NVIDIA_PSTATES=TRUE
	cls & goto DISABLE_WRITECOMBINING
)

:VERIFY_WRITECOMBINING_COMPATIBLE
for %%a in (419.35 425.31 441.41) do (
	if %NVIDIADRIVER% EQU %%a (
		goto DISABLE_WRITECOMBINING
	)
)
>> %config% echo set DISABLE_WRITECOMBINING=FALSE
cls & goto CUSTOM_NIC_AFFINITY

:DISABLE_WRITECOMBINING
cls
echo Would you like to disable writecombining?
echo.
echo [1] Yes (recommended)
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set DISABLE_WRITECOMBINING=FALSE
	cls & goto CUSTOM_NIC_AFFINITY
)
if errorlevel 1 (
	>> %config% echo set DISABLE_WRITECOMBINING=TRUE
	cls & goto CUSTOM_NIC_AFFINITY
)

:CUSTOM_NIC_AFFINITY
cls
echo [3/%QC%] Would you like to set an affinity for the network driver (RssBaseProcessor)?
echo.
echo By default ndis.sys (network driver) runs on cpu 0, it is beneficial for hitreg and dpc latency to offload it to another core
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set CUSTOM_NIC_AFFINITY=FALSE
	cls & goto LAPTOP_KEYBOARD
)
if errorlevel 1 (
	>> %config% echo set CUSTOM_NIC_AFFINITY=TRUE
	cls & goto RSS_BASE_PROC
)

:RSS_BASE_PROC
set /a CPUCORES=%NUMBER_OF_PROCESSORS% - 1
set "output="
for /L %%a in (0,1,%CPUCORES%) do set "output=!output! %%a"
echo Possible values: !output:~1!
echo.
set /p RSS_BASE_PROC="Enter the CPU would you like to set the NIC affinity to "
set RSS_BASE_PROC=%RSS_BASE_PROC: =%

if "%RSS_BASE_PROC%" EQU " =" cls & goto INVALID_RSS_BASE_PROC
if "%RSS_BASE_PROC%" EQU "=" cls & goto INVALID_RSS_BASE_PROC

for /L %%a in (0,1,%CPUCORES%) do (
	if %RSS_BASE_PROC% EQU %%a (
		>> %config% echo set RSS_BASE_PROC=%RSS_BASE_PROC%
		cls & goto LAPTOP_KEYBOARD
	)
)

:INVALID_RSS_BASE_PROC
cls
echo Invalid input
echo.
goto RSS_BASE_PROC

:LAPTOP_KEYBOARD
for /F "tokens=* skip=1" %%n in ('wmic systemenclosure get ChassisTypes ^| findstr "."') do set ChassisTypes=%%n
set ChassisTypes=%ChassisTypes:{=% 
set /a ChassisTypes=%ChassisTypes:}=%
cls
if %ChassisTypes% LEQ 7 (
	>> %config% echo set LAPTOP_KEYBOARD=FALSE
	cls & goto WEBCAM
)

if %ChassisTypes% GTR 7 echo LAPTOP/NOTEBOOK DETECTED!
echo.
echo [4/%QC%] Will you be using the internal laptop keyboard?
echo.
echo NOTE: External keyboard will work on laptops if you choose No. Selecting Yes will disable the msisadrv driver so beware if you need this driver for other other features to function.
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set LAPTOP_KEYBOARD=FALSE
	cls & goto WEBCAM
)
if errorlevel 1 (
	>> %config% echo set LAPTOP_KEYBOARD=TRUE
	cls & goto WEBCAM
)

:WEBCAM
echo [5/%QC%] Will you be using a webcam?
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set WEBCAM=FALSE
	cls & goto POWER_SERVICE
)
if errorlevel 1 (
	>> %config% echo set WEBCAM=TRUE
	cls & goto POWER_SERVICE
)

:POWER_SERVICE
echo [6/%QC%] Do you want to disable the power service for BIOS controlled power mangement over windows?
echo.
echo NOTE: Only choose disabled if you have a fully modded BIOS with cfglock/oclock enabled
echo.
echo [1] Power service enabled (recommended)
echo. 
echo [2] Power service disabled
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set POWER_SERVICE=FALSE
	cls & goto IDLE_SCRIPTS_DESKTOP
)
if errorlevel 1 (
	>> %config% echo set POWER_SERVICE=TRUE
	cls & goto IDLE_SCRIPTS_DESKTOP
)

:IDLE_SCRIPTS_DESKTOP
echo [7/%QC%] Do you want toggle idle disable/enable scripts placed on the desktop?
echo.
echo Toggle idle scripts are useful because you can disable idle just before you launch your game. This way you are not forcing your CPU to run at C0 all the time. Disabling idle significantly improves input and frametime 
echo consistency but comes at the cost of higher temperatures. DO NOT disable idle if you have HT enabled as Windows sleeps the second logical processor of the physical processor for better performance. (source: @calypto)
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set IDLE_SCRIPTS_DESKTOP=FALSE
	cls & goto BCDEDIT_TIMEOUT
)
if errorlevel 1 (
	>> %config% echo set IDLE_SCRIPTS_DESKTOP=TRUE
	cls & goto BCDEDIT_TIMEOUT
)

:BCDEDIT_TIMEOUT
echo [8/%QC%] Select dual boot choice timeout. This does not affect boot times.
echo.
echo This only affects the time given to choose your dual boot at startup.
echo.
echo [1] 0 second timeout
echo.
echo [2] 10 second timeout
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set BCDEDIT_TIMEOUT=10
	cls & goto NX
)
if errorlevel 1 (
	>> %config% echo set BCDEDIT_TIMEOUT=0
	cls & goto NX
)

:NX
echo [9/%QC%] Does your game require NX (DEP) in BCDEDIT.exe to be enabled?
echo.
echo Select Yes if you play: 
echo.
echo FaceIT
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set NX=FALSE
	cls & goto FONT_SMOOTHING
)
if errorlevel 1 (
	>> %config% echo set NX=TRUE
	cls & goto FONT_SMOOTHING
)

:FONT_SMOOTHING
echo [10/%QC%] Do you want text/fonts to have smoothing?
echo.
echo [1] Yes (windows default)
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set FONT_SMOOTHING=FALSE
	cls & goto TSC_SYNC_POLICY
)
if errorlevel 1 (
	>> %config% echo set FONT_SMOOTHING=TRUE
	cls & goto TSC_SYNC_POLICY
)

:TSC_SYNC_POLICY
echo [11/%QC%] Do you want to use a custom Tscsyncpolicy?
echo.
echo These settings must be tested properly. My advice would be to select "None" if you are new to these options.
echo.
echo [1] Legacy
echo. 
echo [2] Enhanced
echo.
echo [3] None (windows default)
echo. 
choice /c:123 /n > NUL 2>&1
if errorlevel 3 (
	>> %config% echo set TSC_SYNC_POLICY=NONE
	cls & goto NSI
)
if errorlevel 2 (
	>> %config% echo set TSC_SYNC_POLICY=ENHANCED
	cls & goto NSI
)
if errorlevel 1 (
	>> %config% echo set TSC_SYNC_POLICY=LEGACY
	cls & goto NSI
)

:NSI
echo [12/%QC%] Does your game require the NSI service to be enabled?
echo.
echo Select Yes if you play:
echo.
echo Valorant
echo Call of Duty Cold War
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set NSI=FALSE
	cls & goto CUSTOM_GPU_AFFINITY
)
if errorlevel 1 (
	>> %config% echo set NSI=TRUE
	cls & goto CUSTOM_GPU_AFFINITY
)

:CUSTOM_GPU_AFFINITY
echo [13/%QC%] Would you like to set a single core GPU affinity to all GPUs in the system?
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set CUSTOM_GPU_AFFINITY=FALSE
	cls & goto CUSTOM_USB_AFFINITY
)
if errorlevel 1 (
	>> %config% echo set CUSTOM_GPU_AFFINITY=TRUE
	cls & goto SELECT_GPU_AFFINITY
)

:SELECT_GPU_AFFINITY
set /a CPUCORES=%NUMBER_OF_PROCESSORS% - 1
set "output="
for /L %%a in (0,1,%CPUCORES%) do set "output=!output! %%a"
echo Possible values: !output:~1!
echo.
set /p CUSTOM_GPU_AFFINITY="Enter the CPU would you like to set the GPU affinity to: "
set CUSTOM_GPU_AFFINITY=%CUSTOM_GPU_AFFINITY: =%

if "%CUSTOM_GPU_AFFINITY%" EQU "=" goto INVALID_GPU_AFFINITY
if "%CUSTOM_GPU_AFFINITY%" EQU " =" goto INVALID_GPU_AFFINITY

for /L %%a in (0,1,%CPUCORES%) do (
	if %CUSTOM_GPU_AFFINITY% EQU %%a (
		goto CONVERT_GPU_AFFINITY
	)
)

:INVALID_GPU_AFFINITY
cls
echo Invalid input
echo.
goto SELECT_GPU_AFFINITY

:CONVERT_GPU_AFFINITY
>> %config% echo set USER_FRIENDLY_GPU_AFFINITY=%CUSTOM_GPU_AFFINITY%
set /a "mask_dec=1<<CUSTOM_GPU_AFFINITY"
set "bin="
for /L %%A in (1,1,32) do (
	set /a "bit=mask_dec&1, mask_dec>>=1"
	set bin=!bit!!bin!
)

call :bin2hex hex !bin:~-%NUMBER_OF_PROCESSORS%!
call :ChangeByteOrder %hex%
>> %config% echo set HEX_GPU_AFFINITY=%BytesLE%
cls & goto INVERT_GPU_AFFINITY_FOR_PROCESSES

:INVERT_GPU_AFFINITY_FOR_PROCESSES
echo Would you like to remove all processes from running on the GPU core (CPU %CUSTOM_GPU_AFFINITY%) ?
echo.
echo Selecting Yes will prevent dwm, svchost, lsass, audiodg and other cycles hungry processes from running on the GPU core which can improve input responsiveness and frametime staibility 
echo.
echo [1] Yes (highly recommended)
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set INVERT_GPU_AFFINITY_FOR_PROCESSES=FALSE
	cls & goto CUSTOM_USB_AFFINITY
)
if errorlevel 1 (
	>> %config% echo set INVERT_GPU_AFFINITY_FOR_PROCESSES=TRUE
	cls & goto PROCESS_INVERT_GPU_AFFINITY_FOR_PROCESSES
)

:PROCESS_INVERT_GPU_AFFINITY_FOR_PROCESSES
set /a "mask_dec=1<<CUSTOM_GPU_AFFINITY"

set "bin="
for /L %%A in (1,1,32) do (
    set /a "bit=mask_dec&1, mask_dec>>=1"
    set bin=!bit!!bin!
)

set binaryaffinity=!bin:~-%NUMBER_OF_PROCESSORS%!
cls & echo Converting binary affinity mask...
for /f %%a in ('powershell "[convert]::ToInt32("%binaryaffinity%",2)"') do set decimal=%%a

set total_dec=0
set /a "total_dec=%total_dec%|%decimal%"

cls & goto CUSTOM_USB_AFFINITY

:CUSTOM_USB_AFFINITY
echo [14/%QC%] Would you like to set a single core USB affinity to all USB controllers in the system?
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set CUSTOM_USB_AFFINITY=FALSE
	cls & goto TASKBAR_ICONS
)
if errorlevel 1 (
	>> %config% echo set CUSTOM_USB_AFFINITY=TRUE
	cls & goto SELECT_USB_AFFINITY
)

:SELECT_USB_AFFINITY
set /a CPUCORES=%NUMBER_OF_PROCESSORS% - 1
set "output="
for /L %%a in (0 1 %CPUCORES%) do set "output=!output! %%a"	
echo Possible values: !output:~1!
echo.
set /p CUSTOM_USB_AFFINITY="enter the CPU would you like to set the USB affinity to: "
set CUSTOM_USB_AFFINITY=%CUSTOM_USB_AFFINITY: =%

if "%CUSTOM_USB_AFFINITY%" EQU "=" goto INVALID_USB_AFFINITY
if "%CUSTOM_USB_AFFINITY%" EQU " =" goto INVALID_USB_AFFINITY
	
for /L %%a in (0,1,%CPUCORES%) do (
	if %CUSTOM_USB_AFFINITY% EQU %%a (
		goto CONVERT_USB_AFFINITY
	)
)

:INVALID_USB_AFFINITY
cls
echo Invalid input
echo.
goto SELECT_USB_AFFINITY

:CONVERT_USB_AFFINITY
>> %config% echo set USER_FRIENDLY_USB_AFFINITY=%CUSTOM_USB_AFFINITY%
set /a "mask_dec=1<<CUSTOM_USB_AFFINITY"
set "bin="
for /L %%A in (1,1,32) do (
	set /a "bit=mask_dec&1, mask_dec>>=1"
	set bin=!bit!!bin!
)

call :bin2hex hex !bin:~-%NUMBER_OF_PROCESSORS%!
call :ChangeByteOrder %hex%
>> %config% echo set HEX_USB_AFFINITY=%BytesLE%
cls & goto INVERT_USB_AFFINITY_FOR_PROCESSES

:INVERT_USB_AFFINITY_FOR_PROCESSES
echo Would you like to remove all processes from running on the USB core (CPU %CUSTOM_USB_AFFINITY%) ?
echo.
echo Selecting Yes will prevent dwm, svchost, lsass, audiodg and other cycles hungry processes from running on the USB core which can improve input responsiveness and polling staibility tremendously
echo.
echo [1] Yes (highly recommended)
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set INVERT_USB_AFFINITY_FOR_PROCESSES=FALSE
	cls & goto TASKBAR_ICONS
)
if errorlevel 1 (
	>> %config% echo set INVERT_USB_AFFINITY_FOR_PROCESSES=TRUE
	cls & goto PROCESS_INVERT_USB_AFFINITY_FOR_PROCESSES
)

:PROCESS_INVERT_USB_AFFINITY_FOR_PROCESSES
set /a "mask_dec=1<<CUSTOM_USB_AFFINITY"

set "bin="
for /L %%A in (1,1,32) do (
    set /a "bit=mask_dec&1, mask_dec>>=1"
    set bin=!bit!!bin!
)

set binaryaffinity=!bin:~-%NUMBER_OF_PROCESSORS%!
cls & echo Converting binary affinity mask...
for /f %%a in ('powershell "[convert]::ToInt32("%binaryaffinity%",2)"') do set decimal=%%a

set /a "total_dec=%total_dec%|%decimal%"

cls & goto TASKBAR_ICONS

:TASKBAR_ICONS
echo [15/%QC%] Combine taskbar buttons/labels?
echo.
echo [1] Always hide labels
echo. 
echo [2] Never combine labels
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set TASKBAR_ICONS_EXTENDED=TRUE
	cls & goto DISABLE_NIC_OFFLOADS
)
if errorlevel 1 (
	>> %config% echo set TASKBAR_ICONS_EXTENDED=FALSE
	cls & goto DISABLE_NIC_OFFLOADS
)

:DISABLE_NIC_OFFLOADS
echo [16/%QC%] Disable network adapter offloads?
echo.
echo Turning on network adapter offload features is usually beneficial. However, the network adapter might not be powerful enough to handle the offload capabilities with high throughput
echo.
echo NOTE: RSS may not function correctly if offloads are disabled.
echo.
echo [1] Yes
echo. 
echo [2] No (recommended)
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set DISABLE_NIC_OFFLOADS=FALSE
	cls & goto AUTOTUNING
)
if errorlevel 1 (
	>> %config% echo set DISABLE_NIC_OFFLOADS=TRUE
	cls & goto AUTOTUNING
)

:AUTOTUNING
echo [17/%QC%] Disable autotuning?
echo.
echo Disabling autotuning may improve bufferbloat but bandwith suffers in some cases, requires testing.
echo.
echo I recommend selecting "Yes", if your bandwith does suffer you can simply revert this.
echo.
echo [1] Yes
echo. 
echo [2] No 
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set DISABLE_AUTOTUNING=FALSE
	cls & goto SET_IOLATENCYCAP
)
if errorlevel 1 (
	>> %config% echo set DISABLE_AUTOTUNING=TRUE
	cls & goto SET_IOLATENCYCAP
)

:SET_IOLATENCYCAP
echo [18/%QC%] Change the IoLatencyCap value?
echo.
echo Description: If this registry value is greater than 0, StorPort will hold incoming I/O requests in the queue when any I/O request sent to miniport driver has not been completed in the period of time specified.
echo.
echo This setting can not be generalized between systems, it requires thorough testing. Select No if you do not know what this is and don't want to risk making your experience laggy/stuttery in general.
echo.
echo Gettng current IoLatencyCap values in the registry...
echo.
for %%a in (IoLatencyCap) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "%%a" ^| findstr "HKEY"') do (
	for /f "tokens=3" %%c in ('reg query "%%b" /v "%%a"') do (
		echo %%b : %%c
	)
)
echo.
echo [1] Yes
echo. 
echo [2] No 
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set SET_IOLATENCYCAP=FALSE
	cls & goto SET_MOUSEDATAQUEUESIZE
)
if errorlevel 1 (
	>> %config% echo set SET_IOLATENCYCAP=TRUE
	cls & goto CHOOSE_IOLATENCYCAP
)

:CHOOSE_IOLATENCYCAP
set /p IOLATENCYCAP="Enter the value less than 2000 you would like to set IoLatencyCap to in milliseconds: "
set IOLATENCYCAP=%IOLATENCYCAP: =%

if "%IOLATENCYCAP%" EQU "=" goto INVALID_IOLATENCYCAP
if "%IOLATENCYCAP%" EQU " =" goto INVALID_IOLATENCYCAP

if %IOLATENCYCAP% LSS 2000 (
	>> %config% echo set IOLATENCYCAP=%IOLATENCYCAP%
	cls & goto SET_MOUSEDATAQUEUESIZE
)

:INVALID_IOLATENCYCAP
cls
echo Invalid input
echo.
goto CHOOSE_IOLATENCYCAP

:SET_MOUSEDATAQUEUESIZE
echo [19/%QC%] Change the mouse driver buffer (MouseDataQueueSize)?
echo.
echo Description: Specifies the number of mouse events buffered by the mouse driver. It also is used in calculating the size of the mouse driver's internal buffer in nonpaged memory pool.
echo.
echo This setting has not been proven to benifit latency, you risk loosing input data if you set it lower than the default value (100).
echo.
echo [1] Yes
echo. 
echo [2] No (recommended)
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set SET_MOUSEDATAQUEUESIZE=FALSE
	cls & goto SET_KEYBOARDDATAQUEUESIZE
)
if errorlevel 1 (
	>> %config% echo set SET_MOUSEDATAQUEUESIZE=TRUE
	cls & goto CHOOSE_MOUSEDATAQUEUESIZE
)

:CHOOSE_MOUSEDATAQUEUESIZE
set /p MOUSEDATAQUEUESIZE="Enter the value less than 500 you would like to set the mouse driver buffer to: "
set MOUSEDATAQUEUESIZE=%MOUSEDATAQUEUESIZE: =%

if "%MOUSEDATAQUEUESIZE%" EQU "=" goto INVALID_MOUSEDATAQUEUESIZE
if "%MOUSEDATAQUEUESIZE%" EQU " =" goto INVALID_MOUSEDATAQUEUESIZE

if %MOUSEDATAQUEUESIZE% LSS 500 (
	>> %config% echo set MOUSEDATAQUEUESIZE=%MOUSEDATAQUEUESIZE%
	cls & goto SET_KEYBOARDDATAQUEUESIZE
)

:INVALID_MOUSEDATAQUEUESIZE
cls
echo Invalid input
echo.
goto CHOOSE_MOUSEDATAQUEUESIZE

:SET_KEYBOARDDATAQUEUESIZE
echo [20/%QC%] Change the keyboard driver buffer (KeyboardDataQueueSize)?
echo.
echo Description: Specifies the number of keyboard events buffered by the keyboard driver. It also is used in calculating the size of the keyboard driver's internal buffer in nonpaged memory pool.
echo.
echo This setting has not been proven to benifit latency, you risk loosing input data if you set it lower than the default value (100).
echo.
echo [1] Yes
echo. 
echo [2] No (recommended)
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set SET_KEYBOARDDATAQUEUESIZE=FALSE
	cls & goto SET_TIMER_RESOLUTION
)
if errorlevel 1 (
	>> %config% echo set SET_KEYBOARDDATAQUEUESIZE=TRUE
	cls & goto CHOOSE_KEYBOARDDATAQUEUESIZE
)

:CHOOSE_KEYBOARDDATAQUEUESIZE
set /p KEYBOARDDATAQUEUESIZE="Enter the value less than 500 you would like to set the keyboard driver buffer to: "
set KEYBOARDDATAQUEUESIZE=%KEYBOARDDATAQUEUESIZE: =%

if "%KEYBOARDDATAQUEUESIZE%" EQU "=" goto INVALID_KEYBOARDDATAQUEUESIZE
if "%KEYBOARDDATAQUEUESIZE%" EQU " =" goto INVALID_KEYBOARDDATAQUEUESIZE

if %KEYBOARDDATAQUEUESIZE% LSS 500 (
	>> %config% echo set KEYBOARDDATAQUEUESIZE=%KEYBOARDDATAQUEUESIZE%
	cls & goto SET_TIMER_RESOLUTION
)

:INVALID_KEYBOARDDATAQUEUESIZE
cls
echo Invalid input
echo.
goto CHOOSE_KEYBOARDDATAQUEUESIZE

:SET_TIMER_RESOLUTION
echo [21/%QC%] Force a timer resolution?
echo.
echo Description: Sets the timer resolution to either 0.5ms or 1ms. Although developers usually allow games to call for 1ms, desktop/browsing is generally laggy and stutters occur if the timer fluctuates (usually 1ms - 8ms)
echo              There is no proven benifit to forcing 1ms if a game calls for 1ms but it will prevent the issue of the timer fluctuating resulting in a unbearable and laggy desktop experience
echo.
echo NOTE: Do not select 0.5ms if you have HPET disabled in BIOS
echo.
echo [1] 1 ms (recommended for all users)
echo. 
echo [2] 0.5 ms (will gimp performance if cpu/os can't keep up)
echo.
echo [3] Don't force a timer resolution at all (good for laptop users/weary about power consumption)
echo. 
choice /c:123 /n > NUL 2>&1
if errorlevel 3 (
	>> %config% echo set SET_TIMER_RESOLUTION=FALSE
	cls & goto QUESTIONABLE_POWER_OPTIONS
)
if errorlevel 2 (
	>> %config% echo set SET_TIMER_RESOLUTION=TRUE
	>> %config% echo set TIMER_RESOLUTION=5000
	cls & goto QUESTIONABLE_POWER_OPTIONS
)
if errorlevel 1 (
	>> %config% echo set SET_TIMER_RESOLUTION=TRUE
	>> %config% echo set TIMER_RESOLUTION=10000
	cls & goto QUESTIONABLE_POWER_OPTIONS
)

:QUESTIONABLE_POWER_OPTIONS
echo [22/%QC%] Would you like to additionally adjust thresholds within the powerplan?
echo.
echo This includes:
echo.
echo Processor performance increase threshold - 2
echo Processor performance decrease threshold - 1
echo Processor idle demote threshold - 100
echo Processor idle promote threshold - 100
echo.
echo [1] Yes (recommended)
echo. 
echo [2] No, leave them at the "ultimate performance plan" default values
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set QUESTIONABLE_POWER_OPTIONS=FALSE
	cls & goto VALORANT
)
if errorlevel 1 (
	>> %config% echo set QUESTIONABLE_POWER_OPTIONS=TRUE
	cls & goto VALORANT
)

:VALORANT
echo [23/%QC%] Will you be playing valorant?
echo.
echo This option will enable Control Flow Guard only for the game exe to allow valorant to run correctly.
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set VALORANT_PLAYER=FALSE
	cls & goto WRITE_CACHE_BUFFER
)
if errorlevel 1 (
	>> %config% echo set VALORANT_PLAYER=TRUE
	cls & goto WRITE_CACHE_BUFFER
)

:WRITE_CACHE_BUFFER
echo [24/%QC%] Disable write cache buffer on all drives?
echo.
echo Description: This option will disable write cache buffer for all drives.
echo.
echo [1] Yes (recommended if you don't have regular power outages)
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set WRITE_CACHE_BUFFER=FALSE
	cls & goto CUSTOM_WIN32PS
)
if errorlevel 1 (
	>> %config% echo set WRITE_CACHE_BUFFER=TRUE
	cls & goto CUSTOM_WIN32PS
)

:CUSTOM_WIN32PS
echo [25/%QC%] Would you like to use a custom Win32PrioritySeperation value?
echo.
echo This requires extensive testing however, it can impact smoothness/responsiveness. If you don't know what you're doing select "No" because 99% of people don't know how to test this correctly.
echo.
echo [1] Yes
echo. 
echo [2] No, use the recommended and predefined value - 26 hex
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set CUSTOM_WIN32PS=FALSE
	cls & goto DISABLE_PREEMPTION
)
if errorlevel 1 (
	>> %config% echo set CUSTOM_WIN32PS=TRUE
	cls & goto CHOOSE_WIN3PS
)

:CHOOSE_WIN3PS
set /p WIN32PS="Enter the custom Win32PrioritySeparation you would like to use in HEX: "
set WIN32PS=%WIN32PS: =%

if "%WIN32PS%" EQU "=" goto INVALID_WIN32PS
if "%WIN32PS%" EQU " =" goto INVALID_WIN32PS

>> %config% echo set WIN32PS_HEX=%WIN32PS%
cls & echo Converting value to decimal to be added via reg add...
for /f %%a in ('powershell -command [uint32]'0x%WIN32PS%'') do set WIN32PS_DEC=%%a

>> %config% echo set WIN32PS_DEC=%WIN32PS_DEC%
cls & goto DISABLE_PREEMPTION

:INVALID_WIN32PS
cls
echo Invalid input
echo.
goto CHOOSE_WIN3PS

:DISABLE_PREEMPTION
echo [26/%QC%] Disable preemption in the graphics drviver and scheduler?
echo.
echo In computing, preemption is the act of temporarily interrupting an executing task, with the intention of resuming it at a later time.
echo.
echo [1] Yes (recommended)
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set DISABLE_PREEMPTION=FALSE
	cls & goto MSSMBIOS
)
if errorlevel 1 (
	>> %config% echo set DISABLE_PREEMPTION=TRUE
	cls & goto MSSMBIOS
)

:MSSMBIOS
echo [27/%QC%] Does your game require the mssmbios driver to be enabled?
echo.
echo Select Yes if you play:
echo.
echo GTA
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set MSSMBIOS=FALSE
	cls & goto MMCSS
)
if errorlevel 1 (
	>> %config% echo set MSSMBIOS=TRUE
	cls & goto MMCSS
)

:MMCSS
echo [28/%QC%] Would you like to have the MMCSS driver enabled or disabled?
echo.
echo This option will either enable or disable the MMCSS driver
echo.
echo [1] MMCSS Enabled
echo. 
echo [2] MMCSS Disabled (recommended)
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set MMCSS_DRIVER=FALSE
	cls & goto SET_PROCESS_PRIORITY
)
if errorlevel 1 (
	>> %config% echo set MMCSS_DRIVER=TRUE
	cls & goto SET_PROCESS_PRIORITY
)

:SET_PROCESS_PRIORITY
echo [29/%QC%] Would you like to set processes that use cycles to low priority?
echo.
echo Selecting Yes will set dwm.exe, lsass.exe, svchost.exe, WmiPrvSE.exe to low priority and split the audio services and levae them at normal priority to prevent audio dropouts when svchost.exe is set to low priority
echo.
echo Users on low end systems (laptops) should select No as desktop/boot times may suffer.
echo.
echo [1] Yes (recommended)
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set SET_PROCESS_PRIORITY=FALSE
	cls & goto SET_MSI_MODE_ALL_DEVICES
)
if errorlevel 1 (
	>> %config% echo set SET_PROCESS_PRIORITY=TRUE
	cls & goto SET_MSI_MODE_ALL_DEVICES
)

:SET_MSI_MODE_ALL_DEVICES
echo [30/%QC%] Enable MSI mode for all devices?
echo.
echo I highly recommend selecting Yes as some manufacturers do not enable MSI mode by default in the driver inf configuration. Selecting Yes also reveals hidden devices in msiutil
echo.
echo [1] Yes (recommended)
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set SET_MSI_MODE_ALL_DEVICES=FALSE
	cls & goto SET_MSI_PRIORITY_ALL_DEVICES
)
if errorlevel 1 (
	>> %config% echo set SET_MSI_MODE_ALL_DEVICES=TRUE
	cls & goto SET_MSI_PRIORITY_ALL_DEVICES
)

:SET_MSI_PRIORITY_ALL_DEVICES
echo [31/%QC%] Would you like to set all devices to a specific priority? (high, normal, low, undefined)
echo.
echo Selecting Yes will allow the user to choose a priority to apply to all devices in msiutil. Selecting No will leave all devices at their default device priority which is specified by the manufacturer in the inf configuration
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set SET_MSI_PRIORITY_ALL_DEVICES=FALSE
	cls & goto SET_RECEIVE_TRANSMIT_BUFFERS
)
if errorlevel 1 (
	>> %config% echo set SET_MSI_PRIORITY_ALL_DEVICES=TRUE
	cls & goto MSIDEVICE_PRIORITY_ALL_DEVICES
)

:MSIDEVICE_PRIORITY_ALL_DEVICES
echo Select a priority to apply to all devices in msiutil
echo.
echo [1] High
echo. 
echo [2] Normal
echo.
echo [3] Low
echo.
echo [4] Undefined
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 4 (
	>> %config% echo set MSIDEVICE_PRIORITY_ALL_DEVICES=0
	cls & goto SET_RECEIVE_TRANSMIT_BUFFERS
)
if errorlevel 3 (
	>> %config% echo set MSIDEVICE_PRIORITY_ALL_DEVICES=1
	cls & goto SET_RECEIVE_TRANSMIT_BUFFERS
)
if errorlevel 2 (
	>> %config% echo set MSIDEVICE_PRIORITY_ALL_DEVICES=2
	cls & goto SET_RECEIVE_TRANSMIT_BUFFERS
)
if errorlevel 1 (
	>> %config% echo set MSIDEVICE_PRIORITY_ALL_DEVICES=3
	cls & goto SET_RECEIVE_TRANSMIT_BUFFERS
)

:SET_RECEIVE_TRANSMIT_BUFFERS
echo [32/%QC%] Would you like to set custom transmit and receive buffers for the network card?
echo.
echo Selecting Yes will allow the user to type a custom value to set transmit and receive buffers to. 
echo.
echo [1] Yes (recommended)
echo. 
echo [2] No
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	>> %config% echo set SET_RECEIVE_TRANSMIT_BUFFERS=FALSE
	cls & goto IMPORT_PROCESS_AFFINITY
)
if errorlevel 1 (
	>> %config% echo set SET_RECEIVE_TRANSMIT_BUFFERS=TRUE
	cls & goto RECEIVE_TRANSMIT_BUFFERS
)

:RECEIVE_TRANSMIT_BUFFERS
echo 1024 or higher recommended. 
echo.
set /p RECEIVE_TRANSMIT_BUFFERS="Enter the value less than 32000 you would like to set the transmit and receive buffers to in the NIC: "
set RECEIVE_TRANSMIT_BUFFERS=%RECEIVE_TRANSMIT_BUFFERS: =%

if "%RECEIVE_TRANSMIT_BUFFERS%" EQU "=" goto INVALID_RECEIVE_TRANSMIT_BUFFERS
if "%RECEIVE_TRANSMIT_BUFFERS%" EQU " =" goto INVALID_RECEIVE_TRANSMIT_BUFFERS

if %RECEIVE_TRANSMIT_BUFFERS% LSS 32000 (
	>> %config% echo set RECEIVE_TRANSMIT_BUFFERS=%RECEIVE_TRANSMIT_BUFFERS%
	cls & goto IMPORT_PROCESS_AFFINITY
)

:INVALID_RECEIVE_TRANSMIT_BUFFERS
cls
echo Invalid input
echo.
goto RECEIVE_TRANSMIT_BUFFERS

:IMPORT_PROCESS_AFFINITY
if not defined total_dec goto CONFIRM_OPTIONS
cls & echo Converting binary affinity mask...
for /f %%a in ('powershell "[Convert]::ToString(%total_dec%,2)"') do set "FINAL=00000000000000000000000000000000%%a"
set FINAL=!FINAL:~-%NUMBER_OF_PROCESSORS%!

set "inverted=%FINAL:1=#%"
set "inverted=%inverted:0=1%"
set "inverted=%inverted:#=0%"

set binaryaffinity=%inverted%

for /f %%a in ('powershell "[convert]::ToInt32("%binaryaffinity%",2)"') do set decimal=%%a

>> "%windir%\EVA\startup.bat" echo set affinity=%Decimal%

:CONFIRM_OPTIONS
cls
call %config%
echo.
echo CONNECTION TYPE : %CONNECTION_TYPE%
echo GPU CONFIG : %GRAPHICS%

if "%GRAPHICS%" EQU "NVIDIA" (
	echo NVIDIA DRIVER : %NVIDIADRIVER%
	echo DISABLE NVIDIA PSTATES : %DISABLE_NVIDIA_PSTATES%
	echo WRITE COMBINING : %DISABLE_WRITECOMBINING%
)
if "%GRAPHICS%" EQU "INTEL_NVIDIA" (
	echo NVIDIA DRIVER : %NVIDIADRIVER%
	echo DISABLE NVIDIA PSTATES : %DISABLE_NVIDIA_PSTATES%
	echo WRITE COMBINING : %DISABLE_WRITECOMBINING%
)
if "%GRAPHICS%" EQU "AMD" (
	echo AMD DRIVER : %AMDDRIVER%
	echo RADEON SOFTWARE : %RADEON_SOFTWARE%
)
if "%GRAPHICS%" EQU "INTEL_AMD" (
	echo AMD DRIVER : %AMDDRIVER%
	echo RADEON SOFTWARE : %RADEON_SOFTWARE%
)

echo CUSTOM NIC AFFINITY : %CUSTOM_NIC_AFFINITY%
if "%CUSTOM_NIC_AFFINITY%" EQU "TRUE" (
	echo NIC AFFINITY : %RSS_BASE_PROC%
)

echo LAPTOP KEYBOARD : %LAPTOP_KEYBOARD%
echo WEBCAM : %WEBCAM%
echo POWER SERVICE : %POWER_SERVICE%
echo IDLE SCRIPTS ON DESKTOP : %IDLE_SCRIPTS_DESKTOP%
echo DUAL BOOT TIMEOUT : %BCDEDIT_TIMEOUT%
echo NX : %NX%
echo FONT SMOOTHING : %FONT_SMOOTHING%
echo TSC SYNC POLICY : %TSC_SYNC_POLICY%
echo NSI SERVICE : %NSI%

echo CUSTOM GPU AFFINITY : %CUSTOM_GPU_AFFINITY%
if "%CUSTOM_GPU_AFFINITY%" EQU "TRUE" (
	echo GPU AFFINITY : %USER_FRIENDLY_GPU_AFFINITY%
	echo REMOVE PROCESSES FROM CPU %USER_FRIENDLY_GPU_AFFINITY%: %INVERT_GPU_AFFINITY_FOR_PROCESSES%
)

echo CUSTOM USB AFFINITY : %CUSTOM_USB_AFFINITY%
if "%CUSTOM_USB_AFFINITY%" EQU "TRUE" (
	echo USB AFFINITY : %USER_FRIENDLY_USB_AFFINITY%
	echo REMOVE PROCESSES FROM CPU %USER_FRIENDLY_USB_AFFINITY% : %INVERT_USB_AFFINITY_FOR_PROCESSES%
)

echo TASKBAR BUTTONS : %TASKBAR_ICONS_EXTENDED%
echo DISABLE NIC OFFLOADS : %DISABLE_NIC_OFFLOADS%
echo AUTOTUNING : %DISABLE_AUTOTUNING%
echo FORCE TIMER RESOUTION : %SET_TIMER_RESOLUTION%
if %SET_TIMER_RESOLUTION% EQU TRUE echo TIMER RESOLUTION : %TIMER_RESOLUTION%
echo QUESTIONABLE POWER OPTIONS : %QUESTIONABLE_POWER_OPTIONS%
echo VALORANT PLAYER : %VALORANT_PLAYER%
echo WRITE CACHE BUFFER : %WRITE_CACHE_BUFFER%
echo CUSTOM W32PS : %CUSTOM_WIN32PS%
if %CUSTOM_WIN32PS% EQU TRUE echo W32PS VALUE : %WIN32PS_HEX%
echo DISABLE PREEMPTION : %DISABLE_PREEMPTION%
echo MSSMBIOS DRIVER : %MSSMBIOS%
echo MMCSS : %MMCSS_DRIVER%
echo SET PROCESS PRIORITY : %SET_PROCESS_PRIORITY%
echo SET MSI MODE ON FOR ALL DEVICES : %SET_MSI_MODE_ALL_DEVICES%
echo SET MSI PRIORITY : %SET_MSI_PRIORITY_ALL_DEVICES%
if %SET_MSI_PRIORITY_ALL_DEVICES% EQU TRUE (
	if "%MSIDEVICE_PRIORITY_ALL_DEVICES%" EQU "0" echo MSI DEVICE PRIORITY FOR ALL DEVICES : UNDEFINED
	if "%MSIDEVICE_PRIORITY_ALL_DEVICES%" EQU "1" echo MSI DEVICE PRIORITY FOR ALL DEVICES : LOW
	if "%MSIDEVICE_PRIORITY_ALL_DEVICES%" EQU "2" echo MSI DEVICE PRIORITY FOR ALL DEVICES : NORMAL
	if "%MSIDEVICE_PRIORITY_ALL_DEVICES%" EQU "3" echo MSI DEVICE PRIORITY FOR ALL DEVICES : HIGH
)
echo SET CUSTOM TRANSMIT AND RECEIVE BUFFERS : %SET_RECEIVE_TRANSMIT_BUFFERS%
if %SET_RECEIVE_TRANSMIT_BUFFERS% EQU TRUE echo TRANSMIT AND RECEIVE BUFFERS : %RECEIVE_TRANSMIT_BUFFERS%
echo.
echo READ ALL INFO ABOVE CAREFULLY... Is all info above correct?
echo.
echo DO NOT COME TO ME AND BLAME ME/ASK FOR HELP DUE TO LOGICAL ERRORS IF YOU HAVE INCORRECTLY SETUP YOUR CONFIG. IT WILL ONLY BE YOUR FAULT.
echo.
echo [1] Yes
echo. 
echo [2] No, i want to select the options again
echo.
choice /c:12 /n > NUL 2>&1
if errorlevel 2 (
	del /f /q %config%
	goto SELECT_OPTIONS
)
if errorlevel 1 (
	set AMDDRIVER=
	set NVIDIADRIVER=
	set RSS_BASE_PROC=
	set CUSTOM_GPU_AFFINITY=
	set total_dec=
	set CUSTOM_USB_AFFINITY=
	set IOLATENCYCAP=
	set MOUSEDATAQUEUESIZE=
	set KEYBOARDDATAQUEUESIZE=
	set RECEIVE_TRANSMIT_BUFFERS=
	set FINAL=
	goto BREAKPOINT
)

:BREAKPOINT
cls
call %config%
echo BREAKPOINT
echo.
echo Breakpoint is essentially a "pause" before the core post install script executes
echo.
echo Things you should do at Breakpoint:
echo.
echo - Install USB, NVME, Audio, Sata, Wifi drivers if you would like to do so
echo - Install Intel iGPU driver
echo - Activate windows
echo - Install modded drivers that you have appropriately adapted for hardware support
echo.
echo =====================================================================================================
echo.
echo NOTE: Snappy Driver Installer Origin will be available on the desktop (internet connection required)
echo NOTE: DO NOT install AMD/NVIDIA GPU drivers here
echo NOTE: DO NOT install Ethernet drivers if your internet already works
if %GRAPHICS% EQU INTEL echo. & echo You are required to install iGPU drivers now.
if %GRAPHICS% EQU INTEL_AMD echo. & echo You are required to install iGPU drivers now.
if %GRAPHICS% EQU INTEL_NVIDIA echo. & echo You are required to install iGPU drivers now.
echo.
echo =====================================================================================================
echo.
echo Enter Breakpoint?
echo.
echo [1] Yes
echo. 
echo [2] No
echo.
echo [3] Enter breakpoint with testsigning enabled (STRICTLY FOR DEBUGGING ONLY!)
echo.
choice /c:123 /n > NUL 2>&1
if errorlevel 3 (
	bcdedit /set testsigning on > NUL 2>&1
	cls & echo Entering Breakpoint with testsigning...
	echo.
	echo Restart your PC to run the script again once you are finished.
	echo.
	pause
	copy /y "%windir%\Modules\Enter windows activation product key.txt" "%userprofile%\desktop" > NUL 2>&1
	nircmd shortcut "%windir%\Modules\SDIO\SDIO_x64_R739.exe" "%userprofile%\desktop" "SDIO"
	shutdown /r /f /t 0
	exit /b
)
if errorlevel 2 (
	cls
	for %%a in (INTEL INTEL_AMD INTEL_NVIDIA) do (
		if !GRAPHICS! EQU %%a (
			wmic path win32_VideoController get name | findstr /L "Intel"
			if !errorlevel! NEQ 0 (
				echo Force entering Breakpoint. You are required to install iGPU drivers now. & goto ENTER_BREAKPOINT
			)
		)
	)
	:: ADD WINDOWS ACTIVATED CHECK
	goto CONNECTION_TYPE
)
if errorlevel 1 (
	cls
	echo Entering Breakpoint...
	:ENTER_BREAKPOINT
	echo.
	echo Restart your PC to run the script again once you are finished.
	echo.
	pause
	copy /y "%windir%\Modules\Enter windows activation product key.txt" "%userprofile%\desktop" > NUL 2>&1
	nircmd shortcut "%windir%\Modules\SDIO\SDIO_x64_R739.exe" "%userprofile%\desktop" "SDIO"
	exit /b
)

:CONNECTION_TYPE
cls
if %CONNECTION_TYPE% EQU ETHERNET goto ETHERNET_USER
if %CONNECTION_TYPE% EQU WIFI goto WIFI_USER

:ETHERNET_USER
ping 1.1.1.1 | find "bytes="
IF %ERRORLEVEL% EQU 0 (   
	goto VALID_ETHERNET
) ELSE (
	goto INVALID_CONNECTION
)

:VALID_ETHERNET
cls
echo Setting Static IP based on current DHCP IP...
for /f "delims=" %%b in ('reg query "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /s /f "DhcpIPAddress" ^| findstr "HKEY"') do (
	for /f "tokens=3" %%a in ('reg query "%%b" /v "DhcpIPAddress"') do set "IpAddress=%%a"
)

for /f "delims=" %%b in ('reg query "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /s /f "DhcpSubnetMask" ^| findstr "HKEY"') do (
	for /f "tokens=3" %%a in ('reg query "%%b" /v "DhcpSubnetMask"') do set "SubnetMask=%%a"
)

for /f "delims=" %%b in ('reg query "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /s /f "DhcpDefaultGateway" ^| findstr "HKEY"') do (
	for /f "tokens=3" %%a in ('reg query "%%b" /v "DhcpDefaultGateway"') do set "DefaultGateway=%%a"
)

for /f "tokens=3*" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkCards" /f "ServiceName" /s^|findstr /i /l "ServiceName"') do (
Reg.exe delete "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "DhcpDomain" /f > NUL 2>&1
Reg.exe delete "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "DhcpNameServer" /f > NUL 2>&1
Reg.exe delete "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "DhcpDefaultGateway" /f > NUL 2>&1
Reg.exe delete "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "DhcpSubnetMaskOpt" /f > NUL 2>&1
Reg.exe delete "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "DhcpIPAddress" /f > NUL 2>&1
Reg.exe delete "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "DhcpSubnetMask" /f > NUL 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "RegistrationEnabled" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "DhcpServer" /t REG_SZ /d "255.255.255.255" /f > NUL 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "IPAddress" /t REG_MULTI_SZ /d "%IpAddress%" /f > NUL 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "SubnetMask" /t REG_MULTI_SZ /d "%SubnetMask%" /f > NUL 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "DefaultGateway" /t REG_MULTI_SZ /d "%DefaultGateway%" /f > NUL 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "DefaultGatewayMetric" /t REG_MULTI_SZ /d "0" /f > NUL 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "NameServer" /t REG_SZ /d "1.1.1.1,1.0.0.1" /f > NUL 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "EnableDHCP" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "RegisterAdapterName" /t REG_DWORD /d "0" /f > NUL 2>&1
)
Reg.exe delete "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters" /v "DhcpNameServer" /f > NUL 2>&1
Reg.exe delete "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters" /v "DhcpDomain" /f > NUL 2>&1
cls
echo Checking if static ip applied correctly...
echo.
timeout t 3 > NUL 2>&1
ping 1.1.1.1 | find "bytes="
IF %ERRORLEVEL% EQU 0 (   
	goto BEGIN_SCRIPT
) ELSE (
    goto INVALID_CONNECTION
)

:WIFI_USER
cls
echo The script will now timeout for 5 minutes...
echo.
echo Press CTRL + ALT + DELETE to connect to your wifi network with the network icon at the bottom right of the screen
timeout /t 300
cls
ping 1.1.1.1 | find "bytes="
IF %ERRORLEVEL% EQU 0 (   
	goto BEGIN_SCRIPT
) ELSE (
	goto INVALID_CONNECTION
)

:INVALID_CONNECTION
cls
echo ERROR: You are not connected to the internet, check your connection details and try again.
pause
cls
goto CONNECTION_TYPE

:BEGIN_SCRIPT

start /b powershell -Command "& {Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Setup is running: DO NOT turn off the computer. Your PC will automatically restart when setup is complete.', 'EVA POST INSTALL - A FREE ISO BY @AMITXV', 'OK', [System.Windows.Forms.MessageBoxIcon]::Information);}" > NUL 2>&1

>> %log% echo EVA POST INSTALL LOG
>> %log% echo.
>> %log% echo IF THIS LOG DOES NOT END IN SETUP COMPLETE, THEN YOUR POST INSTALL FAILED AND YOU MUST REINSTALL OR CONTACT ME VIA THE EVA DISCORD FOR SUPPORT.
>> %log% echo.
>> %log% echo -----------------------------------------------------------------------------------------------------------------------------------------------
>> %log% echo.
>> %log% echo %date% %time% - Setup initialized

cls
:: SET POWERSHELL EXECUTION POLICY TO UNRESTRICTED
cls & echo Setting powershell execution policy to unrestricted...
powershell Set-ExecutionPolicy Unrestricted -force > NUL 2>&1


:: IMPORT POWERPLAN
cls & echo Importing EVA powerplan...

for /F "tokens=* skip=1" %%n in ('wmic systemenclosure get ChassisTypes ^| findstr "."') do set ChassisTypes=%%n
set ChassisTypes=%ChassisTypes:{=% 
set /a ChassisTypes=%ChassisTypes:}=%

:: Duplicate ultimate performance with custom GUID
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 11111111-1111-1111-1111-111111111111
cls

:: Rename powerplan
powercfg -changename 11111111-1111-1111-1111-111111111111 "EVA powerplan" "A powerplan dedicated to EVA for the lowest latency and highest 0.01% lows."

:: Unhide Secondary NVMe Idle Timeout
Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442\d3d55efd-c1ff-424e-9dc3-441be7833010" /v "Attributes" /t REG_DWORD /d "0" /f > NUL 2>&1

:: Unhide Primary NVMe Idle Timeout
Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442\d639518a-e56d-4345-8af2-b9f32fb26109" /v "Attributes" /t REG_DWORD /d "0" /f > NUL 2>&1

:: Unhide Hub Selective Suspend Timeout
Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\0853a681-27c8-4100-a2fd-82013e970683" /v "Attributes" /t REG_DWORD /d "0" /f > NUL 2>&1

:: Unhide USB 3 Link Power Mangement
Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009" /v "Attributes" /t REG_DWORD /d "0" /f > NUL 2>&1

:: Unhide Processor performance increase threshold
Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\06cadf0e-64ed-448a-8927-ce7bf90eb35d" /v "Attributes" /t REG_DWORD /d "0" /f > NUL 2>&1

:: Unhide Processor performance decrease threshold
Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\12a0ab44-fe28-4fa9-b3bd-4b64f44960a6" /v "Attributes" /t REG_DWORD /d "0" /f > NUL 2>&1

:: Unhide Allow Throttle States
Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb" /v "Attributes" /t REG_DWORD /d "0" /f > NUL 2>&1

:: Unhide Processor idle demote threshold
Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\4b92d758-5a24-4851-a470-815d78aee119" /v "Attributes" /t REG_DWORD /d "0" /f > NUL 2>&1

:: Unhide Processor idle disable
Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\5d76a2ca-e8c0-402f-a133-2158492d58ad" /v "Attributes" /t REG_DWORD /d "0" /f > NUL 2>&1

:: Unhide Processor idle promote threshold
Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\7b224883-b3cc-4d79-819f-8374152cbe7c" /v "Attributes" /t REG_DWORD /d "0" /f > NUL 2>&1

:: Hard disk

	:: Turn off hard disk after - 0
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\0012ee47-9041-4b5d-9b77-535fba8b1442\6738e2c4-e8a5-4a42-b16a-e040e769756e" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\0012ee47-9041-4b5d-9b77-535fba8b1442\6738e2c4-e8a5-4a42-b16a-e040e769756e" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
	:: Secondary NVMe Idle Timeout - 0
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\0012ee47-9041-4b5d-9b77-535fba8b1442\d3d55efd-c1ff-424e-9dc3-441be7833010" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\0012ee47-9041-4b5d-9b77-535fba8b1442\d3d55efd-c1ff-424e-9dc3-441be7833010" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
	:: Primary NVMe Idle Timeout - 0
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\0012ee47-9041-4b5d-9b77-535fba8b1442\d639518a-e56d-4345-8af2-b9f32fb26109" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\0012ee47-9041-4b5d-9b77-535fba8b1442\d639518a-e56d-4345-8af2-b9f32fb26109" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
:: Desktop background settings

	:: Slide show - Paused
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\0d7dbae2-4294-402a-ba8e-26777e8488cd\309dce9b-bef4-4119-9921-a851fb12f0f4" /v "ACSettingIndex" /t REG_DWORD /d "1" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\0d7dbae2-4294-402a-ba8e-26777e8488cd\309dce9b-bef4-4119-9921-a851fb12f0f4" /v "DCSettingIndex" /t REG_DWORD /d "1" /f > NUL 2>&1
	
:: Wireless Adapter Settings

	:: Powersaving Mode - Maximum Performance
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\19cbb8fa-5279-450e-9fac-8a3d5fedd0c1\12bbebe6-58d6-4636-95bb-3217ef867c1a" /v "ACSettingIndex" /t REG_BINARY /d "00000000" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\19cbb8fa-5279-450e-9fac-8a3d5fedd0c1\12bbebe6-58d6-4636-95bb-3217ef867c1a" /v "DCSettingIndex" /t REG_BINARY /d "00000000" /f > NUL 2>&1
	
:: Sleep
	
	:: Allow wake timers - Disable
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\238c9fa8-0aad-41ed-83f4-97be242c8f20\bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\238c9fa8-0aad-41ed-83f4-97be242c8f20\bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
:: USB settings

	:: Hub Selective Suspend Timeout - 0
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\2a737441-1930-4402-8d77-b2bebba308a3\0853a681-27c8-4100-a2fd-82013e970683" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\2a737441-1930-4402-8d77-b2bebba308a3\0853a681-27c8-4100-a2fd-82013e970683" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
	:: USB selective suspend setting - Disabled
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\2a737441-1930-4402-8d77-b2bebba308a3\48e6b7a6-50f5-4782-a5d4-53bb8f07e226" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\2a737441-1930-4402-8d77-b2bebba308a3\48e6b7a6-50f5-4782-a5d4-53bb8f07e226" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
	:: USB 3 Link Power Management - Off
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
:: Power buttons and lid

	:: Power button action - Do nothing
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\4f971e89-eebd-4455-a8de-9e59040e7347\7648efa3-dd9c-4e3e-b566-50f929386280" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\4f971e89-eebd-4455-a8de-9e59040e7347\7648efa3-dd9c-4e3e-b566-50f929386280" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
	:: Sleep button action - Do nothing
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\4f971e89-eebd-4455-a8de-9e59040e7347\96996bc0-ad50-47ec-923b-6f41874dd9eb" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\4f971e89-eebd-4455-a8de-9e59040e7347\96996bc0-ad50-47ec-923b-6f41874dd9eb" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
:: PCI Express

	:: Link State Power Management - Off
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
:: Processor power management

	:: Processor performance increase threshold - 2
	if %QUESTIONABLE_POWER_OPTIONS% EQU TRUE PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\06cadf0e-64ed-448a-8927-ce7bf90eb35d" /v "ACSettingIndex" /t REG_DWORD /d "2" /f > NUL 2>&1
	if %QUESTIONABLE_POWER_OPTIONS% EQU TRUE if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\06cadf0e-64ed-448a-8927-ce7bf90eb35d" /v "DCSettingIndex" /t REG_DWORD /d "2" /f > NUL 2>&1
	
	:: Processor performance decrease threshold - 1
	if %QUESTIONABLE_POWER_OPTIONS% EQU TRUE PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\12a0ab44-fe28-4fa9-b3bd-4b64f44960a6" /v "ACSettingIndex" /t REG_DWORD /d "1" /f > NUL 2>&1
	if %QUESTIONABLE_POWER_OPTIONS% EQU TRUE if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\12a0ab44-fe28-4fa9-b3bd-4b64f44960a6" /v "DCSettingIndex" /t REG_DWORD /d "1" /f > NUL 2>&1 
	
	:: Allow Throttle States - Off
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
	:: Processor idle demote threshold - 100
	if %QUESTIONABLE_POWER_OPTIONS% EQU TRUE PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\4b92d758-5a24-4851-a470-815d78aee119" /v "ACSettingIndex" /t REG_DWORD /d "100" /f > NUL 2>&1
	if %QUESTIONABLE_POWER_OPTIONS% EQU TRUE if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\4b92d758-5a24-4851-a470-815d78aee119" /v "DCSettingIndex" /t REG_DWORD /d "100" /f > NUL 2>&1
	
	:: Processor idle disable - Enable idle
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\5d76a2ca-e8c0-402f-a133-2158492d58ad" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\5d76a2ca-e8c0-402f-a133-2158492d58ad" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
	:: Processor idle promote threshold - 100
	if %QUESTIONABLE_POWER_OPTIONS% EQU TRUE PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\7b224883-b3cc-4d79-819f-8374152cbe7c" /v "ACSettingIndex" /t REG_DWORD /d "100" /f > NUL 2>&1
	if %QUESTIONABLE_POWER_OPTIONS% EQU TRUE if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\7b224883-b3cc-4d79-819f-8374152cbe7c" /v "DCSettingIndex" /t REG_DWORD /d "100" /f > NUL 2>&1
	
	:: Minimum processor state - 100
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\893dee8e-2bef-41e0-89c6-b55d0929964c" /v "ACSettingIndex" /t REG_DWORD /d "100" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\893dee8e-2bef-41e0-89c6-b55d0929964c" /v "DCSettingIndex" /t REG_DWORD /d "100" /f > NUL 2>&1
	
	:: System cooling policy - Active
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\94d3a615-a899-4ac5-ae2b-e4d8f634367f" /v "ACSettingIndex" /t REG_DWORD /d "1" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\94d3a615-a899-4ac5-ae2b-e4d8f634367f" /v "DCSettingIndex" /t REG_DWORD /d "1" /f > NUL 2>&1
	
	:: Maximum processor state - 100
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\bc5038f7-23e0-4960-96da-33abaf5935ec" /v "ACSettingIndex" /t REG_DWORD /d "100" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\54533251-82be-4824-96c1-47b60b740d00\bc5038f7-23e0-4960-96da-33abaf5935ec" /v "DCSettingIndex" /t REG_DWORD /d "100" /f > NUL 2>&1
	
:: Display

	:: Turn off display after - 0
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\7516b95f-f776-4464-8c53-06167f40cc99\3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\7516b95f-f776-4464-8c53-06167f40cc99\3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
	:: Display brightness - 100
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\7516b95f-f776-4464-8c53-06167f40cc99\aded5e82-b909-4619-9949-f5d71dac0bcb" /v "ACSettingIndex" /t REG_DWORD /d "100" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\7516b95f-f776-4464-8c53-06167f40cc99\aded5e82-b909-4619-9949-f5d71dac0bcb" /v "DCSettingIndex" /t REG_DWORD /d "100" /f > NUL 2>&1
	
	:: Dimmed display brightness - 100
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\7516b95f-f776-4464-8c53-06167f40cc99\f1fbfde2-a960-4165-9f88-50667911ce96" /v "ACSettingIndex" /t REG_DWORD /d "100" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\7516b95f-f776-4464-8c53-06167f40cc99\f1fbfde2-a960-4165-9f88-50667911ce96" /v "DCSettingIndex" /t REG_DWORD /d "100" /f > NUL 2>&1
	
	:: Enable adaptive brightness - Off
	PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\7516b95f-f776-4464-8c53-06167f40cc99\fbd9aa66-9553-4097-ba44-ed6e9d65eab8" /v "ACSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	if %ChassisTypes% GTR 7 PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\Power\User\PowerSchemes\11111111-1111-1111-1111-111111111111\7516b95f-f776-4464-8c53-06167f40cc99\fbd9aa66-9553-4097-ba44-ed6e9d65eab8" /v "DCSettingIndex" /t REG_DWORD /d "0" /f > NUL 2>&1
	
:: Set powerplan as active
powercfg -setactive 11111111-1111-1111-1111-111111111111

:: Delete stock powerplans
powercfg -delete a1841308-3541-4fab-bc81-f71556f20b4a > NUL 2>&1
powercfg -delete 381b4222-f694-41f0-9685-ff5bb260df2e > NUL 2>&1
powercfg -delete 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c > NUL 2>&1
powercfg -delete e9a42b02-d5df-448d-aa00-03f14749eb61 > NUL 2>&1

:: FILE SYSTEM MODIFICATIONS
:: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-behavior
:: I HAVE DISABLED AUTOMATIC DISK CHECKING/REPARING TO PREVENT UNWANTED BEHAVIOR TO THE SYSTEM, MANUAL DEBUGGING/CHECKING IS MORE RELIABLE
cls & echo Applying file system modifications...

fsutil behavior set allowextchar 0 > NUL 2>&1
fsutil behavior set Bugcheckoncorrupt 0 > NUL 2>&1
fsutil repair set C: 0 > NUL 2>&1
fsutil behavior set disable8dot3 1 > NUL 2>&1
fsutil behavior set disablecompression 1 > NUL 2>&1
fsutil behavior set disableencryption 1 > NUL 2>&1
fsutil behavior set disablelastaccess 1 > NUL 2>&1
fsutil behavior set disablespotcorruptionhandling 1 > NUL 2>&1
fsutil behavior set encryptpagingfile 0 > NUL 2>&1
fsutil behavior set quotanotify 86400 > NUL 2>&1
fsutil behavior set symlinkevaluation L2L:1 > NUL 2>&1
fsutil behavior set disabledeletenotify 0 > NUL 2>&1

:: DISABLE AUDIO EXCLUSIVE MODE
cls & echo Disabling exclusive mode on audio devices...

for /f "delims=" %%a in ('reg query HKLM\Software\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture') do PowerRun.exe /SW:0 reg.exe add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d 0 /f
for /f "delims=" %%a in ('reg query HKLM\Software\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture') do PowerRun.exe /SW:0 reg.exe add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d 0 /f
for /f "delims=" %%a in ('reg query HKLM\Software\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render') do PowerRun.exe /SW:0 reg.exe add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d 0 /f
for /f "delims=" %%a in ('reg query HKLM\Software\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render') do PowerRun.exe /SW:0 reg.exe add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d 0 /f

:: DISABLE THE ASSOCIATED DRIVERS BEFORE DISABLING THE ENTRY IN DEVICE MANAGER
cls & echo Disabling device manager devices...

reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\swenum" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\UEFI" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\msisadrv" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WmiAcpi" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "UMBus Root Bus Enumerator" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Root Print Queue" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "NDIS Virtual Network Adapter Enumerator" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Microsoft Virtual Drive Enumerator" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Microsoft Hyper-V Virtualization Infrastructure Driver" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Microsoft GS Wavetable Synth" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Microsoft Device Association Root Enumerator" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Composite Bus Enumerator" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Microsoft UEFI-Compliant System" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "System board" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "SM Bus Controller" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Motherboard resources" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "PCI Encryption/Decryption Controller" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Microsoft Windows Management Interface for ACPI" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "High precision event timer" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Base System Device" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "PCI Data Acquisition and Signal Processing Controller" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "PCI Simple Communications Controller" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "PCI Device" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Unknown Device" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "PCI Simple Communications Controller" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "PCI Memory Controller" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "PCI standard RAM Controller" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "ACPI Processor Aggregator" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "ACPI Wake Alarm" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "System Speaker" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "System Timer" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "WAN Miniport (IKEv2)" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "WAN Miniport (IP)" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "WAN Miniport (IPv6)" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "WAN Miniport (L2TP)" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "WAN Miniport (Network Monitor)" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "WAN Miniport (PPPOE)" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "WAN Miniport (PPTP)" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "WAN Miniport (SSTP)" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Programmable Interrupt Controller" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Numeric Data Processor" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Microsoft Kernel Debug Network Adapter" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "HID-compliant consumer control device" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "PCI standard ISA bridge" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Plug and Play Software Device Enumerator" > NUL 2>&1
"%windir%\Modules\devmanview.exe" /disable "Direct memory access controller" > NUL 2>&1

:: DISABLE POWERSAVING AND WAKE FEATURES FOR PNP DEVICES IN DEVICE MANAGER
cls & echo Disabling PnP device powersaving...

powershell "%windir%\Modules\PSCODE.ps1" > NUL 2>&1

for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
		for /f %%i in ('echo %%a ^| findstr "{"') do ( 
			reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "PnPCapabilities" /t REG_DWORD /d "24" /f > NUL 2>&1
		)
	)
)

:: DISABLE WRITE CACHE BUFFER IF CONDITION APPLIES

if %WRITE_CACHE_BUFFER% EQU TRUE (
	cls & echo Disabling write cache buffer on all drives...
	for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\SCSI"^| findstr "HKEY"') do (
		for /f "tokens=*" %%a in ('reg query "%%i"^| findstr "HKEY"') do reg.exe add "%%a\Device Parameters\Disk" /v "CacheIsPowerProtected" /t REG_DWORD /d "1" /f > NUL 2>&1
	)
	for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\SCSI"^| findstr "HKEY"') do (
		for /f "tokens=*" %%a in ('reg query "%%i"^| findstr "HKEY"') do reg.exe add "%%a\Device Parameters\Disk" /v "UserWriteCacheSetting" /t REG_DWORD /d "1" /f > NUL 2>&1
	)
)

:: INSTALL FIREFOX
cls & echo Downloading firefox...
echo.
curl -L "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-GB" -o "%temp%\Firefox Setup.exe" --progress-bar
cls & echo Debloating firefox...
7z.exe x -y -o"%temp%\Firefox Setup" "%temp%\Firefox Setup.exe" > NUL 2>&1
for %%a in (crashreporter.exe crashreporter.ini maintenanceservice.exe maintenanceservice_installer.exe minidump-analyzer.exe pingsender.exe updater.exe) do (
	del /f /q "%temp%\Firefox Setup\core\%%a" > NUL 2>&1
)
cls & echo Installing firefox...
if exist "C:\Program Files\Mozilla Firefox" rd /s /q "C:\Program Files\Mozilla Firefox" > NUL 2>&1
move /y "%temp%\Firefox Setup\core" "C:\Program Files" & ren "C:\Program Files\core" "Mozilla Firefox"
Reg.exe add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v "DisableAppUpdate" /t REG_DWORD /d "1" /f > NUL 2>&1
"C:\Program Files\Mozilla Firefox\uninstall\helper.exe" /SetAsDefaultAppGlobal
rd /s /q "C:\Program Files\Mozilla Firefox\uninstall" > NUL 2>&1

:: DELETE LEFT OVER WINDOWS APPS FOLDERS

takeown /F "C:\Program Files\WindowsApps" /A & icacls "C:\Program Files\WindowsApps" /grant Administrators:(F) > NUL 2>&1
takeown /F "%userprofile%\AppData\Local\Microsoft\WindowsApps" /A & icacls "%userprofile%\AppData\Local\Microsoft\WindowsApps" /grant Administrators:(F) > NUL 2>&1
cls
RD /S /Q "C:\Program Files\WindowsApps" > NUL 2>&1
RD /S /Q "%userprofile%\AppData\Local\Microsoft\WindowsApps" > NUL 2>&1

:: INSTALL OPEN SHELL AND IMPORT SETTINGS
cls & echo Installing Open Shell and importing settings...

"%windir%\Modules\Open Shell.exe" /qn ADDLOCAL=StartMenu
Reg.exe add "HKCU\SOFTWARE\OpenShell\StartMenu" /v "ShowedStyle2" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "Version" /t REG_DWORD /d "67371150" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "MenuStyle" /t REG_SZ /d "Win7" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "ShiftClick" /t REG_SZ /d "Nothing" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "ShiftWin" /t REG_SZ /d "Nothing" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "ControlPanelCategories" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "AllProgramsMetro" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "HideProgramsMetro" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "RecentPrograms" /t REG_SZ /d "None" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "ShutdownCommand" /t REG_SZ /d "CommandShutdown" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "HybridShutdown" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "StartScreenShortcut" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "AutoStart" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "HighlightNew" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "HighlightNewApps" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "CheckWinUpdates" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "PreCacheIcons" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SearchBox" /t REG_SZ /d "Normal" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SearchTrack" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SearchPath" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SearchMetroApps" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SearchMetroSettings" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SearchKeywords" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SearchSubWord" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SearchFiles" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SearchContents" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SearchCategories" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SearchInternet" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "InvertMetroIcons" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "MainMenuAnimation" /t REG_SZ /d "None" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SubMenuAnimation" /t REG_SZ /d "None" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "MenuFadeSpeed" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SkinW7" /t REG_SZ /d "Midnight" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SkinVariationW7" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SkinOptionsW7" /t REG_MULTI_SZ /d "USER_IMAGE=0\0SMALL_ICONS=0\0LARGE_FONT=0\0DISABLE_MASK=0\0OPAQUE=1\0TRANSPARENT_LESS=0\0TRANSPARENT_MORE=0\0WHITE_SUBMENUS2=0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "EnableStartButton" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SkipMetro" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "MenuItems7" /t REG_MULTI_SZ /d "Item1.Command=user_files\0Item1.Settings=ITEM_DISABLED\0Item2.Command=user_documents\0Item2.Settings=ITEM_DISABLED\0Item3.Command=user_pictures\0Item3.Settings=ITEM_DISABLED\0Item4.Command=user_music\0Item4.Settings=ITEM_DISABLED\0Item5.Command=user_videos\0Item5.Settings=ITEM_DISABLED\0Item6.Command=downloads\0Item6.Settings=ITEM_DISABLED\0Item7.Command=homegroup\0Item7.Settings=ITEM_DISABLED\0Item8.Command=separator\0Item9.Command=games\0Item9.Settings=TRACK_RECENT|ITEM_DISABLED\0Item10.Command=favorites\0Item10.Settings=ITEM_DISABLED\0Item11.Command=recent_documents\0Item11.Settings=ITEM_DISABLED\0Item12.Command=computer\0Item12.Settings=NOEXPAND\0Item13.Command=network\0Item13.Settings=ITEM_DISABLED\0Item14.Command=network_connections\0Item14.Settings=ITEM_DISABLED\0Item15.Command=separator\0Item16.Command=control_panel\0Item16.Label=$Menu.ControlPanel\0Item16.Tip=$Menu.ControlPanelTip\0Item16.Settings=TRACK_RECENT|NOEXPAND\0Item17.Command=pc_settings\0Item17.Settings=TRACK_RECENT|ITEM_DISABLED\0Item18.Command=admin\0Item18.Settings=TRACK_RECENT|ITEM_DISABLED\0Item19.Command=devices\0Item19.Settings=ITEM_DISABLED\0Item20.Command=defaults\0Item20.Settings=ITEM_DISABLED\0Item21.Command=help\0Item21.Settings=ITEM_DISABLED\0Item22.Command=run\0Item22.Settings=ITEM_DISABLED\0Item23.Command=apps\0Item23.Settings=ITEM_DISABLED\0Item24.Command=windows_security\0Item24.Settings=ITEM_DISABLED" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "EnableContextMenu" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "ShowNewFolder" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "EnableExit" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "EnableExplorer" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SoundMain" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SoundPopup" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SoundCommand" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "SoundDrop" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "ProgramsStyle" /t REG_SZ /d "Inline" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "PinnedPrograms" /t REG_SZ /d "PinnedItems" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "MainMenuAnimate" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "MenuShadow" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "EnableGlass" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "CustomTaskbar" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "TaskbarColor" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "OpenPrograms" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "EnableJumplists" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "EnableAccessibility" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "NumericSort" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKCU\Software\OpenShell\StartMenu\Settings" /v "FontSmoothing" /t REG_SZ /d "None" /f > NUL 2>&1
del /f /q "%windir%\Modules\Open Shell.exe" > NUL 2>&1

:: INSTALL 7-ZIP AND IMPORT SETTINGS
cls & echo Installing 7-Zip and importing settings...

"%windir%\Modules\7-Zip.exe" /S
Reg.exe add "HKCU\Software\7-Zip\Options" /v "ContextMenu" /t REG_DWORD /d "2147488038" /f > NUL 2>&1
Reg.exe add "HKCU\Software\7-Zip\Options" /v "ElimDupExtract" /t REG_DWORD /d "0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.001" /ve /t REG_SZ /d "7-Zip.001" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.7z" /ve /t REG_SZ /d "7-Zip.7z" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.arj" /ve /t REG_SZ /d "7-Zip.arj" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.bz2" /ve /t REG_SZ /d "7-Zip.bz2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.bzip2" /ve /t REG_SZ /d "7-Zip.bzip2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.cab" /ve /t REG_SZ /d "7-Zip.cab" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.cpio" /ve /t REG_SZ /d "7-Zip.cpio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.deb" /ve /t REG_SZ /d "7-Zip.deb" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.dmg" /ve /t REG_SZ /d "7-Zip.dmg" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.fat" /ve /t REG_SZ /d "7-Zip.fat" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.gz" /ve /t REG_SZ /d "7-Zip.gz" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.gzip" /ve /t REG_SZ /d "7-Zip.gzip" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.hfs" /ve /t REG_SZ /d "7-Zip.hfs" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.iso" /ve /t REG_SZ /d "7-Zip.iso" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.lha" /ve /t REG_SZ /d "7-Zip.lha" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.lzh" /ve /t REG_SZ /d "7-Zip.lzh" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.lzma" /ve /t REG_SZ /d "7-Zip.lzma" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.ntfs" /ve /t REG_SZ /d "7-Zip.ntfs" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.rar" /ve /t REG_SZ /d "7-Zip.rar" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.rpm" /ve /t REG_SZ /d "7-Zip.rpm" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.squashfs" /ve /t REG_SZ /d "7-Zip.squashfs" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.swm" /ve /t REG_SZ /d "7-Zip.swm" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.tar" /ve /t REG_SZ /d "7-Zip.tar" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.taz" /ve /t REG_SZ /d "7-Zip.taz" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.tbz" /ve /t REG_SZ /d "7-Zip.tbz" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.tbz2" /ve /t REG_SZ /d "7-Zip.tbz2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.tgz" /ve /t REG_SZ /d "7-Zip.tgz" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.tpz" /ve /t REG_SZ /d "7-Zip.tpz" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.txz" /ve /t REG_SZ /d "7-Zip.txz" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.vhd" /ve /t REG_SZ /d "7-Zip.vhd" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.wim" /ve /t REG_SZ /d "7-Zip.wim" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.xar" /ve /t REG_SZ /d "7-Zip.xar" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.xz" /ve /t REG_SZ /d "7-Zip.xz" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.z" /ve /t REG_SZ /d "7-Zip.z" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\.zip" /ve /t REG_SZ /d "7-Zip.zip" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.001" /ve /t REG_SZ /d "001 Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.001\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,9" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.001\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.001\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.001\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.7z" /ve /t REG_SZ /d "7z Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.7z\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.7z\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.7z\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.7z\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.arj" /ve /t REG_SZ /d "arj Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.arj\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,4" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.arj\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.arj\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.arj\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.bz2" /ve /t REG_SZ /d "bz2 Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.bz2\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.bz2\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.bz2\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.bz2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.bzip2" /ve /t REG_SZ /d "bzip2 Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.bzip2\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.bzip2\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.bzip2\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.bzip2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.cab" /ve /t REG_SZ /d "cab Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.cab\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,7" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.cab\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.cab\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.cab\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.cpio" /ve /t REG_SZ /d "cpio Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.cpio\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,12" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.cpio\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.cpio\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.cpio\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.deb" /ve /t REG_SZ /d "deb Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.deb\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,11" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.deb\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.deb\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.deb\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.dmg" /ve /t REG_SZ /d "dmg Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.dmg\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,17" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.dmg\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.dmg\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.dmg\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.fat" /ve /t REG_SZ /d "fat Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.fat\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,21" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.fat\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.fat\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.fat\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.gz" /ve /t REG_SZ /d "gz Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.gz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.gz\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.gz\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.gz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.gzip" /ve /t REG_SZ /d "gzip Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.gzip\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.gzip\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.gzip\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.gzip\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.hfs" /ve /t REG_SZ /d "hfs Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.hfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,18" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.hfs\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.hfs\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.hfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.iso" /ve /t REG_SZ /d "iso Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.iso\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,8" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.iso\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.iso\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.iso\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lha" /ve /t REG_SZ /d "lha Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lha\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,6" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lha\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lha\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lha\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lzh" /ve /t REG_SZ /d "lzh Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lzh\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,6" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lzh\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lzh\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lzh\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lzma" /ve /t REG_SZ /d "lzma Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lzma\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,16" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lzma\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lzma\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.lzma\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.ntfs" /ve /t REG_SZ /d "ntfs Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.ntfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,22" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.ntfs\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.ntfs\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.ntfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.rar" /ve /t REG_SZ /d "rar Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.rar\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,3" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.rar\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.rar\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.rar\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.rpm" /ve /t REG_SZ /d "rpm Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.rpm\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,10" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.rpm\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.rpm\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.rpm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.squashfs" /ve /t REG_SZ /d "squashfs Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.squashfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,24" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.squashfs\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.squashfs\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.squashfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.swm" /ve /t REG_SZ /d "swm Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.swm\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,15" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.swm\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.swm\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.swm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tar" /ve /t REG_SZ /d "tar Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tar\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,13" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tar\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tar\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tar\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.taz" /ve /t REG_SZ /d "taz Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.taz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,5" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.taz\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.taz\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.taz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tbz" /ve /t REG_SZ /d "tbz Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tbz2" /ve /t REG_SZ /d "tbz2 Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tbz2\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tbz2\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tbz2\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tbz2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tbz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tbz\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tbz\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tbz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tgz" /ve /t REG_SZ /d "tgz Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tgz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tgz\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tgz\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tgz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tpz" /ve /t REG_SZ /d "tpz Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tpz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tpz\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tpz\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.tpz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.txz" /ve /t REG_SZ /d "txz Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.txz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,23" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.txz\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.txz\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.txz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.vhd" /ve /t REG_SZ /d "vhd Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.vhd\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,20" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.vhd\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.vhd\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.vhd\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.wim" /ve /t REG_SZ /d "wim Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.wim\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,15" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.wim\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.wim\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.wim\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.xar" /ve /t REG_SZ /d "xar Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.xar\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,19" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.xar\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.xar\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.xar\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.xz" /ve /t REG_SZ /d "xz Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.xz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,23" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.xz\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.xz\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.xz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.z" /ve /t REG_SZ /d "z Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.z\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,5" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.z\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.z\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.z\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.zip" /ve /t REG_SZ /d "zip Archive" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.zip\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,1" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.zip\shell" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.zip\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\7-Zip.zip\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f > NUL 2>&1
del /f /q "%windir%\Modules\7-Zip.exe" > NUL 2>&1

:: INSTALL MPC MEDIA PLAYER AND APPLY SETTINGS
echo.
cls & echo Downloading MPC media player...
echo.
curl -L "https://github.com/mpc-hc/mpc-hc/releases/download/1.7.13/MPC-HC.1.7.13.x64.exe" -o "%temp%\MPC.exe" --progress-bar
cls & echo Installing MPC media player and applying settings...
"%temp%\MPC.exe" /VERYSILENT /NORESTART
Reg.exe add "HKLM\Software\Classes\MediaPlayerClassic.Autorun\Shell\PlayCDAudio\Command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" %%1 /cd" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\MediaPlayerClassic.Autorun\Shell\PlayDVDMovie\Command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" %%1 /dvd" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\MediaPlayerClassic.Autorun\Shell\PlayMusicFiles\Command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" %%1" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\MediaPlayerClassic.Autorun\Shell\PlayVideoFiles\Command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" %%1" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3g2" /ve /t REG_SZ /d "3G2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3g2\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3g2\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3g2\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3g2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3ga" /ve /t REG_SZ /d "3GP" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3ga\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3ga\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3ga\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3ga\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gp" /ve /t REG_SZ /d "3GP" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gp2" /ve /t REG_SZ /d "3G2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gp2\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gp2\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gp2\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gp2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gp\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gp\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gp\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gp\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gpp" /ve /t REG_SZ /d "3GP" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gpp\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gpp\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gpp\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.3gpp\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aac" /ve /t REG_SZ /d "MPEG-4 Audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aac\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aac\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aac\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aac\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ac3" /ve /t REG_SZ /d "AC-3" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ac3\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ac3\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ac3\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ac3\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aif" /ve /t REG_SZ /d "AIFF" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aif\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aif\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aif\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aif\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aifc" /ve /t REG_SZ /d "AIFF" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aifc\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aifc\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aifc\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aifc\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aiff" /ve /t REG_SZ /d "AIFF" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aiff\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aiff\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aiff\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aiff\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.alac" /ve /t REG_SZ /d "Apple Lossless" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.alac\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.alac\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.alac\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.alac\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.amr" /ve /t REG_SZ /d "AMR" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.amr\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.amr\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.amr\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.amr\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.amv" /ve /t REG_SZ /d "Other" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.amv\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.amv\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.amv\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.amv\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aob" /ve /t REG_SZ /d "Other Audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aob\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aob\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aob\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.aob\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ape" /ve /t REG_SZ /d "Monkey's Audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ape\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ape\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ape\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ape\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.apl" /ve /t REG_SZ /d "Monkey's Audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.apl\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.apl\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.apl\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.apl\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.asf" /ve /t REG_SZ /d "Windows Media Video" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.asf\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.asf\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.asf\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.asf\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.asx" /ve /t REG_SZ /d "Playlist" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.asx\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.asx\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.asx\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.asx\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.au" /ve /t REG_SZ /d "AU/SND" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.au\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.au\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.au\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.au\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.avi" /ve /t REG_SZ /d "AVI" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.avi\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.avi\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.avi\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.avi\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.bdmv" /ve /t REG_SZ /d "Blu-ray playlist" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.bdmv\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.bdmv\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.bdmv\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.bdmv\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.bik" /ve /t REG_SZ /d "Smacker/Bink Video" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.bik\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.bik\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.bik\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.bik\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.cda" /ve /t REG_SZ /d "Audio CD track" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.cda\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.cda\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.cda\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.cda\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.divx" /ve /t REG_SZ /d "Other" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.divx\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.divx\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.divx\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.divx\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsa" /ve /t REG_SZ /d "DirectShow Media" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsa\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsa\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsa\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsa\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsm" /ve /t REG_SZ /d "DirectShow Media" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsm\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsm\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsm\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dss" /ve /t REG_SZ /d "DirectShow Media" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dss\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dss\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dss\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dss\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsv" /ve /t REG_SZ /d "DirectShow Media" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsv\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsv\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsv\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dsv\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dts" /ve /t REG_SZ /d "DTS/DTS-HD" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dts\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dts\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dts\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dts\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dtshd" /ve /t REG_SZ /d "DTS/DTS-HD" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dtshd\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dtshd\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dtshd\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dtshd\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dtsma" /ve /t REG_SZ /d "DTS/DTS-HD" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dtsma\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dtsma\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dtsma\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.dtsma\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.evo" /ve /t REG_SZ /d "MPEG" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.evo\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.evo\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.evo\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.evo\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.f4v" /ve /t REG_SZ /d "Flash Video" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.f4v\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.f4v\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.f4v\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.f4v\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flac" /ve /t REG_SZ /d "FLAC" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flac\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flac\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flac\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flac\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flc" /ve /t REG_SZ /d "FLIC Animation" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flc\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flc\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flc\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flc\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.fli" /ve /t REG_SZ /d "FLIC Animation" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.fli\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.fli\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.fli\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.fli\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flic" /ve /t REG_SZ /d "FLIC Animation" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flic\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flic\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flic\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flic\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flv" /ve /t REG_SZ /d "Flash Video" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flv\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flv\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flv\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.flv\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.hdmov" /ve /t REG_SZ /d "MP4" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.hdmov\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.hdmov\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.hdmov\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.hdmov\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ifo" /ve /t REG_SZ /d "DVD-Video" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ifo\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ifo\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ifo\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ifo\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ivf" /ve /t REG_SZ /d "Indeo Video Format" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ivf\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ivf\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ivf\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ivf\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m1a" /ve /t REG_SZ /d "MPEG audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m1a\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m1a\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m1a\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m1a\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m1v" /ve /t REG_SZ /d "MPEG" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m1v\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m1v\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m1v\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m1v\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2a" /ve /t REG_SZ /d "MPEG audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2a\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2a\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2a\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2a\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2p" /ve /t REG_SZ /d "MPEG" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2p\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2p\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2p\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2p\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2t" /ve /t REG_SZ /d "MPEG-TS" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2t\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2t\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2t\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2t\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2ts" /ve /t REG_SZ /d "MPEG-TS" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2ts\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2ts\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2ts\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2ts\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2v" /ve /t REG_SZ /d "MPEG" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2v\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2v\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2v\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m2v\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m3u" /ve /t REG_SZ /d "Playlist" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m3u8" /ve /t REG_SZ /d "Playlist" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m3u8\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m3u8\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m3u8\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m3u8\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m3u\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m3u\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m3u\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m3u\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4a" /ve /t REG_SZ /d "MPEG-4 Audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4a\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4a\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4a\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4a\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4b" /ve /t REG_SZ /d "MPEG-4 Audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4b\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4b\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4b\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4b\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4r" /ve /t REG_SZ /d "MPEG-4 Audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4r\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4r\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4r\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4r\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4v" /ve /t REG_SZ /d "MP4" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4v\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4v\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4v\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.m4v\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mid" /ve /t REG_SZ /d "MIDI" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mid\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mid\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mid\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mid\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.midi" /ve /t REG_SZ /d "MIDI" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.midi\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.midi\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.midi\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.midi\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mk3d" /ve /t REG_SZ /d "Matroska" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mk3d\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mk3d\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mk3d\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mk3d\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mka" /ve /t REG_SZ /d "Matroska audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mka\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mka\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mka\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mka\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mkv" /ve /t REG_SZ /d "Matroska" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mkv\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mkv\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mkv\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mkv\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mlp" /ve /t REG_SZ /d "Other Audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mlp\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mlp\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mlp\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mlp\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mov" /ve /t REG_SZ /d "QuickTime Movie" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mov\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mov\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mov\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mov\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp2" /ve /t REG_SZ /d "MPEG audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp2\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp2\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp2\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp2v" /ve /t REG_SZ /d "MPEG" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp2v\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp2v\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp2v\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp2v\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp3" /ve /t REG_SZ /d "MP3" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp3\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp3\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp3\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp3\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp4" /ve /t REG_SZ /d "MP4" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp4\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp4\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp4\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp4\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp4v" /ve /t REG_SZ /d "MP4" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp4v\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp4v\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp4v\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mp4v\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpa" /ve /t REG_SZ /d "MPEG audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpa\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpa\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpa\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpa\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpc" /ve /t REG_SZ /d "Musepack" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpc\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpc\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpc\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpc\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpcpl" /ve /t REG_SZ /d "Playlist" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpcpl\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpcpl\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpcpl\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpcpl\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpe" /ve /t REG_SZ /d "MPEG" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpe\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpe\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpe\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpe\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpeg" /ve /t REG_SZ /d "MPEG" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpeg\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpeg\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpeg\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpeg\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpg" /ve /t REG_SZ /d "MPEG" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpg\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpg\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpg\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpg\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpls" /ve /t REG_SZ /d "Blu-ray playlist" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpls\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpls\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpls\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpls\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpv2" /ve /t REG_SZ /d "MPEG" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpv2\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpv2\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpv2\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpv2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpv4" /ve /t REG_SZ /d "MP4" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpv4\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpv4\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpv4\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mpv4\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mts" /ve /t REG_SZ /d "MPEG-TS" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mts\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mts\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mts\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.mts\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ofr" /ve /t REG_SZ /d "OptimFROG" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ofr\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ofr\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ofr\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ofr\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ofs" /ve /t REG_SZ /d "OptimFROG" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ofs\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ofs\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ofs\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ofs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.oga" /ve /t REG_SZ /d "Ogg Vorbis" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.oga\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.oga\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.oga\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.oga\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogg" /ve /t REG_SZ /d "Ogg Vorbis" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogg\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogg\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogg\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogg\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogm" /ve /t REG_SZ /d "Ogg Media" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogm\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogm\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogm\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogv" /ve /t REG_SZ /d "Ogg Media" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogv\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogv\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogv\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ogv\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.opus" /ve /t REG_SZ /d "Opus Audio Codec" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.opus\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.opus\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.opus\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.opus\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.pls" /ve /t REG_SZ /d "Playlist" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.pls\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.pls\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.pls\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.pls\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.pva" /ve /t REG_SZ /d "MPEG" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.pva\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.pva\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.pva\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.pva\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ra" /ve /t REG_SZ /d "Real Audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ra\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ra\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ra\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ra\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ram" /ve /t REG_SZ /d "Real Script" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ram\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ram\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ram\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ram\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rec" /ve /t REG_SZ /d "MPEG-TS" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rec\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rec\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rec\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rec\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rm" /ve /t REG_SZ /d "Real Media" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rm\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rm\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rm\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmi" /ve /t REG_SZ /d "MIDI" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmi\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmi\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmi\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmi\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmm" /ve /t REG_SZ /d "Real Script" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmm\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmm\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmm\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmvb" /ve /t REG_SZ /d "Real Media" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmvb\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmvb\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmvb\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rmvb\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rp" /ve /t REG_SZ /d "Real Script" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rp\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rp\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rp\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rp\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rpm" /ve /t REG_SZ /d "Real Script" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rpm\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rpm\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rpm\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rpm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rt" /ve /t REG_SZ /d "Real Script" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rt\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rt\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rt\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.rt\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smi" /ve /t REG_SZ /d "Real Script" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smi\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smi\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smi\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smi\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smil" /ve /t REG_SZ /d "Real Script" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smil\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smil\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smil\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smil\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smk" /ve /t REG_SZ /d "Smacker/Bink Video" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smk\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smk\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smk\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.smk\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.snd" /ve /t REG_SZ /d "AU/SND" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.snd\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.snd\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.snd\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.snd\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ssif" /ve /t REG_SZ /d "MPEG-TS" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ssif\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ssif\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ssif\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ssif\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.swf" /ve /t REG_SZ /d "Shockwave Flash" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.swf\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.swf\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.swf\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.swf\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tak" /ve /t REG_SZ /d "TAK" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tak\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tak\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tak\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tak\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.thd" /ve /t REG_SZ /d "Other Audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.thd\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.thd\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.thd\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.thd\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tp" /ve /t REG_SZ /d "MPEG-TS" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tp\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tp\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tp\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tp\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.trp" /ve /t REG_SZ /d "MPEG-TS" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.trp\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.trp\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.trp\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.trp\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ts" /ve /t REG_SZ /d "MPEG-TS" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ts\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ts\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ts\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.ts\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tta" /ve /t REG_SZ /d "True Audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tta\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tta\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tta\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.tta\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.vob" /ve /t REG_SZ /d "DVD-Video" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.vob\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.vob\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.vob\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.vob\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wav" /ve /t REG_SZ /d "WAV" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wav\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wav\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wav\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wav\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wax" /ve /t REG_SZ /d "Playlist" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wax\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wax\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wax\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wax\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.webm" /ve /t REG_SZ /d "WebM" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.webm\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.webm\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.webm\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.webm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wm" /ve /t REG_SZ /d "Windows Media Video" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wm\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wm\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wm\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wma" /ve /t REG_SZ /d "Windows Media Audio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wma\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wma\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wma\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wma\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmp" /ve /t REG_SZ /d "Windows Media Video" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmp\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmp\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmp\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmp\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmv" /ve /t REG_SZ /d "Windows Media Video" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmv\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmv\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmv\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmv\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmx" /ve /t REG_SZ /d "Playlist" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmx\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmx\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmx\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wmx\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wv" /ve /t REG_SZ /d "WavPack" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wv\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wv\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wv\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wv\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wvx" /ve /t REG_SZ /d "Playlist" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wvx\DefaultIcon" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\",0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wvx\shell\open" /v "Icon" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wvx\shell\open" /ve /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Classes\mplayerc64.wvx\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\MPC-HC\mpc-hc64.exe\" \"%%1\"" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mpe" /t REG_SZ /d "mplayerc64.mpe" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m1v" /t REG_SZ /d "mplayerc64.m1v" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m2v" /t REG_SZ /d "mplayerc64.m2v" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mpv2" /t REG_SZ /d "mplayerc64.mpv2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mp2v" /t REG_SZ /d "mplayerc64.mp2v" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".pva" /t REG_SZ /d "mplayerc64.pva" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".evo" /t REG_SZ /d "mplayerc64.evo" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m2p" /t REG_SZ /d "mplayerc64.m2p" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ts" /t REG_SZ /d "mplayerc64.ts" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".tp" /t REG_SZ /d "mplayerc64.tp" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".trp" /t REG_SZ /d "mplayerc64.trp" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m2t" /t REG_SZ /d "mplayerc64.m2t" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m2ts" /t REG_SZ /d "mplayerc64.m2ts" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mts" /t REG_SZ /d "mplayerc64.mts" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".rec" /t REG_SZ /d "mplayerc64.rec" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ssif" /t REG_SZ /d "mplayerc64.ssif" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".vob" /t REG_SZ /d "mplayerc64.vob" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ifo" /t REG_SZ /d "mplayerc64.ifo" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mkv" /t REG_SZ /d "mplayerc64.mkv" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mk3d" /t REG_SZ /d "mplayerc64.mk3d" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".webm" /t REG_SZ /d "mplayerc64.webm" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mp4" /t REG_SZ /d "mplayerc64.mp4" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m4v" /t REG_SZ /d "mplayerc64.m4v" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mp4v" /t REG_SZ /d "mplayerc64.mp4v" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mpv4" /t REG_SZ /d "mplayerc64.mpv4" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".hdmov" /t REG_SZ /d "mplayerc64.hdmov" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mov" /t REG_SZ /d "mplayerc64.mov" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".3gp" /t REG_SZ /d "mplayerc64.3gp" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".3gpp" /t REG_SZ /d "mplayerc64.3gpp" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".3ga" /t REG_SZ /d "mplayerc64.3ga" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".3g2" /t REG_SZ /d "mplayerc64.3g2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".3gp2" /t REG_SZ /d "mplayerc64.3gp2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".flv" /t REG_SZ /d "mplayerc64.flv" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".f4v" /t REG_SZ /d "mplayerc64.f4v" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ogm" /t REG_SZ /d "mplayerc64.ogm" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ogv" /t REG_SZ /d "mplayerc64.ogv" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".rm" /t REG_SZ /d "mplayerc64.rm" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".rmvb" /t REG_SZ /d "mplayerc64.rmvb" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".rt" /t REG_SZ /d "mplayerc64.rt" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ram" /t REG_SZ /d "mplayerc64.ram" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".rpm" /t REG_SZ /d "mplayerc64.rpm" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".rmm" /t REG_SZ /d "mplayerc64.rmm" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".rp" /t REG_SZ /d "mplayerc64.rp" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".smi" /t REG_SZ /d "mplayerc64.smi" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".smil" /t REG_SZ /d "mplayerc64.smil" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".wmv" /t REG_SZ /d "mplayerc64.wmv" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".wmp" /t REG_SZ /d "mplayerc64.wmp" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".wm" /t REG_SZ /d "mplayerc64.wm" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".asf" /t REG_SZ /d "mplayerc64.asf" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".smk" /t REG_SZ /d "mplayerc64.smk" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".bik" /t REG_SZ /d "mplayerc64.bik" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".fli" /t REG_SZ /d "mplayerc64.fli" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".flc" /t REG_SZ /d "mplayerc64.flc" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".flic" /t REG_SZ /d "mplayerc64.flic" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".dsm" /t REG_SZ /d "mplayerc64.dsm" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".dsv" /t REG_SZ /d "mplayerc64.dsv" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mpeg" /t REG_SZ /d "mplayerc64.mpeg" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".dss" /t REG_SZ /d "mplayerc64.dss" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ivf" /t REG_SZ /d "mplayerc64.ivf" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".swf" /t REG_SZ /d "mplayerc64.swf" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".divx" /t REG_SZ /d "mplayerc64.divx" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".amv" /t REG_SZ /d "mplayerc64.amv" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ac3" /t REG_SZ /d "mplayerc64.ac3" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".dts" /t REG_SZ /d "mplayerc64.dts" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".dtshd" /t REG_SZ /d "mplayerc64.dtshd" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".dtsma" /t REG_SZ /d "mplayerc64.dtsma" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".aif" /t REG_SZ /d "mplayerc64.aif" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".aifc" /t REG_SZ /d "mplayerc64.aifc" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".aiff" /t REG_SZ /d "mplayerc64.aiff" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mpg" /t REG_SZ /d "mplayerc64.mpg" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".amr" /t REG_SZ /d "mplayerc64.amr" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ape" /t REG_SZ /d "mplayerc64.ape" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".apl" /t REG_SZ /d "mplayerc64.apl" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".au" /t REG_SZ /d "mplayerc64.au" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".snd" /t REG_SZ /d "mplayerc64.snd" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".cda" /t REG_SZ /d "mplayerc64.cda" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".flac" /t REG_SZ /d "mplayerc64.flac" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m4a" /t REG_SZ /d "mplayerc64.m4a" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m4b" /t REG_SZ /d "mplayerc64.m4b" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m4r" /t REG_SZ /d "mplayerc64.m4r" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".aac" /t REG_SZ /d "mplayerc64.aac" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mid" /t REG_SZ /d "mplayerc64.mid" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".midi" /t REG_SZ /d "mplayerc64.midi" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".rmi" /t REG_SZ /d "mplayerc64.rmi" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mka" /t REG_SZ /d "mplayerc64.mka" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mp3" /t REG_SZ /d "mplayerc64.mp3" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mpa" /t REG_SZ /d "mplayerc64.mpa" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mp2" /t REG_SZ /d "mplayerc64.mp2" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m1a" /t REG_SZ /d "mplayerc64.m1a" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m2a" /t REG_SZ /d "mplayerc64.m2a" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mpc" /t REG_SZ /d "mplayerc64.mpc" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ofr" /t REG_SZ /d "mplayerc64.ofr" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ofs" /t REG_SZ /d "mplayerc64.ofs" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ogg" /t REG_SZ /d "mplayerc64.ogg" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".oga" /t REG_SZ /d "mplayerc64.oga" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".opus" /t REG_SZ /d "mplayerc64.opus" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".ra" /t REG_SZ /d "mplayerc64.ra" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".tak" /t REG_SZ /d "mplayerc64.tak" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".tta" /t REG_SZ /d "mplayerc64.tta" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".wav" /t REG_SZ /d "mplayerc64.wav" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".wma" /t REG_SZ /d "mplayerc64.wma" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".wv" /t REG_SZ /d "mplayerc64.wv" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".aob" /t REG_SZ /d "mplayerc64.aob" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mlp" /t REG_SZ /d "mplayerc64.mlp" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".thd" /t REG_SZ /d "mplayerc64.thd" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".asx" /t REG_SZ /d "mplayerc64.asx" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m3u" /t REG_SZ /d "mplayerc64.m3u" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".m3u8" /t REG_SZ /d "mplayerc64.m3u8" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".pls" /t REG_SZ /d "mplayerc64.pls" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".wvx" /t REG_SZ /d "mplayerc64.wvx" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".wax" /t REG_SZ /d "mplayerc64.wax" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".wmx" /t REG_SZ /d "mplayerc64.wmx" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mpcpl" /t REG_SZ /d "mplayerc64.mpcpl" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".mpls" /t REG_SZ /d "mplayerc64.mpls" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".bdmv" /t REG_SZ /d "mplayerc64.bdmv" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".avi" /t REG_SZ /d "mplayerc64.avi" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".dsa" /t REG_SZ /d "mplayerc64.dsa" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Clients\Media\Media Player Classic\Capabilities\FileAssociations" /v ".alac" /t REG_SZ /d "mplayerc64.alac" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlers\PlayCDAudioOnArrival" /v "MPCPlayCDAudioOnArrival" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlers\PlayDVDMovieOnArrival" /v "MPCPlayDVDMovieOnArrival" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlers\PlayMusicFilesOnArrival" /v "MPCPlayMusicFilesOnArrival" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlers\PlayVideoFilesOnArrival" /v "MPCPlayVideoFilesOnArrival" /t REG_SZ /d "" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayCDAudioOnArrival" /v "DefaultIcon" /t REG_SZ /d "C:\Program Files\MPC-HC\mpc-hc64.exe,0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayCDAudioOnArrival" /v "InvokeVerb" /t REG_SZ /d "PlayCDAudio" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayCDAudioOnArrival" /v "InvokeProgID" /t REG_SZ /d "MediaPlayerClassic.Autorun" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayCDAudioOnArrival" /v "Provider" /t REG_SZ /d "Media Player Classic" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayCDAudioOnArrival" /v "Action" /t REG_SZ /d "Play Audio CD" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayDVDMovieOnArrival" /v "InvokeVerb" /t REG_SZ /d "PlayDVDMovie" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayDVDMovieOnArrival" /v "DefaultIcon" /t REG_SZ /d "C:\Program Files\MPC-HC\mpc-hc64.exe,0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayDVDMovieOnArrival" /v "InvokeProgID" /t REG_SZ /d "MediaPlayerClassic.Autorun" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayDVDMovieOnArrival" /v "Provider" /t REG_SZ /d "Media Player Classic" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayDVDMovieOnArrival" /v "Action" /t REG_SZ /d "Play DVD Movie" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayMusicFilesOnArrival" /v "Provider" /t REG_SZ /d "Media Player Classic" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayMusicFilesOnArrival" /v "InvokeProgID" /t REG_SZ /d "MediaPlayerClassic.Autorun" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayMusicFilesOnArrival" /v "InvokeVerb" /t REG_SZ /d "PlayMusicFiles" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayMusicFilesOnArrival" /v "Action" /t REG_SZ /d "Play Music" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayMusicFilesOnArrival" /v "DefaultIcon" /t REG_SZ /d "C:\Program Files\MPC-HC\mpc-hc64.exe,0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayVideoFilesOnArrival" /v "DefaultIcon" /t REG_SZ /d "C:\Program Files\MPC-HC\mpc-hc64.exe,0" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayVideoFilesOnArrival" /v "Provider" /t REG_SZ /d "Media Player Classic" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayVideoFilesOnArrival" /v "Action" /t REG_SZ /d "Play Video" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayVideoFilesOnArrival" /v "InvokeVerb" /t REG_SZ /d "PlayVideoFiles" /f > NUL 2>&1
Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers\MPCPlayVideoFilesOnArrival" /v "InvokeProgID" /t REG_SZ /d "MediaPlayerClassic.Autorun" /f > NUL 2>&1
rd /s /q "C:\Program Files\MPC-HC\CrashReporter" > NUL 2>&1

:: BUILD SERVICES-DRIVERS ENABLED CORE SCRIPT
cls & echo Building services-drivers enable script...

echo REN "%windir%\System32\RuntimeBroker.old" "RuntimeBroker.exe" >> "%windir%\EVA\Services Enable.bat"
echo REN "%windir%\SystemApps\ShellExperienceHost_cw5n1h2txyewy\ShellExperienceHost.old" "ShellExperienceHost.exe" >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "LowerFilters" /t REG_MULTI_SZ /d "fvevol" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "UpperFilters" /t REG_MULTI_SZ /d "volsnap" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}" /v "UpperFilters" /t REG_MULTI_SZ /d "ksthunk" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{6bdd1fc6-810f-11d0-bec7-08002be2092f}" /v "UpperFilters" /t REG_MULTI_SZ /d "ksthunk" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{ca3e7ab9-b4c3-4ae6-8251-579ef933890f}" /v "UpperFilters" /t REG_MULTI_SZ /d "ksthunk" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AJRouter" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ALG" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AppIDSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Appinfo" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AppMgmt" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AppReadiness" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AppVClient" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AppXSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AssignedAccessManagerSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AudioEndpointBuilder" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Audiosrv" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AxInstSV" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BDESVC" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BFE" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BITS" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BrokerInfrastructure" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BTAGService" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BthAvctpSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\bthserv" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\camsvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CDPSvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CertPropSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ClipSVC" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\COMSysApp" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CoreMessagingRegistrar" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CryptSvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DcomLaunch" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\defragsvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DeviceAssociationService" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DeviceInstall" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DevQueryBroker" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Dhcp" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\diagnosticshub.standardcollector.service" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\diagsvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DmEnrollmentSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\dmwappushservice" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DoSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\dot3svc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DPS" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DsmSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Eaphost" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\EFS" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\embeddedmode" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\EntAppSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\EventLog" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\EventSystem" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\FontCache" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\FontCache3.0.0.0" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\FrameServer" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\gpsvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\GraphicsPerfSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\hidserv" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\HvHost" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\icssvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\IKEEXT" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\iphlpsvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\IpxlatCfgSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\KeyIso" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\KtmRm" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LicenseManager" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\lltdsvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\lmhosts" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LSM" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LxpSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mpssvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\MSDTC" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\MSiSCSI" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\msiserver" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NaturalAuthentication" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NcaSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NcdAutoSetup" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Netman" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\netprofm" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NetSetupSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NetTcpPortSharing" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NlaSvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\nsi" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\p2pimsvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\p2psvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PcaSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PeerDistSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PerfHost" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\pla" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PlugPlay" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PNRPAutoReg" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PNRPsvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PolicyAgent" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Power" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ProfSvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\QWAVE" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\RasMan" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\RemoteRegistry" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\RmSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\RpcEptMapper" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\RpcLocator" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\RpcSs" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SamSs" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SCardSvr" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ScDeviceEnum" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Schedule" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SCPolicySvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\seclogon" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SEMgrSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SENS" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SgrmBroker" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ShellHWDetection" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\shpamsvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SmsRouter" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SNMPTRAP" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\sppsvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SSDPSRV" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SstpSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\StateRepository" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\stisvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\svsvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\swprv" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SystemEventsBroker" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\TermService" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Themes" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\TimeBrokerSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\TokenBroker" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\TrkWks" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\TrustedInstaller" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\tzautoupdate" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\UevAgentService" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\upnphost" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\UserManager" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vds" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmicguestinterface" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmicheartbeat" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmickvpexchange" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmicrdv" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmicshutdown" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmictimesync" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmicvmsession" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmicvss" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\VSS" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WarpJITSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Wcmsvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\wcncsvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WdiServiceHost" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WdiSystemHost" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WebClient" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Wecsvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WEPHOSTSVC" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WFDSConMgrSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WiaRpc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Winmgmt" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WlanSvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\wlpasvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\wmiApSrv" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WPDBusEnum" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WSearch" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WwanSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\XboxGipSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BluetoothUserService" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CaptureService" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CDPUserSvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DevicePickerUserSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DevicesFlowUserSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\MessagingService" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WpnUserService" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AcpiDev" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\acpipagr" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AcpiPmi" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Acpitime" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\afunix" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ahcache" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Atapi" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\bam" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Beep" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\bindflt" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\bowser" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CAD" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\cdfs" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\cdrom" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CLFS" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CompositeBus" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\cnghwassist" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CmBatt" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\dam" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\dfsc" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\FileCrypt" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\FileInfo" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\fvevol" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\GpuEnergyDrv" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"

if %LAPTOP_KEYBOARD% equ TRUE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\i8042prt" /v "Start" /t REG_DWORD /d "3" /f > NUL 2>&1
	"%windir%\Modules\devmanview.exe" /enable "PCI standard ISA bridge"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\i8042prt" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
)
if %LAPTOP_KEYBOARD% equ FALSE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\i8042prt" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	"%windir%\Modules\devmanview.exe" /disable "PCI standard ISA bridge"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\i8042prt" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
)

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\iorate" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\KSecPkg" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ksthunk" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\lltdio" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\luafv" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Modem" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\MMCSS" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\MsLldp" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"

if %MSSMBIOS% EQU TRUE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mssmbios" /v "Start" /t REG_DWORD /d "1" /f > NUL 2>&1
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mssmbios" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Disable.bat"
	"%windir%\Modules\devmanview.exe" /enable "Microsoft System Management BIOS Driver" > NUL 2>&1
)

if %MSSMBIOS% EQU FALSE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mssmbios" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mssmbios" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
	"%windir%\Modules\devmanview.exe" /disable "Microsoft System Management BIOS Driver" > NUL 2>&1
)


echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mrxsmb" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Mrxsmb20" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"

if %LAPTOP_KEYBOARD% equ TRUE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\msisadrv" /v "Start" /t REG_DWORD /d "0" /f > NUL 2>&1
	"%windir%\Modules\devmanview.exe" /enable "PCI standard ISA bridge"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\msisadrv" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
)
if %LAPTOP_KEYBOARD% equ FALSE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\msisadrv" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	"%windir%\Modules\devmanview.exe" /disable "PCI standard ISA bridge"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\msisadrv" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
)

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NdisCap" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NdisVirtualBus" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Npsvctrig" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NetBIOS" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PEAUTH" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\pcw" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\QWAVEdrv" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\rdbss" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\rspndr" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\sermouse" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"

if %WEBCAM% equ TRUE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\swenum" /v "Start" /t REG_DWORD /d "3" /f > NUL 2>&1
	"%windir%\Modules\devmanview.exe" /enable "Plug and Play Software Device Enumerator"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\swenum" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
	Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Allow" /f > NUL 2>&1
	Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Allow" /f > NUL 2>&1
	Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam\NonPackaged" /v "Value" /t REG_SZ /d "Allow" /f > NUL 2>&1
)
if %WEBCAM% equ FALSE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\swenum" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	"%windir%\Modules\devmanview.exe" /disable "Plug and Play Software Device Enumerator"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\swenum" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
	Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Deny" /f > NUL 2>&1
	Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Deny" /f > NUL 2>&1
	Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam\NonPackaged" /v "Value" /t REG_SZ /d "Deny" /f > NUL 2>&1
)

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\srv2" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Srvnet" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SgrmAgent" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\storqosflt" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\tunnel" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\tdx" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\tcpipreg" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\udfs" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\UMBus" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\UEFI" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vwifibus" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vwififlt" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vdrvroot" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\VerifierExt" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Volmgrx" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\volsnap" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Wcifs" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Wcnfs" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WindowsTrustedRT" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WindowsTrustedRTProxy" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WmiAcpi" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ws2ifsl" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Enable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Wof" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Enable.bat"
echo shutdown /r /f /t 0 >> "%windir%\EVA\Services Enable.bat"

:: BUILD SERVICES-DRIVERS DISABLED TOGGLE SCRIPT
cls & echo Building services-drivers disable script...

echo REN "%windir%\System32\RuntimeBroker.exe" "RuntimeBroker.old" >> "%windir%\EVA\Services Disable.bat"
echo REN "%windir%\SystemApps\ShellExperienceHost_cw5n1h2txyewy\ShellExperienceHost.exe" "ShellExperienceHost.old" >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "LowerFilters" /t REG_MULTI_SZ /d "" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "UpperFilters" /t REG_MULTI_SZ /d "" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}" /v "UpperFilters" /t REG_MULTI_SZ /d "" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{6bdd1fc6-810f-11d0-bec7-08002be2092f}" /v "UpperFilters" /t REG_MULTI_SZ /d "" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{ca3e7ab9-b4c3-4ae6-8251-579ef933890f}" /v "UpperFilters" /t REG_MULTI_SZ /d "" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AJRouter" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ALG" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AppIDSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Appinfo" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AppMgmt" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AppReadiness" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AppVClient" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AppXSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AssignedAccessManagerSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AudioEndpointBuilder" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Audiosrv" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AxInstSV" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BDESVC" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BFE" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BITS" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BrokerInfrastructure" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BTAGService" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BthAvctpSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\bthserv" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\camsvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CDPSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CertPropSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ClipSVC" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\COMSysApp" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CoreMessagingRegistrar" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CryptSvc" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DcomLaunch" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\defragsvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DeviceAssociationService" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DeviceInstall" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DevQueryBroker" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

if %CONNECTION_TYPE% equ WIFI (
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Dhcp" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Dhcp" /v "DependOnService" /t REG_MULTI_SZ /d "Afd" /f > NUL 2>&1
)
if %CONNECTION_TYPE% equ ETHERNET echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Dhcp" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\diagnosticshub.standardcollector.service" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\diagsvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DmEnrollmentSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\dmwappushservice" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DoSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\dot3svc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DPS" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DsmSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Eaphost" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\EFS" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\embeddedmode" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\EntAppSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\EventLog" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\EventSystem" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\FontCache" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\FontCache3.0.0.0" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\FrameServer" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\gpsvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\GraphicsPerfSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\hidserv" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\HvHost" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\icssvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\IKEEXT" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\iphlpsvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\IpxlatCfgSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\KeyIso" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\KtmRm" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LicenseManager" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\lltdsvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\lmhosts" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LSM" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\LxpSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mpssvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\MSDTC" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\MSiSCSI" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\msiserver" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NaturalAuthentication" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NcaSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NcdAutoSetup" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Netman" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\netprofm" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NetSetupSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NetTcpPortSharing" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NlaSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

if "%CONNECTION_TYPE%" EQU "ETHERNET" set "ETHERNET=TRUE" & set "WIFI=FALSE"
if "%CONNECTION_TYPE%" EQU "WIFI" set "ETHERNET=FALSE" & set "WIFI=TRUE"

for %%i in (%NSI% %WIFI%) do (
	if %%i EQU TRUE echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\nsi" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat" & goto BREAK_1
)

:BREAK_1
if "%NSI%" EQU "FALSE" if "%WIFI%" EQU "FALSE" echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\nsi" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\p2pimsvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\p2psvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PcaSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PeerDistSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PerfHost" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\pla" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PlugPlay" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PNRPAutoReg" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PNRPsvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PolicyAgent" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

if %POWER_SERVICE% EQU TRUE echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Power" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
if %POWER_SERVICE% EQU FALSE echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Power" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ProfSvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\QWAVE" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\RasMan" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\RemoteRegistry" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\RmSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\RpcEptMapper" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\RpcLocator" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\RpcSs" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SamSs" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SCardSvr" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ScDeviceEnum" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Schedule" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SCPolicySvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\seclogon" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SEMgrSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

for %%a in (INTEL_NVIDIA INTEL_AMD INTEL) do (
	if %GRAPHICS% EQU %%a echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SENS" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat" & goto BREAK_2
)

for %%a in (NVIDIA AMD) do (
	if %GRAPHICS% EQU %%a echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SENS" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat" & goto BREAK_2
)

:BREAK_2
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SENS" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SgrmBroker" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ShellHWDetection" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\shpamsvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SmsRouter" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SNMPTRAP" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\sppsvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SSDPSRV" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SstpSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\StateRepository" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\stisvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\svsvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\swprv" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SystemEventsBroker" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\TermService" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Themes" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\TimeBrokerSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\TokenBroker" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\TrkWks" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\TrustedInstaller" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\tzautoupdate" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\UevAgentService" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\upnphost" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\UserManager" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vds" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmicguestinterface" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmicheartbeat" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmickvpexchange" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmicrdv" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmicshutdown" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmictimesync" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmicvmsession" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vmicvss" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\VSS" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WarpJITSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

if %CONNECTION_TYPE% EQU WIFI echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Wcmsvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
if %CONNECTION_TYPE% EQU ETHERNET echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Wcmsvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\wcncsvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WdiServiceHost" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WdiSystemHost" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WebClient" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Wecsvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WEPHOSTSVC" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WFDSConMgrSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WiaRpc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WinHttpAutoProxySvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Winmgmt" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Disable.bat"

if %CONNECTION_TYPE% EQU WIFI (
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WlanSvc" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WlanSvc" /v "DependOnService" /t REG_MULTI_SZ /d "NativeWifiP\0Wcmsvc" /f > NUL 2>&1
)
if %CONNECTION_TYPE% EQU ETHERNET echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WlanSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\wlpasvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\wmiApSrv" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WPDBusEnum" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WSearch" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WwanSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\XboxGipSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\BluetoothUserService" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CaptureService" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CDPUserSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DevicePickerUserSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\DevicesFlowUserSvc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\MessagingService" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WpnUserService" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AcpiDev" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\acpipagr" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AcpiPmi" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Acpitime" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\afunix" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ahcache" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Atapi" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\bam" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Beep" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\bindflt" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\bowser" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CAD" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\cdfs" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\cdrom" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CLFS" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CompositeBus" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\cnghwassist" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"


for /F "tokens=* skip=1" %%n in ('wmic systemenclosure get ChassisTypes ^| findstr "."') do set ChassisTypes=%%n
set ChassisTypes=%ChassisTypes:{=% 
set /a ChassisTypes=%ChassisTypes:}=%

if %ChassisTypes% LEQ 7 (
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CmBatt" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
)

if %ChassisTypes% GEQ 8 (
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\CmBatt" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Disable.bat"
)

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\dam" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\dfsc" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\FileCrypt" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\FileInfo" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\fvevol" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\GpuEnergyDrv" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

if %LAPTOP_KEYBOARD% equ TRUE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\i8042prt" /v "Start" /t REG_DWORD /d "3" /f > NUL 2>&1
	"%windir%\Modules\devmanview.exe" /enable "PCI standard ISA bridge"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\i8042prt" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Disable.bat"
)
if %LAPTOP_KEYBOARD% equ FALSE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\i8042prt" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	"%windir%\Modules\devmanview.exe" /disable "PCI standard ISA bridge"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\i8042prt" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
)

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\iorate" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\KSecPkg" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ksthunk" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\lltdio" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\luafv" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Modem" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

if %MMCSS_DRIVER% EQU TRUE echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\MMCSS" /v "Start" /t REG_DWORD /d "2" /f >> "%windir%\EVA\Services Disable.bat"
if %MMCSS_DRIVER% EQU FALSE echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\MMCSS" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\MsLldp" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

if %MSSMBIOS% EQU TRUE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mssmbios" /v "Start" /t REG_DWORD /d "1" /f > NUL 2>&1
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mssmbios" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Disable.bat"
	"%windir%\Modules\devmanview.exe" /enable "Microsoft System Management BIOS Driver" > NUL 2>&1
)

if %MSSMBIOS% EQU FALSE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mssmbios" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mssmbios" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
	"%windir%\Modules\devmanview.exe" /disable "Microsoft System Management BIOS Driver" > NUL 2>&1
)

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mrxsmb" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Mrxsmb20" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

if %LAPTOP_KEYBOARD% equ TRUE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\msisadrv" /v "Start" /t REG_DWORD /d "0" /f > NUL 2>&1
	"%windir%\Modules\devmanview.exe" /enable "PCI standard ISA bridge"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\msisadrv" /v "Start" /t REG_DWORD /d "0" /f >> "%windir%\EVA\Services Disable.bat"
)
if %LAPTOP_KEYBOARD% equ FALSE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\msisadrv" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	"%windir%\Modules\devmanview.exe" /disable "PCI standard ISA bridge"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\msisadrv" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
)

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NdisCap" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NdisVirtualBus" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Npsvctrig" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NetBIOS" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\PEAUTH" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\pcw" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\QWAVEdrv" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\rdbss" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\rspndr" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\sermouse" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

if %WEBCAM% equ TRUE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\swenum" /v "Start" /t REG_DWORD /d "3" /f > NUL 2>&1
	"%windir%\Modules\devmanview.exe" /enable "Plug and Play Software Device Enumerator"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\swenum" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Disable.bat"
	Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Allow" /f > NUL 2>&1
	Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Allow" /f > NUL 2>&1
	Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam\NonPackaged" /v "Value" /t REG_SZ /d "Allow" /f > NUL 2>&1
)
if %WEBCAM% equ FALSE (
	Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\swenum" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	"%windir%\Modules\devmanview.exe" /disable "Plug and Play Software Device Enumerator"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\swenum" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
	Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Deny" /f > NUL 2>&1
	Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" /v "Value" /t REG_SZ /d "Deny" /f > NUL 2>&1
	Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam\NonPackaged" /v "Value" /t REG_SZ /d "Deny" /f > NUL 2>&1
)

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\srv2" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Srvnet" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\SgrmAgent" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\storqosflt" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\tunnel" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\tdx" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\tcpipreg" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\udfs" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\UMBus" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\UEFI" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"

if %CONNECTION_TYPE% equ WIFI (
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vwifibus" /v "Start" /t REG_DWORD /d "3" /f >> "%windir%\EVA\Services Disable.bat"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vwififlt" /v "Start" /t REG_DWORD /d "1" /f >> "%windir%\EVA\Services Disable.bat"
)
if %CONNECTION_TYPE% equ ETHERNET (
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vwifibus" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
	echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vwififlt" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
)

echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\vdrvroot" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\VerifierExt" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Volmgrx" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\volsnap" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Wcifs" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Wcnfs" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WindowsTrustedRT" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WindowsTrustedRTProxy" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\WmiAcpi" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\ws2ifsl" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Wof" /v "Start" /t REG_DWORD /d "4" /f >> "%windir%\EVA\Services Disable.bat"
echo shutdown /r /f /t 0 >> "%windir%\EVA\Services Disable.bat"

:: INSTALL THE GPU DRIVER
:: SKIP IF INTEL IGPU ONLY BECAUSE THE IGPU SHOULD HAVE ALREADY BEEN INSTALLED AT BREAKPOINT

if %GRAPHICS% EQU AMD goto AMD
if %GRAPHICS% EQU NVIDIA goto NVIDIA
if %GRAPHICS% EQU INTEL goto DIRECTX
if %GRAPHICS% EQU INTEL_AMD goto AMD
if %GRAPHICS% EQU INTEL_NVIDIA goto NVIDIA

:AMD
cls
del /f /q "C:\POST INSTALL\7 NVIDIA Settings.bat" > NUL 2>&1
del /f /q "%windir%\Modules\Inspector.exe" > NUL 2>&1
del /f /q "%windir%\Modules\Basic.nip" > NUL 2>&1
cls
if %AMDDRIVER% EQU SKIP goto DIRECTX
echo Downloading %AMDDRIVER%
echo.
if %AMDDRIVER% EQU 20.4.2 (
	curl -L -H "Referer: https://www.amd.com/en/support/kb/release-notes/rn-rad-win-20-4-2" https://drivers.amd.com/drivers/win10-radeon-software-adrenalin-2020-edition-20.4.2-may25.exe -o "%temp%\%AMDDRIVER%.zip" --progress-bar
)
if %AMDDRIVER% EQU 20.8.3 (
	curl -L -H "Referer: https://www.amd.com/en/support/kb/release-notes/rn-rad-win-20-8-3" https://drivers.amd.com/drivers/beta/win10-radeon-software-adrenalin-2020-edition-20.8.3-sep8.exe -o "%temp%\%AMDDRIVER%.zip" --progress-bar
)
if %AMDDRIVER% EQU 21.10.2 (
	curl -L -H "Referer: https://www.amd.com/en/support/kb/release-notes/rn-rad-win-21-10-2" https://drivers.amd.com/drivers/radeon-software-adrenalin-2020-21.10.2-win10-win11-64bit-oct25.exe -o "%temp%\%AMDDRIVER%.zip" --progress-bar
)
cls
cls & echo Extracting driver...
7z.exe x -y -o"%temp%\%AMDDRIVER%" "%temp%\%AMDDRIVER%.zip" > NUL 2>&1
cls & echo Debloating driver...
rd /s /q "%temp%\%AMDDRIVER%\Packages\Drivers\Display\WT6A_INF\amdlog" > NUL 2>&1
rd /s /q "%temp%\%AMDDRIVER%\Packages\Drivers\Display\WT6A_INF\amdfendr" > NUL 2>&1
rd /s /q "%temp%\%AMDDRIVER%\Packages\Drivers\Display\WT6A_INF\amdxe" > NUL 2>&1
rd /s /q "%temp%\%AMDDRIVER%\Packages\Drivers\Display\WT6A_INF\amdafd" > NUL 2>&1
:: INSTALL DRIVER
cls & echo Installing %AMDDRIVER%... This may take a few minutes be patient.
echo.
pnputil /add-driver "%temp%\%AMDDRIVER%\Packages\Drivers\Display\WT6A_INF\*.inf" /install

if %RADEON_SOFTWARE% EQU TRUE (
	for /f %%a in ('dir /b "!temp!\!AMDDRIVER!\Packages\Drivers\Display\WT6A_INF\B3*"') do (
		if exist "!temp!\!AMDDRIVER!\Packages\Drivers\Display\WT6A_INF\%%a\ccc2_install.exe" (
			7z.exe x -y -o"!temp!\!AMDDRIVER!_RADEONPANEL" "!temp!\!AMDDRIVER!\Packages\Drivers\Display\WT6A_INF\%%a\ccc2_install.exe" > NUL 2>&1
			"!temp!\!AMDDRIVER!_RADEONPANEL\CN\cnext\cnext64\ccc-next64.msi" /quiet /norestart
		) ELSE (
			>> !log! echo.
			>> !log! echo !date! !time! - AMD Contol panel installation failed.
		)
	)
)

goto DIRECTX

:NVIDIA
cls
del /f /q "C:\POST INSTALL\6 AMD Settings.bat" > NUL 2>&1
if %NVIDIADRIVER% EQU SKIP goto DIRECTX
cls & echo Downloading %NVIDIADRIVER%
echo.
if "%NVIDIADRIVER%" EQU "419.35" (
	curl -L "https://us.download.nvidia.com/Windows/419.35/419.35-desktop-win10-64bit-international-whql-rp.exe" -o "%temp%\%NVIDIADRIVER%.zip" --progress-bar
)
if "%NVIDIADRIVER%" EQU "425.31" (
	curl -L "https://us.download.nvidia.com/Windows/425.31/425.31-desktop-win10-64bit-international-whql.exe" -o "%temp%\%NVIDIADRIVER%.zip" --progress-bar
)
if "%NVIDIADRIVER%" EQU "441.41" (
	curl -L "https://us.download.nvidia.com/Windows/441.41/441.41-desktop-win10-64bit-international-whql.exe" -o "%temp%\%NVIDIADRIVER%.zip" --progress-bar
)
if "%NVIDIADRIVER%" EQU "442.74" (
	curl -L "https://us.download.nvidia.com/Windows/442.74/442.74-desktop-win10-64bit-international-whql.exe" -o "%temp%\%NVIDIADRIVER%.zip" --progress-bar
)
if "%NVIDIADRIVER%" EQU "456.71" (
	curl -L "https://us.download.nvidia.com/Windows/456.71/456.71-desktop-win10-64bit-international-whql.exe" -o "%temp%\%NVIDIADRIVER%.zip" --progress-bar
)
if "%NVIDIADRIVER%" EQU "457.30" (
	curl -L "https://us.download.nvidia.com/Windows/457.30/457.30-desktop-win10-64bit-international-whql.exe" -o "%temp%\%NVIDIADRIVER%.zip" --progress-bar
)
if "%NVIDIADRIVER%" EQU "457.51" (
	curl -L "https://us.download.nvidia.com/Windows/457.51/457.51-desktop-win10-64bit-international-whql.exe" -o "%temp%\%NVIDIADRIVER%.zip" --progress-bar
)
if "%NVIDIADRIVER%" EQU "461.92" (
	curl -L "https://us.download.nvidia.com/Windows/461.92/461.92-desktop-win10-64bit-international-whql.exe" -o "%temp%\%NVIDIADRIVER%.zip" --progress-bar
)
if "%NVIDIADRIVER%" EQU "466.11" (
	curl -L "https://us.download.nvidia.com/Windows/466.11/466.11-desktop-win10-64bit-international-whql.exe" -o "%temp%\%NVIDIADRIVER%.zip" --progress-bar
)
if "%NVIDIADRIVER%" EQU "472.12" (
	curl -L "https://us.download.nvidia.com/Windows/472.12/472.12-desktop-win10-win11-64bit-international-whql.exe" -o "%temp%\%NVIDIADRIVER%.zip" --progress-bar
)
cls & echo Extracting driver...
7z.exe x -y -o"%temp%\%NVIDIADRIVER%" "%temp%\%NVIDIADRIVER%.zip" > NUL 2>&1
cls & echo Debloating driver...
for /f %%a in ('dir "%temp%\%NVIDIADRIVER%" /b') do (
	if "%%a" NEQ "Display.Driver" if "%%a" NEQ "NVI2" if "%%a" NEQ "EULA.txt" if "%%a" NEQ "ListDevices.txt" if "%%a" NEQ "setup.cfg" if "%%a" NEQ "setup.exe" (
		rd /s /q "%temp%\%NVIDIADRIVER%\%%a" > NUL 2>&1
		del /f /q "%temp%\%NVIDIADRIVER%\%%a" > NUL 2>&1
	)
)

"%windir%\Modules\strip_nvsetup.exe" "%temp%\%NVIDIADRIVER%\setup.cfg" "%temp%\%NVIDIADRIVER%\m_setup.cfg"
del /f /q "%temp%\%NVIDIADRIVER%\setup.cfg" > NUL 2>&1
REN "%temp%\%NVIDIADRIVER%\m_setup.cfg" "setup.cfg" > NUL 2>&1
cls & echo Installing %NVIDIADRIVER%...
"%temp%\%NVIDIADRIVER%\setup.exe" /s
cls
:: APPLY NVIDIA CONTROL PANEL SETTINGS
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
		for /f %%i in ('echo %%a ^| findstr "{"') do (
			%= VIDEO =%
				%= ADJUST VIDEO IMAGE SETTINGS =%
					%= EDGE ENHANCEMENT - USE THE NVIDIA SETTING =%
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Edge_Enhance" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					%= EDGE ENHANCEMENT 0 =%
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_VAL_Edge_Enhance" /t REG_DWORD /d "0" /f > NUL 2>&1
					%= NOISE REDUCTION - USE THE NVIDIA SETTING =%
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Noise_Reduce" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					%= NOISE REDUCTION - 0 =%
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_VAL_Noise_Reduce" /t REG_DWORD /d "0" /f > NUL 2>&1
					%= DEINTERLACING - DISABLE "USE INVERSE TELECINE" =%
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_XALG_Cadence" /t REG_BINARY /d "0000000000000000" /f > NUL 2>&1

				%= ADJUST VIDEO COLOR SETTINGS =%
					%= COLOR ADJUSTMENTS - WITH THE NVIDIA SETTINGS =%
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Contrast" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_RGB_Gamma_G" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_RGB_Gamma_R" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_RGB_Gamma_B" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Hue" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Saturation" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Brightness" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_XEN_Color_Range" /t REG_DWORD /d "2147483649" /f > NUL 2>&1
					%= DYNAMIC RANGE - FULL =%
					Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "_User_SUB0_DFP2_XALG_Color_Range" /t REG_BINARY /d "0000000000000000" /f > NUL 2>&1
					
				%= DISABLE HDCP =%
				Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "RMHdcpKeyglobZero" /t REG_DWORD /d 1 /f > NUL 2>&1
				%= DEVELOPER - MANAGE GPU PERFORMANCE COUNTERS - "ALLOW ACCESS TO THE GPU PERFORMANCE COUNTERS TO ALL USERS" =%
				Reg.exe add "HKLM\System\CurrentControlSet\Control\Class\%%i" /v "RmProfilingAdminOnly" /t REG_DWORD /d "0" /f > NUL 2>&1
				%= https://github.com/djdallmann/GamingPCSetup/tree/master/CONTENT/RESEARCH/WINDRIVERS#q-is-there-a-registry-setting-that-can-force-your-display-adapter-to-remain-at-its-highest-performance-state-pstate-p0 =%
				if %DISABLE_NVIDIA_PSTATES% EQU TRUE Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "DisableDynamicPstate" /t REG_DWORD /d "1" /f > NUL 2>&1
		)
	)
)
:: DESKTOP > ENABLE DEVELOPER SETTINGS 
Reg.exe add "HKLM\System\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "NvDevToolsVisible" /t REG_DWORD /d "1" /f > NUL 2>&1
:: ADJUST IMAGE SETTINGS WITH PREVIEW - "USE THE ADVANCED 3D IMAGE SETTINGS"
Reg.exe add "HKCU\Software\NVIDIA Corporation\Global\NVTweak" /v "Gestalt" /t REG_DWORD /d "513" /f > NUL 2>&1
:: CONFIGURE SURROUND, PHYSX - PROCESSOR: GPU
Reg.exe add "HKLM\System\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "NvCplPhysxAuto" /t REG_DWORD /d "0" /f > NUL 2>&1
:: MANAGE 3D SETTINGS - UNHIDE SILK SMOOTHNESS OPTION
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS" /v "EnableRID61684" /t REG_DWORD /d "1" /f > NUL 2>&1
:: DEVELOPER - MANAGE GPU PERFORMANCE COUNTERS - "ALLOW ACCESS TO THE GPU PERFORMANCE COUNTERS TO ALL USERS"
Reg.exe add "HKLM\System\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "RmProfilingAdminOnly" /t REG_DWORD /d "0" /f > NUL 2>&1

:: ONLY DISABLE WRITE COMBINING IN SUPPORTED DRIVERS
for %%a in (419.35 425.31 441.41) do (
	if %NVIDIADRIVER% EQU %%a Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "DisableWriteCombining" /t REG_DWORD /d "1" /f > NUL 2>&1
)

for /f "delims=" %%a in ('reg query HKLM\System\CurrentControlSet\Services\nvlddmkm\State\DisplayDatabase') do (
	%= OVERRIDE THE SCALING MODE SET BY GAMES AND PROGRAMS =%
	PowerRun.exe /SW:0 Reg.exe add "%%a" /v "ScalingConfig" /t REG_BINARY /d "DB01000010000000800000006C010000" /f > NUL 2>&1
	%= DISPLAY - CHANGE RESOLUTION - "USE NVIDIA COLOR SETTINGS" =%
	PowerRun.exe /SW:0 Reg.exe add "%%a" /v "ColorformatConfig" /t REG_BINARY /d "DB02000014000000000A00080000000003010000" /f > NUL 2>&1
)
goto DIRECTX

:DIRECTX
:: INSTALL DIRECTX
cls & echo Downloading DirectX...
echo.
curl -L "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" -o "%windir%\Modules\DirectX.exe" --progress-bar
if not exist "%windir%\Modules\DirectX.exe" (
	>> %log% echo.
	>> %log% echo %date% %time% - Direct X download failed.
)
7z.exe x -y -o"%windir%\Modules\Direct X" "%windir%\Modules\DirectX.exe" > NUL 2>&1
cls & echo Installing DirectX...
"%windir%\Modules\Direct X\dxsetup.exe" /silent
del /f /q "%windir%\Modules\DirectX.exe" > NUL 2>&1
rd /s /q "%windir%\Modules\Direct X" > NUL 2>&1

:: INSTALL C++ PACKAGES
cls & echo Downloading C++ packages...
echo.
curl -L "https://github.com/abbodi1406/vcredist/releases/download/v0.54.0/VisualCppRedist_AIO_x86_x64_54.zip" -o "%windir%\Modules\VisualCppRedist_AIO_x86_x64.zip" --progress-bar
if not exist "%windir%\Modules\VisualCppRedist_AIO_x86_x64.zip" (
	>> %log% echo.
	>> %log% echo %date% %time% - C++ packages download failed.
)
7z.exe x -y -o"%windir%\Modules" "%windir%\Modules\VisualCppRedist_AIO_x86_x64.zip" > NUL 2>&1
cls & echo Installing C++ packages...
"%windir%\Modules\VisualCppRedist_AIO_x86_x64" /ai /gm2
del /f /q "%windir%\Modules\VisualCppRedist_AIO_x86_x64.zip" > NUL 2>&1
del /f /q "%windir%\Modules\VisualCppRedist_AIO_x86_x64.exe" > NUL 2>&1

:: DISABLE NETWORK FEATURES IN THE ADAPTER PROPERTIES
cls & echo Disabling network features in the adapter properties...

powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_lldp
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_lltdio
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_implat
powershell Enable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_rspndr
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_server
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_msclient
powershell Enable-NetAdapterBinding -Name "*" -ComponentID ms_pacer

:: APPLY NETWORK TWEAKS
:: https://github.com/djdallmann/GamingPCSetup/blob/master/CONTENT/DOCS/NETWORK/README.md

:: DISABLE NET BIOS, THIS SETTING ONLY TAKES AFFECT WHILE SERVICES ARE ENABLED BECAUSE THE NETBIOS SERVICE IS DISABLED IN THE SERVICES DISABLE SCRIPT
c;s & echo Disabling netbios...
for %%a in (NetbiosOptions) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s /f "%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "%%a" /t REG_DWORD /d "2" /f > NUL 2>&1

:: CHANGE KEYS WITH AN "*"
cls & echo Applying network tweaks...

for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
        for /f %%i in ('echo %%a ^| findstr "{"') do (
			for %%a in (WakeOnMagicPacket WakeOnPattern FlowControl EEE) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /s /f "*%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "*%%a" /t REG_SZ /d "0" /f > NUL 2>&1
		)
    )
)

:: CHANGE KEYS WITHOUT AN "*"

for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
        for /f %%i in ('echo %%a ^| findstr "{"') do (
			for %%a in (EnablePME WakeOnLink EEELinkAdvertisement ReduceSpeedOnPowerDown PowerSavingMode EnableGreenEthernet S5WakeOnLan ULPMode GigaLite EnableSavePowerNow EnablePowerManagement EnableDynamicPowerGating EnableConnectedPowerGating AutoPowerSaveModeEnabled AutoDisableGigabit AdvancedEEE PowerDownPll S5NicKeepOverrideMacAddrV2) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /s /f "%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "%%a" /t REG_SZ /d "0" /f > NUL 2>&1
		)
    )
)

:: DISABLE JUMBOPACKET

for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
        for /f %%i in ('echo %%a ^| findstr "{"') do (
			for %%a in (JumboPacket) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /s /f "*%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "*%%a" /t REG_SZ /d "1514" /f > NUL 2>&1
		)
    )
)

:: SET RECEIVE/TRANSMIT BUFFERS IF CONDIITON APPLIES

if %SET_RECEIVE_TRANSMIT_BUFFERS% EQU TRUE (
	for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
		for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
			for /f %%i in ('echo %%a ^| findstr "{"') do (
				for %%a in (ReceiveBuffers TransmitBuffers) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /s /f "*%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "*%%a" /t REG_SZ /d "%RECEIVE_TRANSMIT_BUFFERS%" /f > NUL 2>&1
			)
		)
	)
)

:: ENABLE RSS IF SUPPORTED

for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
        for /f %%i in ('echo %%a ^| findstr "{"') do (
			for %%a in (RSS) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /s /f "*%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "*%%a" /t REG_SZ /d "1" /f > NUL 2>&1
		)
    )
)

:: INTERRUPT MODERATION TO ADAPTIVE - SHOULD BE ADAPTIVE BY DEFAULT BUT HERE FOR COMPLETENESS

for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
        for /f %%i in ('echo %%a ^| findstr "{"') do (
			for %%a in (ITR) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /s /f "%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "%%a" /t REG_SZ /d "125" /f > NUL 2>&1
		)
    )
)

:: DISABLE WAKE FEATURES

for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
        for /f %%i in ('echo %%a ^| findstr "{"') do (
			for %%a in (WolShutdownLinkSpeed) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /s /f "%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "%%a" /t REG_SZ /d "2" /f > NUL 2>&1
		)
    )
)

:: DISABLE LARGE SEND OFFLOADS
cls & echo Disabling Large send offloads...
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
        for /f %%i in ('echo %%a ^| findstr "{"') do (
			for %%a in (LsoV2IPv4 LsoV2IPv6) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /s /f "*%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "*%%a" /t REG_SZ /d "0" /f > NUL 2>&1
		)
    )
)

:: DISABLE OFFLOADS IF CONDITION APPLIES

if %DISABLE_NIC_OFFLOADS% EQU TRUE (
	cls & echo Disabling NIC offloads...
	for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
		for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
			for /f %%i in ('echo %%a ^| findstr "{"') do (
				for %%a in (UDPChecksumOffloadIPv6 IPChecksumOffloadIPv4 UDPChecksumOffloadIPv4 PMARPOffload PMNSOffload TCPChecksumOffloadIPv4 TCPChecksumOffloadIPv6) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /s /f "*%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "*%%a" /t REG_SZ /d "0" /f > NUL 2>&1
			)
		)
	)
)

:: SOME NIC DRIVERS SET 4 RSS QUEUES BY DEFAULT REGARDLESS OF THE PROCESSOR COUNT
:: SET RSS QUEUES TO 2 IF THE USER DOES NOT HAVE A 8 CORE CPU. 4C OR 6C IS SIMPLY NOT ENOUGH TO HANDLE 4 RSS QUEUES

for /F "tokens=* skip=1" %%z in ('wmic cpu get NumberOfCores  ^| findstr "."') do set CPUCORES=%%z

if %CPUCORES% LEQ 8 (
	for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
		for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
			for /f %%i in ('echo %%a ^| findstr "{"') do ( 
				reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "*NumRssQueues" /t REG_SZ /d "2" /f > NUL 2>&1
			)
		)
	)
)

if %CUSTOM_NIC_AFFINITY% EQU TRUE (
	cls & echo Applying rssbaseprocessor/ndis.sys affinity...
	for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
		for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do (
			for /f %%i in ('echo %%a ^| findstr "{"') do ( 
				reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%i" /v "*RssBaseProcNumber" /t REG_SZ /d "%RSS_BASE_PROC%" /f > NUL 2>&1
			)
		)
	)
)

:: DISABLE NAGLES ALGORITHM
cls & echo Disabling Nagles Algorithm...

for /f %%i in ('wmic path win32_networkadapter get GUID ^| findstr "{"') do (
	Reg.exe add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f > NUL 2>&1
	Reg.exe add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f > NUL 2>&1
	Reg.exe add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "TCPNoDelay" /t REG_DWORD /d "1" /f > NUL 2>&1
)

:: DISABLE AUTOTUNING IF THE CONDITION APPLIES

if %DISABLE_AUTOTUNING% EQU TRUE netsh int tcp set global autotuninglevel=disabled
netsh int tcp set global rsc=disabled

:: ENABLE MSI MODE FOR DEVICES IF CONDITION APPLIES

if %SET_MSI_MODE_ALL_DEVICES% EQU TRUE (
	cls & echo Enabling MSI mode for devices...
	for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI"^| findstr "HKEY"') do (
		for /f "tokens=*" %%a in ('reg query "%%i"^| findstr "HKEY"') do reg.exe add "%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f > NUL 2>&1
	)
)

:: SET ALL DEVICE PRIORITY TO UNDEFINED IF CONDITION APPLIES

if %SET_MSI_PRIORITY_ALL_DEVICES% EQU TRUE (
	if "%MSIDEVICE_PRIORITY_ALL_DEVICES%" EQU "0" (
		cls & echo Setting all device's priority to undefined...
		for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI"^| findstr "HKEY"') do (
			for /f "tokens=*" %%a in ('reg query "%%i"^| findstr "HKEY"') do Reg.exe delete "%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f > NUL 2>&1
		)
	)
	if "%MSIDEVICE_PRIORITY_ALL_DEVICES%" EQU "1" (
		cls & echo Setting all device's priority to low...
		for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI"^| findstr "HKEY"') do (
			for /f "tokens=*" %%a in ('reg query "%%i"^| findstr "HKEY"') do Reg.exe add "%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "1" /f > NUL 2>&1
		)
	)
	if "%MSIDEVICE_PRIORITY_ALL_DEVICES%" EQU "2" (
		cls & echo Setting all device's priority to normal...
		for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI"^| findstr "HKEY"') do (
			for /f "tokens=*" %%a in ('reg query "%%i"^| findstr "HKEY"') do Reg.exe add "%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "2" /f > NUL 2>&1
		)
	)
	if "%MSIDEVICE_PRIORITY_ALL_DEVICES%" EQU "3" (
		cls & echo Setting all device's priority to high...
		for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI"^| findstr "HKEY"') do (
			for /f "tokens=*" %%a in ('reg query "%%i"^| findstr "HKEY"') do Reg.exe add "%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "3" /f > NUL 2>&1
		)
	)
)

:: CREDIT TO REVISION, EDITED BY AMIT

for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /format:value') do set /a RAM=%%i + 100000
reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%RAM%" /f > NUL 2>&1

:: BCDEDIT
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set
cls & echo Applying BCDEDIT modifications...

:: Forces the use of the platform clock as the system's performance counter.
bcdedit /deletevalue useplatformclock > NUL 2>&1
:: Enables and disables dynamic timer tick feature.
bcdedit /set disabledynamictick yes > NUL 2>&1
:: Forces the clock to be backed by a platform source, no synthetic timers are allowed.
bcdedit /set useplatformtick yes > NUL 2>&1
:: The BCDEdit /timeout command sets the time to wait, in seconds, before the boot manager selects a default entry.
bcdedit /timeout %BCDEDIT_TIMEOUT% > NUL 2>&1

:: DISABLE OR ENABLE NX/DEP
if %NX% equ TRUE bcdedit /set nx OptIn > NUL 2>&1
if %NX% equ FALSE bcdedit /set nx AlwaysOff > NUL 2>&1

:: Disables boot graphics.
bcdedit /set bootux disabled > NUL 2>&1
:: Defines the type of boot menu the system will use.
:: The default is already standard, here for completeness.
bcdedit /set bootmenupolicy standard > NUL 2>&1
:: Disable Hyper-V
bcdedit /set hypervisorlaunchtype off > NUL 2>&1
:: Disable TPM. TPM is stripped in the os but i don't trust NTLite so i'm disabling it via bcdedit anyway
bcdedit /set tpmbootentropy ForceDisable > NUL 2>&1
:: Controls the display of a high-resolution bitmap in place of the Windows boot screen display and animation.
bcdedit /set quietboot yes > NUL 2>&1
:: DISABLE THE BOOT LOGO
bcdedit /set {globalsettings} custom:16000067 true > NUL 2>&1
:: DISABLE THE SPINNING ANIMATION IN THE BOOT SCREEN
bcdedit /set {globalsettings} custom:16000069 true > NUL 2>&1
:: DISABLE BOOT MESSAGES
bcdedit /set {globalsettings} custom:16000068 true > NUL 2>&1
:: DISABLE AUTOMATIC REPAIR, BETTER TO DEBUG/CHECK MANUALLY
bcdedit /set {current} recoveryenabled no > NUL 2>&1

:: SPLIT AUDIO SERVICES TO PREVENT AUDIO DROPOUTS WHEN SVCHOST.EXE IS SET TO LOW PRIORITY/IO PRIORITY IF CONDITION APPLIES
:: SET PROCESS PRIORITY TO LOW FOR PROCESSES THAT USE CYCLES WHILE SERVICES ARE DISABLED IF CONDITION APPLIES

if %SET_PROCESS_PRIORITY% EQU TRUE (
	cls & echo Splitting audio services...
	copy /y "%windir%\System32\svchost.exe" "%windir%\System32\audiosvchost.exe" > NUL 2>&1
	reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\Audiosrv" /v "ImagePath" /t REG_EXPAND_SZ /d "%SystemRoot%\System32\audiosvchost.exe -k LocalServiceNetworkRestricted -p" /f > NUL 2>&1
	reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\AudioEndpointBuilder" /v "ImagePath" /t REG_EXPAND_SZ /d "%SystemRoot%\System32\audiosvchost.exe -k LocalSystemNetworkRestricted -p" /f > NUL 2>&1
	cls & echo Setting process priority and disabling security mitigations
	for %%i in (
		dwm.exe
		lsass.exe
		svchost.exe
		WmiPrvSE.exe
	) do (
		reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%i\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "1" /f > NUL 2>&1
		reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%i\PerfOptions" /v "IoPriority" /t REG_DWORD /d "0" /f > NUL 2>&1
		>> "%windir%\EVA\startup.bat" echo wmic process where name="%%i" call setpriority 64
	)
)

:: WINLOGON TO NORMAL PRIORITY / IO BECAUSE IT IS ON HIGH BY DEFAULT. SETTING IT TO NORMAL PRIORITY PREVENTS CHILD PROCESSES FROM INHERITING A HIGH PRIORITY WHICH IS NOT IDEAL
:: A CHAIN OF EVENTS MAY LEAD TO GAMES GETTING SET TO HIGH PRIORITY

reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\winlogon.exe\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "2" /f > NUL 2>&1
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\winlogon.exe\PerfOptions" /v "IoPriority" /t REG_DWORD /d "2" /f > NUL 2>&1

:: CSRSS (RESPONSIBLE FOR RAW INPUT) TO HIGH PRIORITY / IO

Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d "3" /f > NUL 2>&1
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "IoPriority" /t REG_DWORD /d "3" /f > NUL 2>&1

:: DISABLE PROCESS MITIGATIONS
:: https://docs.microsoft.com/en-us/powershell/module/processmitigations/set-processmitigation?view=windowsserver2019-ps

for %%i in (dwm.exe lsass.exe svchost.exe WmiPrvSE.exe winlogon.exe csrss.exe) do (
	reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%i" /v "MitigationOptions" /t REG_BINARY /d "22222222222222222222222222222222" /f > NUL 2>&1
	reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%i" /v "MitigationAuditOptions" /t REG_BINARY /d "22222222222222222222222222222222" /f > NUL 2>&1
)

:: VERY FEW PNP DEVICES HAVE THESE ASPM KEYS, HERE FOR COMPLETENESS
cls & echo Disabling ASPM for PnP devices if they are present on the system...

for %%a in (ASPMOptIn) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet" /s /f "%%a" ^| findstr "HKEY"') do PowerRun.exe /SW:0 reg.exe add "%%b" /v "%%a" /t REG_DWORD /d "0" /f
for %%a in (ASPMOptOut) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet" /s /f "%%a" ^| findstr "HKEY"') do PowerRun.exe /SW:0 reg.exe add "%%b" /v "%%a" /t REG_DWORD /d "1" /f

:: DISABLING POWERSAVING

for %%a in (
	EnhancedPowerManagementEnabled
	AllowIdleIrpInD3
	EnableSelectiveSuspend
	DeviceSelectiveSuspended
	SelectiveSuspendEnabled
	SelectiveSuspendOn
	EnumerationRetryCount
	ExtPropDescSemaphore
	WaitWakeEnabled
	D3ColdSupported
	WdfDirectedPowerTransitionEnable
	EnableIdlePowerManagement
	IdleInWorkingState
) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "%%a" /t REG_DWORD /d "0" /f > NUL 2>&1

:: DMAREMAPPING REGISTRY KEYS EXIST UNDER THE \SERVICES ENTRY ALTHOUGH DMA IS ONLY CONTROLLED ON A KERNEL LEVEL IN 1803
:: https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt

for %%a in (DmaRemappingCompatible) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "%%a" /t REG_DWORD /d "0" /f > NUL 2>&1

:: SET IOLATENCYCAP IF CONDITION APPLIES

if %SET_IOLATENCYCAP% EQU TRUE for %%a in (IoLatencyCap) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "%%a" /t REG_DWORD /d "%IOLATENCYCAP%" /f > NUL 2>&1

for %%a in (EnableHIPM EnableDIPM EnableHDDParking) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "%%a" ^| findstr "HKEY"') do reg.exe add "%%b" /v "%%a" /t REG_DWORD /d "0" /f > NUL 2>&1

:: DISABLE INTEL DRIVERS ON AMD SYSTEMS AND VICE VERSA

for /F "tokens=* skip=1" %%n in ('wmic cpu get Manufacturer ^| findstr "."') do set CPUManufacturer=%%n
if %CPUManufacturer% EQU AuthenticAMD (
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\iagpio" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\iai2c" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\iaLPSS2i_GPIO2" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\iaLPSS2i_GPIO2_BXT_P" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\iaLPSS2i_I2C" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\iaLPSS2i_I2C_BXT_P" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\iaLPSSi_GPIO" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\iaLPSSi_I2C" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\iaStorAVC" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\iaStorV" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\intelide" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\intelpep" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\intelppm" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
)

if %CPUManufacturer% EQU GenuineIntel (
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\AmdK8" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\AmdPPM" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\amdsata" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\amdsbs" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
	PowerRun.exe /SW:0 reg.exe add "HKLM\System\CurrentControlSet\Services\amdxata" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
)

if %IDLE_SCRIPTS_DESKTOP% EQU TRUE (
	>> "%userprofile%\Desktop\Idle Disable.bat" echo @echo off
	>> "%userprofile%\Desktop\Idle Disable.bat" echo powercfg -setacvalueindex scheme_current sub_processor 5d76a2ca-e8c0-402f-a133-2158492d58ad 1
	>> "%userprofile%\Desktop\Idle Disable.bat" echo powercfg -setactive scheme_current
	>> "%userprofile%\Desktop\Idle Disable.bat" echo exit /b
	
	>> "%userprofile%\Desktop\Idle Enable.bat" echo @echo off
	>> "%userprofile%\Desktop\Idle Enable.bat" echo powercfg -setacvalueindex scheme_current sub_processor 5d76a2ca-e8c0-402f-a133-2158492d58ad 0
	>> "%userprofile%\Desktop\Idle Enable.bat" echo powercfg -setactive scheme_current
	>> "%userprofile%\Desktop\Idle Enable.bat" echo exit /b	
)

if %FONT_SMOOTHING% EQU TRUE (
	Reg.exe add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d "2" /f > NUL 2>&1
)

if %CUSTOM_GPU_AFFINITY% EQU TRUE (
	for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
		Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d "4" /f > NUL 2>&1
		Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /t REG_BINARY /d "%HEX_GPU_AFFINITY%" /f > NUL 2>&1
	)
)

if %CUSTOM_USB_AFFINITY% EQU TRUE (
	for /f %%i in ('wmic path Win32_USBController get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
		Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d "4" /f > NUL 2>&1
		Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /t REG_BINARY /d "%HEX_USB_AFFINITY%" /f > NUL 2>&1
	)
)

if %TASKBAR_ICONS_EXTENDED% EQU FALSE (
	Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarGlomLevel" /t REG_DWORD /d "0" /f > NUL 2>&1
)
if %TASKBAR_ICONS_EXTENDED% EQU TRUE (
	Reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarGlomLevel" /t REG_DWORD /d "2" /f > NUL 2>&1
)

if %SET_TIMER_RESOLUTION% EQU TRUE (
	reg.exe add "HKCU\SOFTWARE\Memory Cleaner\Settings" /v "DesiredTimerResolution" /t REG_SZ /d "%TIMER_RESOLUTION%" /f > NUL 2>&1
	reg.exe add "HKCU\SOFTWARE\Memory Cleaner\Settings" /v "EnableCustomTimerResolution" /t REG_SZ /d "1" /f > NUL 2>&1
)
if %SET_TIMER_RESOLUTION% EQU FALSE (
	:: A TIMER RESOLUTION HAS TO BE SPECIFIED FOR THE PROGRAM TO READ EVEN IF THE FEATURE IS DISABLED
	reg.exe add "HKCU\SOFTWARE\Memory Cleaner\Settings" /v "DesiredTimerResolution" /t REG_SZ /d "10000" /f > NUL 2>&1
	reg.exe add "HKCU\SOFTWARE\Memory Cleaner\Settings" /v "EnableCustomTimerResolution" /t REG_SZ /d "0" /f > NUL 2>&1
)

:: ENABLE CFG FOR VALORANT IN THE MITIGATIONS BINARY MASK
:: OTHER MITIGATIONS GET REVERTED WHEN USING THE POWERSHELL COMMAND, EDITING THE BINARY MASK MANUALLY IS MORE RELIABLE METHOD

if %VALORANT_PLAYER% EQU TRUE (
	Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vgc.exe" /v "MitigationOptions" /t REG_BINARY /d "00000000000100000000000000000000" /f > NUL 2>&1
)

if %CUSTOM_WIN32PS% EQU TRUE Reg.exe add "HKLM\System\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "%WIN32PS_DEC%" /f > NUL 2>&1

:: https://docs.microsoft.com/en-us/windows-hardware/drivers/display/changing-the-behavior-of-the-gpu-scheduler-for-debugging
:: https://en.wikipedia.org/wiki/Preemption_(computing)#:~:text=In%20computing%2C%20preemption%20is%20the,or%20cooperation%20from%20the%20task.

if %DISABLE_PREEMPTION% EQU TRUE Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v "EnablePreemption" /t REG_DWORD /d "0" /f > NUL 2>&1

if %SET_MOUSEDATAQUEUESIZE% EQU TRUE Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d "%MOUSEDATAQUEUESIZE%" /f > NUL 2>&1
if %SET_KEYBOARDDATAQUEUESIZE% EQU TRUE Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /t REG_DWORD /d "%KEYBOARDDATAQUEUESIZE%" /f > NUL 2>&1

:: DISABLING AUTORUN TASKS
cls & echo Disabling autorun tasks...

:: AS USER
Reg.exe delete "HKLM\Software\Microsoft\Active Setup\Installed Components\{8A69D345-D564-463c-AFF1-A69D9E530F96}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Active Setup\Installed Components\{AFE6A462-C574-4B8A-AF43-4CC60DF4563B}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Logon\{29D03007-F8B1-4E12-ACAF-5C16C640D894}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Logon\{834F4B4B-2375-46D7-AB12-546EF47FC46F}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Logon\{8B76D8B3-FDFD-4A7D-B89A-C0787A05BE76}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Logon\{CFDB528C-406A-4C14-9533-64C65AA183BB}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{06C2AEAE-A87D-43BA-B84E-AE7E4A11C897}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{06C2AEAE-A87D-43BA-B84E-AE7E4A11C897}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{29D03007-F8B1-4E12-ACAF-5C16C640D894}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{834F4B4B-2375-46D7-AB12-546EF47FC46F}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{8B76D8B3-FDFD-4A7D-B89A-C0787A05BE76}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{CFDB528C-406A-4C14-9533-64C65AA183BB}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\AMDInstallUEP" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\GoogleUpdateTaskMachineCore" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\GoogleUpdateTaskMachineUA" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\StartCN" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\StartDVR" /f > NUL 2>&1
Reg.exe delete "HKLM\System\CurrentControlSet\Control\Terminal Server\Wds\rdpwd" /v "StartupPrograms" /f > NUL 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\Services\AMD External Events Utility" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\Services\AMD External Events Utility" /v "DeleteFlag" /t REG_DWORD /d "1" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Active Setup\Installed Components\{89B4C1CD-B018-4511-B0A1-5476DBF70820}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "Open-Shell Start Menu" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\WOW6432Node\Microsoft\Active Setup\Installed Components\{89B4C1CD-B018-4511-B0A1-5476DBF70820}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{0E76D7E3-DA81-46BD-A750-C06B6B660CB4}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{0E76D7E3-DA81-46BD-A750-C06B6B660CB4}" /f > NUL 2>&1
Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Mozilla\Firefox Background Update 308046B0AF4A39CB" /f > NUL 2>&1
Reg.exe delete "HKLM\System\CurrentControlSet\Control\Session Manager\KnownDLLs" /v "_wow64win" /f > NUL 2>&1
Reg.exe delete "HKLM\System\CurrentControlSet\Control\Session Manager\KnownDLLs" /v "_wowarmhw" /f > NUL 2>&1
Reg.exe delete "HKLM\System\CurrentControlSet\Control\Session Manager\KnownDLLs" /v "_wow64" /f > NUL 2>&1
Reg.exe delete "HKLM\System\CurrentControlSet\Control\Session Manager\KnownDLLs" /v "_wow64cpu" /f > NUL 2>&1
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\FontCache3.0.0.0" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1

:: AS TRUSTEDINSTALLER
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Active Setup\Installed Components\{8A69D345-D564-463c-AFF1-A69D9E530F96}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Active Setup\Installed Components\{AFE6A462-C574-4B8A-AF43-4CC60DF4563B}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Logon\{29D03007-F8B1-4E12-ACAF-5C16C640D894}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Logon\{834F4B4B-2375-46D7-AB12-546EF47FC46F}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Logon\{8B76D8B3-FDFD-4A7D-B89A-C0787A05BE76}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Logon\{CFDB528C-406A-4C14-9533-64C65AA183BB}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{06C2AEAE-A87D-43BA-B84E-AE7E4A11C897}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{06C2AEAE-A87D-43BA-B84E-AE7E4A11C897}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{29D03007-F8B1-4E12-ACAF-5C16C640D894}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{834F4B4B-2375-46D7-AB12-546EF47FC46F}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{8B76D8B3-FDFD-4A7D-B89A-C0787A05BE76}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{CFDB528C-406A-4C14-9533-64C65AA183BB}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\AMDInstallUEP" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\GoogleUpdateTaskMachineCore" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\GoogleUpdateTaskMachineUA" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\StartCN" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\StartDVR" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\System\CurrentControlSet\Control\Terminal Server\Wds\rdpwd" /v "StartupPrograms" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Services\AMD External Events Utility" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Services\AMD External Events Utility" /v "DeleteFlag" /t REG_DWORD /d "1" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Active Setup\Installed Components\{89B4C1CD-B018-4511-B0A1-5476DBF70820}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "Open-Shell Start Menu" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\WOW6432Node\Microsoft\Active Setup\Installed Components\{89B4C1CD-B018-4511-B0A1-5476DBF70820}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{0E76D7E3-DA81-46BD-A750-C06B6B660CB4}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{0E76D7E3-DA81-46BD-A750-C06B6B660CB4}" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Mozilla\Firefox Background Update 308046B0AF4A39CB" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\System\CurrentControlSet\Control\Session Manager\KnownDLLs" /v "_wow64win" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\System\CurrentControlSet\Control\Session Manager\KnownDLLs" /v "_wowarmhw" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\System\CurrentControlSet\Control\Session Manager\KnownDLLs" /v "_wow64" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe delete "HKLM\System\CurrentControlSet\Control\Session Manager\KnownDLLs" /v "_wow64cpu" /f > NUL 2>&1
PowerRun.exe /SW:0 Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\FontCache3.0.0.0" /v "Start" /t REG_DWORD /d "4" /f > NUL 2>&1

:: DISABLING SCHEDULED TASKS
cls & echo Disabling scheduled tasks...

for %%i in (
	"\Microsoft\Windows\Application Experience\StartupAppTask"
	"\Microsoft\Windows\Autochk\Proxy"
	"\Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask"
	"\Microsoft\Windows\Chkdsk\ProactiveScan"
	"\Microsoft\Windows\Chkdsk\SyspartRepair"
	"\Microsoft\Windows\Data Integrity Scan\Data Integrity Scan"
	"\Microsoft\Windows\Data Integrity Scan\Data Integrity Scan for Crash Recovery"
	"\Microsoft\Windows\Defrag\ScheduledDefrag"
	"\Microsoft\Windows\DiskCleanup\SilentCleanup"
	"\Microsoft\Windows\DiskFootPrint\Diagnostics"
	"\Microsoft\Windows\DiskFootPrint\StorageSense"
	"\Microsoft\Windows\LanguageComponentsInstaller\Uninstallation"
	"\Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents"
	"\Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic"
	"\Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser"
	"\Microsoft\Windows\Registry\RegIdleBackup"
	"\Microsoft\Windows\Time Synchronization\ForceSynchronizeTime"
	"\Microsoft\Windows\Time Synchronization\SynchronizeTime"
	"\Microsoft\Windows\Time Zone\SynchronizeTimeZone"
	"\Microsoft\Windows\UpdateOrchestrator\Reboot"
	"\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
	"\Microsoft\Windows\UpdateOrchestrator\USO_Broker_Display"
	"\Microsoft\Windows\UPnP\UPnPHostConfig"
	"\Microsoft\Windows\User Profile Service\HiveUploadTask"
	"\Microsoft\Windows\Windows Filtering Platform\BfeOnServiceStartTypeChange"
	"\Microsoft\Windows\WindowsUpdate\Scheduled Start"
	"\Microsoft\Windows\WindowsUpdate\sih"
	"\Microsoft\Windows\Wininet\CacheTask"
) do (
	Schtasks.exe /Change /Disable /TN %%i > NUL 2>&1
	Powerrun.exe /SW:0 schtasks.exe /Change /Disable /TN %%i
)

:: COMMENTED OUT BECAUSE REMOVING THESE KEYS BREAKS A VAST MAJORITY OF LOGGING APPS SUCH AS XPERF, PRESENTMON, RESOURCE MONITOR.
:: REMOVING THE REGISTRY KEY IS EQUIVALENT TO DELETING EACH LOGGER IN MMC MANUALLY
:: cls & echo Removing all WMI autologgers...

:: PowerRun.exe /SW:0 Reg.exe delete "HKLM\System\CurrentControlSet\Control\WMI\Autologger" /f > NUL 2>&1
:: PowerRun.exe /SW:0 Reg.exe add "HKLM\System\CurrentControlSet\Control\WMI\Autologger" /f > NUL 2>&1

:: DELETE FIREWALL RULES
:: REMOVING THE REGISTRY KEY IS EQUIVALENT TO DELETING EACH RULE IN MMC MANUALLY
Reg.exe delete "HKLM\System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules" /f > NUL 2>&1
Reg.exe add "HKLM\System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules" /f > NUL 2>&1

:: PREPARE DWM SCRIPTS
cls & echo Preparing DWM scripts...

takeown /F "%windir%\System32\dwm.exe" /A & icacls "%windir%\System32\dwm.exe" /grant Administrators:(F) > NUL 2>&1
takeown /F "%windir%\System32\UIRibbon.dll" /A & icacls "%windir%\System32\UIRibbon.dll" /grant Administrators:(F) > NUL 2>&1
takeown /F "%windir%\System32\UIRibbonRes.dll" /A & icacls "%windir%\System32\UIRibbonRes.dll" /grant Administrators:(F) > NUL 2>&1
takeown /F "%windir%\System32\Windows.UI.Logon.dll" /A & icacls "%windir%\System32\Windows.UI.Logon.dll" /grant Administrators:(F) > NUL 2>&1
takeown /F "%windir%\System32\RuntimeBroker.exe" /A & icacls "%windir%\System32\RuntimeBroker.exe" /grant Administrators:(F) > NUL 2>&1
takeown /F "%windir%\SystemApps\ShellExperienceHost_cw5n1h2txyewy" /A & icacls "%windir%\SystemApps\ShellExperienceHost_cw5n1h2txyewy" /grant Administrators:(F) > NUL 2>&1
copy /y "%windir%\System32\dwm.exe" "%windir%\EVA\dwm_scripts\realdwm\dwm.exe" > NUL 2>&1
copy /y "%windir%\System32\rundll32.exe" "%windir%\EVA\dwm_scripts\fakedwm\dwm.exe" > NUL 2>&1
cls

:: CLEANUP AND RESTART
del /f /q "%userprofile%\Desktop\enter windows activation product key.txt" > NUL 2>&1
del /f /q "%windir%\Modules\Enter windows activation product key.txt" > NUL 2>&1
del /f /q "%userprofile%\Desktop\SDIO.lnk" > NUL 2>&1
del /f /q "%windir%\EVA\check_env.bat" > NUL 2>&1
del /f /q "%windir%\Modules\devmanview.exe" > NUL 2>&1
del /f /q "%windir%\Modules\EVA.reg" > NUL 2>&1
del /f /q "%windir%\Modules\refresh_env.bat" > NUL 2>&1
del /f /q "%windir%\Modules\PSCODE.ps1" > NUL 2>&1
del /f /q "%windir%\Modules\FullscreenCMD.vbs" > NUL 2>&1
del /f /q "%windir%\Modules\strip_nvsetup.exe" > NUL 2>&1
rd /s /q "%windir%\Modules\SDIO" > NUL 2>&1

nircmd shortcut "%windir%\EVA\EVA-Support" "%userprofile%\Desktop" "EVA-Support"

Reg.exe delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "POST INSTALL" /f > NUL 2>&1
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "POST INSTALL" /t REG_SZ /d "explorer \"C:\POST INSTALL\"" /f > NUL 2>&1
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "POST INSTALL LOG" /t REG_SZ /d "notepad \"C:\Windows\EVA\logs\POST INSTALL.log\"" /f > NUL 2>&1
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "DEL POST INSTALL SCRIPT" /t REG_SZ /d "cmd /c del /f /q \"%%windir%%\Modules\POST INSTALL.bat\" & exit" /f > NUL 2>&1

>> %log% echo.
>> %log% echo %date% %time% - Setup complete. Restarting.
>> %log% echo.
>> %log% echo -----------------------------------------------------------------------------------------------------------------------------------------------

shutdown /r /f /t 10 /c "Setup complete: restarting..."
exit

:bin2hex <var_to_set> <bin_value>
set "hextable=0000-0;0001-1;0010-2;0011-3;0100-4;0101-5;0110-6;0111-7;1000-8;1001-9;1010-A;1011-B;1100-C;1101-D;1110-E;1111-F"
:bin2hexloop
if "%~2"=="" (
    endlocal & set "%~1=%~3"
    goto :EOF
)
set "bin=000%~2"
set "oldbin=%~2"
set "bin=%bin:~-4%"
set "hex=!hextable:*%bin:~-4%-=!"
set hex=%hex:;=&rem.%
endlocal & call :bin2hexloop "%~1" "%oldbin:~0,-4%" %hex%%~3
goto :EOF

:ChangeByteOrder  <data:hex>
set "BytesLE="
set "BytesBE=%~1"
:ChangeByteOrderLoop
if "%BytesBE:~-2%"=="%BytesBE:~-1%" (
    set "BytesLE=%BytesLE%0%BytesBE:~-1%"
) else set "BytesLE=%BytesLE%%BytesBE:~-2%"
set "BytesBE=%BytesBE:~0,-2%"
if not defined BytesBE exit /B
goto :ChangeByteOrderLoop