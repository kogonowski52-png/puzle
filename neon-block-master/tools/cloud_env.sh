#!/usr/bin/env bash
# Source this file in the prepared cloud machine; no credentials are embedded.
export XDG_CONFIG_HOME=/workspace/toolchain/godot-config
export XDG_DATA_HOME=/workspace/toolchain/godot-data
export XDG_CACHE_HOME=/workspace/toolchain/cache
export GRADLE_USER_HOME=/workspace/toolchain/gradle
export ANDROID_HOME=/workspace/toolchain/android-sdk
export JAVA_HOME=/workspace/toolchain/jdk/root/usr/lib/jvm/java-21-openjdk-amd64
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
