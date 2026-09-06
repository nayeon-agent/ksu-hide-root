#!/system/bin/sh
MODPATH="${0%/*}"

# === BOOTLOADER / INTEGRITY (Green path) ===
resetprop ro.boot.vbmeta.device_state locked
resetprop ro.boot.verifiedbootstate green
resetprop ro.boot.flash.locked 1
resetprop ro.boot.veritymode enforcing

# === WARRANTY CLEAR ===
resetprop ro.boot.warranty_bit 0
resetprop ro.warranty_bit 0
resetprop ro.vendor.boot.warranty_bit 0
resetprop ro.vendor.warranty_bit 0

# === DEBUG / SECURE ===
resetprop ro.debuggable 0
resetprop ro.force.debuggable 0
resetprop ro.secure 1
resetprop ro.adb.secure 1

# === BUILD TYPE (user = no root indicator) ===
resetprop ro.build.type user
resetprop ro.build.tags release-keys

# === SELINUX ===
resetprop ro.boot.selinux enforcing

# === DELETE LEAKY PROPS ===
resetprop --delete ro.boot.verifiedbooterror
resetprop --delete ro.bootloader.lockdowned

# === PRE-EMPTIVE SELINUX CONTEXT FIX ===
# Set KSU paths to system-level context before app can probe.
# Luna (and similar detectors) read SELinux xattr via stat()/getfilecon()
# to fingerprint rooted devices. Stock unrooted never sees /data/adb/ksu.
# By re-labelling, we make the context match a benign system path.
sleep 2  # let KSU finish its early mounts

if [ -d /data/adb/ksu ]; then
    # Re-label KSU tree to a benign userdata context
    chcon -R u:object_r:system_data_file:s0 /data/adb/ksu 2>/dev/null
    chcon -R u:object_r:system_data_file:s0 /data/adb/modules 2>/dev/null
fi