f:=440
ms:=10000
s:=$(shell echo "scale=3; $(ms) / 1000" | bc | awk '{printf "%.3f\n", $$0}')
sr:=48000
codec:=pcm_s24le
bps:=$(shell echo $(codec) | sed -e 's/[^0-9]//g')
mode:=stereo
ifeq ($(mode),mono)
	ch:=1
else
	ch:=2
endif

sine_wav:=sine-$(mode)-$(f)Hz-$(ms)ms-$(sr)Hz-$(codec).wav
silence_wav:=silence-$(mode)-$(ms)ms-$(sr)Hz-$(codec).wav
noise_wav:=noise-$(mode)-$(ms)ms-$(sr)Hz-$(codec).wav

noise_header_size=$(shell du -b noise_header.tmp | awk '{print $$1}')
noise_data_size=$(shell du -b noise_empty.tmp | awk '{print $$1-$(noise_header_size)}')

config:
	@echo frequency=$(f)
	@echo millisecond=$(ms)
	@echo samplerate=$(sr)
	@echo codec=$(codec)
	@echo mode=$(mode)
	@echo bytes/ms=$(shell echo "scale=3; $(ch) * $(sr) * $(bps) / 8 / 1000" | bc)
#	bytes/msに端数がある場合、この形式ではミリ秒は正確に記録されない。

# 正弦波
sine: $(sine_wav)
$(sine_wav):
	ffmpeg -y -f lavfi -i sine=frequency=$(f):sample_rate=$(sr):duration=$(s) -ac $(ch) -acodec $(codec) $@

# 無音
silence: $(silence_wav)
$(silence_wav):
	ffmpeg -y -f lavfi -i anullsrc=channel_layout=$(mode):sample_rate=$(sr):duration=$(s) -ac $(ch) -acodec $(codec) $@

# ノイズ
noise: $(noise_wav)
$(noise_wav): noise_header.tmp noise_data.tmp
#	結合
	cat $^ > $@
	rm -f *.tmp
noise_header.tmp: noise_empty.tmp
#	ヘッダを切り出し
#	サブチャンク識別子'data', サブチャンクサイズ4byte
	perl -pe s/\(data.{4}\).*$$/\$$1/ $< > $@
noise_empty.tmp: $(silence_wav)
#	空白のwavファイルを生成
	mv $< $@
noise_data.tmp: noise_empty.tmp noise_header.tmp
#	ノイズ部分を生成
	dd if=/dev/urandom of=$@ bs=256M iflag=count_bytes count=$(noise_data_size)

.PHONY: clean
clean:
	rm -f *.wav *.tmp