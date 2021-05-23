f=440
ms=10000
s=$(shell echo "scale=3; $(ms) / 1000" | bc | awk '{printf "%.3f\n", $$0}')
sr=48000
codec=pcm_s24le
mode=stereo
ifeq (mode,mono)
	ac=1
else
	ac=2
endif

config:
	@echo frequency=$(f)
	@echo millisecond=$(ms)
	@echo samplerate=$(sr)
	@echo codec=$(codec)
	@echo mode=$(mode)

sine:
	ffmpeg -y -f lavfi -i sine=frequency=$(f):sample_rate=$(sr):duration=$(s) -ac $(ac) -acodec $(codec) sine-$(mode)-$(f)Hz-$(ms)ms-$(sr)Hz-$(codec).wav

silence:
	ffmpeg -y -f lavfi -i anullsrc=channel_layout=$(mode):sample_rate=$(sr):duration=$(s) -ac 2 -acodec $(codec) silence-$(mode)-$(f)Hz-$(ms)ms-$(sr)Hz-$(codec).wav

.PHONY: clean
clean:
	rm -f *.wav