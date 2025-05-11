# This script is used to reset your Power Plan max state when youre done with CPU State Manager


################ PARAMETERS ################

$default_cpu_max_state = 99
$power_plan_name = 'MyPowerSaver'

################ PARAMETERS ################


$guid = powercfg /list | ForEach-Object {
    if ($_ -match "Power Scheme GUID: ([a-f0-9\-]+).*?\($power_plan_name\)") {
        return $matches[1]
    }
}


powercfg -setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMAX $default_cpu_max_state
powercfg -setdcvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMAX $default_cpu_max_state
powercfg -setactive $guid