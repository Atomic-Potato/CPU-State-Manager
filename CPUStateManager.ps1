# CPU State Manager version 1.0
# Made by Atomic Potato Games
# https://github.com/Atomic-Potato/CPU-State-Manager

# ingore this line, it clears the values of the variables between each execution of the script if in the same session
Get-Variable | Remove-Variable -Force -ErrorAction SilentlyContinue



################################################ PARAMETERS ################################################

# !! IMPORTANT !!
# you have to set these up in order for this script to function:
$global:power_plan_name = 'MyPowerSaver' # The Windows Power Plan used to control the temperature
$global:hardware_monitor_dll_path = "C:\Program Files (x86)\LibreHardwareMonitor\LibreHardwareMonitorLib.dll" # path to the hardware monitoring dll file

# The rest of the parameters were optimized according to the MSI Delta 15 laptop

# Temperatures:
$global:target_temp = 75 # ----------------------- # in celcius (default 90), the CPU temp the script will try reaching and balance the CPU max state around, you can definetly set this to a lower values on less demanding games, heres the games that i tested with the other params on default and what i set the target temp to [The Finals: 88, Death Stranding: 90, Vintage story: 75]
$global:danger_temp = 97 # ======================= # in celcius (default 97), if this CPU temp is reached, processor state will be set to the min_cpu_state for the time set in time_beteween_steps_danger
$global:easing_range = 5 # ----------------------- # in celcius (default 5) greater than 0, best explained with an example: if target_temp = 90 and this is 5, 
                                                   #    then as cpu temp approaches > 95 (90+5), the time between each execution step will interpolate from time_beteween_steps_increase_max to time_beteween_steps_increase_min, effectively decreasing the CPU state faster as it heats up 
                                                   #    and as cpu temp approaches < 85 (90-5), the time between each execution step will interpolate from time_beteween_steps_decrease_min to time_beteween_steps_decrease_max, effectively increasing the CPU state slower as it heats up to reach the target temp

# CPU State control:
$global:min_cpu_state = 5 # ====================== # in % (default 5), between 5 and 100, you can override this in Is-Invalid-Params function if you know what you are doing!
$global:max_cpu_state = 99 # --------------------- # in % (default 99), between min_cpu_state and 100. NOTE: I dont remember why but not setting this to 100 disables something that makes ur labdob heat up but for more performance, i recommend keeping it 99

# Execution:
$global:step_size = 1 # ========================== # in % (default 1), greater than 0, each execution step how much will the CPU state increase/decrease (if it does so)

## Time between execution / steps:
$global:time_beteween_steps_increase_max = 6000    # in milliseconds (default 6000), greater or equal than time_beteween_steps_increase_min, explained in easing_range
$global:time_beteween_steps_increase_min = 2000    # in milliseconds (default 2000), less or equal than time_beteween_steps_increase_max, explained in easing_range

$global:time_beteween_steps_decrease_max = 5000    # in milliseconds (default 5000), greater or equal than time_beteween_steps_decrease_min, explained in easing_range
$global:time_beteween_steps_decrease_min = 1000    # in milliseconds (default 1000), less or equal than time_beteween_steps_decrease_max, explained in easing_range

$global:time_beteween_steps_danger = 10000         # in milliseconds (default 10000), how much time will the CPU state stay at min_cpu_state when CPU danger_temp is reached

################################################ PARAMETERS ################################################


