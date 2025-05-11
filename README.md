# CPU State Manager
This is a powershell script that tries to lower your CPU temperature to something you set, by changing dynamically the maximum cpu power state in the selected windows plan, without loosing much performance in your games.

Originally i made it to fix an issue i have, and others, on the MSI Delta 15 overheating and shutting down (more tips for u guys down [here](#more-help-for-msi-delta-15-users)), but you can definetley use it on some hot day or something to just have some fun on the computer.

> [!Important]
> Im not responsible if this causes anything to your computer, despite this being pretty safe and i have made precautions in case anything happens, but just putting this out there, so use it at ur own risk

## Setup & Usage
### SETUP
A. Downloading the scripts
  1. Head to [Releases](https://github.com/Atomic-Potato/CPU-State-Manager/releases) and get the version zip u want and extract it. You could download the repo as a zip but i would not recommend this since its not always tested 

B. Installing a hardware monitor to read CPU temps:
  1. Install either [LibreHardwareMonitor](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases) (this one works for me)or [OpenHardwareMonitor](https://openhardwaremonitor.org/downloads/)
  2. Extract the app somewhere, you probably only need `LibreHardwareMonitorLib.dll` or `OpenHardwareMonitorLib.dll` file, but idk couldnt bother trying)
  3. Open CPUStateManager.ps1 and set the full path of the DLL file in the hardware_monitor_dll_path parameter

C. Making a power plan: 
  1. Write in the windows search bar "choose a power plan"
  2. Click 'Create a new plan on the left', do whatever it asks
  3. Not important, but i usually go into the advanced settings of the plan and try to toggle everything for power saving
  4. Open CPUStateManager.ps1 and set power_plan_name to the name of the plan you created

### USAGE
A. Running the app
  1. Write in the windows search bar and open: Windows Powershel ISE
  2. Open CPUStateManager.ps1 within the ISE
  3. bam you can now just hit the run button or F5 to run it, and to stop it use the big red square or Ctrl+PageBreak
  4. (Optional) i like setting the script pane to the right, just look for it in the bar at the top, youre a big boi u can figure it out
  5. Once youre done using it, open RestoreDefaultCPUState.ps1 set the default value of the state and the power plan name and run it whenever youre done

The script should work fine with the default values, you probably just need to change the target_temp depending on the game youre playing and maybe the min_cpu_state

aight fam, have fun on da computer o7

## More help for MSI Delta 15 users
### Modifing the BIOS
### Setting the fan curves

## Known Issues
- Sometimes the Power Plan doesnt update, so you have to choose another plan manually and switch back for the state to update

## ToDo.. someday
- Read the FPS of your game to refine the algorithm even more and reduce performance loss
- UI

## Contact me for help
- My discord username: atomic\_potato\_32
- My discrod server: [https://discord.gg/JUJKZxp](https://discord.gg/JUJKZxp)
- My email: atomicpotatogames32@gmail.com
