# POST INSTALL - PART 1: THE POST INSTALL SCRIPT
   
  1) After you boot into the EVA, do not close the cmd window. If you accidentally close it you will need to reinstall because you may leave the system in a bad state so you can't simply just run the script again.
   
  2) Answer the questions according to your needs
   
  3) You will be asked if you need to enter BREAKPOINT, as explained in [PRE-INSTALL](https://github.com/AesterFF/Eva-Continued/blob/main/content/docs/PRE-INSTALL.md#preparing-custom-drivers)
   
  4) If you answered yes to wifi, you will be prompted to press CTRL + ALT + DELETE & connect to wifi via the internet icon at the bottom right of the screen:

      <img src="https://github.com/AesterFF/Eva-Continued/blob/main/content/img/POST-INSTALL%20-%20Connect%20to%20wifi.png" width="450" >

  5) When a connection is established, setup will begin. If a internet connection is not established, setup will not continue until you are connected to the internet
      
  6) Your PC will restart automatically and will C:\POST INSTALL and the setup log for you to check if setup completed successfully & for you to do the rest of the post install.

  7) If the log ended in "Setup Complete". If not then you must reinstall and/or contact me for help

# POST INSTALL - PART 2: THE POST INSTALL FOLDER

#### 0 Set Region 

  - Set your region

#### 1 Country & language

  - Set your country & language

#### 2 Sound control panel 

  - Disable unnecessary playback & recording devices
  - NOTE: Avoid using audio enhancements (audiodg.exe uses more cpu cycles/s with them on)

#### 3 Device Manager
  - View > devices by connection
  - Disable any PCI bridges with nothing connected to them
  - Disable any sata controllers with nothing connected to them
  - Disable any unused usb controllers
  - Disable any unused network adapters
  - Go to your main network adapter > properties > advanced > disable any power saving features (i don't have every reg key for every driver so i can't automate this properly but i have already disabled the majority of them)
   (other nic tweaks are automated in the advanced tab)
  - You can check if power saving is disabled on usb devices if you have OCD like me, although it has already been done in the script

#### 4 Device Cleanup.bat

  - Run to clean up hidden, unused devices

