# FFmpeg for CompressO

Builds the `ffmpeg` & `ffprobe` that [CompressO](https://github.com/codeforreal1/compressO) bundles
for Windows & Linux: static builds with only the codecs & hardware encoders the app uses, so they
stay small.

- **Codecs:** x264, x265, SVT-AV1, libaom, VP9 (libvpx), dav1d, MP3 (LAME), Opus, Vorbis
- **Hardware encoders:** NVIDIA (NVENC), Intel (QSV/libvpl), AMD (AMF, Windows), VAAPI (Linux)

They are compiled in [BtbN's FFmpeg-Builds](https://github.com/BtbN/FFmpeg-Builds) images, where
the libraries are already compiled (see `scripts/ffmpeg`).

## Building

Actions → **Build FFmpeg** → **Run workflow**, with an FFmpeg release (e.g. `8.1.3`). It publishes
the release `ffmpeg-<version>` with the binaries, their `SHA256SUMS`, the licence & how they were
built. Or:

```bash
gh workflow run ffmpeg.yml -f version=8.1.3
```

Locally (needs Docker): `scripts/ffmpeg/build.sh linux64 8.1.3` (or `win64`).

## License

FFmpeg built with these libraries is licensed under the GPL (see `LICENSE-ffmpeg.txt` in each
release).
