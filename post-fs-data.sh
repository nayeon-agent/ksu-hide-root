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