#!/bin/sh

cd ios
rm -rf Podfile.lock
pod deintegrate;
pod install --repo-update
cd ..
