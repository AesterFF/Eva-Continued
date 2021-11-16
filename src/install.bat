@echo off
:selectdrive
set /p installdir="type the drive letter you created to install windows on: "

set installdir=%installdir: =%
if "%installdir%" equ " =" goto invalid
if "%installdir%" equ "=" goto invalid

for %%i in (a b d e f g h i j k l m n o p q r s t u v w x y z A B D E F G H I J K L M O P Q R S T U V W X Y Z) do (
    echo. checking if %%i is a valid letter
    if %installdir% equ %%i goto success
)

:invalid
cls
echo invalid input
echo.
goto selectdrive

:success
cls
DISM /Apply-Image /ImageFile:".\sources\install.esd" /Apply-Unattend:.\autounattend.xml /Index:1 /ApplyDir:%installdir%:\
copy /y ".\autounattend.xml" %installdir%:\Windows\System32\Sysprep\unattend.xml
cls
bcdboot %installdir%:\Windows
bcdedit /timeout 0
cls
echo reboot to access EVA.
pause
exit /b