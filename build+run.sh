#!/bin/sh

killall cocoahub
if [ ! -d bin ]; then
	mkdir bin
fi
pod install
pod update
xcodebuild -workspace cocoahub.xcworkspace/ -scheme cocoahub install "DSTROOT=./bin" "INSTALL_PATH=/"
bin/cocoahub > /dev/null 2>&1 &