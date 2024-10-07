#!/bin/bash
rm -f lastcall.zip
../../../bin2wav/bin2wav.js -n ilneresteplusque7jours ringu.rom ringu.wav
zip lastcall.zip ringu.{asm,nfo,rom,wav} -z < ringu.nfo
unzip -t retrograd-lastcall.zip
