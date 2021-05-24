# frequency of sine wave
FREQUENCY:=440

# duration(ms)
DURATION:=1000

SAMPLES_PER_SEC:=48000
BITS_PER_SAMPLE:=24

# mono/stereo
CHANNEL_LAYOUT:=stereo

FFMPEG=ffmpeg -y -loglevel warning

SEC:=$(shell echo "scale=3; $(DURATION) / 1000" | bc | awk '{printf "%.3f\n", $$0}')
#	see also ffmpeg document
CODEC:=pcm_s$(BITS_PER_SAMPLE)le
ifeq ($(CHANNEL_LAYOUT),mono)
	CHANNEL:=1
else
	CHANNEL:=2
endif
OPT:=-ac $(CHANNEL) -acodec $(CODEC)

# oscillator
OSC_SINE:=-f lavfi -i sine=frequency=$(FREQUENCY):sample_rate=$(SAMPLES_PER_SEC):duration=$(SEC)
OSC_SILENCE:=-f lavfi -i anullsrc=channel_layout=$(CHANNEL_LAYOUT):sample_rate=$(SAMPLES_PER_SEC):duration=$(SEC)

# default output name
SINE_WAV:=sine-$(FREQUENCY)Hz-$(DURATION)ms-$(SAMPLES_PER_SEC)Hz-$(CODEC)-$(CHANNEL_LAYOUT).wav
SILENCE_WAV:=silence-$(DURATION)ms-$(SAMPLES_PER_SEC)Hz-$(CODEC)-$(CHANNEL_LAYOUT).wav
NOISE_WAV:=noise-$(DURATION)ms-$(SAMPLES_PER_SEC)Hz-$(CODEC)-$(CHANNEL_LAYOUT).wav

noise_header_size=$(shell du -b noise_header.tmp | awk '{print $$1}')
noise_data_size=$(shell du -b noise_empty.tmp | awk '{print $$1-$(noise_header_size)}')

config:
	@echo -e "FREQUENCY\t= $(FREQUENCY)"
	@echo -e "DURATION\t= $(DURATION)"
	@echo -e "SAMPLES_PER_SEC\t= $(SAMPLES_PER_SEC)"
	@echo -e "BITS_PER_SAMPLE\t= $(BITS_PER_SAMPLE)"
	@echo -e "CHANNEL_LAYOUT\t= $(CHANNEL_LAYOUT)"
	@echo -e "bytes/ms\t= $(shell echo "scale=3; $(CHANNEL) * $(SAMPLES_PER_SEC) * $(BITS_PER_SAMPLE) / 8 / 1000" | bc)"
#	bytes/msに端数がある場合、この形式ではミリ秒は正確に記録されない。

.PHONY: sine
.PHONY: silence
.PHONY: noise

# 正弦波
sine: $(SINE_WAV)
$(SINE_WAV):
	$(FFMPEG) $(OSC_SINE) $(OPT) $@

# 無音
silence: $(SILENCE_WAV)
$(SILENCE_WAV):
	$(FFMPEG) $(OSC_SILENCE) $(OPT) $@

# ノイズ
noise: $(NOISE_WAV)
$(NOISE_WAV): noise_header.tmp noise_data.tmp
#	結合
	cat $^ > $@

.INTERMEDIATE: noise_header.tmp noise_empty.tmp noise_data.tmp
noise_header.tmp: noise_empty.tmp
#	ヘッダを切り出し
#	サブチャンク識別子'data', サブチャンクサイズ4byte
	perl -pe s/\(data.{4}\).*$$/\$$1/ $< > $@
noise_empty.tmp:
#	空白のwavファイルを生成
	$(FFMPEG) $(OSC_SILENCE) $(OPT) noise_empty.wav
	mv noise_empty.wav $@
noise_data.tmp: noise_empty.tmp noise_header.tmp
#	ノイズ部分を生成
	dd if=/dev/urandom of=$@ bs=256M iflag=count_bytes count=$(noise_data_size)

.PHONY: clean
clean:
	rm -f *.wav *.tmp