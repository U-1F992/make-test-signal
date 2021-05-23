f:=440
ms:=10000
s:=$(shell echo "scale=3; $(ms) / 1000" | bc | awk '{printf "%.3f\n", $$0}')
sr:=48000
codec:=pcm_s24le
bps:=24
mode:=stereo
ifeq ($(mode),mono)
	ch:=1
else
	ch:=2
endif

noise_header_size=$(shell du -b noise_header.tmp | awk '{print $$1}')
noise_data_size=$(shell du -b noise_empty.tmp | awk '{print $$1-$(noise_header_size)}')

config:
	@echo frequency=$(f)
	@echo millisecond=$(ms)
	@echo samplerate=$(sr)
	@echo codec=$(codec)
	@echo mode=$(mode)
	@echo bytes/ms=$(shell echo "scale=3; $(ch) * $(sr) * $(bps) / 8 / 1000" | bc)
# bytes/msに端数がある場合、この形式ではミリ秒は正確に記録されない。

# 正弦波
sine: sine-$(mode)-$(f)Hz-$(ms)ms-$(sr)Hz-$(codec).wav
sine-$(mode)-$(f)Hz-$(ms)ms-$(sr)Hz-$(codec).wav:
	ffmpeg -y -f lavfi -i sine=frequency=$(f):sample_rate=$(sr):duration=$(s) -ac $(ch) -acodec $(codec) sine-$(mode)-$(f)Hz-$(ms)ms-$(sr)Hz-$(codec).wav

# 無音
silence: silence-$(mode)-$(ms)ms-$(sr)Hz-$(codec).wav
silence-$(mode)-$(ms)ms-$(sr)Hz-$(codec).wav:
	ffmpeg -y -f lavfi -i anullsrc=channel_layout=$(mode):sample_rate=$(sr):duration=$(s) -ac $(ch) -acodec $(codec) silence-$(mode)-$(ms)ms-$(sr)Hz-$(codec).wav

# ノイズ
noise: noise-$(mode)-$(ms)ms-$(sr)Hz-$(codec).wav
noise-$(mode)-$(ms)ms-$(sr)Hz-$(codec).wav: noise_header.tmp noise_data.tmp
#	結合
	cat noise_header.tmp noise_data.tmp > noise-$(mode)-$(ms)ms-$(sr)Hz-$(codec).wav
	rm -f *.tmp
noise_header.tmp: noise_empty.tmp
#	ヘッダを切り出し
#	サブチャンク識別子'data', サブチャンクサイズ4byte
	perl -pe s/\(data.{4}\).*$$/\$$1/ noise_empty.tmp > noise_header.tmp
noise_empty.tmp:
#	空白のwavファイルを生成
	ffmpeg -y -f lavfi -i anullsrc=channel_layout=$(mode):sample_rate=$(sr):duration=$(s) -ac $(ch) -acodec $(codec) noise_empty.wav
	mv noise_empty.wav noise_empty.tmp
noise_data.tmp: noise_empty.tmp noise_header.tmp
#	ノイズ部分を生成
	dd if=/dev/urandom of=noise_data.tmp bs=256M iflag=count_bytes count=$(noise_data_size)

.PHONY: clean
clean:
	rm -f *.wav *.tmp