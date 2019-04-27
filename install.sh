#!/bin/bash

echo " - Installing dependencies"
sudo apt-get install git-core

git clone https://github.com/emscripten-core/emsdk.git
cd emsdk

./emsdk update
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh