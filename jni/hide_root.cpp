/* hide_root.cpp - Zygisk native module for KernelSU
 * Targets: Luna root detector (stat/fstat/lstat/access/getxattr)
 */
#include <sys/types.h>
#include <cerrno>
#include "zygisk.hpp"
#include <sys/stat.h>
#include <unistd.h>
#include <dlfcn.h>
#include <sys/xattr.h>
#include <cstring>
#include <cstdio>

// ---------- original pointers ----------
static int (*orig_stat)(const char *, struct stat *) = nullptr;
static int (*orig_fstat)(int, struct stat *) = nullptr;
static int (*orig_lstat)(const char *, struct stat *) = nullptr;
static int (*orig_access)(const char *, int) = nullptr;
static int (*orig_faccessat)(int, const char *, int, int) = nullptr;
static ssize_t (*orig_getxattr)(const char *, const char *, void *, size_t) = nullptr;

// ---------- helpers ----------
static bool is_root_path(const char *path) {
    if (!path) return false;
    if (strstr(path, "/data/adb/ksu")) return true;
    if (strstr(path, "/data/adb/modules")) return true;
    if (strstr(path, "/data/adb/magisk")) return true;
    if (strstr(path, "/proc/ksud")) return true;
    if (strstr(path, "/sbin/su")) return true;
    if (strstr(path, "/system/bin/su")) return true;
    if (strstr(path, "/system/xbin/su")) return true;
    if (strstr(path, "/system/su")) return true;
    if (strstr(path, "/vendor/bin/su")) return true;
    if (strstr(path, "/vendor/xbin/su")) return true;
    if (path[0] == '/' && path[1] == 's' && path[2] == 'u' && (path[3] == '\0' || path[3] == '/'))
        return true;
    return false;
}

// ---------- hook implementations ----------
static int hide_stat(const char *path, struct stat *buf) {
    if (is_root_path(path)) { errno = ENOENT; return -1; }
    int ret = orig_stat(path, buf);
    if (ret == 0 && buf) { buf->st_mode &= ~S_ISUID; buf->st_mode &= ~S_ISGID; }
    return ret;
}
static int hide_fstat(int fd, struct stat *buf) {
    int ret = orig_fstat(fd, buf);
    if (ret == 0 && buf) { buf->st_mode &= ~S_ISUID; buf->st_mode &= ~S_ISGID; }
    return ret;
}
static int hide_lstat(const char *path, struct stat *buf) {
    if (is_root_path(path)) { errno = ENOENT; return -1; }
    int ret = orig_lstat(path, buf);
    if (ret == 0 && buf) { buf->st_mode &= ~S_ISUID; buf->st_mode &= ~S_ISGID; }
    return ret;
}
static int hide_access(const char *path, int mode) {
    if (is_root_path(path)) { errno = ENOENT; return -1; }
    return orig_access(path, mode);
}
static int hide_faccessat(int dirfd, const char *path, int mode, int flags) {
    if (is_root_path(path)) { errno = ENOENT; return -1; }
    return orig_faccessat(dirfd, path, mode, flags);
}
static ssize_t hide_getxattr(const char *path, const char *name, void *value, size_t size) {
    if (name && strcmp(name, "security.selinux") == 0 && is_root_path(path)) {
        const char *benign = "u:object_r:system_data_file:s0";
        size_t len = strlen(benign);
        if (size == 0) return len;
        if (size < len) return -1;
        memcpy(value, benign, len);
        return len;
    }
    return orig_getxattr(path, name, value, size);
}

// ---------- module class ----------
class HideRootModule : public zygisk::ModuleBase {
public:
    void onLoad(zygisk::Api *api, JNIEnv *env) override { this->api = api; this->env = env; }

    void preAppSpecialize(zygisk::AppSpecializeArgs *args) override {
        (void)args;
        void *handle = dlopen("libc.so", RTLD_NOW);
        if (!handle) return;
        orig_stat   = (int(*)(const char*, struct stat*)) dlsym(handle, "stat");
        orig_fstat  = (int(*)(int, struct stat*)) dlsym(handle, "fstat");
        orig_lstat  = (int(*)(const char*, struct stat*)) dlsym(handle, "lstat");
        orig_access = (int(*)(const char*, int)) dlsym(handle, "access");
        orig_faccessat = (int(*)(int, const char*, int, int)) dlsym(handle, "faccessat");
        orig_getxattr = (ssize_t(*)(const char*, const char*, void*, size_t)) dlsym(handle, "getxattr");

        // Register PLT hooks – 0,0 lets Zygisk resolve the correct ELF automatically
        api->pltHookRegister(0, 0, "stat",       (void*)hide_stat,       (void**)&orig_stat);
        api->pltHookRegister(0, 0, "fstat",      (void*)hide_fstat,      (void**)&orig_fstat);
        api->pltHookRegister(0, 0, "lstat",      (void*)hide_lstat,      (void**)&orig_lstat);
        api->pltHookRegister(0, 0, "access",     (void*)hide_access,     (void**)&orig_access);
        api->pltHookRegister(0, 0, "faccessat",  (void*)hide_faccessat,  (void**)&orig_faccessat);
        api->pltHookRegister(0, 0, "getxattr",   (void*)hide_getxattr,   (void**)&orig_getxattr);
        api->pltHookCommit();
    }

private:
    zygisk::Api *api = nullptr;
    JNIEnv *env = nullptr;
};

REGISTER_ZYGISK_MODULE(HideRootModule)
