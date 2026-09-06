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

# === HIDE KSU BINARY FROM APP SCAN ===
# Rename su binary path (common detection vector)
if [ -f "/data/adb/ksu/su" ]; then
    mv /data/adb/ksu/su /data/adb/ksu/ks 2>/dev/null
    log "[RENAMED] /data/adb/ksu/su → ks"
fi

log "[DONE] KSU Hide Root active"