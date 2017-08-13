@echo off


for /f %%o in ('adb shell su -c "find /sys/class/thermal/. -maxdepth 1 | wc -l"') do set i=%%o
set /a i-=2
set base_cmd=adb shell su -c "cat /sys/class/thermal/thermal_zone
set end_cmd=/temp"
echo total sensors: %i%
echo readings: 

set total=0


setlocal enabledelayedexpansion
set totalSensors=0
for /L %%f in (0,1,%i%) do (
	set "cmd=%base_cmd%%%f%end_cmd%"
	for /f %%o in ('!cmd!') do set /a tmp=%%o
	echo !tmp!
	if !tmp! LSS 200 (
		if !tmp! GTR 0 (
			set /a total+=!tmp!
			set /a totalSensors+=1
		)
	)
)

set /a avg=%total%/%totalSensors%
echo ---------------------
echo Average Temp: %avg% degC
echo ---------------------
pause