# 🛡️ KSU Hide Root v2.0

Module KSU custom untuk hide root + boot integrity. Built fresh 2026 (bukan Shamiko clone).

## Apa yang dilakukan
- **Resetprop** boot/integrity props ke GREEN (locked + verified + enforcing)
- **Warranty bits** di-nolkan (seperti HP baru)
- **Debug flags** dimatikan (debuggable=0, secure=1)
- **Build type** user + release-keys (bukan userdebug)
- **Ksu binary rename** `/data/adb/ksu/su` → `ks` (anti-detect)
- **Log** ke `/data/adb/KSU-HideRoot-Logs/service.log`

## Install
1. Copy `ksu-hide-root.zip` ke HP
2. KSU Manager → Modules → Install from storage
3. Reboot
4. Cek log: `cat /data/adb/KSU-HideRoot-Logs/service.log`

## Structure
```
ksu-hide-root/
├── module.prop         # KSU metadata
├── post-fs-data.sh     # Boot-time props reset
├── service.sh          # Runtime persist + log
└── system.prop         # Persistent props
```

## PENTING
- Module ini TIDAK handle Play Integrity (tingkat device attestation). Pair dengan PIF module untuk full device spoofing.
- TIDAK ada LSPosed hook. Pure resetprop + file rename.
- Works on KSU + ReZygisk environment.

## Build ZIP
```bash
cd ksu-hide-root && zip -r ../ksu-hide-root.zip .
```

## Author
Nayeon ✦ — nayeon-agent/ksu-hide-root