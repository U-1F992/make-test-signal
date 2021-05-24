# make-test-signal

Simple command-line oscillator

## Requirements
- make
- ffmpeg
- perl

## Configuration
```Makefile
# frequency of sine wave
FREQUENCY:=440

# duration(ms)
DURATION:=1000

SAMPLES_PER_SEC:=48000
BITS_PER_SAMPLE:=24

# mono/stereo
CHANNEL_LAYOUT:=stereo
```

## Usage

```bash
# show configuration
make config

# generate wav file
make sine FREQUENCY=880 DURATION=500
make silence SAMPLES_PER_SEC=44100 BITS_PER_SAMPLE=16
make noise CHANNEL_LAYOUT=mono

# remove *.wav files
make clean
```
