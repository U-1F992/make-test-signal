f=440
ms=10000
s=$(shell echo "scale=3; $(ms) / 1000" | bc | awk '{printf "%.3f\n", $$0}')
sr=48000
codec=pcm_s24le
default=stereo

config:
	@echo frequency=$(f)
	@echo millisecond=$(ms)
	@echo samplerate=$(sr)
	@echo codec=$(codec)
	@echo default=$(default)

sine:
ifeq (default,mono)
	make sine-mono
else
	make sine-stereo
endif

sine-mono: sine-mono-$(f)-$(ms)-$(sr)-$(codec).wav
sine-mono-$(f)-$(ms)-$(sr)-$(codec).wav:
	ffmpeg -y -f lavfi -i sine=frequency=$(f):sample_rate=$(sr):duration=$(s) -ac 1 -acodec $(codec) sine-mono-$(f)Hz-$(ms)ms-$(sr)Hz-$(codec).wav

sine-stereo: sine-stereo-$(f)-$(ms)-$(sr)-$(codec).wav
sine-stereo-$(f)-$(ms)-$(sr)-$(codec).wav:
	ffmpeg -y -f lavfi -i sine=frequency=$(f):sample_rate=$(sr):duration=$(s) -ac 2 -acodec $(codec) sine-stereo-$(f)Hz-$(ms)ms-$(sr)Hz-$(codec).wav

.PHONY: clean
clean:
	rm -f *.wav