function Is-Invalid-Params{
    $is_invalid = $false
    $error_message = ""

    # Power plan
    if (-not $is_invalid){
        $plan_guid = powercfg /list | ForEach-Object {
            if ($_ -match "Power Scheme GUID: ([a-f0-9\-]+).*?\($power_plan_name\)") {
                return $matches[1]
            }
        }
        if ($plan_guid -eq $null){
            $is_invalid = $true
            $error_message = "Could not find power plan: $global:power_plan_name"
        }
    }
    
    # Hardware Monitor
    if (-not $is_invalid){
        if (-not (Test-Path $hardware_monitor_dll_path)){
            $is_invalid = $true
            $error_message = "Could not find hardware monitor in specified path: $hardware_monitor_dll_path"
        }
    }
    if (-not $is_invalid){
        $is_supported = $true
        $dllName = [System.IO.Path]::GetFileName($hardware_monitor_dll_path)
        switch ($dllName) {
            "LibreHardwareMonitorLib.dll" { $is_supported = $true }
            "OpenHardwareMonitorLib.dll"  { $is_supported = $true }
            default                       { $is_supported = $false }
        }
        if (-not $is_supported){
            $is_invalid = $true
            $error_message = "Unsupported hardware monitor dll: $hardware_monitor_dll_path"
        }
    }    

    # Temperatures
    if (-not $is_invalid){
        if ($easing_range -lt 0){
            $is_invalid = $true
            $error_message = "easing_range ($easing_range) cannot be negative"
        }
    }

    # CPU State control
    if (-not $is_invalid){
        if ($min_cpu_state -lt 5 -or $min_cpu_state -gt 100){
            $is_invalid = $true
            $error_message = "min_cpu_state ($min_cpu_state) is out of range [5,100]"
        }
    }
    if (-not $is_invalid){
        if ($max_cpu_state -lt $min_cpu_state -or $max_cpu_state -gt 100){
            $is_invalid = $true
            $error_message = "max_cpu_state ($max_cpu_state) is out of range [$min_cpu_state,100]"
        }
    }

    # Execution
    if (-not $is_invalid){
        if ($step_size -le 0){
            $is_invalid = $true
            $error_message = "step_size ($step_size) cannot be less than 0"
        }
    }
    if (-not $is_invalid){
        if ($time_beteween_steps_increase_max -lt $time_beteween_steps_increase_min){
            $is_invalid = $true
            $error_message = "time_beteween_steps_increase_max ($time_beteween_steps_increase_max) cannot be less than time_beteween_steps_increase_min ($time_beteween_steps_increase_min)"
        }
    }
    if (-not $is_invalid){
        if ($time_beteween_steps_decrease_max -lt $time_beteween_steps_decrease_min){
            $is_invalid = $true
            $error_message = "time_beteween_steps_decrease_max ($time_beteween_steps_decrease_max) cannot be less than time_beteween_steps_decrease_min ($time_beteween_steps_decrease_min)"
        }
    }
    if (-not $is_invalid){
        if ($time_beteween_steps_increase_max -le 0){
            $is_invalid = $true
            $error_message = "time_beteween_steps_increase_max ($time_beteween_steps_increase_max) cannot be less or equal to 0"
        }
    }
    if (-not $is_invalid){
        if ($time_beteween_steps_increase_min -le 0){
            $is_invalid = $true
            $error_message = "time_beteween_steps_increase_min ($time_beteween_steps_increase_min) cannot be less or equal to 0"
        }
    }
    if (-not $is_invalid){
        if ($time_beteween_steps_decrease_max -le 0){
            $is_invalid = $true
            $error_message = "time_beteween_steps_decrease_max ($time_beteween_steps_decrease_max) cannot be less or equal to 0"
        }
    }
    if (-not $is_invalid){
        if ($time_beteween_steps_decrease_min -le 0){
            $is_invalid = $true
            $error_message = "time_beteween_steps_decrease_min ($time_beteween_steps_decrease_min) cannot be less or equal to 0"
        }
    }
    if (-not $is_invalid){
        if ($time_beteween_steps_danger -le 0){
            $is_invalid = $true
            $error_message = "time_beteween_steps_danger ($time_beteween_steps_danger) cannot be less or equal to 0"
        }
    }

    clear
    Write-Host $error_message -ForegroundColor Black -BackgroundColor Red
    return $is_invalid
}

function Clamp {
    param ([double]$value,[double]$min = 0,[double]$max = 1)
    return [Math]::Max($min, [Math]::Min($max, $value))
}

function Lerp {
    param ([double]$a, [double]$b, [double]$t)
    $t = (Clamp -value $t -min 0 -max 1)
    return $a + ($b - $a) * $t
}

function Get-Max-CPU-State {
    param (
        [Parameter(Mandatory = $true)][string]$guid
    )

    $output = powercfg /query $guid SUB_PROCESSOR PROCTHROTTLEMAX
    foreach ($line in $output) {
        if ($line -match "Current AC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
            return [Convert]::ToInt32($matches[1], 16)
        }
    }
}


function Set-Max-CPU-State
{
    param([int]$state, $guid)
    powercfg -setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMAX $state
    powercfg -setdcvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMAX $state
    powercfg -setactive $guid
}

function Set-Min-CPU-State
{
    param([int]$state, $guid)
    powercfg -setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMIN $state
    powercfg -setdcvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMIN $state
    powercfg -setactive $guid
}

function Get-CPU-Temp
{
    param($computer)
    
    $temp = 100 # in case it reads it wrong, better lower the usage rather than rasing it
    $is_set = 0
    
    $dllName = [System.IO.Path]::GetFileName($hardware_monitor_dll_path)
    switch ($dllName) {
        "LibreHardwareMonitorLib.dll" {
            foreach ($hardware in $computer.Hardware) {
                if ($hardware.HardwareType -eq [LibreHardwareMonitor.Hardware.HardwareType]::Cpu) {
                    $hardware.Update()
                    foreach ($sensor in $hardware.Sensors) {
                        if ($sensor.SensorType -eq [LibreHardwareMonitor.Hardware.SensorType]::Temperature) {
                            $temp = [int]$sensor.Value
                            $is_set = 1
                        }
                    }
                }
            }
        }
        "OpenHardwareMonitorLib.dll"{
            foreach ($hardware in $computer.Hardware) {
                if ($hardware.HardwareType -eq [OpenHardwareMonitor.Hardware.HardwareType]::CPU) {
                    $hardware.Update()
                    foreach ($sensor in $hardware.Sensors) {
                        if ($sensor.SensorType -eq [OpenHardwareMonitor.Hardware.SensorType]::Temperature) {
                            $temp = [int]$sensor.Value
                            $is_set = 1
                        }
                    }
                }
            }
        }
        default{
            Write-Host 'Unsported Hardware Monitor dll in hardware_monitor_dll_path. Setting CPU temp to 100 to force minimum cpu state...' -ForegroundColor Black -BackgroundColor Red
        }
    }
    
    if ($is_set -eq 0){
        Write-Host 'Could not read CPU temp, check hardware_monitor_dll_path or switch to a different hardware monitor! Setting CPU temp to 100 to force minimum cpu state...' -ForegroundColor Black -BackgroundColor Red
    }

    return $temp
}

