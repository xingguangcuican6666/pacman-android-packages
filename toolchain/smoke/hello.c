#include <stdio.h>

#ifndef PACMAN_ANDROID_TARGET
#define PACMAN_ANDROID_TARGET "unknown"
#endif

#ifndef PACMAN_ANDROID_ROOTDIR
#define PACMAN_ANDROID_ROOTDIR "/data/adb/pacman"
#endif

int main(void) {
    printf("pacman-android smoke target=%s rootdir=%s\n",
           PACMAN_ANDROID_TARGET,
           PACMAN_ANDROID_ROOTDIR);
    return 0;
}
