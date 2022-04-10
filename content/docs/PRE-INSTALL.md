This page was inspired by [PC-Optimization-Hub by Bored](https://github.com/BoringBoredom/PC-Optimization-Hub) & [GamingPCSetup](https://github.com/djdallmann/GamingPCSetup/).

### BIOS

  - Disable hyperthreading/SMT unless you have a 4 core CPU. This feature is beneficial for highly threaded operations such as video editing/compiling/rendering however, system latency is increased as each core is given two workloads.
  - Disable c-states and disable all p-states except p0.
  - Disable Speedstep/Cool&Quiet and set a manual all core overclock instead.
  - Disable virtualization to disable [kernel DMA protection](https://docs.microsoft.com/en-us/windows/security/information-protection/kernel-dma-protection-for-thunderbolt#using-system-information).
  - Disable ASPM on pci/sata devices and any other powersaving features you can locate in BIOS. Always google and check settings if you are unsure.
  - If you don't use it disable it. Turn off devices/features that are not active and you know you won't be using e.g USB ports, sata ports, network controllers (wifi), unused PCI slots...

### REDUCING INTEFERENCE

  - Move devices that emit RF/EMF/EMI away from your setup/bedroom such as radios, phones, routers. They have the potential to increase input latency due to unwanted/unintended behavior of electronic components.
  - Always favor wired over cordless. This generally applies to mice, headsets and speakers.
  - Disconnect uneeded devices from your motherboard to reduce the risk of coupling. This incudes LEDs, external USB ports, hard drives, RGB light strips etc.
  - Consider proper cable management. Ensure there is a moderate amount of space between all cables (no cables should be touching) in your setup to also reduce the risk of coupling.
  
### FINDING THE CLOSEST USB PORT OF THE CLOSEST USB CONTROLLER CONNECTED TO THE CPU/CHIPSET

  - Download [USB tree viewer](https://www.uwe-sieber.de/usbtreeview_e.html) & with trial & error, plug your mouse into every USB port available on your motherboard & keep a mental note which is the closest usb hub available of your first usb     
    controller. 
  - Use the 1st closest port for your mouse
  - Use the 2nd closest port for your keyboard
  - Use other ports for other other devices such as DACs/headsets. If you have more than one USB controller, you can also offload devices to other controllers to prevent e.g a USB DAC intefering with polling stability.

### TURN ON AUDIO PERIPHERALS & OTHER DEVICES

  - The post install script disables audio enhancements etc, if the script can not detect your audio device, it will not apply the settings properly so ensure all  
    devices such as headsets/DACS are turned on (as if you were about to begin gaming) before the post install script begins.

### CONFIGURE PERIPHERALS SETTINGS

  - If your peripherals support onboard memory/profiles, tune your mouse settings before booting into EVA. 
  - Increasing DPI [reduces latency](https://youtu.be/6AoRfv9W110). Most mice are able to handle 1600dpi without [sensor smoothing](https://www.reddit.com/r/MouseReview/comments/5haxn4/sensor_smoothing/)
  - USB output is limited to roughly 7A & RGB requires unnecessary power. Turn off RGB where you can or strip the LEDs from the peripheral as ["Running a RGB effect/animation can take a great toll on the MCU. It requires a lot of processing power and will delay other processes.](https://blog.wooting.nl/what-influences-keyboard-speed/)
  
### PREPARING CUSTOM DRIVERS

  - I follow a strict order of setup. If you want to install custom drivers, they MUST be installed at BREAKPOINT. If you install drivers after, tweaks/settings WILL get reverted.
   
  - NOTE: If you have an intel iGPU you are required to install drivers in this section.
   
  - If you usually install custom drivers, get them ready. Keep them somewhere you can access them offline because you won't have a browser at that point of time (e.g a usb stick/ a secondary drive). You will be required to install them at BREAKPOINT. SDIO is also available on the desktop for you to install drivers.
	
	NOTE: I may personally recommend you to do specific things at BREAKPOINT if you come to me with an issue.

    <img src="https://github.com/AesterFF/Eva-Continued/blob/main/content/img/PRE-INSTALL%20-%20Breakpoint.png" width="800" >