# Error checking
if (Is-Invalid-Params){
    exit
}

# Initialize the Computer object
Add-Type -Path $hardware_monitor_dll_path
$computer = $null
$dllName = [System.IO.Path]::GetFileName($hardware_monitor_dll_path)
switch ($dllName) {
    "LibreHardwareMonitorLib.dll"{
        $computer = New-Object -TypeName LibreHardwareMonitor.Hardware.Computer
        $computer.IsCpuEnabled = $true
    }
    "OpenHardwareMonitorLib.dll"{
        $computer = New-Object -TypeName OpenHardwareMonitor.Hardware.Computer
        $computer.CPUEnabled = $true
    }
}
$computer.Open()

# Getting power plan GUID
$plan_guid = powercfg /list | ForEach-Object {
    if ($_ -match "Power Scheme GUID: ([a-f0-9\-]+).*?\($power_plan_name\)") {
        return $matches[1]
    }
}

# Setting initial CPU states
Set-Min-CPU-State -state $min_cpu_state -guid $plan_guid
Set-Max-CPU-State -state $max_cpu_state -guid $plan_guid

$current_max_state = $max_cpu_state
$last_state = $current_max_state

# MAIN LOOP
while(1)
{
    clear
    
    Write-Host " ------------------------- CPU State Manager ------------------------- "
    Write-Host ""

    # Setting CPU temp
    $cpu_temp = (Get-CPU-Temp -computer $computer)
    $color = [System.ConsoleColor]::Cyan
    if ($cpu_temp -gt 69){
        $color = [System.ConsoleColor]::Yellow
        if ($cpu_temp -gt 85){
            $color = [System.ConsoleColor]::Red
        }
    }
    Write-Host "CPU: $($cpu_temp)°C " -ForegroundColor $color -NoNewline
    Write-Host "| Target: $($target_temp)°C"


    $step_time = 0
    $arrow = '-'

    # Danger temp edge case
    if ($cpu_temp -eq $danger_temp){
        $arrow = '!'
        Set-Max-CPU-State -state $min_cpu_state -guid $plan_guid
        Write-Host "CPU State: $($current_max_state)% $arrow" -ForegroundColor Red
        Start-Sleep -Milliseconds $time_beteween_steps_danger
        continue
    }
    
    # Handling CPU state based on temperature
    $color = [System.ConsoleColor]::White

    if ($cpu_temp -le $target_temp){ # If cpu temp less or equal to target temp
        $step_time = Lerp -a $time_beteween_steps_increase_min -b $time_beteween_steps_increase_max -t (($target_temp - $cpu_temp)/$easing_range)
        $arrow = '^'
        $current_max_state += $step_size
        if ($current_max_state -gt $max_cpu_state){
            $current_max_state = $max_cpu_state
            $arrow = '-'
        }else{
            $color = [System.ConsoleColor]::Green
        }
    }
    elseif ($cpu_temp -gt $target_temp){ # If cpu temp greater than target temp
        $step_time = Lerp -a $time_beteween_steps_decrease_max -b $time_beteween_steps_decrease_min -t (($cpu_temp - $target_temp)/$easing_range)
        $arrow = 'v'
        $current_max_state -= $step_size
        if ($current_max_state -lt $min_cpu_state){
            $current_max_state = $min_cpu_state
            $arrow = '-'
        }
        else{
            $color = [System.ConsoleColor]::Magenta
        }
    }

    # update the state
    if ($current_max_state -ne $last_state){ # if there was a change in state
        $last_state = $current_max_state
        Set-Max-CPU-State -state $current_max_state -guid $plan_guid
    }

    Write-Host "CPU State: $($current_max_state)% $arrow" -ForegroundColor $color


    # Getting actual CPU state

    $actual_cpu_state = Get-Max-CPU-State -guid $plan_guid

    Write-Host ""
    Write-Host " ----------------------------- DEBUGGING ----------------------------- "
    Write-Host ""
    Write-Host "Actual CPU State: $($actual_cpu_state)%

(IMPORTANT: if 'Actual CPU State' does not match CPU State above,
then simply switch to another power plan in windows settings and back 
to your custom one while the app is running)"

    Start-Sleep -Milliseconds $step_time
}

$computer.Close()
