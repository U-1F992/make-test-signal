# wav-generator

Simple command-line oscillator

## Requirements
- make
- ffmpeg

## Configuration
```Makefile
# frequency of sine wave
FREQUENCY:=440

# duration
DURATION:=10000
SEC:=$(shell echo "scale=3; $(DURATION) / 1000" | bc | awk '{printf "%.3f\n", $$0}')

# sampling rate
SAMPLES_PER_SEC:=48000
# bit rate
# see also ffmpeg document
CODEC:=pcm_s24le
BITS_PER_SAMPLE:=$(shell echo $(CODEC) | sed -e 's/[^0-9]//g')

# mono/stereo
LAYOUT:=stereo
ifeq ($(LAYOUT),mono)
	CHANNEL:=1
else
	CHANNEL:=2
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