#### 5 Set Memory Cleaner Hotkey

  - Set a hotkey to manually clear the standbylist in memory cleaner. (don't use auto cleaning apps like ISLC/Memreduct, they are cpu cycles hungry & cause stuttering)
  - The Timer Resolution is set according to what you chose in the post installs script

#### 6 AMD Settings

  - Run the script & configure your control panel settings
  - Anti-Lag/prerendered frames have been set according to what you selected in the post install script
  - I can't automate HDCP for AMD gpus so make sure you disable HDCP in the display tab under overrides

    <img src="https://github.com/AesterFF/Eva-Continued/blob/main/content/img/POST-INSTALL%20-%20HDCP%20AMD.png" width="500" >

#### 7 NVIDIA Settings

  - Run the script & configure your control panel settings
  - Disable silk smoothness if you wish
  - Low latency mode controls the amount of frames the CPU buffers before the GPU renderes the frame. Reducing the amount of frames that are buffered can influence latency however you are giving your GPU less headroom to render frames.
	```
	Off - 3 prerendered frames (default)
	On - 1 prerendered frames (recommended)
	Ultra - 0 prerendered frames (equivalent of AMD's anti-lag, may cause stuttering on weak systems)
	```
	
  - Threaded optimization allows the GPU driver to offload certain processing tasks on available CPU cores.
    ```
    GPU Bottleneck = on
    CPU Bottleneck = off
    ```
  - GSYNC is left on by default, however any type of variable refresh rate feature has been proven to increase total system latency. I highly recommend turning it off but the choice is yours.
  
	<img src="https://github.com/AesterFF/Eva-Continued/blob/main/content/img/POST-INSTALL%20-%20Disable%20G-SYNC.png" width="500" >

#### 8 Interrupt Affinity Tool.exe

  - I only suggest setting affinity to your GPU & primary USB controller (the option was also in the post install script)
  - Ideally you should use [AutoGpuAffinity](https://github.com/AesterFF/AutoGpuAffinity) to determine what CPU core gives the highest fps for each physical CPU
  - Use [Mouse tester](https://www.overclock.net/threads/mousetester-software.1535687/?__cf_chl_captcha_tk__=pmd_L1o.971oW6uA63B.sm169mZeW388u5WHIG2q_2Fr5XM-1631972772-0-gqNtZGzNAyWjcnBszQfl) to determine which CPU core gives the most stable polling for your USB controller

#### 9 MSI Utility.exe 

  - This is automated, leave what you can on undefined priority. It's here for completeness & for people that want to set irq limits for devices
   
#### 10 CRU.exe

  - Try to remove every other resolution you are not going to use. This will prevent the 2-3 second black screen when alt tabbing 
    in FSE
  - Remove audio blocks
  - Any scaling adds latency. Try to use your monitors native resolution at all times (reduce your games 3D resolution instead of 
    using a lower resolution)
   
#### 11 Restart GPU

  - Restarts the GPU driver after CRU modifications

#### 12 Disable scaling.bat

  - Run this script to use set scaling to 1 for all displays

  - ```1 = No Scaling controlled by the program/ operating system```
  - ```2 = No Scaling controlled by the GPU driver```
  - ```3 = Full-Screen```
  - ```4 = Aspect ratio```

#### 13 Set resolution if required

  - Mostly for AMD GPU users to set their screen resolution

#### 14 Set process affinity.bat

  - This script will remove cycle hungry processes from running on the core you enter each time on startup.
  - I would recommend entering your USB affinity or GPU affinity to prevent those processes from running on those cores
  - e.g scenario: USB affinity on CPU 1, enter 1 in this script and processes will run on every core except CPU 1
  - This is to be automated in the future
  
#### 15 Install your games & apps

  - Install all your desired games & apps now
  - EVAMANAGER is a built in tool which allows you to install some apps instantly. open CMD & type "EVA" for more info

#### 16 FSE-QOS for game exes.bat

  - This is a multifunctional script to disable FSO & enable DSCP 46 for your game which will prioritize packets over other devices on your network & PC
  - The script also asks if you want to enable exclusive fullscreen for the game exe & override the scaling mode
  - It also adds the game exe & sets it to high performance however, this is only for those that have two GPUs. It literally 
    does nothing for single GPU scenarios as per official microsoft docs
    
    <details><summary><ins>How can you verify if DSCP is working?</ins></summary>
   
    - Download [Microsoft Network Monitor 3.4](https://www.microsoft.com/en-gb/download/details.aspx?id=4865)
   
    - Create a new capture
   
      <img src="https://github.com/AesterFF/Eva-Continued/blob/main/content/img/POST-INSTALL%20-%20Network%20monitor%20new%20capture.png" width="450" >
   
    - Open a game that you have applied a DSCP value for and enter a gamemode in which the game will send & receive packets (e.g an online match, not a local match).
   
    - Press F5 to start logging. After 30 seconds or so press F7 to stop the log.
   
    - In the left hand pane, click on the game executable name & click on a packet header. Expand the packet info under "Frame Details" and finally expand the subcatagory 
       "Ipv4". This will reveal the current DSCP value of each frame.

      <img src="https://github.com/AesterFF/Eva-Continued/blob/main/content/img/POST-INSTALL%20-%20Network%20monitor%20DSCP.png" width="450" >
  
#### 17 Autoruns.exe

  - Autoruns is automated, but it's included so that you can remove game launchers & other apps from automatically starting when EVA boots up
  
#### 18 General tips

  - Kill explorer.exe after you launch your game, it uses a ton of cycles
  - Try to kill the game launcher (if the game allows you to) after you launch your game
  - Don't run random tweaks, tweaking programs or fall for the "fps boost" marketing nonsense. If you have a question about a specific option or setting tag me in the EVA discord and i will be happy to answer your question
  - Try to favour FOSS (free & open source software). Stay away from proprietary software where you can due to security features disabled in EVA
  - You do not need an antivirus. You need a brain & uBlock origin in your browser, i also recommend installing ClearURL & https everywhere extensions
  - Cap your framerate at a multiple of your monitors refreshrate to prevent frame mistiming (source @calypto). e.g possible fps caps with a 144hz monitor: 72, 144, 288, 432 ...
  - Avoid capping your fps with external limiters (RTSS/GPU CP). External limiters usually buffer 1 frame which will introduce an unacceptable amount of additional latency. (144fps external cap --> added ~7ms of latency)

#### 19 Services-Drivers Disable

  - You're done! Run Services-Drivers Disable.bat & go play games.
  - If you ever find that something does not work you can revert to Services-Drivers Enable.bat & do whatever you were trying to do. once you are done, return to Services-Drivers Disable.bat to enjoy a bare, snappy environment.
