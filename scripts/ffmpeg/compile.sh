#!/usr/bin/env bash
# Compiles CompressO's ffmpeg & ffprobe inside a BtbN FFmpeg-Builds image (see `build.sh`), whose
# libraries are already compiled. Only what CompressO uses is included, so the binaries stay small.
#
# The image provides the cross-compiler settings (`FFBUILD_TARGET_FLAGS`, `CC`, ...) & every
# library's configure option (`FF_CONFIGURE`); options of libraries not in `ALLOWED` are dropped.
#
# Env: TARGET (win64 | linux64), VERSION (an FFmpeg release, e.g. 8.1.3). Output: /out
set -euo pipefail

# Codecs & hardware encoders CompressO uses (see its `src-tauri/src/core/ffmpeg.rs` &
# `hardware_encoder.rs`). The app only uses ffmpeg's built-in filters.
ALLOWED=" gpl version3 \
  libx264 libx265 libsvtav1 libaom libvpx libdav1d \
  libmp3lame libopus libvorbis \
  zlib iconv \
  ffnvcodec libvpl amf vaapi libdrm "

CONFIGURE=()
for option in $FF_CONFIGURE; do
  case "$option" in
    --enable-*)
      name="${option#--enable-}"
      if [[ "$ALLOWED" == *" $name "* ]]; then CONFIGURE+=("$option"); fi
      ;;
    *) CONFIGURE+=("$option") ;;
  esac
done

# Nothing is added by itself (e.g. Vulkan, X11, network), only the above & the GPU encoders
CONFIGURE+=(--disable-autodetect --disable-network --disable-ffplay --disable-doc --disable-debug --enable-nvenc)
if [[ "$TARGET" == win64 ]]; then
  # Windows hardware decoding
  CONFIGURE+=(--enable-d3d11va --enable-dxva2)
fi

# The images' iconv is GNU libiconv (its header renames `iconv_open` to `libiconv_open`), which BtbN's
# full build links through other libraries (e.g. libxml2); without them, it is linked here (`-liconv`)

cd /tmp
rm -rf ffmpeg prefix
git clone --depth 1 --branch "n$VERSION" https://github.com/FFmpeg/FFmpeg.git ffmpeg
cd ffmpeg

echo "configure: $FFBUILD_TARGET_FLAGS ${CONFIGURE[*]}"
# shellcheck disable=SC2086
./configure --prefix=/tmp/prefix --pkg-config-flags="--static" $FFBUILD_TARGET_FLAGS "${CONFIGURE[@]}" \
  --extra-cflags="${FF_CFLAGS:-}" --extra-cxxflags="${FF_CXXFLAGS:-}" --extra-libs="${FF_LIBS:-} -liconv" \
  --extra-ldflags="${FF_LDFLAGS:-}" --extra-ldexeflags="${FF_LDEXEFLAGS:-}" \
  --cc="$CC" --cxx="$CXX" --ar="$AR" --ranlib="$RANLIB" --nm="$NM" \
  --extra-version="compresso" || { tail -n 80 ffbuild/config.log; exit 1; }

make -j"$(nproc)"
make install

case "$TARGET" in
  win64) SUFFIX="x86_64-pc-windows-msvc.exe"; EXT=".exe" ;;
  linux64) SUFFIX="x86_64-unknown-linux-gnu"; EXT="" ;;
  *) echo "Unknown target: $TARGET"; exit 1 ;;
esac

mkdir -p /out
cp "/tmp/prefix/bin/ffmpeg$EXT" "/out/compresso_ffmpeg-$SUFFIX"
cp "/tmp/prefix/bin/ffprobe$EXT" "/out/compresso_ffprobe-$SUFFIX"
cp COPYING.GPLv3 /out/LICENSE-ffmpeg.txt
# What it was built with, for the release
# (`#define FFMPEG_CONFIGURATION "..."` in config.h)
sed -n 's/^#define FFMPEG_CONFIGURATION "\(.*\)"$/\1/p' config.h > /out/configuration.txt
chmod -R a+rw /out
ls -la /out
