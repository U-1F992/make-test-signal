# wav-generator

Simple command-line oscillator

## Requirements
- make
- ffmpeg

## Configuration
```Makefile
# frequency of sine wave
f:=440

# duration
ms:=10000
s:=$(shell echo "scale=3; $(ms) / 1000" | bc | awk '{printf "%.3f\n", $$0}')

# sampling rate
sr:=48000
# bit rate
# see also ffmpeg document
codec:=pcm_s24le
bps:=$(shell echo $(codec) | sed -e 's/[^0-9]//g')

# mono/stereo
mode:=stereo
ifeq ($(mode),mono)
	ch:=1
else
	ch:=2
endif
```

## Usage

```bash
# show configuration
make config

# generate wav file
make sine
make silence
make noise

# remove *.wav files
make clean
```
