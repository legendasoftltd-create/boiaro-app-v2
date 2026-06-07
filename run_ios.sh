#!/bin/bash

# Helper script to run Boiaro on the iOS simulator while bypassing the WebKit dyld link error.
# This injects the simulator's host Cryptexes path where libswiftWebKit.dylib resides.

SIMCTL_CHILD_DYLD_FALLBACK_LIBRARY_PATH="/Library/Developer/CoreSimulator/Volumes/iOS_22F77/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 18.5.simruntime/Contents/Resources/RuntimeRoot/System/Cryptexes/OS/usr/lib/swift" flutter run "$@"
