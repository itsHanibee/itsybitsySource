#!/system/bin/sh
MODDIR=${0%/*}

# Maximum unsigned integer size in C
UINT_MAX="4294967295"

# Duration in nanoseconds of one scheduling period
SCHED_PERIOD="$((5 * 1000 * 1000))"

# How many tasks should we have at a maximum in one scheduling period
SCHED_TASKS="10"

# Execute script by tytydraco and his project ktweak, thanks! 
write() {
	# Bail out if file does not exist
	[[ ! -f "$1" ]] && return 1
	
	# Make file writable in case it is not already
	chmod +w "$1" 2> /dev/null

	# Write the new value and bail if there's an error
	if ! echo "$2" > "$1" 2> /dev/null
	then
		echo "Failed: $1 → $2"
		return 1
	fi
}

# Detect if we are running on Android
grep -q android /proc/cmdline && ANDROID=true

sleep 25

# Sync before execute to avoid crashes
sync

# logs ded
write /sys/kernel/tracing/tracing_on 0
su -c "stop tcpdump"
su -c "stop cnss_diag"
su -c "stop statsd"
su -c "stop traced"
su -c "stop idd-logreader"
su -c "stop idd-logreadermain"
su -c "stop perfd"
su -c "stop statscompanion"

# Disabling a little bit of Kernel Debugging stuff and Logs
echo "Y" > /sys/module/bluetooth/parameters/disable_ertm
echo "Y" > /sys/module/bluetooth/parameters/disable_esco
echo "0" > /sys/module/dwc3/parameters/ep_addr_rxdbg_mask
echo "0" > /sys/module/dwc3/parameters/ep_addr_txdbg_mask
echo "0" > /sys/module/dwc3_msm/parameters/disable_host_mode
echo "0" > /sys/module/wakelock/parameters/debug_mask
echo "0" > /sys/module/userwakelock/parameters/debug_mask
echo "0" > /sys/module/binder/parameters/debug_mask
echo "0" > /sys/module/debug/parameters/enable_event_log
echo "0" > /sys/module/glink/parameters/debug_mask
echo "N" > /sys/module/ip6_tunnel/parameters/log_ecn_error
echo "0" > /sys/module/msm_show_resume_irq/parameters/debug_mask
echo "0" > /sys/module/msm_smd_pkt/parameters/debug_mask
echo "N" > /sys/module/sit/parameters/log_ecn_error
echo "0" > /sys/module/smp2p/parameters/debug_mask
echo "0" > /sys/module/usb_bam/parameters/enable_event_log

# FSync OFF
echo "N" > /sys/module/sync/parameters/fsync_enabled

# Subsystem
echo "1" > /sys/module/subsystem_restart/parameters/disable_restart_work

# Kernel Panic (*pat pat* woa chill there pro dev, drink something before blood pressure spikes. will eventually write a toggle for this but seeing as how MOST kernel devs are competent to get their kernels stable ill leave this on as default for now)
for kernel in /proc/sys/kernel; do
    write $kernel/panic 0
    write $kernel/panic_on_oops 0
    write $kernel/panic_on_warn 0
    write $kernel/panic_on_rcu_stall 0
    write $kernel/softlockup_panic 0
    write $kernel/nmi_watchdog 0
done

for kernel in /sys/module/kernel; do
    write $kernel/parameters/panic 0
    write $kernel/parameters/panic_on_warn 0
    write $kernel/parameters/pause_on_oops 0
    write $kernel/panic_on_rcu_stall 0
done

# Disable CRC
for parameters in /sys/module/mmc_core/parameters; do
    write $parameters/use_spi_crc 0
    write $parameters/removable N
    write $parameters/crc N
done

# virtual memory parameters (custom)
for virtual_memory in /proc/sys/vm; do
    write $virtual_memory/stat_interval 10
    write $virtual_memory/vfs_cache_pressure 95
    write $virtual_memory/extfrag_threshold 750
    write $virtual_memory/oom_kill_allocating_task 0
    write $virtual_memory/oom_dump_tasks 0
    write $virtual_memory/reap_mem_on_sigkill 0
    write $virtual_memory/page-cluster 0
    write $virtual_memory/dirty_expire_centisecs 2000
    write $virtual_memory/dirty_writeback_centisecs 3000
done

echo "0" > /proc/sys/vm/block_dump
echo "1103" > /proc/sys/vm/stat_interval
echo "50" > /proc/sys/vm/overcommit_ratio
echo "24300" > /proc/sys/vm/extra_free_kbytes

#echo "64" > /proc/sys/kernel/random/read_wakeup_threshold
#echo "128" > /proc/sys/kernel/random/write_wakeup_threshold

# Disables Printk
write /proc/sys/kernel/printk 0 0 0 0
write /proc/sys/kernel/printk_devkmsg off
write /sys/kernel/printk_mode/printk_mode 0
echo "Y" > /sys/module/printk/parameters/console_suspend
echo "N" > /sys/module/printk/parameters/cpu
echo "Y" > /sys/module/printk/parameters/ignore_loglevel
echo "N" > /sys/module/printk/parameters/pid
echo "N" > /sys/module/printk/parameters/time

# Disable Debugging
write /sys/module/rpm_smd/parameters/debug_mask 0
write /sys/module/msm_show_resume_irq/parameters/debug_mask 0
write /sys/module/rmnet_data/parameters/rmnet_data_log_level 0
write /sys/module/ip6_tunnel/parameters/log_ecn_error 0

# Touchboost
write /sys/module/msm_performance/parameters/touchboost 0
write /sys/power/pnpmgr/touch_boost 0

# rip ramdumps
write /sys/module/subsystem_restart/parameters/enable_ramdumps 0
write /sys/module/subsystem_restart/parameters/enable_mini_ramdumps 0

# LMK
for parameters in /sys/module/lowmemorykiller/parameters; do
    write $parameters/debug_level 0
done

# LPM
for parameters in /sys/module/lpm_levels/parameters; do
    write $parameters/lpm_prediction 0
    write $parameters/lpm_ipi_prediction 0
done

# FS
for fs in /proc/sys/fs; do
    write $fs/dir-notify-enable 0
    write $fs/lease-break-time 20
    write $fs/by-name/userdata/iostat_enable 0
done

# I/O Optimization
for queue in /sys/block/*/queue; do
    write $queue/scheduler noop
    write $queue/iostats 0
    write $queue/read_ahead_kb 128
    write $queue/add_random 0
    write $queue/nomerges 0
    write $queue/nr_requests 512
    write $queue/rq_affinity 1
    write $queue/iosched/back_seek_penalty 1
done

echo $setiosched > /sys/block/mmcblk0/queue/scheduler
echo $setiosched > /sys/block/mmcblk0rpmb/queue/scheduler
echo $setiosched > /sys/block/mmcblk1/queue/scheduler

# GPU
for gpu in /sys/class/kgsl/kgsl-3d0; do
    write $gpu/snapshot/snapshot_crashdumper 0
    write $gpu/adrenoboost 0
    write $gpu/devfreq/adrenoboost 0
    write $gpu/adreno_idler_active N
done

# Schedutil
for cpu in /sys/devices/system/cpu/*/cpufreq/schedutil; do
    write $cpu/down_rate_limit_us 20000
    write $cpu/up_rate_limit_us 500
    write $cpu/hispeed_load 98
    write $cpu/pl 1
    write $cpu/iowait_boost_enable 0
done

for schedutil in /sys/devices/system/cpu/cpufreq/schedutil; do
    write $schedutil/down_rate_limit_us 20000
    write $schedutil/up_rate_limit_us 500
    write $schedutil/hispeed_load 98
    write $schedutil/pl 1
    write $schedutil/iowait_boost_enable 0
done

# Task Scheduler
echo "NO_GENTLE_FAIR_SLEEPERS" > /sys/kernel/debug/sched_features
echo "NO_HRTICK" > /sys/kernel/debug/sched_features
echo "NO_DOUBLE_TICK" > /sys/kernel/debug/sched_features
echo "NO_RT_RUNTIME_SHARE" > /sys/kernel/debug/sched_features
echo "NEXT_BUDDY" > /sys/kernel/debug/sched_features
echo "NO_TTWU_QUEUE" > /sys/kernel/debug/sched_features
echo "UTIL_EST" > /sys/kernel/debug/sched_features
echo "ARCH_CAPACITY" > /sys/kernel/debug/sched_features
echo "ARCH_POWER" > /sys/kernel/debug/sched_features
echo "ENERGY_AWARE" > /sys/kernel/debug/sched_features

# ipv4
for ipv4 in /proc/sys/net/ipv4; do
    write $ipv4/tcp_fastopen 3
    write $ipv4/tcp_ecn 1
    write $ipv4/tcp_syncookies 0
done

echo $settcpcong > /proc/sys/net/ipv4/tcp_congestion_control

# Optimize Network
echo "0" > "/proc/sys/net/ipv4/tcp_timestamps"
echo "1" > "/proc/sys/net/ipv4/tcp_tw_reuse"
echo "1" > "/proc/sys/net/ipv4/tcp_sack"
echo "4096,16384,404480" > "/proc/sys/net/ipv4/tcp_wmem"
echo "4096,87380,404480" > "/proc/sys/net/ipv4/tcp_rmem"

# Battery!
write /sys/module/workqueue/parameters/power_efficient Y

# kTweak (tytydraco) // slightly modified for garbage phones
write /proc/sys/kernel/perf_cpu_time_max_percent 3
write /proc/sys/kernel/sched_autogroup_enabled 1
write /proc/sys/kernel/sched_child_runs_first 0
write /proc/sys/kernel/sched_tunable_scaling 0
write /proc/sys/kernel/sched_latency_ns "$SCHED_PERIOD"
write /proc/sys/kernel/sched_min_granularity_ns "$((SCHED_PERIOD / SCHED_TASKS))"
write /proc/sys/kernel/sched_wakeup_granularity_ns "$((SCHED_PERIOD / 2))"
write /proc/sys/kernel/sched_migration_cost_ns 5000000
write /proc/sys/kernel/sched_min_task_util_for_colocation 0
write /proc/sys/kernel/sched_nr_migrate 128
write /proc/sys/kernel/sched_schedstats 0
write /proc/sys/vm/dirty_background_ratio 15
write /proc/sys/vm/dirty_ratio 30
write /proc/sys/vm/swappiness 100

#echo "3" > /proc/sys/vm/drop_caches 
# best if i disable for now, might do A/B testing down the road before i enable

##########
if [[ -f "/sys/kernel/debug/sched_features" ]]
then
	# Consider scheduling tasks that are eager to run
	write /sys/kernel/debug/sched_features NEXT_BUDDY

	# Schedule tasks on their origin CPU if possible
	write /sys/kernel/debug/sched_features TTWU_QUEUE
fi
##########

# Loop over each CPU in the system
for cpu in /sys/devices/system/cpu/cpu*/cpufreq
do
	# Fetch the available governors from the CPU
	avail_govs="$(cat "$cpu/scaling_available_governors")"

	# Attempt to set the governor in this order
	for governor in schedutil interactive
	do
		# Once a matching governor is found, set it and break for this CPU
		if [[ "$avail_govs" == *"$governor"* ]]
		then
			write "$cpu/scaling_governor" "$governor"
			break
		fi
	done
done

# Apply governor specific tunables for schedutil
find /sys/devices/system/cpu/ -name schedutil -type d | while IFS= read -r governor
do
	# Consider changing frequencies once per scheduling period
	write "$governor/up_rate_limit_us" "$((SCHED_PERIOD / 1000))"
	write "$governor/down_rate_limit_us" "$((4 * SCHED_PERIOD / 1000))"
	write "$governor/rate_limit_us" "$((SCHED_PERIOD / 1000))"

	# Jump to hispeed frequency at this load percentage
	write "$governor/hispeed_load" 98
done

# Unity/Unreal Engine tweaks (meh what even is the point)
#write /proc/sys/kernel/sched_lib_name "com.garena.game., com.garena., com.activision., com.miHoYo., com.riotgames., com.riotgames.league., com.mobile., com.mobile.legends, com.epicgames, UnityMain, libunity.so, libil2ccp.so, libmain.so, libcri_vip_unity.so, libopus.so, libxlua.so, libUE4.so, libAsphalt9.so, libnative-lib.so, libRiotGamesApi.so, libResources.so, libagame.so, libapp.so, libflutter.so, libMSDKCore.so, libFIFAMobileNeon.so, libUnreal.so, libEOSSDK.so, libcocos2dcpp.so"
#write /proc/sys/kernel/sched_lib_mask_force 255

# Thanks Saitama and Lazar // fixes a whole bunch of wonkiness on badly made roms sometimes
#su -c "cmd package bg-dexopt-job"

# cancer cure // sorry for any frustrations but this is for your own good
rm -rf /storage/emulated/0/Android/data/com.zhiliaoapp.musically/*
rm -rf /storage/emulated/0/Android/data/com.ss.android.ugc.trill/*

# Shell
su -lp 2000 -c "cmd notification post -S bigtext -t '🤏 itsy bitsy Tweaks!' 'Tag' 'successfully executed script at startup, have fun! 🥂'"

exit 0