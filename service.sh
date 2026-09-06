#!/system/bin/sh
MODPATH="${0%/*}"
LOG_DIR="/data/adb/KSU-HideRoot-Logs"
mkdir -p "$LOG_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_DIR/service.log"
}

# Wait for boot complete
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 8

# === PERSIST PROPS (re-apply after boot) ===
for prop_tuple in \
    "ro.boot.vbmeta.device_state=locked" \
    "ro.boot.verifiedbootstate=green" \
    "ro.boot.flash.locked=1" \
    "ro.boot.veritymode=enforcing" \
    "ro.debuggable=0" \
    "ro.force.debuggable=0" \
    "ro.secure=1" \
    "ro.adb.secure=1" \
    "ro.build.type=user" \
    "ro.build.tags=release-keys" \
    "ro.boot.warranty_bit=0" \
    "ro.warranty_bit=0" \
; do
    p="${prop_tuple%%=*}"
    v="${prop_tuple#*=}"
    [ "$(getprop "$p")" != "$v" ] && resetprop "$p" "$v" && log "[SET] $p = $v"
done

# === FIX SELINUX CONTEXT (Luna detection) ===
# Luna checks SELinux context of KSU/Magisk binaries. Set them to stock unrooted context.
# Unrooted Android has no /data/adb/ksu at all, so context inherits default.
# We delete the KSU path and let it be recreated fresh on next root call,
# OR we can set SELinux context to match a system_app_data_file.

# Move su binary to hidden location + chcon to default
if [ -f "/data/adb/ksu/su" ]; then
    # Set SELinux context to match system unrooted (default system label)
    chcon u:object_r:system_app_data_file:s0 /data/adb/ksu/su 2>/dev/null && log "[CHCON] su → system_app_data_file"
    chcon u:object_r:system_app_data_file:s0 /data/adb/ksu/* 2>/dev/null
    chcon -R u:object_r:system_app_data_file:s0 /data/adb/ksu 2>/dev/null
    log "[CHCON] /data/adb/ksu → system_app_data_file"
fi

# Hide KSU module path
if [ -d "/data/adb/modules" ]; then
    # Modules dir is normal userdata, but Luna may scan it
    chcon -R u:object_r:system_data_file:s0 /data/adb/modules 2>/dev/null
    log "[CHCON] modules → system_data_file"
fi

# Hide /proc mount entries related to overlay
# (KSU uses overlayfs on /data/adb/ksu, /data/adb/modules)
# We can rename to avoid name-based detection
if [ -d "/data/adb/ksu" ]; then
    # Luna path checks likely include: /data/adb/ksu, /data/adb/modules
    # Use bind mount to hide, but that's complex; try chcon first
    chcon u:object_r:system_data_file:s0 /data/adb 2>/dev/null
    log "[CHCON] /data/adb → system_data_file"
fi

log "[DONE] KSU Hide Root active (SELinux-aware)"