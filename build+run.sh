#!/bin/sh

killall cocoahub
if [ ! -d bin ]; then
	mkdir bin
fi
pod install
pod update
xcodebuild -workspace cocoahub.xcworkspace/ -scheme cocoahub install "DSTROOT=./bin" "INSTALL_PATH=/"
bin/cocoahub 2&>1 >/dev/null  &