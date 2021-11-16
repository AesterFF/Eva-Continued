@echo off
call :USER_DEFINED

:: STOP SERVICES

sc stop UserManager
sc stop ProfSvc
sc stop sppsvc

sc stop UserManager
sc stop ProfSvc
sc stop sppsvc

sc stop UserManager
sc stop ProfSvc
sc stop sppsvc

:: SET PROCESS AFFINITY IF DEFINED, OTHERWISE LEAVE DEFAULT

:processaffinity
if defined affinity (
	if not %affinity% GTR 0 goto INVALID_AFFINITY
	PowerShell -NoLogo -NoProfile -NonInteractive -Command "get-process dwm,audiosvchost,audiodg,lsass,svchost,WmiPrvSE | ForEach-Object {$_.ProcessorAffinity=%affinity%}"
)

:INVALID_AFFINITY
:: WINLOGON TO NORMAL PRIORITY / IO BECAUSE IT IS ON HIGH BY DEFAULT. SETTING IT TO NORMAL PRIORITY PREVENTS CHILD PROCESSES FROM INHERITING A HIGH PRIORITY WHICH IS NOT IDEAL
wmic process where name="winlogon.exe" call setpriority 32

:: CLEAR TEMP FOLDER
rd /s /q "%temp%" & mkdir "%userprofile%\AppData\Local\Temp"

:: BREAKS POWERSHELL, NEED TO FIND A COMPROMISE
:: PowerRun.exe /SW:0 logman.exe stop UserNotPresentTraceSession -ets
:: PowerRun.exe /SW:0 logman.exe stop UBPM -ets

exit /b

:USER_DEFINED
