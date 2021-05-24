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

SINE_WAV:=sine-$(FREQUENCY)Hz-$(DURATION)ms-$(SAMPLES_PER_SEC)Hz-$(CODEC)-$(LAYOUT).wav
SILENCE_WAV:=silence-$(DURATION)ms-$(SAMPLES_PER_SEC)Hz-$(CODEC)-$(LAYOUT).wav
NOISE_WAV:=noise-$(DURATION)ms-$(SAMPLES_PER_SEC)Hz-$(CODEC)-$(LAYOUT).wav

noise_header_size=$(shell du -b noise_header.tmp | awk '{print $$1}')
noise_data_size=$(shell du -b noise_empty.tmp | awk '{print $$1-$(noise_header_size)}')

config:
	@echo frequency=$(FREQUENCY)
	@echo millisecond=$(DURATION)
	@echo samplerate=$(SAMPLES_PER_SEC)
	@echo codec=$(CODEC)
	@echo mode=$(LAYOUT)
	@echo bytes/ms=$(shell echo "scale=3; $(CHANNEL) * $(SAMPLES_PER_SEC) * $(BITS_PER_SAMPLE) / 8 / 1000" | bc)
#	bytes/msに端数がある場合、この形式ではミリ秒は正確に記録されない。

# 正弦波
sine: $(SINE_WAV)
$(SINE_WAV):
	ffmpeg -y -f lavfi -i sine=frequency=$(FREQUENCY):sample_rate=$(SAMPLES_PER_SEC):duration=$(SEC) -ac $(CHANNEL) -acodec $(CODEC) $@

# 無音
silence: $(SILENCE_WAV)
$(SILENCE_WAV):
	ffmpeg -y -f lavfi -i anullsrc=channel_layout=$(LAYOUT):sample_rate=$(SAMPLES_PER_SEC):duration=$(SEC) -ac $(CHANNEL) -acodec $(CODEC) $@

# ノイズ
noise: $(NOISE_WAV)
$(NOISE_WAV): noise_header.tmp noise_data.tmp
#	結合
	cat $^ > $@
	rm -f *.tmp
noise_header.tmp: noise_empty.tmp
#	ヘッダを切り出し
#	サブチャンク識別子'data', サブチャンクサイズ4byte
	perl -pe s/\(data.{4}\).*$$/\$$1/ $< > $@
noise_empty.tmp:
#	空白のwavファイルを生成
	ffmpeg -y -f lavfi -i anullsrc=channel_layout=$(LAYOUT):sample_rate=$(SAMPLES_PER_SEC):duration=$(SEC) -ac $(CHANNEL) -acodec $(CODEC) noise_empty.wav
	mv noise_empty.wav $@
noise_data.tmp: noise_empty.tmp noise_header.tmp
#	ノイズ部分を生成
	dd if=/dev/urandom of=$@ bs=256M iflag=count_bytes count=$(noise_data_size)

.PHONY: clean
clean:
	rm -f *.wav *.tmp